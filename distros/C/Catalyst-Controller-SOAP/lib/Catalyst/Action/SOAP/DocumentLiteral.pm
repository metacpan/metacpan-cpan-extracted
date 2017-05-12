{ package Catalyst::Action::SOAP::DocumentLiteral;

  use base 'Catalyst::Action::SOAP';
  use constant NS_SOAP_ENV => "http://schemas.xmlsoap.org/soap/envelope/";

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;
      $self->prepare_soap_helper($controller,$c);
      $self->prepare_soap_xml_post($controller,$c);
      unless ($c->stash->{soap}->fault) {
          my $envelope = $c->stash->{soap}->parsed_envelope;
          my $namespace = $c->stash->{soap}->namespace || NS_SOAP_ENV;
          my ($body) = $envelope->getElementsByTagNameNS($namespace, 'Body');
          my $operation = $self->name;
          $c->stash->{soap}->operation_name($operation);
          eval {
              if ($controller->wsdlobj) {
                  $body = $c->stash->{soap}->arguments
                    ($controller->decoders->{$operation}->($body));
              }
          };
          if ($@) {
              $c->stash->{soap}->fault
                ({ code => 'SOAP-ENV:Client',
                   reason => 'Bad Body', detail =>
                   'Schema validation on the body failed: '.$@});
          } else {
              $self->next::method($controller, $c, $body);
          }
      }
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::DocumentLiteral - Document Literal service

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This action implements a simple parse of the envelope and passing the
body to the service as a xml object.

=head1 TODO

Almost all the SOAP protocol is unsupported, only the method
dispatching and, optionally, the soap-decoding of the arguments are
made.

=head1 AUTHORS

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

