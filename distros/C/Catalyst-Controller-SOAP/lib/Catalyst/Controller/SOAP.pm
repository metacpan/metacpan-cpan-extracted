{   package Catalyst::Controller::SOAP;

    use strict;
    use base 'Catalyst::Controller';
    use XML::LibXML;
    use XML::Compile::WSDL11;
    use XML::Compile::SOAP11;
    use MRO::Compat;
    use mro 'c3';
    use Encode;

    use constant NS_SOAP_ENV => "http://schemas.xmlsoap.org/soap/envelope/";
    use constant NS_WSDLSOAP => "http://schemas.xmlsoap.org/wsdl/soap/";

    our $VERSION = '1.25';

    __PACKAGE__->mk_accessors (qw(wsdl wsdlobj decoders encoders ports
         wsdlservice xml_compile soap_action_prefix rpc_endpoint_paths
         doclitwrapped_endpoint_paths));

    sub __init_wsdlobj {
        my ($self, $c) = @_;

        my $wsdlfile = $self->wsdl;

        if ($wsdlfile) {
            if (!$self->wsdlobj) {
                my $schema;
                if (ref $wsdlfile eq 'HASH') {
                    $schema = $wsdlfile->{schema};
                    $wsdlfile = $wsdlfile->{wsdl};
                }

                if (ref $wsdlfile eq 'ARRAY') {
                    my $main = shift @{$wsdlfile};
                    $c->log->debug("WSDL: adding main WSDL $main")
                      if $c->debug;
                    $self->wsdlobj(XML::Compile::WSDL11->new($main));
                    foreach my $file (@{$wsdlfile}) {
                        $c->log->debug("WSDL: adding additional WSDL $file")
                          if $c->debug;
                        $self->wsdlobj->addWSDL($file);
                    }
                }
                else {
                      $c->log->debug("WSDL: adding WSDL $wsdlfile")
                        if $c->debug;
                      $self->wsdlobj(XML::Compile::WSDL11->new($wsdlfile));
                }

                if (ref $schema eq 'ARRAY') {
                    foreach my $file (@$schema) {
                        $c->log->debug("WSDL: Import schema $file")
                          if $c->debug;
                        $self->wsdlobj->importDefinitions($file);
                    }
                }
                elsif ($schema) {
                    $c->log->debug("WSDL: Import schema $schema") if $c->debug;
                    $self->wsdlobj->importDefinitions($schema)
                }
            }
        }

        return $self->wsdlobj ? 1 : 0;
    }

    sub _parse_WSDLPort_attr {
        my ($self, $c, $name, $value, $wrapped) = @_;

        die 'Cannot use WSDLPort without WSDL.'
          unless $self->__init_wsdlobj($c);

        $self->ports({}) unless $self->ports();
        $self->ports->{$name} = $value;
        my $operation = $self->wsdlobj->operation($name,
                                                  port => $value,
                                                  service => $self->wsdlservice)
          or die 'Every operation should be on the WSDL when using one.';
        # TODO: Use more intelligence when selecting the address.
        my ($path) = $operation->endPoints;

        $path =~ s#^[^:]+://[^/]+##;

        my $style = $operation->style;
        my $use = $operation->{input_def}->{body}->{use};

        $style = $style =~ /document/i ? 'Document' : 'RPC';
        $use = $use =~ /literal/i ? 'Literal' : 'Encoded';
        $c->log->debug("WSDLPort: [$name] [$value] [$path] [$style] [$use]")
          if $c->debug;

        if ($style eq 'Document' && !$wrapped) {
            return
              (
               Path => $path,
               $self->_parse_SOAP_attr($c, $name, $style.$use)
              );
	} elsif ($style eq 'Document' && $wrapped) {
            $self->doclitwrapped_endpoint_paths([]) unless $self->doclitwrapped_endpoint_paths;
            $path =~ s/\/$//;
            push @{$self->doclitwrapped_endpoint_paths}, $path
              unless grep { $_ eq $path }
                @{$self->doclitwrapped_endpoint_paths};
            return
              (
               $self->_parse_SOAP_attr($c, $name, $style.$use)
              );
        } else {
            $self->rpc_endpoint_paths([]) unless $self->rpc_endpoint_paths;
            $path =~ s/\/$//;
            push @{$self->rpc_endpoint_paths}, $path
              unless grep { $_ eq $path }
                @{$self->rpc_endpoint_paths};
            return
              (
               $self->_parse_SOAP_attr($c, $name, $style.$use),
              );
        }
    }

    sub _parse_WSDLPortWrapped_attr {
        my ($self, $c, $name, $value) = @_;
	my %attrs = $self->_parse_WSDLPort_attr($c, $name, $value, 'wrapped');
	delete $attrs{Path};
	return %attrs;
    }

    # Let's create the rpc_endpoint action.
    sub register_actions {
        my $self = shift;
        my ($c) = @_;
        $self->SUPER::register_actions(@_);

        if ($self->rpc_endpoint_paths) {
            my $namespace = $self->action_namespace($c);
            my $action = $self->create_action
              (
               name => '___base_rpc_endpoint',
               code => sub {  },
               reverse => ($namespace ? $namespace.'/' : '') . '___base_rpc_endpoint',
               namespace => $namespace,
               class => (ref $self || $self),
               attributes => { ActionClass => [ 'Catalyst::Action::SOAP::RPCEndpoint' ],
                               Path => $self->rpc_endpoint_paths }
              );
            $c->dispatcher->register($c, $action);
        }

        if ($self->doclitwrapped_endpoint_paths) {
            my $namespace = $self->action_namespace($c);
            my $action = $self->create_action
              (
               name => '___base_doclitwrapped_endpoint',
               code => sub {  },
               reverse => ($namespace ? $namespace.'/' : '') . '___base_doclitwrapped_endpoint',
               namespace => $namespace,
               class => (ref $self || $self),
               attributes => { ActionClass => [ 'Catalyst::Action::SOAP::DocumentLiteralWrapped' ],
                               Path => $self->doclitwrapped_endpoint_paths }
              );
            $c->dispatcher->register($c, $action);
        }

    }

    sub _parse_SOAP_attr {
        my ($self, $c, $name, $value) = @_;

        my $wsdlfile     = $self->wsdl;
        my $wsdlservice  = $self->wsdlservice;
        my $compile_opts = $self->xml_compile || {};
        my $reader_opts  = $compile_opts->{reader} || {};
        my $writer_opts  = $compile_opts->{writer} || {};

        if ($wsdlfile) {

            die 'WSDL initialization failed.'
              unless $self->__init_wsdlobj($c);

            $self->ports({}) unless $self->ports();
            my $operation = $self->wsdlobj->operation($name,
                                                      port => $self->ports->{$name},
                                                      service => $wsdlservice)
              or die 'Every operation should be on the WSDL when using one.';

            my $in_message = $operation->{input_def}->{body}->{message};
            my $in_namespace = $operation->{input_def}{body}{namespace};
            my $out_message = $operation->{output_def}->{body}->{message};
            my $out_namespace = $operation->{output_def}{body}{namespace};

            $c->log->debug("SOAP: ".$operation->name." ".($in_message||'(none)').' '.($out_message||'(none)'))
              if $c->debug;

            if ($in_message) {
                my $input_parts = $self->wsdlobj->findDef(message => $in_message)
                  ->{wsdl_part};

                for (@{$input_parts}) {
                    my $type = $_->{type} ? $_->{type} : $_->{element};
                    $c->log->debug("SOAP: @{[$operation->name]} input part $_->{name}, type $type")
                      if $c->debug;
                    $_->{compiled_reader} = $self->wsdlobj->compile
                      (READER => $type,
                       %$reader_opts);
                };

                $self->decoders({}) unless $self->decoders();
                $self->decoders->{$name} = sub {
                    my $body = shift;
                    my @nodes = grep { UNIVERSAL::isa($_, 'XML::LibXML::Element') } $body->childNodes();
                    return
                      {
                       map {
                           my $data = $_->{compiled_reader}->(shift @nodes);
                           $_->{name} => $data;
                       } @{$input_parts}
                      }, @nodes;
                };
            }

            my $name = $operation->name;
            if ($out_message) {

                my $output_parts = $self->wsdlobj->findDef(message => $out_message)
                  ->{wsdl_part};
                for (@{$output_parts}) {
                    my $type = $_->{type} ? $_->{type} : $_->{element};
                    $c->log->debug("SOAP: @{[$operation->name]} out part $_->{name}, type $type")
                      if $c->debug;
                    $_->{compiled_writer} = $self->wsdlobj->compile
                      (WRITER => $_->{type} ? $_->{type} : $_->{element},
                       elements_qualified => 'ALL',
                       %$writer_opts);
                }

                $self->encoders({}) unless $self->encoders();
                if ($operation->style eq 'rpc') {
                  $self->encoders->{$name} = sub {
                    my ($doc, $data) = @_;
                    my $element = $doc->createElementNS($out_namespace,$name.'Response');
                    $element->appendChild($_) for map {
                      $_->{compiled_writer}->($doc, $data->{$_->{name}})
                    } @{$output_parts};
                    return
                      [ $element ];
                  };

                } else {
                  $self->encoders->{$name} = sub {
                    my ($doc, $data) = @_;
                    return
                      [
                       map {
                         $_->{compiled_writer}->($doc, $data->{$_->{name}})
                       } @{$output_parts}
                      ];
                  };
                }

            }
        }

        my $actionclass = ($value =~ /^\+/ ? $value :
          'SOAP::'.$value);
        (
         ActionClass => $actionclass,
        )
    }

    # this is implemented as to respond a SOAP message according to
    # what has been sent to $c->stash->{soap}
    sub end : Private {
        my ($self, $c) = (shift, shift);
        my $soap = $c->stash->{soap};

        return $self->maybe::next::method($c, @_)
          unless $soap;

        if (scalar @{$c->error}) {
            $c->stash->{soap}->fault
              ({ code => '{'.NS_SOAP_ENV.'}Client',
                 reason => 'Unexpected Error', detail =>
                 'Unexpected error in the application: '.(join "\n", @{$c->error} ).'!'})
                unless $c->stash->{soap}->fault;
            $c->error(0);
        }

        my $namespace = $soap->namespace || NS_SOAP_ENV;
        my $response = XML::LibXML->createDocument('1.0','UTF8');

        my $envelope;

        if ($soap->fault) {

            $envelope = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Envelope");

            $response->setDocumentElement($envelope);

            my $body = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Body");

            $envelope->appendChild($body);

            my $fault = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Fault");
            $body->appendChild($fault);

            my $code = $response->createElement("faultcode");
            $fault->appendChild($code);
            my $codestr = $soap->fault->{code};
            if (my ($ns, $val) = $codestr =~ m/^\{(.+)\}(.+)$/) {
                my $prefix = $fault->lookupNamespacePrefix($ns);
                if ($prefix) {
                    $code->appendText($prefix.':'.$val);
                } else {
                    $code->appendText($val);
                }
            } else {
                $code->appendText('SOAP-ENV:'.$codestr);
            }

            my $faultstring = $response->createElement("faultstring");
            $fault->appendChild($faultstring);
            $faultstring->appendText($soap->fault->{reason});

            if (UNIVERSAL::isa($soap->fault->{detail}, 'XML::LibXML::Node')) {
                my $detail = $response->createElement("detail");
                $detail->appendChild($soap->fault->{detail});
                $fault->appendChild($detail);
            } elsif ($soap->fault->{detail}) {
                my $detail = $response->createElement("detail");
                $fault->appendChild($detail);
                # TODO: we don't support the xml:lang attribute yet.
                my $text = $response->createElementNS
                  ('http://www.w3.org/2001/XMLSchema','xsd:documentation');
                $detail->appendChild($text);
                $text->appendText($soap->fault->{detail});
            }
        } else {

            if ($soap->string_return) {
                $envelope = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Envelope");
                $response->setDocumentElement($envelope);
                my $body = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Body");
                $envelope->appendChild($body);
                $body->appendText($soap->string_return);
            } elsif (my $lit = $soap->literal_return) {
                $envelope = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Envelope");
                $response->setDocumentElement($envelope);
                my $body = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Body");
                $envelope->appendChild($body);
                if (ref $lit eq 'XML::LibXML::NodeList') {
                    for ($lit->get_nodelist) {
                        $body->appendChild($_);
                    }
                } else {
                    $body->appendChild($lit);
                }
            } elsif (my $cmp = $soap->compile_return) {
                $envelope = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Envelope");
                $response->setDocumentElement($envelope);
                my $body = $response->createElementNS(NS_SOAP_ENV, "SOAP-ENV:Body");
                $envelope->appendChild($body);
                die 'Tried to use compile_return without WSDL'
                  unless $self->wsdlobj;

                my $arr = $self->encoders->{$soap->operation_name}->($response, $cmp);

                $body->appendChild($_) for @$arr;
            }
        }

        if ($envelope) {
          $c->log->debug("Outgoing XML: ".$envelope->toString()) if $c->debug;
          $c->res->content_type('text/xml; charset=UTF-8');
          $c->res->body(encode('utf8',$envelope->toString()));
        } else {
          $c->maybe::next::method($c, @_);
        }
    }


};

{   package Catalyst::Controller::SOAP::Helper;

    use base 'Class::Accessor::Fast';

    __PACKAGE__->mk_accessors(qw{envelope parsed_envelope arguments fault namespace
                                 encoded_return literal_return string_return
                                 compile_return operation_name});


};


1;

__END__

=head1 NAME

Catalyst::Controller::SOAP - Catalyst SOAP Controller

=head1 SYNOPSIS

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller::SOAP';

    # When using a WSDL, you can just specify the Port name, and it
    # will infer the style and use. To do that, you just need to use
    # the WSDLPort attribute. This might be required if your service
    # has more than one port.  This operation will be made available
    # using the path part of the location attribute of the port
    # definition.
    __PACKAGE__->config->{wsdl} = 'file.wsdl';
    sub servicefoo : WSDLPort('ServicePort') {}

    # available in "/example" as operation "ping". The arguments are
    # treated as a literal document and passed to the method as a
    # XML::LibXML object
    # Using XML::Compile here will help you reading the message.
    sub ping : SOAP('RPCLiteral') {
        my ( $self, $c, $xml) = @_;
        my $name = $xml->findValue('some xpath expression');
    }

    # avaiable as "/example/world" in document context. The entire body
    # is delivered to the method as a XML::LibXML object.
    # Using XML::Compile here will help you reading the message.
    sub world :Local SOAP('DocumentLiteral')  {
        my ($self, $c, $xml) = @_;
    }

    # avaiable as "/example/get" in HTTP get context.
    # the get attributes will be available as any other
    # get operation in Catalyst.
    sub get :Local SOAP('HTTPGet')  {
        my ($self, $c) = @_;
    }

    # this is the endpoint from where the RPC operations will be
    # dispatched. This code won't be executed at all.
    # See Catalyst::Controller::SOAP::RPC.
    sub index :Local SOAP('RPCEndpoint') {}


=head1 ABSTACT

Implements SOAP serving support in Catalyst.

=head1 DESCRIPTION

SOAP Controller for Catalyst which we tried to make compatible with
the way Catalyst works with URLS.It is important to notice that this
controller declares by default an index operation which will dispatch
the RPC operations under this class.

=head1 ATTRIBUTES

This class implements the SOAP attribute wich is used to do the
mapping of that operation to the apropriate action class. The name of
the class used is formed as Catalyst::Action::SOAP::$value, unless the
parameter of the attribute starts with a '+', which implies complete
namespace.

The implementation of SOAP Action classes helps delivering specific
SOAP scenarios, like HTTP GET, RPC Encoded, RPC Literal or Document
Literal, or even Document RDF or just about any required combination.

See L<Catalyst::Action::SOAP::DocumentLiteral> for an example.

=head1 ACCESSORS

Once you tagged one of the methods, you'll have an $c->stash->{soap}
accessor which will return an C<Catalyst::Controller::SOAP::Helper>
object. It's important to notice that this is achieved by the fact
that all the SOAP Action classes are subclasses of
Catalyst::Action::SOAP, which implements most of that.

You can query this object as follows:

=over 4

=item $c->stash->{soap}->envelope()

The original SOAP envelope as string.

=item $c->stash->{soap}->parsed_envelope()

The parsed envelope as an XML::LibXML object.

=item $c->stash->{soap}->arguments()

The arguments of a RPC call.

=item $c->stash->{soap}->fault({code => $code,reason => $reason, detail => $detail])

Allows you to set fault code and message. Optionally, you may define
the code itself as an arrayref where the first item will be this code
and the second will be the subcode, which recursively may be another
arrayref.

=item $c->stash->{soap}->encoded_return(\@data)

This method will prepare the return value to be a soap encoded data.

  # TODO: At this moment, only Literals are working...

=item $c->stash->{soap}->literal_return($xml_node)

This method will prepare the return value to be a literal XML
document, in this case, you can pass just the node that will be the
root in the return message or a nodelist.

Using XML::Compile will help to elaborate schema based returns.

=item $c->stash->{soap}->string_return($non_xml_text)

In this case, the given text is encoded as CDATA inside the SOAP
message.

=back

=head1 USING WSDL

If you define the "wsdl" configuration key, Catalyst::Controller::SOAP
will automatically map your operations into the WSDL operations, in
which case you will receive the parsed Perl structure as returned by
XML::Compile according to the type defined in the WSDL message.

You can define additional wsdl files or even additional schema
files. If $wsdl is an arrayref, the first element is the one passed to
new, and the others will be the argument to subsequent addWsdl calls.
If $wsdl is a hashref, the "wsdl" key will be handled like above and
the "schema" key will be used to importDefinitions. If the content of
the schema key is an arrayref, it will result in several calls to
importDefinition.

When using WSDL, you can use the WSDLPort attribute, that not only
sets the port name but also infer which is the style of the binding,
the use of the input body and also declares the Path for the operation
according to the 'location' attribute in the WSDL file. For RPC
operations, the endpoint action will be created dinamically also in
the path defined by the WSDL file.

This is the most convenient way of defining a SOAP service, which, in
the end, will require you to have it as simple as:

  package SOAPApp::Controller::WithWSDL;
  use base 'Catalyst::Controller::SOAP';
  __PACKAGE__->config->{wsdl} = 't/hello4.wsdl';
  
  # in this case, the input has two parts, named 'who' and 'greeting'
  # and the output has a single 'greeting' part.
  sub Greet : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => $grt.' '.$who.'!' });
  }

When using WSDL with more than one port, the use of this attribute is
mandatory.

When the WSDL describes more than one service, the controller can only
represent one of them, so you must define the 'wsdlservice' config key
that will be used to select the service.

Also, when using wsdl, you can define the response using:

  $c->stash->{soap}->compile_return($perl_structure)

In this case, the given structure will be transformed by XML::Compile,
according to what's described in the WSDL file.

If you define "xml_compile" as a configuration key (which is a 
hashref with keys 'reader' and 'writer', which both have a hashref
as their value), those key / value pairs will be passed as options
to the XML::Compile::Schema::compile() method.

  __PACKAGE__->config->{xml_compile} = {
      reader => {sloppy_integers => 1}, writer => {sloppy_integers => 1},
  };

=head1 Support for Document/Literal-Wrapped

Please make sure you read the documentation at
L<Catalyst::Action::SOAP::DocumentLiteralWrapped> before using this
feature.

The support for Document/Literal-Wrapped works by faking RPC style
even when the WSDL says the service is in the "Document" mode. The
parameter used for the actual dispatch is the soapAction attribute.

In practice, the endpoint of the action is an empty action that will
redirect the request to the actual action based on the name of the
soapAction. It uses the soap_action_prefix controller configuration
variable to extract the name of the action.

There is an important restriction in that fact. The name of the
operation in the WSDL must match the suffix of the soapAction
attribute.

If you have a Document/Literal-Wrapped WSDL and rewriting it as
RPC/Literal is not an option, take the following steps:

=over

=item Set the soap_action_prefix

It is assumed that all operations in the port have a common prefix, it
is also assumed that when the prefix is removed, the remaining string
can be used as a subroutine name (i.e.: it should not contain
additional slashes).

  __PACKAGE__->config->{soap_action_prefix} = 'http://foo.com/bar/';

=item Make sure the soapAction attribute is consistent with the operation name

Since the dispatching mechanism is dissociated from the
encoding/decoding process, the only way for this to work is to have
the soapAction to be consistent with the operation name.

  <!--- inside the WSDL binding section -->
  <wsdl:operation name="Greet">
      <soap:operation soapAction="http://foo.com/bar/Greet" />
      <wsdl:input>
  ...

Note that the name of the operation is "Greet" and the soapAction
attribute is the result of concatenating the soap_action_prefix and
the name of the operation.

=item Implement the action using the WSDLPortWrapped action attribute

Instead of using the standard WSDLPort attribute, use the alternative
implementation that will provide the extra dispatching.

  sub Greet :WSDLPortWrapped('GreetPort') {
     ...
  }

Note that the name of the sub is consistent with the name of the
operation.

=back

But always try to refactor your WSDL as RPC/Literal instead, which is
much more predictable and, in fact, is going to provide you a much
more sane WSDL file.

=head1 USING WSDL AND Catalyst::Test

If you'd like to use the built-in server from Catalyst::Test with your
WSDL file (which likely defines an <address location="..."> that differs
from the standard test server) you'll need to use the transport_hook
option available with $wsdl->compileClient() in your test file.


    # t/soap_message.t
    use XML::Compile::WSDL11;
    use XML::Compile::Transport::SOAPHTTP;
    use Test::More 'no_plan';

    BEGIN {
        use_ok 'Catalyst::Test', 'MyServer';
    }

    sub proxy_to_test_app
    {
        my ($request, $trace) = @_;
        # request() is a function inserted by Catalyst::Test which
        # sends HTTP requests to the just-started test server.
        return request($request);
    }

    my $xml       = '/path/to/wsdl/file';
    my $message   = 'YourMessage';
    my $port_name = 'YourPort';
    my $wsdl      = XML::Compile::WSDL11->new($xml);
    my $client    = $wsdl->compileClient($message, 
        port => $port_name, transport_hook => \&proxy_to_test_app,
    );
    $client->(...);


=head1 TODO

No header features are implemented yet.

The SOAP Encoding support is also missing, when that is ready you'll
be able to do something like the code below:

    # available in "/example" as operation "echo"
    # parsing the arguments as soap-encoded.
    sub echo : SOAP('RPCEncoded') {
        my ( $self, $c, @args ) = @_;
    }

=head1 SEE ALSO

L<Catalyst::Action::SOAP>, L<XML::LibXML>, L<XML::Compile>
L<Catalyst::Action::SOAP::DocumentLiteral>,
L<Catalyst::Action::SOAP::RPCLiteral>,
L<Catalyst::Action::SOAP::HTTPGet>, L<XML::Compile::WSDL11>,
L<XML::Compile::Schema>

=head1 AUTHORS

Daniel Ruoso C<daniel@ruoso.com>

Drew Taylor C<drew@drewtaylor.com>

Georg Oechsler C<goe-cpan@space.net>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
