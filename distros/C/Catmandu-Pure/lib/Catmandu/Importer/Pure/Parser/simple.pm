package Catmandu::Importer::Pure::Parser::simple;

use strict;
use XML::LibXML::Simple ();
use Moo;

our $VERSION = '0.02';

has xmlsimple => ( is => 'ro', default => sub { XML::LibXML::Simple->new } );

sub parse {
    my ($self, $dom) = @_;

    $self->xmlsimple->XMLin(
        $dom , KeepRoot => 1, ForceArray => 1, NsStrip => 1, KeyAttr => []);
}

1;
