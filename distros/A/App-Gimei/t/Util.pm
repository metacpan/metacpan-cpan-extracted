use v5.36;

package t::Util;

use Exporter 'import';
our @EXPORT_OK = qw(run);

use lib ".";
use t::CLI;

use Test::More;

sub run {
    my @tests = @_;

    foreach my $t (@tests) {
        my $cli = t::CLI->run( @{ $t->{args} } );

        if ( $t->{expected_error_message} ) {
            if ( ref( $t->{expected_error_message} ) eq 'Regexp' ) {
                like $cli->error_message, $t->{expected_error_message},
                  "$t->{Name} error_message";
            } else {
                is $cli->error_message, $t->{expected_error_message},
                  "$t->{Name} error_message";
            }
            is $cli->exit_code, undef, "$t->{Name} exit_code";
        } else {
            is $cli->exit_code, 0, "$t->{Name} exit_code";
        }

        if ( ref( $t->{expected_stdout} ) eq 'Regexp' ) {
            like $cli->stdout, $t->{expected_stdout}, "$t->{Name} stdout";
        } else {
            is $cli->stdout, $t->{expected_stdout}, "$t->{Name} stdout";
        }

        if ( ref( $t->{expected_stderr} ) eq 'Regexp' ) {
            like $cli->stderr, $t->{expected_stderr}, "$t->{Name} stderr";
        } else {
            is $cli->stderr, $t->{expected_stderr}, "$t->{Name} stderr";
        }
    }

    done_testing;
}
1;
