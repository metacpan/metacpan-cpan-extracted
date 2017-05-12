package Catalyst::ActionRole::JMS;
$Catalyst::ActionRole::JMS::VERSION = '1.3';
{
  $Catalyst::ActionRole::JMS::DIST = 'Catalyst-ActionRole-JMS';
}
use strict;
use warnings;
use Moose::Role;
use List::Util 'first';
use namespace::autoclean;

# ABSTRACT: role for actions to dispatch based on JMSType


requires 'attributes';


has jmstype => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_jmstype',
);

sub _build_jmstype {
    my ($self) = @_;

    return $self->attributes->{JMSType}[0] || $self->name;
}


around match => sub {
    my ($orig,$self,$ctx) = @_;

    # ugly hack, some pieces along the way lose the method
    $ctx->req->method('POST') unless $ctx->req->method;

    my $req_jmstype = $self->_extract_jmstype($ctx);
    if ($self->_match_jmstype($req_jmstype)) {
        return $self->$orig($ctx);
    }
    return 0;
};


sub _extract_jmstype {
    my ($self,$ctx) = @_;

    my $ret = $ctx->request->headers->header('jmstype')
        || $ctx->request->headers->header('type');
    return $ret if defined $ret;
    my $env = eval { $ctx->engine->env } || $ctx->request->env;

    return $env->{'jms.type'};
}


sub _match_jmstype {
    my ($self,$req_jmstype) = @_;

    return $self->jmstype eq $req_jmstype;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::ActionRole::JMS - role for actions to dispatch based on JMSType

=head1 VERSION

version 1.3

=head1 SYNOPSIS

  sub an_action : Does('Catalyst::ActionRole::JMS') JMSType('some_type') {
    # do whatever
  }

=head1 DESCRIPTION

Apply this role to your actions (via the
L<Does|Catalyst::Controller/Does> attribute) to have
the dispatch look at the JMSType of incoming requests (that should
really be messages from some queueing system, see
L<Plack::Handler::Stomp> for an example). The requests / messages
should be dispatched to the namespace of the action.

You should look at L<Catalyst::Controller::JMS> for a more integrated
solution using this module together with automatic (de-)serialization.

=head1 ATTRIBUTES

=head2 C<jmstype>

The type to match against. Defaults to the value of a C<JMSType>
action attribute, or the action name if such attribute is not present.

=head1 METHODS

=head2 C<match>

C<around> modifier for the C<match> method of the action
class. Extracts the request / message type by calling
L</_extract_jmstype>, and compares it with the value of the
L</jmstype> attribute by calling L</_match_jmstype>. If it matches,
delegates to the normal C<match> method, otherwise signals a non-match
to the dispatched by returning false.

=head2 C<_extract_jmstype>

  my $type = $self->_extract_jmstype($ctx);

Gets the type of the request / message. It first looks in the request
headers for C<jmstype> or C<type> keys, then looks into the PSGI
environment for a C<jms.type> key.

=head2 C<_match_jmstype>

  my $ok = $self->_match_jmstype($request_type);

Simple string equality comparison. Override this if you need more
complicated matching semantics.

=head1 EXAMPLES

You can find examples of use in the tests, or at
https://github.com/dakkar/CatalystX-StompSampleApps

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
