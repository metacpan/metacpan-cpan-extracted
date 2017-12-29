use strict;
use warnings;
use v5.10;

package Async::ContextSwitcher;

our $VERSION = '0.02';

use base "Exporter::Tiny";
our @EXPORT = qw(context cb_w_context);

=head1 NAME

Async::ContextSwitcher - helps track execution context in async programs

=head1 DESCRIPTION

This is a very simple module that helps you carry around execution context
in async programs.

Idea is simple:

=over 4

=item * you create a L</new> context for an entry point

It can be a new web request, a new message from a queue to process
or command line script command

=item * use L</cb_w_context> to create all callbacks in your application

=item * correct context restored when your callbacks are called

=item * use L</context> to access data

=back

=cut


our $CTX;

=head1 METHODS and FUNCTIONS

=head2 new

Creates a new context and makes it the current one. Takes named pairs and stores
them in the context.

    Async::ContextSwitcher->new( request => $psgi_env );

=cut

sub new {
    my $self = shift;

    return $CTX = bless {@_}, ref( $self ) || $self;
}

=head2 context

Returns the current context. Function is exported. Always returns context.

    my $ct = context->{request}{HTTP_CONTENT_TYPE};
    context->{user} = $user;

=cut

sub context() {
    return $CTX if $CTX;
    return $CTX = __PACKAGE__->new;
}

=head2 cb_w_context

Wrapper for callbacks. Function is exported. Wraps a callback with code
that stores and restores context to make sure correct context travels
with your code.

    async_call( callback => cb_w_context { context->{good} = shift } );

Make sure that all callbacks in your code are created with this function
or you can loose track of your context.

=cut

sub cb_w_context(&) {
    my $cb = $_[0];
    my $ctx = $CTX;
    return sub {
        $CTX = $ctx;
        goto &$cb;
    };
}


=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
