package CPAN::Testers::WWW::Development;

use warnings;
use strict;

$|++;

our $VERSION = '2.11';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Development - The CPAN Testers Development website

=head1 SYNOPSIS

  perl cpandevel-writepages

This script calls this module as appropriate.

=head1 DESCRIPTION

Using the locations listed in the configuration file, calculates the file sizes
of the CPAN Testers databases, which should in the local directory, extracts
all the data into the components of each page. Then creates each HTML page for
the site.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use Config::IniFiles;
use File::Basename;
use File::Copy;
use File::Path;
use Getopt::ArgvFile default=>1;
use Getopt::Long;
use Number::Format qw(format_bytes);
use Template;

# -------------------------------------
# Variables

my (%options);

$Number::Format::KILO_SUFFIX = ' KB';
$Number::Format::MEGA_SUFFIX = ' MB';
$Number::Format::GIGA_SUFFIX = ' GB';

# -------------------------------------
# Program

# -------------------------------------
# Subroutines

=head1 FUNCTIONS

=over 4

=item main

Main control routine. Calls init_options and make_pages.

=item init_options

Prepare command line options

=item make_pages

Create all the appropriate pages for the website.

=cut

sub main {
    init_options();
    make_pages();
}

sub make_pages {
    my %tvars;

    for($options{cfg}->Parameters('LOCATIONS')) {
        my $source = $options{cfg}->val('LOCATIONS',$_);
        $tvars{$_} = -f $source ? format_bytes((-s $source)) : 0;
    }

    $tvars{VERSION} = $VERSION;

    my %config = (                          # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $options{templates},
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
        TRIM            => 1,
    );

    my $target = $options{directory} . '/index.html';
    my $parser = Template->new(\%config);   # initialise parser
    $parser->process('index.html',\%tvars,$target) # parse the template
        or die $parser->error() . "\n";

    foreach my $filename (@{$options{tocopy}}) {
        my $src  = $options{templates} . "/$filename";
        if(-f $src) {
            my $dest = $options{directory} . "/$filename";
            mkpath( dirname($dest) );
            if(-d dirname($dest)) {
                copy( $src, $dest );
            } else {
                warn "Missing directory: $dest\n";
            }
        } else {
            warn "Missing file: $src\n";
        }
    }
}

sub init_options {
    GetOptions( \%options,
        'config=s',
        'templates=s',
        'directory=s',
        'logfile=s',
        'logclean=i',
        'help|h',
        'version|v'
    );

    _help(1) if($options{help});
    _help(0) if($options{version});

    # ensure we have a configuration file
    die "Must specify the configuration file\n"             unless(   $options{config});
    die "Configuration file [$options{config}] not found\n" unless(-f $options{config});

    # load configuration file
    local $SIG{'__WARN__'} = \&_alarm_handler;
    eval { $options{cfg} = Config::IniFiles->new( -file => $options{config} ); };
    die "Cannot load configuration file [$options{config}]: $@\n"   unless($options{cfg} && !$@);

    my @TOCOPY = split("\n", $options{cfg}->val('TOCOPY','LIST'));
    $options{tocopy} = \@TOCOPY;

    $options{templates} ||= $options{cfg}->val('MASTER','templates');
    $options{directory} ||= $options{cfg}->val('MASTER','directory');
    $options{logfile}   ||= $options{cfg}->val('MASTER','logfile'  );
    $options{logclean}  ||= $options{cfg}->val('MASTER','logclean' ) || 0;

    _log("$_=".($options{$_}|| ''))  for(qw(templates logfile logclean directory));

    die "Must specify the output directory\n"           unless(   $options{directory});
    die "Must specify the template directory\n"         unless(   $options{templates});
    die "Template directory not found\n"                unless(-d $options{templates});
    mkpath($options{directory});
    die "Could not create output directory\n"           unless(-d $options{directory});
}

# -------------------------------------
# Private Methods

sub _help {
    my $full = shift;

    if($full) {
        print "\n";
        print "Usage:$0 --config=<file> \\\n";
        print "         [--logfile=<file> [--logclean=<1|0>]] \\\n";
        print "         [--templates=<dir>]   \\\n";
        print "         [--directory=<dir>]   \\\n";
        print "         [--help|h] [--version|v] \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program builds the CPAN Testers Statistics website.\n";

        print "\nFunctional Options:\n";
        print "  [--config=<file>]          # path to config file [required]\n";
        print "  [--templates=<dir>]        # path to templates\n";
        print "  [--directory=<dir>]        # path to website directory\n";
        print "  [--logfile=<file>]         # path to logfile\n";
        print "  [--logclean]		        # overwrite log if specified\n";

        print "\nOther Options:\n";
        print "  [--version]                # program version\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n";
    exit(0);
}

sub _log {
    my $log = $options{logfile} or return;
    mkpath(dirname($log))   unless(-f $log);

    my $mode = $options{logclean} ? 'w+' : 'a+';
    $options{logclean} = 0;

    my @dt = localtime(time);
    my $dt = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $dt[5]+1900,$dt[4]+1,$dt[3],$dt[2],$dt[1],$dt[0];

    my $fh = IO::File->new($log,$mode) or die "Cannot write to log file [$log]: $!\n";
    print $fh "$dt ", @_, "\n";
    $fh->close;
}

1;

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Development

=head1 SEE ALSO

F<http://devel.cpantesters.org/>,
F<http://blog.cpantesters.org/>,
F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

F<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

F<http://iheart.cpantesters.org>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2016 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
