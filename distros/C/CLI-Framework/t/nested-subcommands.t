use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More qw( no_plan );
use My::DemoNestedSubcommands;

#~~~~~~
close STDOUT;
open ( STDOUT, '>', File::Spec->devnull() );
#~~~~~~

@ARGV = qw( tree );
ok( my $app = My::DemoNestedSubcommands->new(),
    'My::DemoNestedSubcommands->new()' );
ok( $app->register_command( 'command0' ),
    'register command0' );
ok( $app->register_command( 'command1' ),
    'register command1' );

# check the class hierarchy for registered commands, ensuring that parent-child
# relationships are as expected:
verify_expected_command_tree( $app );

ok( $app->run(), 'run()' );

#-------

sub verify_expected_command_tree { 
    my ($app) = @_;

    my $c0 = $app->registered_command_object( 'command0' );
    is( $c0->name(), 'command0', 'command0 is child of app' );

    my $c0_0 = $c0->registered_subcommand_object( 'command0_0' );
    is( $c0_0->name(), 'command0_0' , 'command0_0 is child of command0' );
    
    my $c0_1 = $c0->registered_subcommand_object( 'command0_1' );
    is( $c0_1->name(), 'command0_1', 'command0_1 is child of command0' );

    my $c0_1_0 = $c0_1->registered_subcommand_object( 'command0_1_0' );
    is( $c0_1_0->name(), 'command0_1_0', 'command0_1_0 is child of command0_1' );

    my $c1 = $app->registered_command_object( 'command1' );
    is( $c1->name(), 'command1', 'command1 is child of app' );

    my $c1_0 = $c1->registered_subcommand_object( 'command1_0' );
    is( $c1_0->name(), 'command1_0', 'command1_0 is child of command1' );

    my $c1_1 = $c1->registered_subcommand_object( 'command1_1' );
    is( $c1_1->name(), 'command1_1', 'command1_1 is child of command1' );

    my $c1_1_0 = $c1_1->registered_subcommand_object( 'command1_1_0' );
    is( $c1_1_0->name(), 'command1_1_0', 'command1_1_0 is child of command1_1' );
}

__END__

=pod

=head1 PURPOSE

Test to ensure that the proper class hierarchy for registered commands is
established with the correct parent-child relationships as defined by CLIF
Command subclasses.

=cut
