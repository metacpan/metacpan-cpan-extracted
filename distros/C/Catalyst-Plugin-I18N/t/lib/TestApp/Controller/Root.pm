package TestApp::Controller::Root;
use warnings;
use strict;

use base 'Catalyst::Controller';

__PACKAGE__->config( namespace => q{} );

sub maketext : Global {
    my( $self, $c, $key ) = @_;
    $c->res->body( $c->localize( $key ) );
}

sub current_language : Global {
    my( $self, $c ) = @_;
    $c->res->body( $c->language );
}

sub current_language_tag : Global {
    my( $self, $c ) = @_;
    $c->res->body( $c->language_tag );
}

sub current_languages_list : Global {
    my( $self, $c ) = @_;
    my $h = $c->installed_languages;
    my $output = join(", ", map { "$_=".$h->{$_} } (sort keys %$h) );
    $c->res->body( $output );
}

1;
