#$Id: HasTrackbackURI.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::HasTrackbackURI;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Has auto-discoverable Trackback URI?');

sub validate {
    my ($self, $res) = @_;
    while ($res->content =~ m!(<rdf:RDF.*?</rdf:RDF>)!sg) {
        my $rdf = $1;
        my $ping_url;
        if ($rdf =~ m!trackback:ping="(.+?)"!) {
            $ping_url = $1;
        } elsif ($rdf =~ m!about="(.+?)"!) {
            $ping_url = $1;
        }
        return $self->is_ok(1) if $ping_url;
    }
}

1;
