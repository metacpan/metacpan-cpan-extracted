#!perl

use 5.010;
use strict;
use warnings;

use Module::Path::More qw(module_path);
use Test::Exception;
use Test::More 0.98;

use Class::GenSource qw(gen_class_source_code);

my %spec1 = (
    attributes => {
        bar=>{},
        baz=>{default=>-1},
        qux=>{default=>-2},
    },
);

subtest classic => sub {
    my $src = gen_class_source_code(name => 'Foo', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    is($obj->baz(5), 5);

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

subtest 'Mo' => sub {
    plan skip_all => 'Mo not available'
        unless module_path(module => 'Mo');

    my $src = gen_class_source_code(
        name => 'Foo::Mo', variant => 'Mo', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo::Mo->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    is($obj->baz(5), 5);

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

subtest 'Moo' => sub {
    plan skip_all => 'Moo not available'
        unless module_path(module => 'Moo');

    my $src = gen_class_source_code(
        name => 'Foo::Moo', variant => 'Moo', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo::Moo->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    is($obj->baz(5), 5);

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

subtest 'Mouse' => sub {
    plan skip_all => 'Mouse not available'
        unless module_path(module => 'Mouse');

    my $src = gen_class_source_code(
        name => 'Foo::Mouse', variant => 'Mouse', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo::Mouse->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    is($obj->baz(5), 5);

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

subtest 'Moose' => sub {
    plan skip_all => 'Moose not available'
        unless module_path(module => 'Moose');

    my $src = gen_class_source_code(
        name => 'Foo::Moose', variant => 'Moose', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo::Moose->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    is($obj->baz(5), 5);

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

subtest 'Mojo::Base' => sub {
    plan skip_all => 'Mojo::Base not available'
        unless module_path(module => 'Mojo::Base');

    my $src = gen_class_source_code(
        name => 'Foo::Mojo', variant => 'Mojo::Base', %spec1);

    eval $src;
    ok(!$@, "compile succeeds") or diag explain {code=>$src, error=>$@};

    my $obj = Foo::Mojo->new(bar=>2, baz=>3);
    is($obj->bar, 2);
    is($obj->baz, 3);
    is($obj->qux, -2);
    $obj->bar(4);
    is($obj->bar, 4);
    #is($obj->baz(5), 5); # in Mojo::Base, setting returns the object

    dies_ok { $obj->thud } "access unknown attribute -> dies";

    # XXX test subclass instance
};

done_testing;
