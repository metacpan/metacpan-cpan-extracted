package TestApp::Controller::Cache;

use strict;
use base 'Catalyst::Controller';

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->config->{counter}++;

    return 1;
}

sub count : Local {
    my ( $self, $c, $expires ) = @_;

    $c->cache_page( $expires );

    $c->res->output( $c->config->{counter} );
}

sub auto_count : Local {
    my ( $self, $c ) = @_;

    $c->res->output( $c->config->{counter} );
}

sub set_count : Local {
    my ( $self, $c, $newvalue ) = @_;

    $c->config->{counter} = $newvalue || 0;

    $c->res->output( $c->config->{counter} );
}

sub another_auto_count : Local {
    my ( $self, $c ) = @_;

    $c->forward( 'auto_count' );
}

sub cache_extension_header : Local {
    my ( $self, $c, $expires ) = @_;
    $c->cache_page( $expires );
    $c->res->headers->header('X-Bogus-Extension' => 'True');
    $c->res->output( 'ok' );
}

sub clear_cache : Local {
    my ( $self, $c ) = @_;

    my $removed = $c->clear_cached_page( '/cache/count' );

    $c->res->output( $removed );
}

sub clear_cache_regex : Local {
    my ( $self, $c ) = @_;

    my $removed = $c->clear_cached_page( '/cache/.*' );

    $c->res->output( $removed );
}

sub test_datetime : Local {
    my ( $self, $c ) = @_;

    require DateTime;

    my $dt = DateTime->new( day => 24, month => 1, year => 2026, time_zone => 'UTC' );

    $c->cache_page( $dt );

    $c->res->output( $c->config->{counter} );
}

sub extra_options : Local {
    my ( $self, $c ) = @_;

    $c->cache_page(
        last_modified   => time,
        expires         => 60,
        cache_seconds   => 20,
    );

    $c->res->output( $c->config->{counter} );
}

sub no_cache : Local {
    my ( $self, $c ) = @_;

    $c->cache_page(
        last_modified   => time,
        expires         => 0,
        cache_seconds   => 20,
    );

    $c->res->output( $c->config->{counter} );
}

sub busy : Local {
    my ( $self, $c ) = @_;

    $c->cache_page( 1 );

    sleep 2;

    $c->res->output( $c->config->{counter} );
}

sub get_key : Local {
    my ( $self, $c ) = @_;

    $c->cache_page( 1 );

    $c->res->output( $c->_get_page_cache_key );
}

1;
