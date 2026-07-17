package Catalyst::Plugin::MCP::Role::PromptProvider;
use v5.36;
use Moo::Role;

our $VERSION = '0.003';

requires qw/list get/;

=head1 NAME

Catalyst::Plugin::MCP::Role::PromptProvider - MCP prompt provider contract

=head1 REQUIRED METHODS

=head2 list( $cursor )

Return C<< { prompts => \@items, nextCursor => $opt } >>.

=head2 get( $name, $args )

Return the prompt result hashref (C<< { messages => [...] } >>), or C<undef> if
the name is unknown (the engine turns C<undef> into a -32602 error).

=cut

1;
