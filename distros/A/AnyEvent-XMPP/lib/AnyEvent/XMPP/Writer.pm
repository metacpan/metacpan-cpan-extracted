package AnyEvent::XMPP::Writer;
use strict;
use XML::Writer;
use Authen::SASL qw/Perl/;
use MIME::Base64;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/simxml filter_xml_chars filter_xml_attr_hash_chars/;
use Digest::SHA qw/sha1_hex/;
use Encode;

=head1 NAME

AnyEvent::XMPP::Writer - "XML" writer for XMPP

=head1 SYNOPSIS

   use AnyEvent::XMPP::Writer;
   ...

=head1 DESCRIPTION

This module contains some helper functions for writing XMPP "XML", which is not
real XML at all ;-( I use L<XML::Writer> and tune it until it creates "XML"
that is accepted by most servers propably (all of the XMPP servers I tested
should work (jabberd14, jabberd2, ejabberd, googletalk).

I hope the semantics of L<XML::Writer> don't change much in the future, but if
they do and you run into problems, please report them!

The whole "XML" concept of XMPP is fundamentally broken anyway. It's supposed
to be an subset of XML. But a subset of XML productions is not XML. Strictly
speaking you need a special XMPP "XML" parser and writer to be 100% conformant.

On top of that XMPP B<requires> you to parse these partial "XML" documents.
But a partial XML document is not well-formed, heck, it's not even a XML
document!  And a parser should bail out with an error. But XMPP doesn't care,
it just relies on implementation dependend behaviour of chunked parsing modes
for SAX parsing.  This functionality isn't even specified by the XML
recommendation in any way.  The recommendation even says that it's undefined
what happens if you process not-well-formed XML documents.

But I try to be as XMPP "XML" conformant as possible (it should be around
99-100%).  But it's hard to say what XML is conformant, as the specifications
of XMPP "XML" and XML are contradicting. For example XMPP also says you only
have to generated and accept UTF-8 encodings of XML, but the XML recommendation
says that each parser has to accept UTF-8 B<and> UTF-16. So, what do you do? Do
you use a XML conformant parser or do you write your own?

I'm using XML::Parser::Expat because expat knows how to parse broken (aka
'partial') "XML" documents, as XMPP requires. Another argument is that if you
capture a XMPP conversation to the end, and even if a '</stream:stream>' tag
was captured, you wont have a valid XML document. The problem is that you have
to resent a <stream> tag after TLS and SASL authentication each! Awww... I'm
repeating myself.

But well... AnyEvent::XMPP does it's best with expat to cope with the
fundamental brokeness of "XML" in XMPP.

Back to the issue with "XML" generation: I've discoverd that many XMPP servers
(eg.  jabberd14 and ejabberd) have problems with XML namespaces. Thats the
reason why I'm assigning the namespace prefixes manually: The servers just
don't accept validly namespaced XML. The draft 3921bis does even state that a
client SHOULD generate a 'stream' prefix for the <stream> tag.

I advice you to explicitly set the namespaces too if you generate "XML" for
XMPP yourself, at least until all or most of the XMPP servers have been fixed.
Which might take some years :-) And maybe will happen never.

And another note: As XMPP requires all predefined entity characters to be
escaped in character data you need a "XML" writer that will escape everything:

   RFC 3920 - 11.1.  Restrictions:

     character data or attribute values containing unescaped characters
     that map to the predefined entities (Section 4.6 therein);
     such characters MUST be escaped

This means:
You have to escape '>' in the character data. I don't know whether XML::Writer
does that. And I honestly don't care much about this. XMPP is broken by design and
I have barely time to writer my own XML parsers and writers to suit their sick taste
of "XML". (Do I repeat myself?)

I would be happy if they finally say (in RFC3920): "XMPP is NOT XML. It's just
XML-like, and some XML utilities allow you to process this kind of XML.".

=head1 METHODS

=over 4

=item B<new (%args)>

This methods takes following arguments:

=over 4

=item write_cb

The callback that is called when a XML stanza was completely written and is
ready for transfer. The first argument of the callback will be the character
data to send to the socket.

=back

And calls C<init>.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = {
      write_cb     => sub {},
      send_iq_cb   => sub {},
      send_msg_cb  => sub {},
      send_pres_cb => sub {},
      @_
   };
   bless $self, $class;
   $self->init;
   return $self;
}

=item B<init>

(Re)initializes the writer.

=cut

sub init {
   my ($self) = @_;
   $self->{write_buf} = "";
   $self->{writer} =
      XML::Writer->new (OUTPUT => \$self->{write_buf}, NAMESPACES => 1, UNSAFE => 1);
}

=item B<flush ()>

This method flushes the internal write buffer and will invoke the C<write_cb>
callback. (see also C<new ()> above)

=cut

sub flush {
   my ($self) = @_;
   $self->{write_cb}->(substr $self->{write_buf}, 0, (length $self->{write_buf}), '');
}

=item B<send_init_stream ($language, $domain, $namespace)>

This method will generate a XMPP stream header. C<$domain> has to be the
domain of the server (or endpoint) we want to connect to.

C<$namespace> is the namespace URI or the tag (from L<AnyEvent::XMPP::Namespaces>)
for the stream namespace. (This is used by L<AnyEvent::XMPP::Component> to connect
as component to a server). C<$namespace> can also be undefined, in this case
the C<client> namespace will be used.

=cut

sub send_init_stream {
   my ($self, $language, $domain, $ns, $vers_override) = @_;

   $ns ||= 'client';

   my $w = $self->{writer};
   $w->xmlDecl ();
   $w->addPrefix (xmpp_ns ('stream'), 'stream');
   $w->addPrefix (xmpp_ns ($ns), '');
   $w->forceNSDecl (xmpp_ns ($ns));
   $w->startTag (
      [xmpp_ns ('stream'), 'stream'],
      to      => $domain,
      version => (defined $vers_override ? $vers_override : '1.0'),
      [xmpp_ns ('xml'), 'lang'] => $language
   );
   $self->flush;
}

=item B<send_whitespace_ping>

This method sends a single space to the server.

=cut

sub send_whitespace_ping {
   my ($self) = @_;
   $self->{writer}->raw (' ');
   $self->flush;
}

=item B<send_handshake ($streamid, $secret)>

This method sends a component handshake. Please note that C<$secret>
must be XML escaped!

=cut

sub send_handshake {
   my ($self, $id, $secret) = @_;
   my $out_secret = encode ("UTF-8", $secret);
   my $out = lc sha1_hex ($id . $out_secret);
   simxml ($self->{writer}, defns => 'component', node => {
      ns => 'component', name => 'handshake', childs => [ $out ]
   });
   $self->flush;
}

=item B<send_end_of_stream>

Sends end of the stream.

=cut

sub send_end_of_stream {
   my ($self) = @_;
   my $w = $self->{writer};
   $w->endTag ([xmpp_ns ('stream'), 'stream']);
   $self->flush;
}

=item B<send_sasl_auth ($mechanisms, $user, $hostname, $pass)>

This methods sends the start of a SASL authentication. C<$mechanisms> is
an array reference, containing the mechanism names that are to be tried.

=cut

sub send_sasl_auth {
   my ($self, $mechs, $user, $hostname, $pass) = @_;

   my $data;
    
   my $found_mech = 0;
   while (!$found_mech) {
      my $sasl = Authen::SASL->new (
         mechanism => join (' ', @$mechs),
         callback => {
            # XXX: removed authname, because it ensures maximum connectivitiy
            #      along multiple server implementations - XMPP is such a crap
            #        authname => $user . '@' . $domain,
            user => $user,
            pass => $pass,
         }
      );

      my $mech = $sasl->client_new ('xmpp', $hostname);
      $data = $mech->client_start;

      if (my $e = $mech->error) {
         @$mechs = grep { $_ ne $mech->mechanism } @$mechs;
         die "No usable SASL mechanism found (tried: "
             . join (', ', @$mechs)
             . ")!\n"
            unless @$mechs;
         next;
      }

      $found_mech = 1;
      $self->{sasl} = $mech;
   }

   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('sasl'),   '');
   $w->startTag ([xmpp_ns ('sasl'), 'auth'], mechanism => $self->{sasl}->mechanism);
   $w->characters (MIME::Base64::encode_base64 ($data, ''));
   $w->endTag;
   $self->flush;
}

=item B<send_sasl_response ($challenge)>

This method generated the SASL authentication response to a C<$challenge>.
You must not call this method without calling C<send_sasl_auth ()> before.

=cut

sub send_sasl_response {
   my ($self, $challenge) = @_;
   $challenge = MIME::Base64::decode_base64 ($challenge);
   my $ret = '';
   unless ($challenge =~ /rspauth=/) { # rspauth basically means: we are done
      $ret = $self->{sasl}->client_step ($challenge);
      if (my $e = $self->{sasl}->error) {
         die "Error in SASL authentication in client step with challenge: '" . $e . "'\n";
      }
   }
   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('sasl'),   '');
   $w->startTag ([xmpp_ns ('sasl'), 'response']);
   $w->characters (MIME::Base64::encode_base64 ($ret, ''));
   $w->endTag;
   $self->flush;
}

=item B<send_starttls>

Sends the starttls command to the server.

=cut

sub send_starttls {
   my ($self) = @_;
   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('tls'),   '');
   $w->emptyTag ([xmpp_ns ('tls'), 'starttls']);
   $self->flush;
}

=item B<send_iq ($id, $type, $create_cb, %attrs)>

This method sends an IQ stanza of type C<$type> (to be compliant
only use: 'get', 'set', 'result' and 'error').

If C<$create_cb> is a code reference it will be called with an XML::Writer
instance as first argument, which must be used to fill the IQ stanza. The
XML::Writer is in UNSAFE mode, so you can safely use C<raw()> to write out XML.

C<$create_cb> is a hash reference the hash will be used as key=>value arguments
for the C<simxml> function defined in L<AnyEvent::XMPP::Util>. C<simxml> will then
be used to generate the contents of the IQ stanza. (This is very convenient
when you want to write the contents of stanzas in the code and don't want to
build a DOM tree yourself...).

If C<$create_cb> is an array reference it's elements will be interpreted as
single C<$create_cb> argument (which can either be a hash reference or code
reference themself) and executed sequentially.

If C<$create_cb> is undefined an empty tag will be generated.

Example:

   $writer->send_iq ('newid', 'get', {
      defns => 'version',
      node  => { name => 'query', ns => 'version' }
   }, to => 'jabber.org')

C<%attrs> should have further attributes for the IQ stanza tag.
For example 'to' or 'from'. If the C<%attrs> contain a 'lang' attribute
it will be put into the 'xml' namespace. If the 'to' attribute contains
an undef it will be omitted.

C<$id> is the id to give this IQ stanza and is mandatory in this API.

Please note that all attribute values and character data will be filtered
by C<filter_xml_chars> (see also L<AnyEvent::XMPP::Util>).

=cut

sub send_iq {
   my ($self, $id, $type, $create_cb, %attrs) = @_;

   $create_cb = _trans_create_cb ($create_cb);
   $create_cb = $self->_fetch_cb_additions (send_iq_cb => $create_cb, $id, $type, \%attrs);

   my (@from) = ($self->{jid} ? (from => $self->{jid}) : ());
   if ($attrs{lang}) {
      push @from, ([ xmpp_ns ('xml'), 'lang' ] => delete $attrs{leng})
   }

   unless (defined $attrs{to}) {
      delete $attrs{to};
   }

   push @from, (id => filter_xml_chars $id) if defined $id;

   filter_xml_attr_hash_chars \%attrs;

   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('client'), '');

   if (defined $create_cb) {
      $w->startTag ([xmpp_ns ('client'), 'iq'], type => $type, @from, %attrs);
      $create_cb->($w);
      $w->endTag;
   } else {
      $w->emptyTag ([xmpp_ns ('client'), 'iq'], type => $type, @from, %attrs);
   }
   $self->flush;
}

=item B<send_presence ($id, $type, $create_cb, %attrs)>

Sends a presence stanza.

C<$create_cb> has the same meaning as for C<send_iq>.
C<%attrs> will let you pass further optional arguments like 'to'.

C<$type> is the type of the presence, which may be one of:

   unavailable, subscribe, subscribed, unsubscribe, unsubscribed, probe, error

Or undef, in case you want to send a 'normal' presence.
Or something completely different if you don't like the RFC 3921 :-)

C<%attrs> contains further attributes for the presence tag or may contain one of the
following exceptional keys:

If C<%attrs> contains a 'show' key: a child xml tag with that name will be generated
with the value as the content, which should be one of 'away', 'chat', 'dnd' and 'xa'.
If it contains an undefined value no such tag will be generated, which usually means
that the 'available' presence is meant.

If C<%attrs> contains a 'status' key: a child xml tag with that name will be generated
with the value as content. If the value of the 'status' key is an hash reference
the keys will be interpreted as language identifiers for the xml:lang attribute
of each status element. If one of these keys is the empty string '' no xml:lang attribute
will be generated for it. The values will be the character content of the status tags.

If C<%attrs> contains a 'priority' key: a child xml tag with that name will be generated
with the value as content, which must be a number between -128 and +127.

Note: If C<$create_cb> is undefined and one of the above attributes (show,
status or priority) were given, the generates presence tag won't be empty.

Please note that all attribute values and character data will be filtered
by C<filter_xml_chars> (see also L<AnyEvent::XMPP::Util>).

=cut

sub _generate_key_xml {
   my ($w, $key, $value) = @_;
   $w->startTag ($key);
   $w->characters (filter_xml_chars $value);
   $w->endTag;
}

sub _generate_key_xmls {
   my ($w, $key, $value) = @_;
   if (ref ($value) eq 'HASH') {
      for (keys %$value) {
         $w->startTag ($key, ($_ ne '' ? ([xmpp_ns ('xml'), 'lang'] => $_) : ()));
         $w->characters (filter_xml_chars $value->{$_});
         $w->endTag;
      }
   } else {
      $w->startTag ($key);
      $w->characters (filter_xml_chars $value);
      $w->endTag;
   }
}

sub _trans_create_cb {
   my ($cb) = @_;
   return unless defined $cb;
   if (ref ($cb) eq 'HASH') {
      my $args = $cb;
      $cb = sub {
         my ($w) = @_;
         simxml ($w, %$args);
      }
   } elsif (ref ($cb) eq 'ARRAY') {
      my @cbs = map { _trans_create_cb ($_) } @$cb;
      $cb = sub {
         my ($w) = @_;
         for (@cbs) { $_->($w) }
      }
   }
   $cb
}

sub _fetch_cb_additions {
   my ($self, $key, $create_cb, @args) = @_;
   my (@add_cbs) = $self->{$key}->(@args);
   @add_cbs = map { _trans_create_cb ($_) } @add_cbs;

   if (@add_cbs) {
      my $crcb = $create_cb;
      $create_cb = sub {
         my (@args) = @_;
         $crcb->(@args) if $crcb;
         for (@add_cbs) { $_->(@args) }
      }
   }

   $create_cb
}

sub send_presence {
   my ($self, $id, $type, $create_cb, %attrs) = @_;

   $create_cb = _trans_create_cb ($create_cb);
   $create_cb = $self->_fetch_cb_additions (send_pres_cb => $create_cb, $id, $type, \%attrs);

   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('client'), '');

   my @add;
   push @add, (type => $type) if defined $type;
   push @add, (id => $id) if defined $id;

   my %fattrs =
      map { $_ => $attrs{$_} }
         grep { my $k = $_; not grep { $k eq $_ } qw/show priority status/ }
            keys %attrs;

   filter_xml_attr_hash_chars \%fattrs;

   if (defined $create_cb) {
      $w->startTag ([xmpp_ns ('client'), 'presence'], @add, %fattrs);
      _generate_key_xml ($w, show => $attrs{show})         if defined $attrs{show};
      _generate_key_xml ($w, priority => $attrs{priority}) if defined $attrs{priority};
      _generate_key_xmls ($w, status => $attrs{status})    if defined $attrs{status};
      $create_cb->($w);
      $w->endTag;
   } else {
      if (exists $attrs{show} or $attrs{priority} or $attrs{status}) {
         $w->startTag ([xmpp_ns ('client'), 'presence'], @add, %fattrs);
         _generate_key_xml ($w, show => $attrs{show})         if defined $attrs{show};
         _generate_key_xml ($w, priority => $attrs{priority}) if defined $attrs{priority};
         _generate_key_xmls ($w, status => $attrs{status})    if defined $attrs{status};
         $w->endTag;
      } else {
         $w->emptyTag ([xmpp_ns ('client'), 'presence'], @add, %fattrs);
      }
   }

   $self->flush;
}

=item B<send_message ($id, $to, $type, $create_cb, %attrs)>

Sends a message stanza.

C<$to> is the destination JID of the message. C<$type> is
the type of the message, and if C<$type> is undefined it will default to 'chat'.
C<$type> must be one of the following: 'chat', 'error', 'groupchat', 'headline'
or 'normal'.

C<$create_cb> has the same meaning as in C<send_iq>.

C<%attrs> contains further attributes for the message tag or may contain one of the
following exceptional keys:

If C<%attrs> contains a 'body' key: a child xml tag with that name will be generated
with the value as content. If the value of the 'body' key is an hash reference
the keys will be interpreted as language identifiers for the xml:lang attribute
of each body element. If one of these keys is the empty string '' no xml:lang attribute
will be generated for it. The values will be the character content of the body tags.

If C<%attrs> contains a 'subject' key: a child xml tag with that name will be generated
with the value as content. If the value of the 'subject' key is an hash reference
the keys will be interpreted as language identifiers for the xml:lang attribute
of each subject element. If one of these keys is the empty string '' no xml:lang attribute
will be generated for it. The values will be the character content of the subject tags.

If C<%attrs> contains a 'thread' key: a child xml tag with that name will be generated
and the value will be the character content.

Please note that all attribute values and character data will be filtered
by C<filter_xml_chars> (see also L<AnyEvent::XMPP::Util>).

=cut

sub send_message {
   my ($self, $id, $to, $type, $create_cb, %attrs) = @_;

   $create_cb = _trans_create_cb ($create_cb);
   $create_cb = $self->_fetch_cb_additions (send_msg_cb => $create_cb, $id, $to, $type, \%attrs);

   my $w = $self->{writer};
   $w->addPrefix (xmpp_ns ('client'), '');

   my @add;
   push @add, (id => $id) if defined $id;

   $type ||= 'chat';

   my %fattrs =
      map { $_ => $attrs{$_} }
         grep { my $k = $_; not grep { $k eq $_ } qw/subject body thread/ }
            keys %attrs;

   if (defined $create_cb) {
      $w->startTag ([xmpp_ns ('client'), 'message'], @add, to => $to, type => $type, %fattrs);
      _generate_key_xmls ($w, subject => $attrs{subject})    if defined $attrs{subject};
      _generate_key_xmls ($w, body => $attrs{body})          if defined $attrs{body};
      _generate_key_xml ($w, thread => $attrs{thread})       if defined $attrs{thread};
      $create_cb->($w);
      $w->endTag;
   } else {
      if (exists $attrs{subject} or $attrs{body} or $attrs{thread}) {
         $w->startTag ([xmpp_ns ('client'), 'message'], @add, to => $to, type => $type, %fattrs);
         _generate_key_xmls ($w, subject => $attrs{subject})    if defined $attrs{subject};
         _generate_key_xmls ($w, body => $attrs{body})          if defined $attrs{body};
         _generate_key_xml ($w, thread => $attrs{thread})       if defined $attrs{thread};
         $w->endTag;
      } else {
         $w->emptyTag ([xmpp_ns ('client'), 'message'], @add, to => $to, type => $type, %fattrs);
      }
   }

   $self->flush;
}


=item B<write_error_tag ($error_stanza_node, $error_type, $error)>

C<$error_type> is one of 'cancel', 'continue', 'modify', 'auth' and 'wait'.
C<$error> is the name of the error tag child element. If C<$error> is one of
the following:

   'bad-request', 'conflict', 'feature-not-implemented', 'forbidden', 'gone',
   'internal-server-error', 'item-not-found', 'jid-malformed', 'not-acceptable',
   'not-allowed', 'not-authorized', 'payment-required', 'recipient-unavailable',
   'redirect', 'registration-required', 'remote-server-not-found',
   'remote-server-timeout', 'resource-constraint', 'service-unavailable',
   'subscription-required', 'undefined-condition', 'unexpected-request'

then a default can be select for C<$error_type>, and the argument can be undefined.

Note: This method is currently a bit limited in the generation of the xml
for the errors, if you need more please contact me.

=cut

our %STANZA_ERRORS = (
   'bad-request'             => ['modify', 400],
   'conflict'                => ['cancel', 409],
   'feature-not-implemented' => ['cancel', 501],
   'forbidden'               => ['auth',   403],
   'gone'                    => ['modify', 302],
   'internal-server-error'   => ['wait',   500],
   'item-not-found'          => ['cancel', 404],
   'jid-malformed'           => ['modify', 400],
   'not-acceptable'          => ['modify', 406],
   'not-allowed'             => ['cancel', 405],
   'not-authorized'          => ['auth',   401],
   'payment-required'        => ['auth',   402],
   'recipient-unavailable'   => ['wait',   404],
   'redirect'                => ['modify', 302],
   'registration-required'   => ['auth',   407],
   'remote-server-not-found' => ['cancel', 404],
   'remote-server-timeout'   => ['wait',   504],
   'resource-constraint'     => ['wait',   500],
   'service-unavailable'     => ['cancel', 503],
   'subscription-required'   => ['auth',   407],
   'undefined-condition'     => ['cancel', 500],
   'unexpected-request'      => ['wait',   400],
);

sub write_error_tag {
   my ($self, $errstanza, $type, $error) = @_;

   my $w = $self->{writer};

   $_->write_on ($w) for $errstanza->nodes;

   my @add;

   unless (defined $type and defined $STANZA_ERRORS{$error}) {
      $type = $STANZA_ERRORS{$error}->[0];
   }

   push @add, (code => $STANZA_ERRORS{$error}->[1]);

   my %add = @add;
   filter_xml_attr_hash_chars \%add;

   $w->addPrefix (xmpp_ns ('client'), '');
   $w->startTag ([xmpp_ns ('client') => 'error'], type => $type, %add);
      $w->addPrefix (xmpp_ns ('stanzas'), '');
      $w->emptyTag ([xmpp_ns ('stanzas') => filter_xml_chars $error]);
   $w->endTag;
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
