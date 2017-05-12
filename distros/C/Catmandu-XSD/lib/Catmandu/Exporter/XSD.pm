package Catmandu::Exporter::XSD;

use Catmandu::Sane;

our $VERSION = '0.04';

use Moo;
use Catmandu;
use Catmandu::XSD;

with 'Catmandu::Exporter';

has 'root'     => (is => 'ro' , required => 1);
has 'schemas'  => (is => 'ro' , required => 1);
has 'mixed'    => (is => 'ro' , default => sub { 'ATTRIBUTES' });
has 'prefixes' => (is => 'ro');

has 'split'           => (is => 'ro');
has 'split_pattern'   => (is => 'ro' , default => sub { '%s.xml' } );
has 'split_directory' => (is => 'ro' , default => sub { '.' });

has 'template_before' => (is => 'ro');
has 'template'        => (is => 'ro');
has 'template_after'  => (is => 'ro');

has 'tt'       => (is => 'lazy');
has 'xsd'      => (is => 'lazy');

sub BUILD {
    my ($self,$args) = @_;

    die "split and template can't be set at the same time"
        if (exists $args->{split} && exists $args->{template});
}

sub _build_xsd {
    my $self = $_[0];
    return Catmandu::XSD->new(
        root     => $self->root ,
        schemas  => $self->schemas ,
        mixed    => $self->mixed ,
        prefixes => $self->prefixes ,
    );
}

sub _build_tt {
    my $self = $_[0];

    if ($self->template) {
        Catmandu->exporter(
            'Template',
            fh              => $self->fh ,
            template_before => $self->template_before ,
            template        => $self->template ,
            template_after  => $self->template_after ,
        );
    }
}

sub add {
    my ($self, $data) = @_;

    my $xml = $self->xsd->to_xml($data);

    if ($self->template) {
        $xml =~ s{<\?xml version="1.0" encoding="UTF-8"\?>}{};
        $data->{xml} = $xml;
        $self->tt->add($data);
    }
    elsif ($self->split) {
        my $id = $data->{_id} // $self->count;
        my $directory = $self->split_directory;
        my $filename  = sprintf $self->split_pattern , $id;
        local(*F);
        open(F,'>:encoding(utf-8)',"$directory/$filename")
            || die "failed to open $directory/$filename for writing : $!";
        print F $xml;
        close(F);
    }
    else {
        $self->fh->print($xml);
    }
}

sub commit {
    my $self = $_[0];

    if ($self->template && $self->count) {
        $self->tt->commit;
    }

    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::XSD - Export and validate XML documents

=head1 SYNOPSIS

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

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('XSD',
                        root => ...
                        schemas => ...
    );

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });
    $exporter->add($hashref);

    $exporter->commit;

=head1 DESCRIPTION

This is a L<Catmandu::Exporter> for converting Perl into valided XML documents
using an XSD schema file.

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path. Alternatively a scalar
reference can be passed to write to a string.

=item fh

Write output to an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the output stream from the C<file> argument or by using STDOUT.

=item split

Optional. Don't write to the file (or STDOUT) and split the output documents into
one or more files. E.g.

    catmandu ... to XSD --root ... --schemas ... --split 1  < data

=item split_pattern

Optional. Use a FORMAT as template for naming output files. Uses the '_id' field in
the data or an incremental counter as input. E.g.

    # Creates 000001.xml , 000002.xml, etc
    catmandu ... to XSD --root ... --schemas ... --split 1 --split_pattern '%-6.6d.xml' < data

=item split_directory

Optional. Specify the directory in which the split files need to be written.

=item template

Optional. A template toolkit template to be used for creating each XML output record. Gets as input
the input data plus the XML serialized form in the 'xml' field.

=item template_before

Optional. The template toolkit template to be used as XML header.

=item template_after

Optional. The template toolkit template to be used as XML footer.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item root

Required. The name (and namespace) of the root element of the XML document. E.g.:

    {}shiporder
    {http://www.loc.gov/mods/v3}mods
    {urn:isbn:1-931666-22-9}ead

=item schemas

Required. An array or comma separated list of XSD schema locations.

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

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Exporter>, L<Catmandu::XSD> , L<Template>

=cut
