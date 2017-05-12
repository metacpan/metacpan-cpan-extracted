#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '3.44';

$|++;

#----------------------------------------------------------------------------

=head1 NAME

compress-reports.pl - program to compress CPAN Testers reports.

=head1 SYNOPSIS

  perl compress-reports.pl

=head1 DESCRIPTION

Called via the command line, will compress a set of CPAN Testers reports.

=cut

# -------------------------------------
# Library Modules

use lib qw(/var/www/reports/cgi-bin/lib /var/www/reports/cgi-bin/plugins);

use Labyrinth;
use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Globals  qw(:all);
use Labyrinth::Variables;
use Labyrinth::Plugin::CPAN;

use Config::IniFiles;
use Data::Dumper;
use Data::FlexSerializer;
use Getopt::Long;

# -------------------------------------
# Variables

my $VHOST = '/var/www/reports/';
my (%options,$serializer,$cpan,$dbx);
my $limit = 1_000_000;

# -------------------------------------
# Program

init_options();
process_reports();

# -------------------------------------
# Subroutines

sub init_options {
    GetOptions(\%options, 'from=i', 'to=i') or usage();
    usage(1,'missing lower limit --from')                           unless(defined $options{from});
    $options{to} ||= $options{from} + $limit;
#print "$options{to} - $options{from} = " .  $options{to}-$options{from} . "\n";
    usage(1,'lower limit os greater than upper limit')              unless($options{from} < $options{to});
    usage(1,'difference between limits is greater than 1 million')  unless($options{to} - $options{from} <= $limit);

    $options{config} = $VHOST . 'cgi-bin/config/settings.ini';

    error("Must specific the configuration file\n")             unless($options{config});
    error("Configuration file [$options{config}] not found\n")  unless(-f $options{config});

    $serializer = Data::FlexSerializer->new(
        detect_compression => 1,
    );

    # load configuration
    Labyrinth::Variables::init();   # initial standard variable values
    LoadSettings($options{config});            # Load All Global Settings

    SetLogFile( FILE   => $settings{'logfile'} . '.serializer.log',
                USER   => 'labyrinth',
                LEVEL  => ($settings{'loglevel'} || 0),
                CLEAR  => 1,
                CALLER => 1);

    DBConnect();

    $cpan = Labyrinth::Plugin::CPAN->new();
    $dbx = $cpan->DBX('metabase');
    $cpan->Configure();

    LogDebug("DEBUG: configuration done");
}

sub process_reports {
    for my $next ( $options{from} .. $options{to} ) {
        my @rows = $dbx->GetQuery('hash','GetReport',$next);
        unless(@rows) {
            print "$next: no report\n";
            next;
        }

        my $row = $rows[0];

        my ($data,$json);
        eval {
            $json = $serializer->deserialize($row->{report});
            $data = $serializer->serialize($json);
        };

        if($@ || !$data) {
            print "$row->{id}: no data - $@\n";
            next;
        }

        $dbx->DoQuery('UpdateReport',$data,$row->{id});
        print "$row->{id}: update\n";
    }
}

sub usage {
    my ($full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print "\n";
        print "Usage: $0 --from=<num> [--to=<num>]\n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program manages the cpan-tester reports compression.\n";

        print "\nFunctional Options:\n";
        print "   --from=<num>              # starting report number\n";
        print "  [--to=<num>]               # finishing report number (optional)\n";

        print "\n--to must be greater than --from, with a maximum of 1 million difference.";
        print "\nBy default 1 million is set as the upper limit\n";
    }

    print "\n$0 v$VERSION\n\n";
    exit(0);
}

1;

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers=WWW-Reports

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>,
L<CPAN::Testers::WWW::Wiki>,
L<CPAN::Testers::WWW::Blog>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie       <barbie@cpan.org>   2008-present

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2013 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
