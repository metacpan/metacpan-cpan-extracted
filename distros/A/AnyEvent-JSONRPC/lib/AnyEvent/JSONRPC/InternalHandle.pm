package AnyEvent::JSONRPC::InternalHandle;
use Any::Moose;

use AnyEvent;

has cv => (
    is      => 'ro',
    isa     => 'AnyEvent::CondVar',
    default => sub {
        AnyEvent->condvar;
    },
    handles => [qw( recv cb )],
);

no Any::Moose;

sub push_write {
    my ($self, $type, $json) = @_;

    $self->cv->send( $json );
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords condvar

=head1 NAME

AnyEvent::JSONRPC::InternalHandle - Handle object used internally in
AnyEvent::JSONRPC::TCP::Server

=head1 SEE ALSO

L<AnyEvent::JSONRPC>.

=head1 AUTHOR

Peter Makholm <peter@makholm.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Peter Makholm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
