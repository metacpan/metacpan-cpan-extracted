#!/usr/bin/perl

package InsideOut;

use strict;
use warnings;

eval "use Class::Accessor::Fast;";
use Class::Tie::InsideOut;

our @ISA = qw( Class::Tie::InsideOut Class::Accessor::Fast );

our %GoodKey;

InsideOut->mk_accessors(qw( GoodKey ) );

package main;

use strict;
use warnings;

use Test::More skip_all => "Class::Accessor::Fast fails tests";

eval "use Class::Accessor::Fast;";
plan skip_all => "Class::Accessor::Fast is not installed" if ($@);

plan tests => 3;

my $obj = InsideOut->new();
ok($obj->isa("InsideOut"));
ok($obj->isa("Class::Tie::InsideOut"));

$obj->GoodKey(1);
ok($obj->GoodKey == 1, "set/get");

