BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;


package Foo;

use Test::More tests => 8;
use Scalar::Util qw( blessed );

sub new { bless {}, shift }

my $foo = Foo->new;
is( blessed($foo), 'Foo' );
ok( !Foo->can('bar'), "check that we can't do 'bar'" );

require Class::ExtraAttributes;
Class::ExtraAttributes->import( qw( bar ) );
ok( Foo->can('bar'), "check that we can't do 'bar'" );

ok( !defined $foo->bar('bar'), 'check we can set and old value undef' );
is( $foo->bar, 'bar', 'check value was set correctly' );

my $result = eval { Class::ExtraAttributes->import('new'); 1; };
ok( !$result, "check failed to add 'new' as attribute" );

my @attributes = Class::ExtraAttributes->attributes;
is( scalar @attributes, 1, "only one extra attribute: @attributes" );
is( $attributes[0], 'bar', 'extra attribute' );
