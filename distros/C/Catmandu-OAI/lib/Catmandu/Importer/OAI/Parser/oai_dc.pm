package Catmandu::Importer::OAI::Parser::oai_dc;

use Catmandu::Sane;
use Moo;

our $VERSION = '0.17';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $rec = {};

    for ($dom->findnodes("./*")) {
        my $name  = $_->localName;
        my $value = $_->textContent;
        push(@{$rec->{$name}}, $value);
    }

    $rec;
}

1;