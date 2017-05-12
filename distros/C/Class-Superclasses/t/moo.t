#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin ();

use_ok "Class::Superclasses";

my $parser = Class::Superclasses->new();

isa_ok $parser, 'Class::Superclasses';

{
    my $testfile = $FindBin::Bin . '/test_moo.pm';
    $parser->document($testfile);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base);

    is_deeply \@superclasses, \@parents;
}

{
    my $testfile = $FindBin::Bin . '/test_moo_func.pm';
    $parser->document($testfile);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base);

    is_deeply \@superclasses, \@parents;
}

{
    my $testfile = $FindBin::Bin . '/test_moo_multi.pm';
    $parser->document($testfile);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base Base2);

    is_deeply \@superclasses, \@parents;
}

{
    my $testfile = $FindBin::Bin . '/test_moo_multi_qw.pm';
    $parser->document($testfile);

    my @superclasses = $parser->superclasses();
    my @parents      = qw(Moo::Base Base2);

    is_deeply \@superclasses, \@parents;
}

done_testing();
