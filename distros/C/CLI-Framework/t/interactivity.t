use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use File::Spec;

use Test::More;

# These tests require DBI and DBD::SQLite (My::Journal dependencies)...
my $prereqs_installed = eval 'use DBI; use DBD::SQLite';
if( $@ ) { plan skip_all => 'DBI and DBD::SQLite are required for tests that use demo app My::Journal' }
else { plan 'no_plan' }
use_ok( 'My::Journal' );

#~~~~~~
# Prepare null device for supressing output...
open ( my $devnull, '>', File::Spec->devnull() );

my $app = My::Journal->new();

# Build fake interactive request sequence...
my @application_quit_signals = $app->quit_signals();
my $canned_request = [
    [ 'list' ],
    [ 'publish' ],
    [ 'help', 'entry' ],
    [ 'entry', 'foo' ],
    [ 'tree' ],
    [ 'bogus' ],
    [ 'menu' ],
    [ 'dump' ],

    # (2nd-to-last canned request will be the last command run):
    [ 'entry' ],
    # (last canned request should be a 'quit signal')
    [ $application_quit_signals[0] ]
];
# Replace normal procedure to interactively read requests with a dummy
# version that uses our fake request sequence...
{
    no strict 'refs'; no warnings;
    *{My::Journal::read_cmd} = \&get_canned_request;
}
#~~~~~~

ok( ! $app->get_interactivity_mode(), 'just after construction, application is non-interactive' );
ok( $app->set_interactivity_mode(1), 'interactivity mode set' );
ok( $app->get_interactivity_mode(), 'after turning ON interactivity mode, application state is interactive' );

my @valid_commands = keys %{ $app->command_map_hashref() };
my @noninteractive_commands = $app->noninteractive_commands();

# We expect the interactive commands to be those which are valid but NOT non-interactive...
my @expected_interactive;
for my $valid (@valid_commands) {
    push(@expected_interactive, $valid) unless grep { $valid eq $_ } $app->noninteractive_commands();
}
@expected_interactive = sort @expected_interactive;
my @got_interactive = sort $app->get_interactive_commands();

is_deeply( \@got_interactive, \@expected_interactive,
    'in interactive mode, non-interactive commands are not included in the set of commands returned by get_interactive_commands()' );

# Send output to null device...
select $devnull;

ok( $app->run_interactive( initialize => 1 ), 'run_interactive()' );
is( $app->get_current_command(), $canned_request->[-2]->[0], 'interactive session ended with expected command' );

# Make sure that non-interactive commands get forwarded to 'help' in
# interactive mode:
$canned_request = [
    [ 'console' ],
    [ $application_quit_signals[0] ]
];
ok( $app->run_interactive( initialize => 1 ), 'run_interactive()' );
is( $app->get_current_command(), 'help', "attempt to run non-interactive command in interactive session forwards to 'help' command" );

# Make sure that requests for usage info for non-interactive commands get
# forwarded to 'help' in interactive mode:
$canned_request = [
    [ 'help console' ],
    [ $application_quit_signals[0] ]
];
ok( $app->run_interactive( initialize => 1 ), 'run_interactive()' );
is( $app->get_current_command(), 'help', "attempt to show usage info for non-interactive command in interactive session forwards to 'help' command" );

#~~~~~~
close $devnull;
#~~~~~~

# Command request reader that iterates over our fake request sequences:
{
    my $i = 0;
    sub get_canned_request {
        my $j = $i++ % @$canned_request;
        @ARGV = @{ $canned_request->[$j] };
        return 1;
    }
}

__END__

=pod

=head1 PURPOSE

To verify basic CLIF features related to interactivity.

=cut
