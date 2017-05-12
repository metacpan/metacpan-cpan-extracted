#!/usr/bin/perl -w
use strict;

my $VERSION = '0.11';

#----------------------------------------------------------------------------

=head1 NAME

addresses-parser.pl - parse old-style addresses file, and write to database.

=head1 SYNOPSIS

  perl addresses.pl --address|a=<file>

=head1 DESCRIPTION

Using the old addresses file format, parse and update the database.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use CPAN::Testers::Common::DBUtils;
use Config::IniFiles;
use IO::File;
use Getopt::Long;

# -------------------------------------
# Variables

my %defaults = (
    'address'   => 'data/addresses.txt',
);

my (%options,$dbh);

my %phrasebook = (
    'InsertTester'          => q{INSERT INTO tester_profile (name,pause) VALUES (?,?)},
    'GetTesterByPause'      => q{SELECT testerid FROM tester_profile WHERE pause = ?},
    'GetTesterByName'       => q{SELECT testerid FROM tester_profile WHERE name = ?},

    'InsertAddress'         => q{INSERT INTO tester_address (testerid,address,email) VALUES (?,?,?)},
    'GetAddressByText'      => q{SELECT addressid,testerid FROM tester_address WHERE address = ?},
    'UpdateAddress'         => q{UPDATE tester_address SET testerid=? WHERE addressid=?},
);

# -------------------------------------
# Program

init_options();
load_addresses();

# -------------------------------------
# Subroutines

=head1 FUNCTIONS

=over 4

=item load_addresses

Loads all the data files with addresses against we can match, then load all
the addresses listed in the DB that we need to match against.

=cut

sub load_addresses {
    my ($testerid,$addressid) = (1,1);
    my (%tester,%address);

    $tester{'UNKNOWN USER'}->{pause} = '';
    $tester{'UNKNOWN USER'}->{id} = $testerid++;

    my $fh = IO::File->new($options{address})    or die "Cannot open address file [$options{address}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($source,$target) = (/(.*),(.*)/);
        next    unless($source && $target);

        my ($email) = $source =~ /([-+=\w.]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|[a-z]{2,2}))/i;
        my $name = $target;
        my ($pause) = $name =~ /\(([A-Z]+)\)$/;
        if($pause) {
            $name =~ s/ \($pause\)//;
        } else {
            $pause = '';
        }

        my @rows = $dbh->get_query('hash',$phrasebook{'GetTesterByPause'},$pause);
        @rows = $dbh->get_query('hash',$phrasebook{'GetTesterByName'},$name)  unless(@rows);

        my $testerid = 0;
        if(@rows && $rows[0]->{testerid}) {
            $testerid = $rows[0]->{testerid};
        } else {
            printf "INSERT INTO tester_profile (name,pause) VALUES ('%s','%s');\n", quote($name),$pause;
            $testerid = $dbh->id_query($phrasebook{'InsertTester'},$name,$pause);
        }

        @rows = $dbh->get_query('hash',$phrasebook{'GetAddressByText'},$source);
        if(@rows) {
            if($rows[0]->{testerid} == 0 && $testerid != 0) {
                printf "UPDATE tester_address SET testerid=%d WHERE addressid=%d;\n", $testerid,$rows[0]->{addressid};
                $dbh->do_query($phrasebook{'UpdateAddress'},$testerid,$rows[0]->{addressid});
            }
        } else {
            my $email = extract_email($source);
            printf "INSERT INTO tester_address (testerid,address,email) VALUES (%s,'%s','%s');\n", $testerid,quote($source),quote($email);
            $dbh->do_query($phrasebook{'InsertAddress'},$testerid,$source,$email);
        }
    }
    $fh->close;
}

sub quote {
    my $str = shift;
    $str =~ s/'/\\'/g;
    return $str;
}

sub extract_email {
    my $str = shift;
    #my ($email) = $str =~ /([-+=\w.]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|[a-z]{2,2}))/i;
    my ($email) = $str =~ /([-+=\w.]+\@[-\w\.]+)/i;
    return $email || '';
}

=item init_options

Prepare command line options

=cut

sub init_options {
    my $self = shift;
    my %hash = @_;
    my @options = qw(address verbose);

    GetOptions( \%options,
        'config|c=s',   # config file
        'address|a=s',  # address file
        'verbose|v',    # verbose messages
        'help|h'        # help screen
    ) or _help();

    $options{$_} ||= $hash{$_}  for(qw(config help),@options);

    _help(1) if($options{help});

    _help(1,"Must specify the configuration file")                       unless(   $options{config});
    _help(1,"Configuration file [$options{config}] not found")   unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure databases
    my %opts;
    my $db = 'CPANSTATS';
    die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
    $opts{$_} = $cfg->val($db,$_)   for(qw(driver database dbfile dbhost dbport dbuser dbpass));
    $dbh = CPAN::Testers::Common::DBUtils->new(%opts);
    die "Cannot configure $db database\n" unless($dbh);

    # use configuration settings or defaults if none provided
    for my $opt (@options) {
        $options{$opt} ||= $cfg->val('MASTER',$opt) || $defaults{$opt};
    }

    return  unless($options{verbose});
    print STDERR "config: $_ = ".($options{$_}||'')."\n"  for(@options);
}

sub _help {
    my ($self,$full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print "\n";
        print "Usage:$0 [--verbose|v] --config|c=<file> \\\n";
        print "         ( [--help|h] \\\n";
        print "         --address=<file> \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program manages the cpan-tester addresses.\n";

        print "\nFunctional Options:\n";
        print "   --config=<file>           # path/file to configuration file\n";
        print "   --address=<file>          # path/file to address file\n";

        print "\nOther Options:\n";
        print "  [--verbose]                # turn on verbose messages\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n";
    exit(0);
}

__END__

=back

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2013 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut

