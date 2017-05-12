#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '0.05';

#----------------------------------------------------------------------------

=head1 NAME

build-testers-db.pl - script to create the tables in the testers database

=head1 SYNOPSIS

  perl build-testers-db.pl --config=files.ini

=head1 DESCRIPTION

Builds the tables from existing data, both in the cpanstats and metabase
databases, and stand-alone files used by the system.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use Compress::Zlib;
use Config::IniFiles;
use DateTime;
use File::Basename;
use File::Slurp;
use Getopt::ArgvFile default=>1;
use Getopt::Long;
use IO::File;
use LWP::UserAgent;
use Path::Class;
use Parse::CPAN::Authors;
use Template;
use Time::Piece;
use WWW::Mechanize;

use CPAN::Testers::Common::DBUtils;

# -------------------------------------
# Variables

my $DEBUG = 0;

my %defaults = (
    'address'   => 'data/addresses.txt',
    'mailrc'    => 'data/01mailrc.txt',
);

my (%parsed_map,%cpan_map,%pause_map,%unparsed_map,%address_map,%domain_map,%target_map,%author_map,%named_map);
my (%result,%options);
my $parsed = 0;

# -------------------------------------
# Program

init_options();
load_addresses();
check() if($options{check});
build() if($options{build});

# -------------------------------------
# Functions

sub check {
    for my $name (keys %named_map) {
        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE name=?",$name);
        if(@rows) {
            next    if($rows[0]->{pause} eq $named_map{$name});
#            _log("Updating profile $name => $named_map{$name}") if($options{verbose});
#            $options{source}->do_query('UPDATE testers.profile SET pause=? WHERE name=?',$named_map{$name},$name);
            _log("UPDATE testers.profile SET pause='$named_map{$name}' WHERE name='$name'");
        } else {
#            _log("PAUSE name missing: $name => $named_map{$name}");
        }
    }    

    for my $pause (keys %author_map) {
        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE pause=?",$pause);
        next if(@rows);
        _log("PAUSE missing: $pause => $author_map{$pause}");
    }    

#    for my $email (keys %address_map) {
#        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.address WHERE email=?",$email);
#        next if(@rows);
#
#        @rows = $options{source}->get_query('hash',"SELECT * FROM cpanstats WHERE tester LIKE ?",'%' . $email . '%');
#        if(@rows) {
#            _log("EMAIL missing: $email => $address_map{$email}");
#        } else {
#            _log("EMAIL unused: $email => $address_map{$email}");
#        }
#    }    

    for my $address (keys %parsed_map) {
        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.address a LEFT JOIN testers.profile p ON p.testerid=a.testerid WHERE a.address=?",$address);
        if(@rows) {
            if($rows[0]->{name}) {
                my $name = $rows[0]->{name} . ($rows[0]->{pause} ? " ($rows[0]->{pause})" : '');
                next if($parsed_map{$address} eq $name);

                _log("NAME MAP missing: $name => $address => $parsed_map{$address}");
            } else {

                my ($name,$pause) = $parsed_map{$address} =~ /^(.*?)(?:(?:\s+\((\w+)\))|$)/;
                next    if($name =~ /\@/);

                if($pause) {
                    my @pause = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE pause=?",$pause);
                    if(@pause) {
                        $options{source}->do_query("UPDATE testers.address SET testerid=? WHERE addressid=?",$pause[0]->{testerid},$rows[0]->{addressid});
                        _log("-- UPDATE testers.address SET testerid=$pause[0]->{testerid} WHERE addressid=$rows[0]->{addressid};");
                    } else {
                        @pause = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE name=?",$name);
                        if(@pause) {
                            $options{source}->do_query("UPDATE testers.address SET testerid=? WHERE addressid=?",$pause[0]->{testerid},$rows[0]->{addressid});
                            _log("-- UPDATE testers.address SET testerid=$pause[0]->{testerid} WHERE addressid=$rows[0]->{addressid};");
                        } else {
                            _log("INSERT testers.profile SET name='$name', pause='$pause';");
                        }
                    }
                } else {
                    my @pause = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE name=?",$name);
                    if(@pause) {
                        $options{source}->do_query("UPDATE testers.address SET testerid=? WHERE addressid=?",$pause[0]->{testerid},$rows[0]->{addressid});
                        _log("-- UPDATE testers.address SET testerid=$pause[0]->{testerid} WHERE addressid=$rows[0]->{addressid};");
                    } else {
                        _log("INSERT testers.profile SET name='$name';");
                    }
                }
            }
 
        } else {
            @rows = $options{source}->get_query('hash',"SELECT * FROM cpanstats WHERE tester = ?",$address);
            if(@rows) {
#                _log("ADDRESS missing: $address => $parsed_map{$address}");
            } else {
#                _log("ADDRESS unused: $address => $parsed_map{$address}");
            }
        }
    }    

#    for my $pause (keys %pause_map) {
#        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.profile WHERE pause=?",$pause);
#        next if(@rows);
#        _log("ALIAS missing: $pause => $pause_map{$pause}");
#    }    

#    for my $email (keys %cpan_map) {
#        my @rows = $options{source}->get_query('hash',"SELECT * FROM testers.address WHERE email=?",$email);
#        next if(@rows);
#        _log("CPAN missing: $email => $cpan_map{$email}");
#    }    
}

sub build {
    my $next;

    if($options{max}) {
        my @rows = $options{source}->get_query('array',"SELECT MAX(id) FROM testers.ixreport");
        $options{from} = $rows[0]->[0]  if(@rows);
    }

    # find all reports since last update
    if($options{from}) {
        $next = $options{source}->iterator('hash',"SELECT * FROM cpanstats WHERE type=2 AND id >= $options{from} ORDER BY id");
    } else {
        $next = $options{source}->iterator('hash',"SELECT * FROM cpanstats WHERE type=2 ORDER BY id");
    }

    #my $next = $options{source}->iterator('hash',"SELECT c.id,c.guid,c.fulldate,c.tester FROM cpanstats c LEFT JOIN testers.ixreport r ON r.id=c.id WHERE c.type=2 AND r.id IS NULL ORDER BY c.id");

    while(my $row = $next->()) {
        my ($testerid,$addressid,$email);
        my @address = $options{source}->get_query('hash','SELECT * FROM testers.address WHERE address=?',$row->{tester});
        if($address[0]) {
            $testerid  = $address[0]->{testerid};
            $addressid = $address[0]->{addressid};
            $email     = $address[0]->{email};
        } else {
            $email = extract_email($row->{tester});
            $addressid = $options{source}->id_query('INSERT INTO testers.address SET testerid=0,address=?,email=?',$row->{tester},$email);
            _log("Creating address entry: $row->{tester},$email,$addressid");
            $testerid = 0;
        }

        my @report = $options{source}->get_query('hash','SELECT * FROM testers.ixreport WHERE id=?',$row->{id});
        if($report[0]) {
            _log("Updating report index: $report[0]->{id},$row->{tester},$email,$addressid") if($options{verbose});
            $options{source}->do_query('UPDATE testers.ixreport SET guid=?,fulldate=?,addressid=? WHERE id=?',$row->{guid},$row->{fulldate},$addressid,$report[0]->{id});
        } else {
            _log("Creating report index: $row->{id},$row->{tester},$email,$addressid") if($options{verbose});
            $options{source}->do_query('INSERT INTO testers.ixreport SET id=?,guid=?,fulldate=?,addressid=?',$row->{id},$row->{guid},$row->{fulldate},$addressid);
        }

        my $target = $parsed_map{$row->{tester}};
        $target = $address_map{$email}  unless($target);
        $target = $cpan_map{$email}     unless($target);

        unless($target) {
            my @rows = $options{source}->get_query('hash','SELECT fullname FROM metabase.testers_email WHERE email=? or email=?',$email,$row->{tester});
            $target = $rows[0]->{fullname} if(@rows);
        }

        if($target) {
            my ($name,$pause) = $target =~ /^(.*?)(?:(?:\s+\((\w+)\))|$)/;
            my $profile;
            if($pause) {
                my @rows = $options{source}->get_query('hash','SELECT * FROM testers.profile WHERE pause=?',$pause);
                $profile = $rows[0] if(@rows);
            }
            if(!$profile && $name) {
                my @rows = $options{source}->get_query('hash','SELECT * FROM testers.profile WHERE name=?',$name);
                $profile = $rows[0] if(@rows);
            }
            if($profile) {
                if($testerid != $profile->{testerid}) {
                    _log("Updating address entry from profile: $row->{tester},$email,$addressid,$profile->{testerid},$name,$pause") if($options{verbose});
                    $options{source}->do_query('UPDATE testers.address SET testerid=? WHERE addressid=?',$profile->{testerid},$addressid);
                }
            } elsif($name) {
                _log("Creating profile: $row->{tester},$email,$addressid,-,$name,$pause");
                my $id = $options{source}->id_query('INSERT INTO testers.profile SET name=?,pause=?',$name,$pause);
                $options{source}->do_query('UPDATE testers.address SET testerid=? WHERE addressid=?',$id,$addressid);
                _log("Updating address entry from profile: $row->{tester},$email,$addressid,$profile->{testerid},$name,$pause") if($options{verbose});
            }
        } else {
            _log("No target found: $row->{tester},$email,$addressid");
        }
    }
}

sub load_addresses {
    my $fh = IO::File->new($options{address})    or die "Cannot open address file [$options{address}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($source,$target) = (/(.*),(.*)/);
        next    unless($source && $target);
        $parsed_map{$source} = $target;
        my $email = extract_email($source);
        next    unless($email);

        my ($local,$domain) = split(/\@/,$email);
        $address_map{$email} = $target;
        $domain_map{$domain} = $target;
        $target_map{$target} = $email;
        my ($author) = ($target =~ /\(([A-Z0-9]+)\)/);
        $author_map{$author} = $email if($author);
#_log("$source => $local => $domain\n"   unless($domain);

    }
    $fh->close;

    if($options{verbose}) {
        _log("parsed entries  = " . scalar(keys %parsed_map));
        _log("address entries = " . scalar(keys %address_map));
        _log("domain entries  = " . scalar(keys %domain_map));
    }
#    use Data::Dumper;
#    _log(Dumper(\%domain_map);

    $fh = IO::File->new($options{mailrc})    or die "Cannot open mailrc file [$options{mailrc}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($alias,$name,$email) = (/alias\s+([A-Z]+)\s+"([^<]+) <([^>]+)>"/);
        next    unless($alias);
        $named_map{$name}  = "$alias";
        $pause_map{lc($alias)} = "$name ($alias)";
        $cpan_map{lc($email)}  = "$name ($alias)";
    }
    $fh->close;

    if($options{verbose}) {
        _log("pause entries = " . scalar(keys %pause_map));
        _log("cpan entries  = " . scalar(keys %cpan_map));
    }
}

sub extract_email {
    my $address = shift;
    my ($email) = $address =~ /([-+=\w]+\@(?:[-\w]+\.)+(?:[a-z]{2,}))/i;
    return lc $email;
}

sub init_options {
    GetOptions( \%options,
        'config=s',
        'build',
        'check',
        'max',
        'verbose',
        'help|h',
        'version|V'
    );

    _help(1)    if($options{help});
    _help(0)    if($options{version});

    die "Configuration file [$options{config}] not found\n" unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure cpanstats DB
    my %opts = map {$_ => $cfg->val('CPANSTATS',$_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    $options{source} = CPAN::Testers::Common::DBUtils->new(%opts);

    die "Cannot configure SOURCE database\n"    unless($options{source});

    # use defaults if none provided
    for my $opt (qw(address mailrc verbose logfile logclean)) {
        $options{$opt} ||= $cfg->val('MASTER',$opt) || $defaults{$opt};
    }
}

sub _help {
    my $full = shift;

    if($full) {
        print <<HERE;

Usage: $0 \\
         [-config=<file>] [--build [--max | --from=<id>]] [--check] [-h] [-V]

  --config=<file>   database configuration file

  --build           build testers database
  --max             build from the last id
  --from=<id>       build from a specific id

  --check           checks whether the loaded data has been saved

  -h                this help screen
  -V                program version

HERE

    }

    print "$0 v$VERSION\n";
    exit(0);
}


sub _log {
    return  unless($options{logfile});

    my $mode = $options{logclean} ? 'w+' : 'a+';
    my $log = IO::File->new($options{logfile},$mode) or die "Cannot open file [$options{logfile}]: $!\n";
    $options{logclean} = 0;

    my $ts = DateTime->now->datetime();
    print $log join(' ',$ts,@_) . "\n";
    $log->close;
}

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Admin

=head1 SEE ALSO

L<CPAN::WWW::Testers>,
L<CPAN::Testers::WWW::Admin>

F<http://www.cpantesters.org/>,
F<https://admin.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2014 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
