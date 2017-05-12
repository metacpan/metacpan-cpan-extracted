#$Id: UseLighttpd.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::UseLighttpd;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Served by lighttpd?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok(
        $res->headers->header('Server') &&
        $res->headers->header('Server') =~ m!lighttpd!
    );
}

1;
