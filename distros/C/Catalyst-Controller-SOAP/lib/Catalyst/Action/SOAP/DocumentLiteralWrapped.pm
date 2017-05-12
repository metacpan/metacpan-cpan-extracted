{ package Catalyst::Action::SOAP::DocumentLiteralWrapped;
  use strict;
  use base 'Catalyst::Action::SOAP';

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;

      $self->prepare_soap_helper(@_);

      my $prefix = $controller->soap_action_prefix;
      my $soapaction = $c->req->headers->header('SOAPAction');

      die 'No SOAP Action' unless $soapaction;

      $soapaction =~ s/(^\"|\"$)//g;

      die 'Bad SOAP Action: '.$soapaction unless
        $prefix eq substr($soapaction,0,length($prefix));

      my $operation = substr($soapaction,length($prefix));
      my $action = $controller->action_for($operation);

      die 'SOAP Action does not map to any operation' unless $action;

      $c->forward($operation);
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::DocumentLiteralWrapped - Document/Literal
Wrapped SOAP ActionClass

=head1 SYNOPSIS

 # in the controller

 __PACKAGE__->{config}{soap_action_prefix} = 'http://foo/bar/';

 use base 'Catalyst::Controller::SOAP::DocumentLiteralWrapped';
 # or
 sub endpoint : Local ActionClass(SOAP::DocumentLiteralWrapped) { }

=head1 DESCRIPTION

Microsoft has defined a pseudo-standard for SOAP usage called
Document/Literal Wrapped. This standard is a deviation of both the
Document/Literal and of the RPC/Literal usages.

A Document/Literal service is supposed to have one operation per bind,
as it's not techically possible to dispatch on the content of the
Body. In fact, as the Body is used as "literal" the dispatching should
not even look at it, it should be based on the port that received the
request.

RPC/Literal, on the other hand, supports the use of several operations
per bind, and the dispatching of this operations is based on the first
and only child element of the message body, which defines the
operation. The arguments are set as the parts of the message in the
WSDL.

Document/Literal-Wrapped is a deviation of both, as the message should
be interpreted as Document/Literal, but the dispatching requires an
additional step of looking at the SOAPAction HTTP header, which will
identify the proper operation to be dispatched.

This is plain wrong, as the SOAP Action information should be used for
routing pourposes only and not for operation dispatch. Please see the
SOAP standard. In fact, SOAP1.2 even makes SOAPAction optional.

=head1 WARNING

THIS MODULE IS HERE FOR COMPATIBILITY REASONS ONLY, SO YOU CAN USE
WHEN IN NEED TO IMPLEMENT A LEGACY SERVICE THAT USES THIS
PSEUDO-STANDARD. THIS USAGE SCENARIO SHOULD NOT BE PROMOTED BY ANY
WAY. THE CORRECT WAY TO IMPLEMENT THE SAME FUNCTIONALITY IS BY USING
RPC/Literal, THAT WILL IN PRODUCE THE EXACT SAME MESSAGE BODY.

=head1 USE

The operation is dispatched according to the SOAPAction header. The
operation name is extracted by removing the given prefix and assuming
the rest of the SOAPAction is the effective operation name (removing
"s).

=head1 TODO

Well, here? nothing, all the work is done in the superclass.

=head1 AUTHOR

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

