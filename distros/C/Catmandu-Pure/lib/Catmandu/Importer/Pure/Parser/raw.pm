package Catmandu::Importer::Pure::Parser::raw;

use Catmandu::Sane;
use Moo;

our $VERSION = '0.03';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;
    $dom->toString;
}

1;
