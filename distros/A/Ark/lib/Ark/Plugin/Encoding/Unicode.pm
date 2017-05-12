package Ark::Plugin::Encoding::Unicode;
use strict;
use warnings;
use Ark::Plugin;
use Encode;

sub prepare_encoding { }

sub finalize_encoding {
    my $self = shift;

    my $res = $self->response;
    $res->body(encode_utf8 $res->body ) if !$res->binary and $res->has_body;
};

1;
