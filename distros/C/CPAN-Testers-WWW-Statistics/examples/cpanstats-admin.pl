#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.01';
$|++;

# cpanstats-admin.pl
#
# This is a temporary script to mark reports for exclusion from statistical 
# analysis. Typically because smoker is broker and submitting bogus reports.
# This script will be obsolete once the Admin site is launched.

#----------------------------------------------------------------------------
# Library Modules

use CPAN::Testers::Common::DBUtils;
use Config::IniFiles;
use Getopt::Long;
use JSON;
use File::Slurp;

#----------------------------------------------------------------------------
# Variables

my (%cfg);

#----------------------------------------------------------------------------
# The Application Programming Interface

load_configuration();

while(<DATA>) {
    next    if(/^\s*$/ || /^__/);
    my ($guid) = /([a-z0-9\-]+)/;
    next    unless($guid);

    my $query = 
        'SELECT c.id,c.guid,u.author,c.dist,c.version,c.type,c.state,c.perl FROM cpanstats AS c '.
        'INNER JOIN uploads AS u ON (u.dist=c.dist AND c.version=u.version) '.
        'WHERE c.guid = ?';
    my @rows = $cfg{CPANSTATS}->get_query('hash',$query,$guid);

    next    unless($rows[0]->{type} == 2);

    # reset type in cpanstats
    $query = 'UPDATE cpanstats SET type=3 WHERE guid=?';
    print "$query [$guid]\n";
    $cfg{CPANSTATS}->do_query($query,$guid);


    # get info from release_data
    $query = 'SELECT * FROM release_data WHERE guid=?';
    my @data = $cfg{CPANSTATS}->get_query('hash',$query,$guid);

    # delete from release_data
    $query = 'DELETE FROM release_data WHERE guid=?';
    print "$query [$guid]\n";
    $cfg{CPANSTATS}->do_query($query,$guid);

    # update release_summary
    my $field = lc $rows[0]->{state};
    if($field =~ /^(pass|fail|na|unknown)$/) {
        $query = 
            "UPDATE release_summary SET $field = $field - 1 ".
            'WHERE guid=? AND oncpan=? AND distmat=? AND perlmat=? AND patched=? AND dist=? AND version=?';
        print "$query [$guid,$data[0]->{oncpan},$data[0]->{distmat},$data[0]->{perlmat},$data[0]->{patched},$rows[0]->{dist},$rows[0]->{version}]\n";
        $cfg{CPANSTATS}->do_query($query,$guid,
            $data[0]->{oncpan},$data[0]->{distmat},$data[0]->{perlmat},$data[0]->{patched},
            $rows[0]->{dist},$rows[0]->{version});
    }    
    
    my $query1 = 'SELECT * FROM summary WHERE type=? AND name=?';
    my $query2 = 'UPDATE summary SET dataset=? WHERE type=? AND name=?';

    # update dist summary
    @data = $cfg{CPANSTATS}->get_query('hash',$query1,'distro',$rows[0]->{dist});
    if(@data) {
        my $json = decode_json($data[0]->{dataset});
        if($json->{stats} && $rows[0]->{perl} && $rows[0]->{osname} && $json->{stats}{$rows[0]->{perl}} && $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}) {
            print "DIST SUM WAS: $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}\n";
            $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}--;
            print "DIST SUM WAS: $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}\n";
            my $data = encode_json($json);
            $cfg{CPANSTATS}->do_query($query,$data,'distro',$rows[0]->{dist});
        }
    }

    # update author summary
    @data = $cfg{CPANSTATS}->get_query('hash',$query1,'author',$rows[0]->{author});
    if(@data) {
        my $json = decode_json($data[0]->{dataset});
        if($json->{stats} && $rows[0]->{perl} && $rows[0]->{osname} && $json->{stats}{$rows[0]->{perl}} && $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}) {
            print "AUTH SUM WAS: $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}\n";
            $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}--;
            print "AUTH SUM NOW: $json->{stats}{$rows[0]->{perl}}{$rows[0]->{osname}}{count}\n";
            my $data = encode_json($json);
            $cfg{CPANSTATS}->do_query($query,$data,'author',$rows[0]->{author});
        }
    }

    # update dist JSON files
    my $file = sprintf "/var/www/reports/html/static/distro/%s/%s.json",uc substr($rows[0]->{dist},0,1),$rows[0]->{dist};
    if(-f $file) {
        my @json;
        my $json = read_file($file);
        my $data = decode_json($json);
        print "JSON DIST WAS: ".scalar(@$data)."\n";
        while(my $item = shift @$data) {
            next    if($item->{guid} eq $guid);
            push @json, $item;
        }
        print "JSON DIST NOW: ".scalar(@json)."\n";
        next    unless(@json);
        $json = encode_json(\@json);
        write_file($file,$json);
    }

    # update author JSON files
    $file = sprintf "/var/www/reports/html/static/author/%s/%s.json",uc substr($rows[0]->{author},0,1),$rows[0]->{author};
    if(-f $file) {
        my @json;
        my $json = read_file($file);
        my $data = decode_json($json);
        print "JSON AUTH WAS: ".scalar(@$data)."\n";
        while(my $item = shift @$data) {
            next    if($item->{guid} eq $guid);
            push @json, $item;
        }
        print "JSON AUTH NOW: ".scalar(@json)."\n";
        next    unless(@json);
        $json = encode_json(\@json);
        write_file($file,$json);
    }

    # push page request for dist and author
    $query = 'INSERT INTO page_requests (type,name,weight) VALUES (?,?,?)';
    $cfg{CPANSTATS}->do_query($query,'distro',$rows[0]->{dist},50);
    $cfg{CPANSTATS}->do_query($query,'author',$rows[0]->{author},50);
}

#----------------------------------------------------------------------------
# Methods

sub load_configuration {
    GetOptions( \%cfg,

        # mandatory options
        'config|c=s',

        # other options
        'verbose|v',
        'version',
        'help|h'

    ) or usage(1);

    usage(1) if($cfg{help});
    usage(0) if($cfg{version});

    usage(1,"Must specify the configuration file")          unless(   $cfg{config});
    usage(1,"Configuration file [$cfg{config}] not found")  unless(-f $cfg{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $cfg{config} );

    # configure databases
    my %opts;
    my $db = 'CPANSTATS';
    die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
    $opts{$_} = $cfg->val($db,$_)   for(qw(driver database dbfile dbhost dbport dbuser dbpass));
    $cfg{$db} = CPAN::Testers::Common::DBUtils->new(%opts);
    die "Cannot configure $db database\n" unless($cfg{$db});

    return  unless($cfg{verbose});
    print STDERR "config: $_ = ".($cfg{$_}||'')."\n"  for(qw(config));
}

sub usage {
    my ($self,$full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print "\n";
        print "Usage:$0 [--verbose|v] --config|c=<file> \\\n";
        print "         ( [--help|h] [--version] \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program manages the cpan-tester addresses.\n";

        print "\nFunctional Options:\n";
        print "   --config=<file>           # path/file to configuration file\n";

        print "\nOther Options:\n";
        print "  [--verbose]                # turn on verbose messages\n";
        print "  [--version]                # display version string\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n";
    exit(0);
}


__END__
__DATA__
2370c52c-6a1a-11e0-9736-5845d53d7a3f
fd0411be-6a19-11e0-80c3-fd44d53d7a3f
d63420f6-6a19-11e0-9e4b-9f44d53d7a3f

