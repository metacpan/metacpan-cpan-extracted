package TestApp;

use strict;
use Catalyst qw/Pluggable/;

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir' );

TestApp->setup;

sub runtest : Global {
    my( $self, $c ) = @_;
    $c->forward_all( 'test' );
}

sub runtest_args : Global {
    my( $self, $c ) = @_;
    $c->forward_all( 'test', [ 'X' ] );
}

sub runtest_reverse : Global {
    my( $self, $c ) = @_;
    $c->forward_all( 'test', '$b->{class} cmp $a->{class}' );
}

1;
