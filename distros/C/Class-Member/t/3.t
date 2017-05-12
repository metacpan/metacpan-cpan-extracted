use strict;
use Test::More tests=>14;

package My::New::Package::GLOB;
use Class::Member qw/member_A member_B -CLASS_MEMBERS/;
use Symbol qw/gensym/;

sub new {
  bless gensym()=>shift;
}

package My::New::Package::HASH;
use Class::Member qw/member_A member_B -CLASS_MEMBERS/;

sub new {
  bless {}=>shift;
}

package main;

ok( eq_array( \@My::New::Package::HASH::CLASS_MEMBERS,
	      [qw/member_A member_B/] ), '-CLASS_MEMBERS (HASH)' );

ok( eq_array( \@My::New::Package::GLOB::CLASS_MEMBERS,
	      [qw/member_A member_B/] ), '-CLASS_MEMBERS (GLOB)' );

my $o=My::New::Package::HASH->new;

$o->member_A='A';
ok( $o->member_A eq 'A', 'member_A eq A (HASH)' );

$o->member_A('B');
ok( $o->member_A eq 'B', 'member_B eq B (HASH)' );

$o->member_B=1;
ok( $o->member_B==1, 'member_B==1 (HASH)' );

$o->member_B(2);
ok( $o->member_B==2, 'member_B==2 (HASH)' );

ok( !eval {My::New::Package::HASH->member_A},
    'die if called as static (HASH)' );

ok( $@=~/^My::New::Package::HASH::member_A must be called as instance method/,
    'exceptional message check (HASH)' );

$o=My::New::Package::GLOB->new;

$o->member_A='A';
ok( $o->member_A eq 'A', 'member_A eq A (GLOB)' );

$o->member_A('B');
ok( $o->member_A eq 'B', 'member_B eq B (GLOB)' );

$o->member_B=1;
ok( $o->member_B==1, 'member_B==1 (GLOB)' );

$o->member_B(2);
ok( $o->member_B==2, 'member_B==1 (GLOB)' );

ok( !eval {My::New::Package::GLOB->member_A},
    'die if called as static (GLOB)' );

ok( $@=~/^My::New::Package::GLOB::member_A must be called as instance method/,
    'exceptional message check (GLOB)' );

# Local Variables:
# mode: cperl
# End:
