# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN{
    use_ok( 'Carp::Proxy',
            fatal      => {},
            fatal_exit => { exit_code => 17 },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->exit_code( $setting )
        if defined $setting;

    return;
}

sub main {

    foreach my $tuple ( [ \&fatal,      undef, 1,  'default'     ],
                        [ \&fatal,      5,     5,  'override'    ],
                        [ \&fatal_exit, undef, 17, 'constructor' ],
                      ) {

        my( $proxy, $setting, $exit_code, $title ) = @{ $tuple };

        my $pid = fork();

        SKIP: {

            skip 'Unable to fork()', 1
                if not defined $pid;

            if (not $pid) { # child

                #-----
                # We don't want the proxy to spew diagnostics to our
                # test suite, so we attempt to capture the spew in a
                # scalar (string filehandle).
                #-----
                my $log_out = '';
                close STDOUT                or exit 96;
                open STDOUT, '>', \$log_out or exit 97;

                my $log_err = '';
                close STDERR                or exit 98;
                open STDERR, '>', \$log_err or exit 99;

                $proxy->('handler', $setting );
            }
            else { # parent

                waitpid $pid, 0;
                my $status = $CHILD_ERROR >> 8;

                is
                    $status,
                    $exit_code,
                    "Exit code $exit_code validates for $title";
            }
        }
    }

    return;
}
