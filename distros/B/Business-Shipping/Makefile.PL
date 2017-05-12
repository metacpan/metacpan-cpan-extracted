#!/bin/env perl

use 5.006000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use English;

# Defaults
my %my_globals = (
    PREFIX_DIR => '/usr/local/B_Shipping'

        # These are set manually later on, so don't bother defaulting them.
        #CONFIG_DIR	=> '/usr/local/B_Shipping/config',
        #LOG_DIR     => '/usr/local/B_Shipping/log',
        #DATA_DIR	=> '/usr/local/B_Shipping/data',
);

=head1 USAGE

 perl Makefile.PL [--use_defaults=<1|0>] [-u=<1|0>]
 
 -u=1 or --use_defaults=1: Use default values, do not ask for values.  
 
 This option is only available if you have Getopt::Long installed.

=cut

# Default is zero, but can be overridden by environment variable, which,
# in turn, can be overridden by command-line.
$::UseDefaults = $ENV{B_SHIPPING_USE_DEFAULTS} ? 1 : 0;

if (@ARGV) {
    eval { require Getopt::Long };
    if ($@) {
        warn "Getopt::Long required in order to use command line arguments.";
    }
    else {
        import Getopt::Long;
        Getopt::Long::GetOptions('use_defaults=i' => \$::UseDefaults);
    }
}

WriteMakefile(
    NAME         => 'Business::Shipping',
    VERSION_FROM => 'lib/Business/Shipping.pm',
    ABSTRACT  => 'Business::Shipping - Rates and tracking for UPS and USPS',
    AUTHOR    => 'Daniel Browning <db@kavod.com>',
    CONFIGURE => \&extra_WriteMakefile_options,
    PREREQ_PM => {
        'Any::Moose'       => 0,
        'Config::IniFiles' => 0,
        'Log::Log4perl'    => 0,
        'Test::More'       => 0.40,
    },
    EXE_FILES => ['bin/update-UPS-surcharge.pl',],
    NO_META   => 1,
);

# Override the standard "install" target, so that it calls
# "support_files_install"
sub MY::install {

    package MY;
    my $inherited = shift->SUPER::install(@_);
    my $new;
    for (split("\n", $inherited)) {
        if (/^install :: /) {
            $_ .= " support_files_install";
        }
        $new .= "$_\n";
    }
    return $new;
}

# Currently there is no data files installation, because the data files are
# installed by the DataFiles module.
sub MY::postamble {
    return qq{
docs :
	find lib -name '*.pm' -or -name '*.pod' -exec podchecker -nowarnings {} \\;
	pod2text doc/INSTALL.pod > INSTALL
	pod2html doc/INSTALL.pod > doc/INSTALL.html
	pod2text doc/INSTALL.pod > doc/INSTALL.txt
	pod2text lib/Business/Shipping.pm > README
	pod2text lib/Business/Shipping.pm > doc/README.txt
	pod2html lib/Business/Shipping.pm > doc/README.html
	
support_files_install :
	\@echo "Installing configuration files to $my_globals{CONFIG_DIR}"
	\@\$(MKPATH) $my_globals{LOG_DIR}
	\@\$(MKPATH) $my_globals{CONFIG_DIR}
	\@\$(CP) -R -f config/* $my_globals{CONFIG_DIR}/
};    #/qq
}    #/sub MY::postamble

sub extra_WriteMakefile_options {
    if (not $::UseDefaults) {
        my $module = 'Business::Shipping';

        my $question = qq(
             ---  $module configuration, logging, and data directory  ---
  
What directory should be used for storing configuration files, logging files, and data?

$module support files directory:);

        $my_globals{PREFIX_DIR} = prompt($question, $my_globals{PREFIX_DIR},);

        $my_globals{PREFIX_DIR} =~ s:[\\/]\s*$::;
        $my_globals{PREFIX_DIR} =~ s:^\s*::;
    }    # end if not use defaults

    $my_globals{CONFIG_DIR} = $my_globals{PREFIX_DIR} . '/config';
    $my_globals{LOG_DIR}    = $my_globals{PREFIX_DIR} . '/log';
    $my_globals{DATA_DIR}   = $my_globals{PREFIX_DIR} . '/data';

    # Now we are going to substitute the support files directory in
    # lib/Business/Shipping/Config.pm
    subst(
        variables => {
            DEFAULT_CONFIG_DIR => $my_globals{CONFIG_DIR},
            DEFAULT_LOG_DIR    => $my_globals{LOG_DIR},
            DEFAULT_DATA_DIR   => $my_globals{DATA_DIR},
        },
        files => ['lib/Business/Shipping/Config.pm', 'config/log4perl.conf',]
    );

    my %EXTRA_CONFIG_OPTIONS;

    #$EXTRA_CONFIG_OPTIONS{ }
    #$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';

    return \%EXTRA_CONFIG_OPTIONS;
}

=head1 METHODS

=head2 subst( files => [ ], variables => { } )

Converts variables, like so:
 
 $a = '~_~SUPPORT_FILES_DIR~_~';

into

 $a = '/blah/blah/';

=cut

# TODO: Make this Windows compatible
sub subst {
    my (%opt) = @_;

    return unless $opt{files} and $opt{variables};

    my $base_path = '.';
    foreach my $file (@{ $opt{files} }) {
        $file = "$base_path/$file";

        copy($file, "$file.tmp") or die "Copy failed: $OS_ERROR";
        open(NEW, ">$file")     or die "Open failed: $OS_ERROR";
        open(OLD, "<$file.tmp") or die "Open failed: $OS_ERROR";

        # Read in the entire file for speed.
        undef $INPUT_RECORD_SEPARATOR;

        # This regex taken from Interchange (http://www.icdevgroup.org) and
        # modified slightly to work with extra newlines required by perltidy.
        $_ = <OLD>;
        s{.*\n\n?(#(.*)~_~(\w+)~_~(.*))}{$2 . $opt{ variables }->{ $3 } . "$4\n\n$1"}eg;
        print NEW $_;

        close NEW;
        close OLD;
        unlink "$file.tmp" or die "Delete failed: $OS_ERROR";
    }

    return;
}
