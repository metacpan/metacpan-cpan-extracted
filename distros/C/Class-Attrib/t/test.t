#
# Test suite by:
# 	Alexandr Ciornii <alexchorny@gmail.com>
# 	Kevin Cody-Little <kcody@cpan.org>
#

package MyApp::MyPackage;
use warnings;
use strict;

use Class::Attrib;
our @ISA = qw( Class::Attrib );

our %Attrib = (
	ClassAttrib		=> 12345,
	translucent_attrib	=> "foo",
	mandatory_attrib	=> undef,
);

sub new {
    bless {}, shift;
}

package main;
use warnings;
use strict;

use Test::More;

plan tests => 13;

my $t = MyApp::MyPackage->new;

# test changing class default
is( $t->ClassAttrib, 12345 );
ok( $t->ClassAttrib( 56789 ) );
is( MyApp::MyPackage->ClassAttrib, 56789 );

# test translucency
is( $t->translucent_attrib, "foo" );
ok( $t->translucent_attrib( "bar" ) );
is( $t->translucent_attrib, "bar" );

# change translucent default
ok( MyApp::MyPackage->translucent_attrib( "bam" ) );
is( $t->translucent_attrib, "bar" );
ok( $t->translucent_attrib( undef ) );
is( $t->translucent_attrib, "bam" );

# test plain instance attribute
is( $t->mandatory_attrib, undef );
ok( $t->mandatory_attrib( "somevalue" ) );
is( $t->mandatory_attrib, "somevalue" );

