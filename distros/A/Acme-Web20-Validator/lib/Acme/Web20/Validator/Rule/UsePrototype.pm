#$Id: UsePrototype.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::UsePrototype;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Has prototype.js?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok($res->content =~ m/prototype\.js/);
}

1;
