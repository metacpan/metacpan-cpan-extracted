#$Id: HasAnyFeeds.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::HasAnyFeeds;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);
use Feed::Find;

__PACKAGE__->name('Syndicate with RSS or Atom feeds?');

sub validate {
    my ($self, $res) = @_;
    my $html = $res->content;
    my @feeds = Feed::Find->find_in_html(\$html, $res->base);
    $self->is_ok(scalar @feeds);
}

1;
