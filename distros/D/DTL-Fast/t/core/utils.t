#!/usr/bin/perl
use strict; use warnings FATAL => 'all';
use Test::More;

#use DTL::Fast::Utils;
#
#sub regular_method{return 1;}
#sub lvalue_method: lvalue{ my $a = 1; return $a;}
#
#package Foo;
#
#sub new{return bless {}, shift;}
#sub regular_method{ return 1 };
#sub lvalue_method: lvalue{ my $a = 1; return $a; };
#
#package main;
#
#is( DTL::Fast::Utils::is_lvalue(\&regular_method), 0, 'is_lavlue: regular sub');
#is( DTL::Fast::Utils::is_lvalue(\&lvalue_method), 1, 'is_lavlue: lvalue sub');
#
#is( DTL::Fast::Utils::is_lvalue(\&Foo::regular_method), 0, 'is_lavlue: regular package sub');
#is( DTL::Fast::Utils::is_lvalue(\&Foo::lvalue_method), 1, 'is_lavlue: lvalue package sub');
#
#my $foo = Foo->new();
#my $regular_method = 'regular_method';
#my $lvalue_method = 'lvalue_method';
#
#is( DTL::Fast::Utils::is_lvalue($foo->can($regular_method)), 0, 'is_lavlue: regular object sub');
#is( DTL::Fast::Utils::is_lvalue($foo->can($lvalue_method)), 1, 'is_lavlue: lvalue object sub');

plan( skip_all => "Nothing to test. is_lvalue method removed" );

done_testing();
