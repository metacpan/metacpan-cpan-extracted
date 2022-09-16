package Catmandu::XML::Transformer;

our $VERSION = '0.17';

use Catmandu::Sane;
use Moo;
use Carp;
use XML::LibXML;
use XML::LibXSLT;
use Scalar::Util qw(blessed reftype);
use XML::Struct::Reader;
use XML::Struct::Writer;

has stylesheet => (
    is      => 'ro',
    coerce  => sub {
        ref $_[0] // '' eq 'ARRAY' ? $_[0] : [ split /,/, $_[0] ]
    },
    default => sub { [] }
);

has output_format => (
    is     => 'ro', 
    coerce => sub { defined $_[0] ? lc $_[0] : undef }
);

has process => (
    is      => 'lazy',
    builder => sub {
        [
            map {
                XML::LibXSLT->new()->parse_stylesheet(
                    XML::LibXML->load_xml(location => $_, no_cdata=>1)
                )
            } @{$_[0]->stylesheet} 
        ]
    }
);

sub BUILD {
    if (@{$_[0]->process} and $_[0]->process->[-1]->output_method eq 'text') {
        $_[0]->{output_format} = 'string'; 
    }
}

sub transform {
    my ($self, $xml) = @_;
    my ($format, $result);

    return if !defined $xml;

    if (blessed $xml) {
        if ($xml->isa('XML::LibXML::Document') or $xml->isa('XML::LibXML::Element')) {
            $format = 'dom';
        } else {
            croak "Cannot convert ".ref($xml)." to XML";
        }
    } elsif (ref $xml) {
        if (reftype $xml eq 'ARRAY') {
            $format = 'struct';
            $xml = XML::Struct::Writer->new->write($xml);
        } else {
            $format = 'simple';
            $xml = XML::Struct::Writer->new(simple => 1)->write($xml);
        }
    } else {
        $format = 'string';
        $xml = XML::LibXML->load_xml(string => $xml);
    }

    $format = $self->output_format if $self->output_format;

    if (@{$self->process}) {
        foreach (@{$self->process}) {
            $xml = $_->transform($xml);
        }
    }

    if ($format eq 'string') {
        if ($self->process->[-1]) {
            return $self->process->[-1]->output_as_chars($xml);
        } else {
            return $xml->toString;
        }
    } elsif ($format eq 'struct') {
        return XML::Struct::Reader->new( from => $xml )->readDocument;
    } elsif ($format eq 'simple') {
        my $reader = XML::Struct::Reader->new( from => $xml, simple => 1, root => 1 );
        return $reader->readDocument;
    } else {
        return $xml;
    }
}

1;
__END__

=head1 NAME

Catmandu::XML::Transformer - Utility module for XML/XSLT processing

=cut

=head1 SYNOPISIS

    $transformer = Catamandu::XML::Transformer->new( stylesheet => 'file.xsl' );

    $xml_string = $transformer->transform( $xml_string ); # SCALAR
    $xml_dom    = $transformer->transform( $xml_dom );    # XML::LibXML::Document
    $xml_struct = $transformer->transform( $xml_struct ); # ARRAY reference
    $xml_simple = $transformer->transform( $xml_simple ); # HASH reference

    $transformer = Catamandu::XML::Transformer->new( output_format => 'string' );
    $xml_string  = $transformer->transform( $xml );       # any XML to SCALAR

=head1 CONFIGURATION

=over

=item stylesheet

Zero or more XSLT files given as comma-separated list of files or array
reference with multiple files to apply as transformation pipeline. Files are
parsed once on instantiation of the Catmandu::XML::Transformer object.

=item output_format

Expected output format C<dom>, C<string>, C<struct>, C<simple>. By default the
input format triggers the output format. If the last stylesheet has text output
(C<< <xsl:output method="text"/> >>) then output format is automatically set to
C<string>.

=back

=head1 METHODS

=over

=item stylesheet()

Returns an array reference of XSLT filenames used as transformation pipeline.

=item output_format()

Returns the output format or C<undef>.

=back

=head1 SEE ALSO

L<XML::Struct>

=cut
