#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok "Class::Superclasses";

my $parser = Class::Superclasses->new();

isa_ok $parser, 'Class::Superclasses';

{
    my $code = q~package test_moo;
        use Moo;
        extends 'Moo::Base';
        1;
    ~;
    $parser->document(\$code);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base);

    is_deeply \@superclasses, \@parents;
}

{
    my $code = q~package test_moo;
        use Moo;
        extends( 'Moo::Base' );
        1;
    ~;
    $parser->document(\$code);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base);

    is_deeply \@superclasses, \@parents;
}

{
    my $code = q~package test_moo;
        use Moo;
        extends 'Moo::Base', 'Base2';
        1;
    ~;
    $parser->document(\$code);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base Base2);

    is_deeply \@superclasses, \@parents;
}

{
    my $code = q~package test_moo;
        use Moo;
        extends qw/Moo::Base Base2/;
        1;
    ~;
    $parser->document(\$code);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base Base2);

    is_deeply \@superclasses, \@parents;
}

done_testing();
