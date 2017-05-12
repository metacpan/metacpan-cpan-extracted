package Catmandu::Importer::OAI::Parser::raw;

use Catmandu::Sane;
use Moo;

our $VERSION = '0.17';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    { _metadata => $dom->toString };
}

1;
