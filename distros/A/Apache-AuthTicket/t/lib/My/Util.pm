package My::Util;

use strict;
use base 'Exporter';

our @EXPORT_OK = qw(mod_perl_version);

sub mod_perl_version {
    # try MP2
    eval {
        require mod_perl2;
    };
    unless ($@) {
        return 2;
    }

    # try MP1
    eval {
        require mod_perl;
    };
    unless ($@) {
        if ($mod_perl::VERSION >= 1.99) {
            # mod_perl 2, prior to the mod_perl2 rename
            die "mod_perl 2.0 RC5 or later is required\n";
        }

        return 1;
    }

    # assume mod_perl version 2 is wanted
    return 2;
}

1;
