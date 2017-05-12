#$Id: UseRails.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::UseRails;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Appears to be built using Ruby on Rails?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok($res->content =~ m/ruby on rails/i);
}

1;
