package Catalyst::Plugin::MCP::Role::ResourceProvider;
use v5.36;
use Moo::Role;

our $VERSION = '0.003';

requires qw/list templates read/;

=head1 NAME

Catalyst::Plugin::MCP::Role::ResourceProvider - MCP resource provider contract

=head1 REQUIRED METHODS

=head2 list( $cursor )

Return C<< { resources => \@items, nextCursor => $opt } >>. C<$cursor> is the
opaque pagination cursor from the request (or undef). Echo a C<nextCursor> only
when more pages remain.

=head2 templates

Return C<< { resourceTemplates => \@items } >>.

=head2 read( $uri )

Return the read result hashref (C<< { contents => [...] } >>), or C<undef> if
the URI is unknown (the engine turns C<undef> into a -32002 error).

=cut

1;
