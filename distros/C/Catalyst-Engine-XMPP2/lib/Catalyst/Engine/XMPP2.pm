{   package Catalyst::Engine::XMPP2;
    use strict;
    use warnings;
    our $VERSION = '0.4';
    use base qw(Catalyst::Engine::Embeddable);
    use Event qw(loop);
    use Encode;
    use HTTP::Request;
    use AnyEvent::XMPP::Connection;
    use UNIVERSAL qw(isa);

    __PACKAGE__->mk_accessors(qw( connections ));

    my %http_xmpp_error_map =
      (
       400 => { cond => 'bad-request',
                type => 'modify' },
       409 => { cond => 'conflict',
                type => 'cancel' },
       501 => { cond => 'feature-not-implemented',
                type => 'cancel' },
       403 => { cond => 'forbidden',
                type => 'auth' },
       410 => { cond => 'gone',
                type => 'modify' },
       500 => { cond => 'internal-server-error',
                type => 'wait' },
       404 => { cond => 'item-not-found',
                type => 'cancel' },
       520 => { cond => 'jid-malformed',
                type => 'modify' },
       406 => { cond => 'not-acceptable',
                type => 'modify' },
       420 => { cond => 'not-allowed',
                type => 'cancel' },
       401 => { cond => 'not-authorized',
                type => 'auth' },
       402 => { cond => 'payment-required',
                type => 'auth' },
       521 => { cond => 'recipient-unavailable',
                type => 'wait' },
       302 => { cond => 'redirect',
                type => 'modify' },
       421 => { cond => 'registration-required',
                type => 'auth' },
       502 => { cond => 'remote-server-not-found',
                type => 'cancel' },
       504 => { cond => 'remote-server-timeout',
                type => 'wait' },
       412 => { cond => 'resource-constraint',
                type => 'wait' },
       503 => { cond => 'service-unavailable',
                type => 'cancel' },
       422 => { cond => 'subscription-required',
                type => 'auth' },
       423 => { cond => 'undefined-condition',
                type => 'cancel' },
       424 => { cond => 'unexpected-request',
                type => 'wait' },
      );

    sub run {
        my ($self, $app) = @_;

        die 'No Engine::XMPP2 configuration found'
          unless ref $app->config->{'Engine::XMPP2'} eq 'HASH';

        # list the path actions that will be mapped as resources.
        my %uniq_ns;
        my @resources =
          map { s#^/?## ; $_ }
          map { @{$_->attributes->{Path} || []} }
          values %{$app->dispatcher->action_hash};

        $self->connections({}) unless $self->connections();

        my %template = %{$app->config->{'Engine::XMPP2'}};
        delete $template{jid};
        delete $template{resource};

        #$app->log->debug('Initializing AnyEvent::XMPP::Connection objects');

        foreach my $resource (@resources) {
            $self->connections->{$resource} =
              AnyEvent::XMPP::Connection->new(resource => $resource,
                                          %template);
        }

        #$app->log->debug('Connecting XMPP resources.');

        foreach my $resource (@resources) {
            $self->connections->{$resource}->connect
              or die 'Could not connect resource: '.$resource.', '.$!;
            $self->connections->{$resource}->reg_cb
              (stream_ready => sub {
                   $self->connections->{$resource}->send_presence('available', sub{});
               },
               bind_error => sub {
                   die 'Error binding resource '.$resource.': '.shift;
               },
               # the four events are registered as separate to let AnyEvent::XMPP
               # handle all other types of events, but we can actually process
               # them the same way.
               iq_get_request_xml => sub {
                   my ($conn, $node) = @_;
                   #$app->log->debug('Received an iq get stanza at '.$resource);
                   $self->handle_xmpp_node($app, $resource, $node, 'iq');
               },
               iq_set_request_xml => sub {
                   my ($conn, $node) = @_;
                   #$app->log->debug('Received an iq set stanza at '.$resource);
                   $self->handle_xmpp_node($app, $resource, $node, 'iq');
               },
               message_xml => sub {
                   my ($conn, $node) = @_;
                   #$app->log->debug('Received a message stanza at '.$resource);
                   $self->handle_xmpp_node($app, $resource, $node, 'message');
               },
               presence_xml => sub {
                   my ($conn, $node) = @_;
                   #$app->log->debug('Received a presence stanza at '.$resource);
                   $self->handle_xmpp_node($app, $resource, $node, 'presence');
               });
        }

        loop();
    }

    sub handle_xmpp_node {
        my ($self, $app, $resource, $node, $type) = @_;

        # we're going to avoid doing any action on a message of type "error"
        return if 
          defined $type &&
            $type eq 'message' &&
              defined $node->attr('type') &&
                $node->attr('type') eq 'error';

        my $config = $app->config->{'Engine::XMPP2'};
        my $url = 'xmpp://'.$config->{username}.'@'.$config->{domain}.'/'.$resource;

        my $request = HTTP::Request->new(POST => $url);

        $request->header('Content-type' => 'application/xml; charset=utf-8');
        $request->header('XMPP_Stanza' => $type);
        $request->header('XMPP_Resource' => $resource);

        $request->header('XMPP_Stanza_'.$_ => $node->attr($_))
          for grep { $node->attr($_) } qw(to from id type xml:lang);
        my $content = join '', $node->text, map { $_->as_string } $node->nodes;
        $request->content_length( length($content) );
        $request->content( $content);

        #$app->log->debug('[Request Content] '.$request->content);

        my $response;

        $app->handle_request($request, \$response);

        my %response_attrs = map { $_ => $response->header('XMPP_Stanza_'.$_) }
          grep { $response->header($_) } qw(to from id type xml:lang);

        if ($response->is_success && $type ne 'iq') {
            #$app->log->debug('Request ended successfully, no response needed.');
        } elsif ($response->is_success) {
            my $content_type = $response->header('Content-type');
            my $content_raw = $response->content();
            $self->connections->{$resource}->reply_iq_result
              ($node, sub {
                   my $xml_writer = shift;
                   my $ctype = $content_type;
                   my $craw = $content_raw;
                   if ($ctype &&
                       $ctype =~ /xml/) {
                       $xml_writer->raw($craw);
                   } else {
                       $xml_writer->raw('<body>'.$craw.'</body>');
                   }
               }, %response_attrs);
        } else {
            my $cond = $http_xmpp_error_map{$response->code}{cond}
              || 'internal-server-error';
            my $type = $http_xmpp_error_map{$response->code}{type}
              || 'wait';
            if (my $over = $response->header('XMPP_error-type')) {
                $type = $over;
            }
            if ($node->name eq 'iq') {
                $self->connections->{$resource}->reply_iq_error
                  ($node, $type, $cond, %response_attrs);
            } else {
                my $content_raw = $response->content();
                $self->connections->{$resource}->send_message
                  ($node->attr('from'), 'error', sub {
                       my $xml_writer = shift;
                       $xml_writer->raw($content.'<error type="'.$type.'">'.
                                        '<'.$cond.' xmlns=\'urn:ietf:params:xml:ns:xmpp-stanzas\'/>'.
                                        '<text>'.$content_raw.'</text></error>');
                   } , %response_attrs);
            }
        }
    }

    sub connection {
        my ($self, $c) = @_;
        my $resource = $c->req->header('XMPP_Resource');
        return $self->connections->{$resource};
    }

    sub send_message {
        my $self = shift;
        my $c = shift;
        $self->connection($c)->send_message(@_);
    }

    sub send_presence {
        my $self = shift;
        my $c = shift;
        $self->connection($c)->send_presence(@_);
    }

    sub send_iq {
        my $self = shift;
        my $c = shift;
        $self->connection($c)->send_iq(@_);
    }


};
__PACKAGE__
__END__

=head1 NAME

Catalyst::Engine::XMPP2 - AnyEvent::XMPP::Connection Catalyst Engine

=head1 SYNOPSIS

  MyApp->config->{Engine::XMPP2} =
   {
    username => "abc",
    domain => "jabber.org",
    password => "foo",
    override_host => "myserver",
    override_port => 5722
   };
  MyApp->run();


=head1 DESCRIPTION

This engine enables you to deploy a Catalyst application that can be
accessed using the XMPP protocol. This is done by a mapping of each
XMPP stanza to a HTTP Request, using the Catalyst::Engine::Embeddable
as a base.

=head1 Semantics mapping

One important thing to realise is that the XMPP semantics are
considerably different than the HTTP semantics, that way, a set of
mappings must be done.

=over

=item Request-Response

Usually, an HTTP application implements only Request-Response
semantics for every action. That is not always true for the XMPP
protocol. In fact, the only stanza that implements this semantics is
the <iq/> stanza.

That way, when receiving <message/> or <presence/> stanzas, the
response will be ignored on success. If the response is a failure (400
or 500), an error response will be sent. If wanting to send an
explicit message, that should be done explicitly.

When receiving <iq/> stanzas, the response will be sent back as the
action processing returns, independent of the response status.

In any way, the attributes of the stanza root element will be
translated as HTTP Headers with the "XMPP_Stanza_" prefix.

=item SCRIPT_NAME

This is the most relevant aspect of this mapping. As XMPP doesn't have
a URI definition for each stanza, that means that there's no proper
way of dispatching a message to a given controller action in Catalyst.

What this mapping does is, at the beggining, creating several
connections to the server, providing different resource identifiers
based on the Path actions registered in the application.

This have two important side-effects to realize:

A Catalyst XMPP application can only use 'Path' actions, because that
is the only DispatchType that have a static mapping of the available
actions. Other DispatchTypes, like Chained or Index, depends on the
current request to find out which action to dispatch. This doesn't
forbid the use of the other DispatchTypes for internal forward and
dispatch, but the only really public actions will be the ones seen by
the 'Path' DispatchType.

You have to keep in mind that the resources will be pre-advertised,
and that for each public path action, you will have a public jabber
id, and, at least by now, a separated connection to the server, so
it's probably a good idea to do a carefull planning of which actions
to make public.

=item Content-Type

XMPP has no support for MIME types. Every message is, by definition, a
XML document. So every request will have the "application/xml" MIME
type. If the response content-type is also "application/xml", it will
be written as raw into the XMPP stream. This will allow SOAP
responses, for instance, to be sent as in XEP-0072.

On the other hand, if the content type is of some other type, it will
be sent as literal string inside a <body> tag, as described by XMPP
RFC3921, this way, interaction with regular IM clients should be
natural.

=item Scalability

At this point, this engine is single-threaded, which means that it
will block in each operation, and, therefore it cannot handle more
than one request at a time. At the time of this writing, two options
are available to solve this problem:

The first would be to turn this engine into a pre-fork server that
would keep pipes to every child and dispatch the requests to them,
while keeping a single control thread for the XMPP connections.

The other option would be to implement a balancer server that would
accept several connections for the same JID and connect only once for
each JID, dispatching a message sent to some JID among each of the
candidate connections. DJabberd::Plugin::Balancer implements that for
the DJabberd server.

=item Error handling

Error handling in XMPP is also different than from HTTP. While HTTP
defines numeric error codes, XMPP defines a set of named
conditions. But both provide a way to return a custom text to the
requestor. This way, the HTTP error codes will be mapped to the XMPP
error conditions, and the content of the response will be set as the
error text. The XMPP spec also define the "error-type" concept which
indicates what the requestor can do about, and the recommended
error-type for each of the known conditions. The user can override
this default by sending the XMPP_error-type header in the failure
case.

The HTTP-XMPP error code mapping will happen as described in the
following table.

  bad-request                          400
  conflict                             409
  feature-not-implemented              501
  forbidden                            403
  gone                                 410
  internal-server-error                500
  item-not-found                       404
  jid-malformed                        520*
  not-acceptable                       406
  not-allowed                          420*
  not-authorized                       401
  payment-required                     402
  recipient-unavailable                521*
  redirect                             302
  registration-required                421*
  remote-server-not-found              502
  remote-server-timeout                504
  resource-constraint                  412
  service-unavailable                  503
  subscription-required                422*
  undefined-condition                  423*
  unexpected-request                   424*

The items marked with an * are of codes that are not standard HTTP
error codes. Most error codes in this list could be mapped literally.

=back

=head1 USAGE

The 'Engine::XMPP2' configuration key expects a hashref that will be
sent to AnyEvent::XMPP::Connection->new dereferenced. It's important to
notice, however, that setting "jid" or "resource" in this hash has no
effect as this values will be set according to the Action-Resource
mapping.

=head1 SENDING MESSAGES

One of the greater benefits of the XMPP protocol is the hability to
chain operations in a more complex choreography. In order to do that,
you just need to send new messages while processing other messages, in
order to do that, you can access the engine object by using $c->engine
and use one of the following methods

=over

=item $c->engine->send_message($c, $to, $type, $create_cb, %attrs)

This will call send_message on the connection that generated the
current request with the parameters as described in
AnyEvent::XMPP::Connection.

One important hint: if $create_db is a CODE ref, it will be executed
with a XML::Writer object in UNSAFE mode as its first argument, which
means you can call "raw" on it to send unencoded data.

As you'll be sending the message with the connection that generated
this request, it will have the complete JID, with the resource, as the
"from".

=item $c->engine->send_presence($c, $type, $create_cb, %attrs)

Same as above.

=item $c->engine->send_iq($c, $type, $create_cb, $result_cb, %attrs)

Same as above.

Hint: $result_cb is a coderef that will be executed once the response
for this iq arrives. This method won't block, so you might have to
implement a semaphore if the reply for this iq is relevant to the rest
of this request.

=back

=head1 DIRECT CONNECTION MANIPULATION

This is strongly discouraged, but it might be life-saving for some
corner cases.

=over

=item $c->engine->connection($c)

Access the connection object that generated the current request.

=item $c->engine->connections()

This returns a hashref identifying all the connections by the resource
name.

=back

=head1 INTERNAL METHODS

=over

=item $engine->handle_xmpp_node($app, $resource, $node)

This method is called by the stanza callbacks in the connections.

=back

=head1 SEE ALSO

L<Catalyst::Engine>, L<Catalyst::Engine::CGI>, L<HTTP::Request>,
L<HTTP::Reponse>, L<Catalyst>, L<AnyEvent::XMPP::Connection>,
L<Catalyst::Engine::Embeddable>

=head1 AUTHORS

Daniel Ruoso C<daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Engine::XMPP2> to
C<bug-catalyst-engine-xmpp2@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

