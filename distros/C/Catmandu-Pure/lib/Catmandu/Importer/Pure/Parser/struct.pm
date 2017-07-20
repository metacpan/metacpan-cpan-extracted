package Catmandu::Importer::Pure::Parser::struct;

use Catmandu::Sane;
use Moo;
use XML::Struct qw(readXML);

our $VERSION = '0.02';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;
    readXML($dom);
}

1;
