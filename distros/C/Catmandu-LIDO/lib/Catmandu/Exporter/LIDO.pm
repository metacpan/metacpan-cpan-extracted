package Catmandu::Exporter::LIDO;

use Catmandu::Sane;

our $VERSION = '0.10';

use Moo;
use Encode;
use Lido::XML;

with 'Catmandu::Exporter';

has 'lido'      => (is => 'lazy');

sub _build_lido {
    return Lido::XML->new;
}

sub add {
    my ($self, $data) = @_;

    my $xml = $self->lido->to_xml($data);
    #$self->fh->print($xml);
    $self->fh->print(decode('UTF-8', $xml, Encode::FB_CROAK));
}

sub commit {
    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::LIDO - a LIDO exporter

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON --fix myfixes to LIDO < /tmp/data.json

    # From Perl

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('LIDO');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

    # Get an array ref of all records exported
    my $data = $exporter->as_arrayref;

=head1 DESCRIPTION

This is a L<Catmandu::Exporter> for converting Perl into LIDO XML (an XML Schema for
Contributing Content to Cultural Heritage Repositories).

=head1 SEE ALSO

L<Catmandu::Importer::LIDO>, L<Lido::XML>

=cut
