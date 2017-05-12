use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;

# These tests require DBI and DBD::SQLite (My::Journal dependencies)...
my $prereqs_installed = eval 'use DBI; use DBD::SQLite';
if( $@ ) { plan skip_all => 'DBI and DBD::SQLite are required for tests that use demo app My::Journal' }
else { plan 'no_plan' }
use_ok( 'My::Journal' );

my $app = My::Journal->new();

# Register some commands...
ok( my $cmd = $app->register_command( 'console'   ), "register (built-in) 'console' command" );
ok( $cmd->isa( 'CLI::Framework::Command::Console' ), "built-in 'console' command object returned" );
is( $cmd->name(), 'console', 'command name is as expected' );

ok( $cmd = $app->register_command( 'menu'   ), "register (overridden) 'menu' command" );
ok( $cmd->isa( 'My::Journal::Command::Menu' ),
    "application-specific, overridden command returned instead of the built-in 'menu' command" );
is( $cmd->name(), 'menu', 'command name is as expected' );

# Get and check list of all registered commands...
ok( my @registered_cmd_names = $app->registered_command_names(),
    'CLI::Framework::Application::registered_command_names()' );
my @got_cmd_names = sort @registered_cmd_names;
my @expected_cmd_names = sort qw( console menu );
is_deeply( \@got_cmd_names, \@expected_cmd_names,
    'registered_command_names() returned expected set of commands that were registered' );

# Check that we can get registered commands by name...
ok( my $console_command = $app->registered_command_object('console'), 'retrieve console command by name' );
ok( $console_command->isa('CLI::Framework::Command::Console'), 'command object is ref to proper class' );
ok( my $menu_command = $app->registered_command_object('menu'), 'retrieve menu command by name' );
ok( $menu_command->isa('CLI::Framework::Command::Menu'), 'command object is a ref to proper class');

__END__

=pod

=head1 PURPOSE

To verify basic CLIF features related to registration of commands.

=cut
