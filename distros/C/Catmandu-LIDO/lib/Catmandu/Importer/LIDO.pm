package Catmandu::Importer::LIDO;

use Catmandu::Sane;
use Lido::XML;
use XML::LibXML::Reader;

our $VERSION = '0.09';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has 'lido'      => (is => 'lazy');

sub _build_lido {
    return Lido::XML->new;
}

sub generator {
    my ($self) = @_;
    my $file = $self->file;
    my %opts;

    if (ref($file)) {
        %opts = ('IO' , $file);
    }
    else {
        %opts = ('location' , $file);
    }

    sub {
        state $reader = XML::LibXML::Reader->new(%opts);

        my $match = $reader->nextPatternMatch(
            XML::LibXML::Pattern->new(
                '//lido:lido', { lido => 'http://www.lido-schema.org' }
            )
        );

        return undef unless $match == 1;

        my $xml = $reader->readOuterXml();

        return undef unless length $xml;

        $reader->nextSibling();

        return $self->lido->parse($xml);
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::LIDO - A LIDO XML importer

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert LIDO to YAML < ex/lido.xml

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('LIDO',file => 'ex/lido.xml');

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This is a L<Catmandu::Importer> for converting LIDO data (an XML Schema for
Contributing Content to Cultural Heritage Repositories).

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item size

Number of items. If not set, an endless stream is imported.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Importer>, L<Lido::XML>

=cut
