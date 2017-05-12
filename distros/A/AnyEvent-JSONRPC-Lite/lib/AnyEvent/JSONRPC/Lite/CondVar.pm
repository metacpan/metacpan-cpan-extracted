package AnyEvent::JSONRPC::Lite::CondVar;
use Any::Moose;

use AnyEvent;

has _cv => (
    is      => 'ro',
    isa     => 'AnyEvent::CondVar',
    default => sub {
        AnyEvent->condvar;
    },
);

no Any::Moose;

sub _cb {
    my ($self, $cb) = @_;
    $self->_cv->cb($cb);
}

sub result {
    my ($self, @result) = @_;
    $self->_cv->send( result => @result);
}

sub error {
    my ($self, @error) = @_;
    $self->_cv->send( error => @error);
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords condvar

=head1 NAME

AnyEvent::JSONRPC::Lite::CondVar - Condvar object used in AnyEvent::JSONRPC::Lite::Server

=head1 SEE ALSO

L<AnyEvent::JSONRPC::Lite::Server>.

=head1 METHOD

=head2 result (@results)

Return back C<@results> to client as result.

=head2 error ($error)

Return back C<$error> to client as error.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
