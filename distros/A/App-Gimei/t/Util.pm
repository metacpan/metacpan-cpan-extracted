use v5.42;

package t::Util;

use Exporter 'import';
our @EXPORT_OK = qw(run);

use lib ".";
use t::CLI;

use Test2::V1 -utf8;
use Test2::Tools::Spec;

#
# package methods
#

sub run (@tests) {
    foreach my $t (@tests) {
        my $cli = t::CLI->run( @{ $t->{args} } );

        if ( $t->{expected_error_message} ) {
            if ( ref( $t->{expected_error_message} ) eq 'Regexp' ) {
                T2->like(
                    $cli->error_message,
                    $t->{expected_error_message},
                    "$t->{Name} error_message"
                );
            } else {
                T2->is(
                    $cli->error_message,
                    $t->{expected_error_message},
                    "$t->{Name} error_message"
                );
            }
            T2->is( $cli->exit_code, undef, "$t->{Name} exit_code" );
        } else {
            T2->is( $cli->exit_code, 0, "$t->{Name} exit_code" );
        }

        if ( ref( $t->{expected_stdout} ) eq 'Regexp' ) {
            T2->like( $cli->stdout, $t->{expected_stdout}, "$t->{Name} stdout" );
        } else {
            T2->is( $cli->stdout, $t->{expected_stdout}, "$t->{Name} stdout" );
        }

        if ( ref( $t->{expected_stderr} ) eq 'Regexp' ) {
            T2->like( $cli->stderr, $t->{expected_stderr}, "$t->{Name} stderr" );
        } else {
            T2->is( $cli->stderr, $t->{expected_stderr}, "$t->{Name} stderr" );
        }
    }

    T2->done_testing;
}

1;
