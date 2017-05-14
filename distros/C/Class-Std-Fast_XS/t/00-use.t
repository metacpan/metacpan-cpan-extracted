package TestClass;
use Class::Std::Fast::Storable;

my %bla_of :ATTR(:name<bla>);


package TestClass_XS;
use Class::Std::Fast::Storable;

require Class::Std::Fast_XS;
my %foo_of :ATTR(:name<bla>);


package main;
use lib '../lib';
use lib '../blib/arch';

use strict;
use warnings;
use Test::More tests => 4; #qw(no_plan);

my $obj = TestClass->new({ bla => 'foo'});
eval { TestClass_XS->new() };
like $@, qr{Missing \s initializer \s label}x;



my $xs = TestClass_XS->new({ bla => 'foo' });
is $xs->get_bla(), 'foo';

ok $xs->set_bla('baz');
is $xs->get_bla(), 'baz';
