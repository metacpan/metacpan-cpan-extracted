package Test::PrettyCure;
use strict;
use warnings;
use utf8;

# The helpers shared by the tests. They are written on Test2 (Test2::API and Test2::Tools::*), so that
# they work both in the tests on Test::More and in the ones on Test2::V0 (phase 2 moves every test to
# Test2::V0; #6).
use Test2::API qw(context test2_add_callback_post_load test2_stack);
use Test2::Tools::Compare ();
use Encode qw(decode_utf8);
use Exporter 'import';

our @EXPORT = qw(is_output);

# The test names and the diagnostics are Japanese: print them as UTF-8, as Test2::Plugin::UTF8 does
# (without its `use utf8`, which would not reach the test file from here).
test2_add_callback_post_load(
    sub {
        my $format = test2_stack()->top->format;
        $format->encoding('utf8') if $format && $format->can('encoding');
    }
);

# is_output { CODE } $expected, $name;
#
# Runs CODE, and checks that what it printed to STDOUT is $expected, with the colors stripped.
sub is_output(&$;$) {
    my ( $func, $expected, $name ) = @_;
    my $ctx = context();

    my $output = '';
    my $ok     = eval {
        open my $out, '>', \$output or die "Cannot open a scalar: $!";
        local *STDOUT = $out;
        $func->();
        close $out;
        1;
    };
    unless ($ok) {
        # Release the context before the error goes on, or Test2 adds a warning about a context
        # destroyed without release() that hides the real failure.
        my $error = $@;
        $ctx->release;
        die $error;
    }
    $output =~ s/\e\[(?:[34]8;5;[0-9]+?|0)m//g;    # strip the colors

    my $passed = Test2::Tools::Compare::is( decode_utf8($output), $expected, $name );
    $ctx->release;
    return $passed;
}

1;
