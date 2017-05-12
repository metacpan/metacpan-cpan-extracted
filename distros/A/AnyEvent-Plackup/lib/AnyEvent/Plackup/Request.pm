package AnyEvent::Plackup::Request;
use strict;
use warnings;
use parent 'Plack::Request';
use AnyEvent;

sub respond {
    my ($self, $psgi_res) = @_;
    $self->_response_cv->send($psgi_res);
}

sub _response_cv {
    my $self = shift;
    return $self->env->{'anyevent.plackup.response_cv'} ||= AE::cv;
}

1;

__END__

=head1 NAME

AnyEvent::Plackup::Request - Request object for AnyEvent::Plackup

=head1 SYNOPSIS

  my $req = $server->recv;
  $req->respond([ 200, [], [ 'OK' ] ]);

=head1 METHODS

=over 4

=item $req->respond($psgi_response)

Responds a PSGI response to client.

=back

=cut
