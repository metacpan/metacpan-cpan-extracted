#$Id: ReferToDelicious.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::ReferToDelicious;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Refers to del.icio.us?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok($res->content =~ m/del\.icio\.us/);
}

1;
