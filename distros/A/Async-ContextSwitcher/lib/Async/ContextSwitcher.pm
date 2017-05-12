use strict;
use warnings;
use v5.10;

package Async::ContextSwitcher;

our $VERSION = '0.01';

use base "Exporter::Tiny";
our @EXPORT = qw(context cb_w_context);

=head1 NAME

Async::ContextSwitcher - helps track execution context in async programs

=head1 DESCRIPTION

This is a very simple module that helps you carry around execution context
in async programs.

Idea is simple:

=over 4

=item * you create a new context when a new web request comes or whan a new message
comes from a queue or command line script starts

=item * use L</cb_w_context> to create callbacks

=item * correct context restored when your callbacks are called

=item * use L</context> to access it

=back


You can live without it in simple applications It's not something you can deal

=cut


our $CTX;

sub new {
    my $self = shift;

    return $CTX = bless {@_}, ref( $self ) || $self;
}

sub context() {
    return $CTX if $CTX;
    return $CTX = __PACKAGE__->new;
}

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
