package Catmandu::Importer::XML;

our $VERSION = '0.16';

use namespace::clean;
use Catmandu::Sane;
use Moo;
use XML::Struct::Reader;
use Catmandu::XML::Transformer;

with 'Catmandu::Importer';

has type       => (is => 'ro', default => sub { 'simple' });
has path       => (is => 'ro');
has root       => (is => 'lazy', default => sub { defined $_[0]->path ? 1 : 0 });
has depth      => (is => 'ro');
has ns         => (is => 'ro', default => sub { '' });
has attributes => (is => 'ro', default => sub { 1 });
has whitespace => (is => 'ro', default => sub { 0 });
has xslt       => (
    is => 'ro', 
    lazy => 1,
    coerce => sub {
        Catmandu::XML::Transformer->new( stylesheet => $_[0] ) if defined $_[0]
    },
    builder => sub {
        $_[0]->transform
    } 
);
has transform => (
    is => 'ro',
    coerce => sub {
        warn "Catmandu::Importer::XML option 'transform' renamed to 'xslt'\n";
        $_[0];
    }
);

sub generator {
    my ($self) = @_;
    sub {
        state $reader = do { 
            my %options = (
                from       => ($self->file || $self->fh),
                whitespace => $self->whitespace,
                attributes => $self->attributes,
                depth      => $self->depth,
                ns         => $self->ns,
            );
            $options{path} = $self->path if defined $self->path;
            if ($self->type eq 'simple') {
                $options{simple} = 1;
                $options{root} = $self->root;
            } elsif ($self->type ne 'ordered') {
                return;
            }
            XML::Struct::Reader->new(%options);
        };
    
        my $item = $reader->readNext;

        # TODO: transformation should be done earlier for efficiency
        # and because simple format modifies the XML document (bug)
        return $self->xslt ?
               $self->xslt->transform($item) : $item
    }
}

1;
__END__

=head1 NAME

Catmandu::Importer::XML - Import serialized XML documents

=head1 DESCRIPTION

This L<Catmandu::Importer> reads XML and transforms it into a data structure. 

See L<Catmandu::Importer>, L<Catmandu::Iterable>, L<Catmandu::Logger> and
L<Catmandu::Fixable> for methods and options derived from these modules.

The importer can also be used internally for custom importers that need to
parse XML data.

=head1 CONFIGURATION

=over

=item type

By default (type "C<simple>"), elements and attributes and converted to keys in
a key-value structure. For instance this document: 

    <doc attr="value">
      <field1>foo</field1>
      <field1>bar</field1>
      <bar>
        <doz>baz</doz>
      </bar>
    </doc>
     
is imported as

    {
        attr => 'value',
        field1 => [ 'foo', 'bar' ],
        field2 => { 'doz' => 'baz' },
    }

With type "C<ordered>" elements are preserved in the order of their appereance.
For instance the sample document above is imported as:

    [ 
        doc => { attr => "value" }, [
            [ field1 => { }, ["foo"] ],
            [ field1 => { },  ["bar"] ],
            [ field2 => { }, [ [ doz => { }, ["baz"] ] ] ]
        ]
    ] 

=item depth

Maximum depth for type "C<simple>". For instance with depth 1, the sample document above
would be imported as:

    {
        attr => 'value',
        field1 => [ 'foo', 'bar' ],
        field2 => { 
            doz => [ [ doz => { }, ["baz"] ] ]
        }
    }

=item attributes

Include XML attributes. Enabled by default.

=item path

Path expression to select XML elements. If not set the root element is
selected.

=item root

Include root element name for type C<simple>. Disabled by default.  The option
is ignored if type is not C<simple> or if a C<path> has explicitly been set.

=item ns

Set to C<strip> for stripping namespace prefixes and xmlns-attributes.

=item whitespace

Include ignoreable whitespace. Disabled by default.

=item xslt

Optional (list of) XSLT stylesheets to process records with
L<Catmandu::XML::Transformer>.

=item transform

Deprecated alias for option C<xslt>.

=back

=head1 SEE ALSO

This module is just a thin layer on top of L<XML::Struct::Reader>. Have a look
at L<XML::Struct> to implement Importers and Exporters for more specific
XML-based data formats.

=cut

=encoding utf8
