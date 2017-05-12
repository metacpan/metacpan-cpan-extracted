package Catmandu::Importer::XSD;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use XML::LibXML::Reader;
use Catmandu::XSD;
use feature 'state';

our $VERSION = '0.04';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has 'root'        => (is => 'ro' , required => 1);
has 'schemas'     => (is => 'ro' , required => 1);
has 'mixed'       => (is => 'ro' , default => sub { 'ATTRIBUTES' });
has 'any_element' => (is => 'ro' , default => sub { 'TAKE_ALL' });
has 'prefixes'    => (is => 'ro' , default => sub { [] });
has 'files'       => (is => 'ro');
has 'xpath'       => (is => 'ro' , default => sub { '*' });
has 'example'     => (is => 'ro');

has 'xsd'      => (is => 'lazy');

sub _build_xsd {
    my $self = $_[0];
    return Catmandu::XSD->new(
        root        => $self->root ,
        schemas     => $self->schemas ,
        mixed       => $self->mixed ,
        any_element => $self->any_element ,
        prefixes    => $self->prefixes ,
    );
}

sub generator {
    my $self = $_[0];

    if ($self->example) {
        $self->example_generator
    }
    elsif ($self->files) {
        $self->multi_file_generator
    }
    else {
        $self->single_file_generator
    }
}

sub example_generator {
    my $self = $_[0];

    my $count = 0;

    sub {
        $count++ ? undef : $self->xsd->template;
    };
}

sub multi_file_generator {
    my $self = $_[0];

    my @files = glob($self->files);

    sub {
        my $file = shift @files;

        return undef unless $file;
        my $xml = XML::LibXML->load_xml(location => $file);
        $self->xsd->parse($xml);
    };
}

sub single_file_generator {
    my $self = $_[0];

    my $prefixes = {};

    if ($self->prefixes) {
        if (is_array_ref $self->prefixes) {
            for (@{$self->prefixes}) {
                my ($key,$val) = each %$_;
                $prefixes->{$key} = $val;
            }
        }
        else {
            for (split(/,/,$self->prefixes)) {
                my ($key,$val) = split(/:/,$_,2);
                $prefixes->{$key} = $val;
            }
        }
    }

    # Drop all PerlIO layers possibly created by a use open pragma
    # requirement for XML::LibXML parsing
    # See: https://metacpan.org/pod/distribution/XML-LibXML/LibXML.pod
    binmode $self->fh;

    sub {
        state $reader = XML::LibXML::Reader->new(IO => $self->fh);

        my $match = $reader->nextPatternMatch(
            XML::LibXML::Pattern->new($self->xpath , $prefixes)
        );

        return undef unless $match == 1;

        my $xml = $reader->readOuterXml();

        return undef unless length $xml;

        $reader->nextSibling();

        my $data = $self->xsd->parse($xml);

        return $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::XSD - Import and validate serialized XML documents

=head1 SYNOPSIS

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

    # In Perl
    use Catmandu;

    my $importer = Catmandu->importer('XSD',
                file => 'ex/data.xml'
                root => ...,
                schemas => [ ...]
    );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This is a L<Catmandu::Importer> for parsing and validating XML data using one or
more XSD schema files.

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item files

Optional. Don't read the content from the standard input but use the 'files' parameter
as a glob for one or more filenames. E.g.

    catmandu ... --files 'data/input/*.xml'

=item examples

Optional. Don't do anything only show an example output how a document should be
structured in the given XSD scheme. E.g.

    catmandu convert XSD --root {}shiporder --schemas "t/demo/ead/*xsd" --example 1 to YAML

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item root

Required. The name (and namespace) of the root element of the XML document. E.g.:

    {}shiporder
    {http://www.loc.gov/mods/v3}mods
    {urn:isbn:1-931666-22-9}ead

=item schemas

Required. An array or comma separated list of XSD schema locations.

=item xpath

Optional. An XPath expression, the XML container in which the PNX record can
be found. Default : /oai:OAI-PMH/oai:ListRecords//oai:record/oai:metadata/*

=item prefixes

Optional. An array or comma delimited string of namespace prefixes to be used
hand handling XML files. E.g.

    # On the command line:
    catmandu ... --prefixes ead:urn:isbn:1-931666-22-9,...

    # In Perl
    prefixes => [
        ead => 'urn:isbn:1-931666-22-9' ,
        ... => ...
    ]

=item mixed

Optional. The handling of mixed element content. One of ATTRIBUTES (default),
TEXTUAL, STRUCTURAL, XML_NODE, XML_STRING, CODE reference. See also
L<Catmandu::XSD> and L<XML::Compile::Translate::Reader>

=item any_element

Optional. The handling of C<<any>> content in schemas. One of TAKE_ALL (default:
process as XML::LibXML::Node) , SKIP_ALL (ignore these) , XML_STRING (process as string)
, CODE (provide a reference to parse the data). See L<XML::Compile::Translate::Reader>

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Importer>, L<Catmandu::XSD>

=cut
