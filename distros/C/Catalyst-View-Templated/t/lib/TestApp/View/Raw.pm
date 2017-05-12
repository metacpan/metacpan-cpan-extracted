package TestApp::View::Raw;
use strict;
use warnings;
use base 'Catalyst::View::Templated';

sub _render {
    my ($self, $template, $stash) = @_;
    return join ':', map { "$_=>". $stash->{$_} } keys %$stash;
}

1;
