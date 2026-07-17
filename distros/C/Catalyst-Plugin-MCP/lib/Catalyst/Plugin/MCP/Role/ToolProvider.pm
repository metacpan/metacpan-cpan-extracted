package Catalyst::Plugin::MCP::Role::ToolProvider;
use v5.36;
use Moo::Role;

our $VERSION = '0.003';

requires qw/list call/;

=head1 NAME

Catalyst::Plugin::MCP::Role::ToolProvider - MCP tool provider contract

=head1 REQUIRED METHODS

=head2 list( $cursor )

Return C<< { tools => \@items } >>. Each tool is a hashref with at least a
C<name>. Tools are NOT paginated: C<list> must return the complete tool set
(the engine validates a C<tools/call> name against it). Keep C<list> cheap: it
is also called once per C<tools/call> to validate the name, so cache it or make
it a trivial lookup if the underlying source is expensive.

=head2 call( $name, $args )

Return a tool result hashref. For an execution failure return a normal result
carrying C<< isError => 1 >> with C<content>, NOT an exception. (Unknown-tool
and bad-argument cases are protocol errors raised by the engine, not here.)

=cut

1;
