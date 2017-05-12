{ package Catalyst::Action::SOAP::RPCEndpoint;

  use strict;
  use base 'Catalyst::Action::SOAP';
  use constant NS_SOAP_ENV => "http://schemas.xmlsoap.org/soap/envelope/";
  use UNIVERSAL;

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;

      $self->prepare_soap_helper($controller,$c);
      $self->prepare_soap_xml_post($controller,$c);
      unless ($c->stash->{soap}->fault) {
          my $envelope = $c->stash->{soap}->parsed_envelope;
          my $namespace = $c->stash->{soap}->namespace || NS_SOAP_ENV;
          my ($body) = $envelope->getElementsByTagNameNS($namespace,'Body',0);
          my @children = grep { UNIVERSAL::isa( $_, 'XML::LibXML::Element') } $body->getChildNodes();
          if (scalar @children != 1) {
              $c->stash->{soap}->fault
                ({ code => 'SOAP-ENV:Client',
                   reason => 'Bad Body', detail =>
                   'RPC messages should contain only one element inside body'})
            } else {
                my $rpc_element = $children[0];
                my ($smthing, $operation) = split /:/, $rpc_element->nodeName();
                $operation ||= $smthing; # if there's no ns prefix,
                                         # operation is the first
                                         # part.
                $c->stash->{soap}->operation_name($operation);

                eval {
                    if ($controller->wsdlobj) {
                        my $decoder = $controller->decoders->{$operation};
                        my ($args) = $decoder->($rpc_element)
                          if UNIVERSAL::isa($decoder,'CODE');
                        $c->stash->{soap}->arguments($args);
                    } else {
                        my $arguments = $rpc_element->getChildNodes();
                        $c->stash->{soap}->arguments($arguments);
                    }
                };
                if ($@) {
                    $c->stash->{soap}->fault
                      ({ code => 'SOAP-ENV:Client',
                         reason => 'Bad Body', detail =>
                         'Malformed parts on the message body: '.$@});
                } else {
                    my $action = $controller->action_for($operation);

                    if (!$action ||
                        !grep { /RPC(Encoded|Literal)/ } @{$action->attributes->{ActionClass}}) {
                        $c->stash->{soap}->fault
                          ({ code => 'SOAP-ENV:Client',
                             reason => 'Bad Operation', detail =>
                             'Invalid Operation'});
                    } else {
                        # this is our RPC action
                        $c->forward($operation);
                    }
                }

            }
      }
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::RPCEndpoint - RPC Dispatcher

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This class is used by L<Catalyst::Controller::SOAP> to dispatch to the
RPC operations inside a controller. These operations are quite
different from the others, as they are seen by Catalyst as this single
action. During the registering phase, the soap rpc operations are
included in the hash that is sent to this object, so they can be
invoked later.

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

