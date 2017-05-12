#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

$SIG{__DIE__} = \&Carp::confess;

{

    package MyApp;

    sub new { bless {} }

    my $moose = bless {}, "Foodiness";
    sub moose { $moose }

    my %config;
    sub config { \%config }

    sub debug { 0 }

    my $destroyed;
    sub DESTROY {
        $destroyed++;
    }

    sub destroyed { $destroyed }

    package MyApp::View::Foo;
    use base qw/Catalyst::View::TT::FunctionGenerator/;

    package Foodiness;

    sub foo { "magic foo @_" }
    sub bar { "bar" }
}

{
    no warnings 'redefine';
    sub Catalyst::View::TT::template_vars { key => "value" }
}

my $m = "Catalyst::View::TT::FunctionGenerator";

can_ok( $m, "template_vars" );

can_ok( $m, "generate_functions" );

{
    my $c = MyApp->new;
    my $v = MyApp::View::Foo->new("MyApp",{})->ACCEPT_CONTEXT($c);

    is_deeply(
        { $v->template_vars( $c ) },
        { key => "value" },
        "template_vars unchanged with no extra data"
    );
}

{
    my $c = MyApp->new;
    my $v = MyApp::View::Foo->new("MyApp",{})->ACCEPT_CONTEXT($c);

$v->generate_functions("moose");

    my $vars = { $v->template_vars( $c ) };

    is_deeply(
        [ sort keys %$vars ],
        [ sort qw/key foo bar/ ],
        "moose methods added to vars"
    );

    is( ref $vars->{foo},
        "CODE", "the value of the 'foo' variable is a code ref" );

    is(
        $vars->{foo}->(qw/arg1 arg2/),
        $c->moose->foo(qw/arg1 arg2/),
        'calling foo is like calling $c->moose->foo'
    );
}

{
    my $c = MyApp->new;
    my $v = MyApp::View::Foo->new("MyApp",{})->ACCEPT_CONTEXT($c);

    $v->generate_functions( [ moose => "bar" ] );

    my $vars = { $v->template_vars( $c ) };

    is_deeply( [ sort keys %$vars ], [ sort qw/key bar/ ], "one method added" );

    is(
        $vars->{bar}->(qw/arg1 arg2/),
        $c->moose->bar(qw/arg1 arg2/),
        'calling bar is like calling $c->moose->bar',
    );
}

{
    my $c = MyApp->new;
    my $v = MyApp::View::Foo->new("MyApp",{})->ACCEPT_CONTEXT($c);

    $v->generate_functions( [ MyApp->moose() => "bar" ] );

    my $vars = { $v->template_vars( $c ) };

    is_deeply( [ sort keys %$vars ], [ sort qw/key bar/ ], "one method added" );

    is(
        $vars->{bar}->(qw/arg1 arg2/),
        $c->moose->bar(qw/arg1 arg2/),
        "calling bar is like calling MyApp->new->moose->bar"
    );

    is( MyApp->destroyed, 3, "destroyed count is correct" );
}

{
    my $c = MyApp->new;
    my $v = MyApp::View::Foo->new("MyApp",{})->ACCEPT_CONTEXT($c);

    $v->generate_functions( $c );

    my $vars = { $v->template_vars( $c ) };
    
    is_deeply( [ sort keys %$vars ], [ sort qw/key new config debug moose destroyed DESTROY/ ], 'all methods of $c added' );

    is( $vars->{moose}->(), MyApp->moose, "methods are intact" );

    is( MyApp->destroyed, 4, "destroyed count is correct" );
}

is( MyApp->destroyed, 5, "no circular refs");
