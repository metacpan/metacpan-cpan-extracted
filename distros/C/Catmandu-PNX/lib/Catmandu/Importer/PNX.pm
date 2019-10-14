package Catmandu::Importer::PNX;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use XML::LibXML::Reader;
use Catmandu::PNX;
use feature 'state';

our $VERSION = '0.04';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has 'xpath'    => (is => 'ro' , default => sub { '/oai:OAI-PMH/oai:ListRecords//oai:record/oai:metadata/*' });
has 'pnx'      => (is => 'lazy');

sub _build_pnx {
    return Catmandu::PNX->new;
}

sub generator {
    my ($self) = @_;
    $self->{encoding} = ':raw';
    sub {
        state $reader = XML::LibXML::Reader->new(IO => $self->fh);

        my $match = $reader->nextPatternMatch(
            XML::LibXML::Pattern->new(
                 $self->xpath ,
                 { oai => 'http://www.openarchives.org/OAI/2.0/' }
            )
        );

        return undef unless $match == 1;

        my $xml = $reader->readOuterXml();

        $xml =~ s{xmlns="[^"]+"}{};

        return undef unless length $xml;

        $reader->nextSibling();

        my $data = $self->pnx->parse($xml);

        if (exists $data->{control} && exists $data->{control}->{sourcerecordid}) {
            $data->{_id} = $data->{control}->{sourcerecordid};
        }

        return $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::PNX - A Primo normalized XML (PNX) importer

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert PNX to YAML < ex/lido.xml

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('PNX',file => 'ex/pnx.xml');

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This is a L<Catmandu::Importer> for converting PNX data (an XML Schema for
Ex Libris' Primo search engine).

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

=item xpath

Optional. An XPath expression, the XML container in which the PNX record can
be found. Default : /oai:OAI-PMH/oai:ListRecords//oai:record/oai:metadata/*

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Importer>, L<Catmandu::PNX>

=cut
