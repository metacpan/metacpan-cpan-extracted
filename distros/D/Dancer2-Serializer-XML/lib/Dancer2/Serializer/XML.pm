package Dancer2::Serializer::XML;
#ABSTRACT: serializer for handling XML data in Dancer2
our $AUTHORITY = 'cpan:IGIBBS';
use strict;
use warnings;
use Moo;
use Dancer2;	# So that setting is available in tests
use Class::Load 'load_class';
with 'Dancer2::Core::Role::Serializer';

our $VERSION = '0.06';

has '+content_type' => ( default => sub {'application/xml'} );
has 'xml_options' => 
( 
	default => sub { {RootName => 'data', KeyAttr => [], AttrIndent => 1} },
	is => 'rw'
);

sub BUILD
{
    my ($self) = @_;
    die 'XML::Simple is needed and is not installed' unless $self->loaded_xmlsimple;
    die 'XML::Simple needs XML::Parser or XML::SAX and neither is installed' unless $self->loaded_xmlbackends;
}

sub serialize
{
	my $self    = shift;
	my $entity  = shift;

	#my $s = setting('engines') || {};
	#if(exists($s->{serializer}) && exists($s->{serializer}{serialize}))
	#{
	#	$options = (%options, %{$s->{serializer}{serialize}});
	#}
	my %options = ();
	%options = %{$self->xml_options->{'serialize'}} if(exists($self->xml_options->{'serialize'}));
	my $xml = XML::Simple::XMLout($entity, %options);
	utf8::encode($xml);

	return $xml;
}	

sub deserialize
{
	my $self = shift;
	my $xml = shift;
	
	utf8::decode($xml);

	#~ my $s = setting('engines') || {};
	#~ if(exists($s->{serializer}) && exists($s->{serializer}{deserialize}))
	#~ {
		#~ %options = (%options, %{$s->{serializer}{deserialize}});
	#~ }
	my %options = ();
	%options = %{$self->xml_options->{'deserialize'}} if(exists($self->xml_options->{'deserialize'}));

	return XML::Simple::XMLin($xml, %options);
}

sub loaded_xmlsimple
{
	load_class('XML::Simple');
}

sub loaded_xmlbackends
{	# We need either XML::Parser or XML::SAX too
	load_class('XML::Parser') or
	load_class('XML::SAX');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Serializer::XML - serializer for handling XML data

=head1 SYNOPSIS

   set serializer => 'XML';

   # Send an XML string to the caller
   get '/xml/get_example' => sub {
      return { foo => 'one', bar => 'two' }
   }
   
   # Parse an XML string sent by the caller
   put '/xml/from_body' => sub {
      debug request->data();	# Contains the deserialised Perl object
      return template 'ok';
   };

=head1 DESCRIPTION

This module is a plugin for the Web application frmaework Dancer2, and 
allows it to serialise Perl objects into XML, and deserialise XML into 
Perl objects. It uses L<XML::Simple> under the covers.

=head2 STATUS

Alpha, but it works for me. Reports of success are gratefully received.

=head2 METHODS

=head3 serialize

Serialize a data structure to an XML structure. Called automatically by 
Dancer2.

=head3 deserialize

Deserialize an XML structure to a data structure. Called automatically
 by Dancer2.

=head3 content_type

Returns the string 'application/xml'

=head2 CONFIGURATION

The default behaviour of this module is the default behaviour of 
L<XML::Simple> - nothing is overridden, which creates backwards 
compatability with L<Dancer::Serializer::XML>. Every option that 
L<XML::Simple> supports is also supported by this module. 

You can control options for serialization and deserialization 
separately. See the examples below.

=head3 Configuration in code

To configure the serializer in a route, do this:

   get '/xml/example' => sub {
      my $self = shift;
      $self->{'serializer_engine'}->{'xml_options'}->{'serialize'}->
                                                  {'RootName'} = 'data';
      return { foo => 'one', bar => 'two' }
   }
	
Which will produce this:

   <data bar="two" foo="one" />
   
You can pass a reference to a hash to configure multiple things:

   $self->{'serializer_engine'}->{'xml_options'}->{'serialize'} = 
                                  { RootName => 'data', KeyAttr => [] };
   
To configure the deserializer, do similarly:

   put '/from_body' => sub {
      my $self = shift;
      $self->{'serializer_engine'}->{'xml_options'}->{'deserialize'}->
                                                       {'KeepRoot'} = 1;
      return template 'ok';
   };

etc. See below for the recommended configuration.

=head3 Configuration in config file

At this time there seems I cannot find a way for a Dancer2 serializer to
 directly access the configuration of a Dancer2 app. If you know it, 
 please tell me. Until then, do this in your code:
 
   get '/xml/example' => sub {
      my $self = shift;
      $self->{'serializer_engine'}->{'xml_options'} = 
                         $self->{'config'}->{'engines'}->{'serializer'};
      return { foo => 'one', bar => 'two' }
   }

and put this in your config file:

   engines:
      serializer:
        serialize:
           RootName: 'data'
           KeyAttr: []
        deserialize:
           KeepRoot: 1

BUT see L</"Recommended configuration">.
	
=head3 Recommended configuration

For new code, these are the recommended settings for consistent 
behaviour. In code:

   my $xml_options = { 'serialize' => { RootName => 'test',
   									KeyAttr => []
   									},
   					'deserialize' => { ForceContent => 1,
   									KeyAttr => [],
   									ForceArray => 1,
   									KeepRoot => 1
   									}
   					};

In config:

   engines:
      serializer:
        serialize:
           AttrIndent: 1
           KeyAttr: []
        deserialize:
           ForceArray: 1
           KeyAttr: []
           ForceContent: 1
           KeepRoot: 1

=head1 SEE ALSO / EXAMPLES

L<XML::Simple>

=head1 SOURCE / BUGS / CONTRIBUTIONS

L<GitHub|https://github.com/realflash/perl-dancer2-serializer-xml>

=head1 AUTHOR

Ian Gibbs, E<lt>igibbs@cpan.orgE<gt> and
Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ian Gibbs and
Copyright (C) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
