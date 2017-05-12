package AnyEvent::JSONRPC::CondVar;
use Any::Moose;

use AnyEvent;

has cv => (
    is      => 'ro',
    isa     => 'AnyEvent::CondVar',
    default => sub {
        AnyEvent->condvar;
    },
    handles => [qw( send recv cb )],
);

has call => (
    is       => 'ro',
    isa      => 'JSON::RPC::Common::Procedure::Call',
    required => 1,
    handles  => [qw( is_notification )], 
);

no Any::Moose;

sub result {
    my ($self, @result) = @_;
    $self->send( $self->call->return_result( @result ));
}

sub error {
    my ($self, @error) = @_;
    $self->send( $self->call->return_error ( @error ) );
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords condvar

=head1 NAME

AnyEvent::JSONRPC::CondVar - Condvar object used in
AnyEvent::JSONRPC::TCP::Server and AnyEvent::JSONRPC::HTTP::Server

=head1 SEE ALSO

L<AnyEvent::JSONRPC::TCP::Server> and L<AnyEvent::JSONRPC::HTTP::Server>

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
