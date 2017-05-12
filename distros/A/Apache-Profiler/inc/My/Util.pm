package inc::My::Util;

use strict;
use base 'Exporter';

our @EXPORT_OK = qw(mod_perl_version);

sub mod_perl_version {
    eval {
        require mod_perl;
    };
    unless ($@) {
        if ($mod_perl::VERSION < 1.99) {
            # mod_perl 1.x
            return 1;
        }
        elsif ($mod_perl::VERSION < 1.999022) {
            # mod_perl2 prior to RC5
            die mp2_version_error($mod_perl::VERSION);
        }
    }

    eval {
        require mod_perl2;
    };
    unless ($@) {
        if ($mod_perl::VERSION < 1.999022) {
            # mod_perl2 prior to RC5
            die mp2_version_error($mod_perl::VERSION);
        }
        else {
            return 2;
        }
    }

    # return minimum required version
    return 1;
}

sub mp2_version_error {
    my $version = shift;

    return
        "mod_perl 2.0.0 RC5 (1.999022) or later is required for this module\n".
        "    found version $version at ". $INC{'mod_perl.pm'}. "\n";
}

1;
