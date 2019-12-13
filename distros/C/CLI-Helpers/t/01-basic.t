use strict;
use warnings;

use Capture::Tiny qw(capture);
use CLI::Helpers qw( :output delay_argv );
use Test::More qw( no_plan );


cli_helpers_initialize([]);
my ($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\n", "normal output");
ok($stderr eq "normal stderr\n", "normal stderr");

cli_helpers_initialize(['--verbose']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\n", "verbose output");

cli_helpers_initialize(['-v','-v']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\nverbose2\n", "verbose output");

cli_helpers_initialize(['--debug']);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\nverbose\nverbose2\ndebug\n", "debug output");

cli_helpers_initialize([]);
($stdout,$stderr) = capture { run(); };
ok($stdout eq "normal\n", "normal after reinit output");

@ARGV = ( '--verbose' );
cli_helpers_initialize();
is( CLI::Helpers::def('VERBOSE'), 1, "ARGV first pass" );
cli_helpers_initialize();
is( CLI::Helpers::def('VERBOSE'), 1, "ARGV processing is idempotent" );

done_testing;

sub run {
    output('normal');
    verbose('verbose');
    verbose({level=>2}, "verbose2");
    debug('debug');

    output({stderr=>1}, 'normal stderr');
}
