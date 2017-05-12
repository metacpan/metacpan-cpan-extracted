package TestApp;

use strict;
use Catalyst qw/HTML::Widget/;

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir' );

TestApp->setup;

sub nameless : Global {
    my ( $self, $c, $key ) = @_;
    $c->widget->element( 'Textfield', 'foo' );
    $c->widget->constraint( All => 'foo' );
    $c->res->body( $c->widget->process->as_xml );
}

sub nameless_result : Global {
    my ( $self, $c, $key ) = @_;
    $c->widget->element( 'Textfield', 'foo' );
    $c->widget->constraint( Integer => 'foo' );
    $c->widget->constraint( All     => 'foo' );
    $c->widget->indicator('foo');
    $c->res->body( $c->widget_result->as_xml );
}

sub nameless_noresult : Global {
    my ( $self, $c, $key ) = @_;
    $c->widget_result->element( 'Textfield', 'foo' );
    $c->widget->constraint( All => 'foo' );
    $c->widget->indicator('bar');
    $c->res->body( $c->widget_result->as_xml );
}

sub nameless_res_nores : Global {
    my ( $self, $c, $key ) = @_;
    $c->widget_result->element( 'Textfield', 'foo' );
    $c->widget->constraint( All => 'foo' );
    $c->widget_result;
    $c->res->body( $c->widget_result->as_xml );
}

sub named : Global {
    my ( $self, $c, $key ) = @_;
    $c->widget('foo')->element( 'Submit', 'foo' );
    $c->res->body( $c->widget->process->as_xml );
}

1;
