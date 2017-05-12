#!perl -T
#
# $Id: 03-obj.t,v 1.0 2013/04/03 06:49:25 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Constant;
use Data::Lock qw/dlock dunlock/;
#use Test::More 'no_plan';
use Test::More tests => 14;

{
    package Foo;
    sub new { my $pkg = shift; bless { @_ }, $pkg }
    sub get { $_[0]->{foo} }
    sub set { $_[0]->{foo} = $_[1] };
}
{
    my $o : Constant( Foo->new(foo=>1) );
    isa_ok $o, 'Foo';
    is $o->get, 1, '$o->get == 1';
    eval{ $o = Foo->new(foo=>2) };
    ok $@, $@;
    eval{ $o->set(2) };
    ok $@, '$o->set(2)' . ': ' . $@;
    is $o->get, 1, '$o->get == 1';
    dunlock($o);
    eval{ $o->set(2) };
    ok !$@, '$o->set(2)';
    is $o->get, 2, '$o->get == 2';
}
SKIP: {
    skip 'Perl 5.9.5 or better required', 7 unless $] >= 5.009005;
    my $o : Constant( 
		     Foo->new(foo=>1) 
		    );
    isa_ok $o, 'Foo';
    is $o->get, 1, '$o->get == 1';
    eval{ $o = Foo->new(foo=>2) };
    ok $@, $@;
    eval{ $o->set(2) };
    ok $@, '$o->set(2)' . ': ' . $@;
    is $o->get, 1, '$o->get == 1';
    dunlock($o);
    eval{ $o->set(2) };
    ok !$@, '$o->set(2)';
    is $o->get, 2, '$o->get == 2';
}

__END__
#SCALAR
ARRAY
HASH
#CODE
#REF
#GLOB
#LVALUE
#FORMAT
#IO
#VSTRING
#Regexp

