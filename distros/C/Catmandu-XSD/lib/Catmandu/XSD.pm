package Catmandu::XSD;

use Moo;
use Catmandu::Util;
use XML::Compile;
use XML::Compile::Cache;
use XML::Compile::Util 'pack_type';

our $VERSION = '0.04';

has 'root'      => (is => 'ro' , required => 1);
has 'schemas'   => (is => 'ro' , required => 1 , coerce => sub {
    my ($value) = @_;
    if (Catmandu::Util::is_array_ref($value)) {
        return $value;
    }
    elsif ($value =~ /\*/) {
        my @files = glob($value);
        \@files;
    }
    else {
        my @files = split(/,/,$value);
        \@files;
    }
});

has 'mixed'       => (is => 'ro' , default => sub { 'ATTRIBUTES' });
has 'any_element' => (is => 'ro' , default => sub { 'TAKE_ALL' } , coerce => sub {
        my $val = $_[0];
        if (defined $val && $val eq 'XML_STRING') {
            return sub {
                my ($path, $node , $handler) = @_;
                if ($node && ref($node)) {
                    my $str = '';
                    for (@$node) {
                        $str .= $_->toString;
                    }
                    ('_',$str);
                }
                else {
                    $node;
                }
            };
        }
        else {
            $val;
        }
});
has 'prefixes'    => (is => 'ro' , coerce  => sub {
   my ($value) = @_;
   if (Catmandu::Util::is_array_ref($value)) {
       return $value;
   }
   elsif (defined($value)) {
       my $ret = [];
       for (split(/,/,$value)) {
           my ($ns,$url) = split(/:/,$_,2);
           push @$ret , { $ns => $url };
       }
       return $ret;
   }
   else {
       undef;
   }
});

has '_reader'    => (is => 'ro');
has '_writer'    => (is => 'ro');

sub BUILD {
    my ($self) = @_;

    my $schema = XML::Compile::Cache->new($self->schemas);

    $schema->addHook(
        action => 'READER' ,
        after => sub {
             my ($xml, $data, $path) = @_;
             delete $data->{_MIXED_ELEMENT_MODE} if Catmandu::Util::is_hash_ref($data);
             $data;
        }
    );

    $self->{_reader} = $schema->compile(
            READER          => $self->root,
            mixed_elements  => $self->mixed ,
            any_element     => $self->any_element ,
            sloppy_floats   => 'true',
            sloppy_integers => 'true' ,
    );

    $self->{_writer} = $schema->compile(
            WRITER          => $self->root,
            prefixes        => $self->prefixes,
            sloppy_floats   => 'true',
            sloppy_integers => 'true' ,
    );

    $schema = undef;
}

sub template {
    my ($self) = @_;
    my $schema = XML::Compile::Cache->new($self->schemas);
    $schema->template('PERL', $self->root , show => 'ALL');
}

sub parse {
    my ($self,$input) = @_;
    $self->_reader->($input);
}

sub to_xml {
    my ($self,$data) = @_;
    my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml    = $self->_writer->($doc, $data);
    $doc->setDocumentElement($xml);
    $doc->toString(1);
}

1;

__END__

=encoding utf8

=head1 NAME

Catmandu::XSD - Modules for handling XML data with XSD compilation

=head1 SYNOPSIS

    ## Converting XML to YAML/JSON/CSV/etc

    # Compile an XSD schema file and parse one shiporder.xml file
    catmandu convert XSD --root '{}shiporder'
                         --schemas demo/order/*.xsd
                         to YAML < shiporder.xml

    # Same as above but parse more than one file into an array of records
    catmandu convert XSD --root '{}shiporder'
                         --schemas demo/order/*.xsd
                         --files 'data/*.xml'
                         to YAML

    # Same as above but all array of records are in a XML container file
    catmandu convert XSD --root '{}shiporder'
                         --schemas demo/order/*.xsd
                         --xpath '/Container/List//Record/Payload/*'
                         to YAML < data/container.xml

    ## Convert an YAML/JSON/CSV into XML validated against an XSD schemas

    # Convert one shiporder YAML to XML
    catmandu convert YAML to XSD --root '{}shiporder'
                                 --schemas demo/order/*.xsd < shiporder.YAML

    # Same as above but store multiple shiporders in the YAML into a separate file
    catmandu convert YAML to XSD --root '{}shiporder'
                                 --schemas demo/order/*.xsd
                                 --split 1
                                 < shiporder.YAML

    # Same as above but use template toolkit to pack the XML into an container
    # (The xml record is stored in the 'xml' key which can be retrieved in the
    # template by [% xml %])
    catmandu convert YAML to XSD --root '{}shiporder'
                                 --schemas demo/order/*.xsd
                                 --template_before t/xml_header.tt
                                 --template t/xml_record.tt
                                 --template t/xml_footer.tt
                                 < shiporder.YAML

     ## Example documents

     # Show an example how a valid XML document needs to be structured for an
     # XSD scheme.
     catmandu convert XSD --root {}shiporder
                          --schemas "t/demo/order/*xsd"
                          --example 1 to YAML

=head1 DESCRIPTION

L<Catmandu::XSD> contains modules for handling XML data within the L<Catmandu>
framework. Parsing and serializing is based on L<XML::Compile>.

There are two modules available for handling XML data in the Catmandu framework:
L<Catmandu::XML> and L<Catmandu::XSD>. The former one can be used when no XML schema
is available for the data. It provides a simple interface to read in XML data and
transform it to other formats. Because L<Catmandu::XML> doesn't depend on an
XSD schema, it can't know which fields in the input XML files are sequences or
single value elements. Each record is parsed on its own. A record with content:

    <foo>
      <bar>test</bar>
    </foo>

will be parsed into a YAML output like:

    catmandu XML to YAML < test.xml
    --
    bar: test

A record with content:

    <foo>
      <bar>test</bar>
      <bar>test</bar>
    </foo>

will be parsed into a YAL output like:

    catmandu XML to YAML < test2.xml
    --
    bar:
      - test
      - test

In the first case 'bar' will contain a string, in the second case an array. This
might no be what you want in some programming projects. E.g. when you need the 'bar'
field to be always an array of values, then you an XSD schema file is required
containing the exact structure of the XML document:

    test.xsd:
    <?xml version="1.0" encoding="UTF-8" ?>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="foo">
         <xs:complexType>
          <xs:sequence>
            <xs:element name="bar" type="xs:string" maxOccurs="unbounded"/>
          </xs:sequence>
         </xs:complexType>
        </xs:element>
    </xs:schema>

And now the test.xml and test2.xml can be parsed with help of Catmandu::XSD:

    catmandu XSD --root '{}foo' --schemas test.xsd to YAML < test.xml
    --
    bar:
      - test

    catmandu XSD --root '{}foo' --schemas test.xsd to YAML < test2.xml
    --
    bar:
      - test
      - test

=head1 WILDCARDS

Some XSD Schema allow for C<any> or C<anyAttribute> specifications in the schema.
The L<Catmandu::XSD> modules can't guess in these cases what the schema implementation
is. These nodes will be parsed as L<XML::LibXML::Node>s in the
resulting documents. Catmandu output formats such as L<Catmandu::Exporter::JSON>
can't handle these XML::LibXML::Node nodes. You have to implement yourself a
L<Catmandu::Fix> to translate these values in to plain string, array or hash elements.

But in general a round trip should be problematic:

    catmandu XSD --root ... --schema wildcard.xsd to XSD  --root ... --schema wildcard.xsd < data.xml

=head1 MIXED ELEMENTS

ComplexType and ComplexContent in the XSD schema can be declared with the C<<mixed="true">> attribute.
This means that in the XML documents simple text and XML elements can be mixed as in:

      Hello, I'm <name>John</name> how can I <bold>help</bold> you?

In these cases it is not know if the elements are required as an hash or should be ignored. By
defaults L<Catmandu::XSD> will parse these elements as L<XML::LibXML::Node>s documents.
This behavious can be changed by setting the 'mixed' flag:

    # All mixed elements will be XML::LibXML::Node-s
    catmandu XSD --root ... --schema mixed.xsd  < data.xml

    # The mixed elements will be ignored, only the text will survive
    #
    #  Hello, I'm <name>John</name> how can I <bold>help</bold> you?
    #
    #  =>  Hello, I'm John how can I help you?
    catmandu XSD --root ... --schema mixed.xsd --mixed TEXTUAL < data.xml

    # The mixed text will be ignored, only the elements will survive
    #
    #  Hello, I'm <name>John</name> how can I <bold>help</bold> you?
    #
    #  =>  { name => 'John' , bold => 'help' }
    catmandu XSD --root ... --schema mixed.xsd --mixed STRUCTURAL < data.xml

    # The mixed elements will be a plain XML fragment string
    #
    #  Hello, I'm <name>John</name> how can I <bold>help</bold> you?
    #
    #  =>  $r = 'Hello, I'm <name>John</name> how can I <bold>help</bold> you?'
    catmandu XSD --root ... --schema mixed.xsd --mixed XML_STRING < data.xml

=head1 MODULES

=over

=item L<Catmandu::Importer::XSD>

Parse and validate XML data using an XSD file for structural data

=item L<Catmandu::Exporter::XSD>

Serialize and validate XML data using an XSD file for structural data

=back

=head1 BUGS, QUESTIONS, HELP

Use the github issue tracker for any bug reports or questions on this module:
https://github.com/LibreCat/Catmandu-XSD/issues

=head1 DISCLAIMER

This module is based on L<XML::Compile> and the L<Catmandu> framework.

L<XML::Compile> is the workhorse that forms the core of this module to
compile XSD file into parser and serializers.

L<Catmandu> is used to transform parsed XML into any format you like.
Catmandu contains a simple DSL languages called L<Catmandu::Fix> to create
small scripts to manipulate data. The L<Catmandu> toolkit is used by many
university libraries to process metadata collections.

For more information on Catmandu visit: http://librecat.org/Catmandu/
or follow the blog posts at: https://librecatproject.wordpress.com/

=head1 AUTHOR

Patrick Hochstenbach , C<< patrick.hochstenbach at ugent.be >>

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<XML::Compile> , L<Catmandu> , L<Template> , L<Catmandu::XML>

=cut
