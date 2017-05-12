#$Id: MentionsWeb20.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::MentionsWeb20;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Actually mentions Web 2.0?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok($res->content =~ m!web\s*2.0!i);
}

1;
