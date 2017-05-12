#$Id: UseCatalyst.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::UseCatalyst;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Appears to be built using Catalyst?');

sub validate {
    my ($self, $res) = @_;
    my $bool = 0;
    $bool = 1 if ($res->headers->header('X-Catalyst'));
    $self->is_ok($bool);
}

1;
