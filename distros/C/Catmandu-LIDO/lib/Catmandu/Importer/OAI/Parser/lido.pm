package Catmandu::Importer::OAI::Parser::lido;

use Catmandu::Sane;
use Moo;
use Catmandu;
use Catmandu::Util;
use Lido::XML;
use JSON;

with 'Catmandu::Logger';

has 'lido'      => (is => 'lazy');

sub _build_lido {
    return Lido::XML->new;
}

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $xml  = $dom->toString;
    my $perl = { error => 1 };

    eval {
        $perl = $self->lido->parse($xml);
    };
    if ($@) {
        $perl = { error => $@ };
        $self->log->error($@);
        $self->log->error("Failed to parse: $xml");
    }

    { _metadata => $perl };
}

1;

__END__

=encoding utf8

=head1 NAME

Catmandu::Importer::OAI::Parser::lido - A Lido XML OAI-PMH handler

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert OAI \
    --url http://collections.britishart.yale.edu/oaicatmuseum/OAIHandler \
    --metadataPrefix lido \
    --handler lido to YAML \


=head1 SEE ALSO

L<Catmandu::OAI>

=cut
