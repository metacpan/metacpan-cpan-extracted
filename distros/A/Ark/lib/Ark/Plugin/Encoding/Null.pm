package Ark::Plugin::Encoding::Null;
use strict;
use warnings;
use Ark::Plugin;

sub prepare_encoding {
    my $c   = shift;
    my $req = $c->request;
    $req->env->{'plack.request.withencoding.encoding'} = undef;
}

sub finalize_encoding { };

1;

