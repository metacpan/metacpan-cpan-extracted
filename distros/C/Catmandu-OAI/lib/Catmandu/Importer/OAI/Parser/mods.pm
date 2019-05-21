package Catmandu::Importer::OAI::Parser::mods;

use Catmandu::Sane;
use Moo;
use MODS::Record;
use Catmandu::Util;
use JSON;

our $VERSION = '0.19';

with 'Catmandu::Logger';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $xml  = $dom->toString;
    my $perl = { error => 1 };

    eval {
        my $mods = MODS::Record->from_xml($xml);
        $perl = JSON::decode_json($mods->as_json);
    };
    if ($@) {
        $self->log->error($@);
        $self->log->error("Failed to parse: $xml");
    }

    { _metadata => $perl };
}

1;
