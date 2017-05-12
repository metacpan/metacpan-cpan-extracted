#$Id: UseFeedBurner.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::UseFeedBurner;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);
use Feed::Find;

__PACKAGE__->name('Burning the feed by FeedBurner?');

sub validate {
    my ($self, $res) = @_;
    my $html = $res->content;
    my @feeds = Feed::Find->find_in_html(\$html, $res->base) or return;
    for (@feeds) {
        $self->is_ok(1) if m!^http://feeds\.feedburner\.com/!;
    }
}

1;
