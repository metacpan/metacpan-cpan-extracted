package Catmandu::Importer::OAI::Parser::struct;

use Catmandu::Sane;
use Moo;
use XML::Struct qw(readXML);

our $VERSION = '0.20';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    { _metadata => readXML($dom) };
}

1;
