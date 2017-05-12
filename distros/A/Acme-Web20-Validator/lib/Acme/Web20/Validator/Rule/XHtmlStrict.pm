#$Id: XHtmlStrict.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule::XHtmlStrict;
use strict;
use warnings;
use base qw (Acme::Web20::Validator::Rule);

__PACKAGE__->name('Attempts to be XHTML Strict?');

sub validate {
    my ($self, $res) = @_;
    $self->is_ok($res->content =~ m|<!DOCTYPE.*?-//W3C//DTD XHTML 1\.0 Strict//EN.*?>|i);
}

1;
