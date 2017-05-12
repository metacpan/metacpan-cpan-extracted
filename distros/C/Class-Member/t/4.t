use strict;
use Test::More tests=>11;

package My::New::Package;
use Class::Member::Dynamic qw/member_A member_B -CLASS_MEMBERS/;
use Symbol qw/gensym/;

sub new_glob {
  bless gensym()=>shift;
}

sub new_hash {
  bless {}=>shift;
}

package main;

ok( eq_array( \@My::New::Package::CLASS_MEMBERS,
	      [qw/member_A member_B/] ), '-CLASS_MEMBERS' );

my $o=My::New::Package->new_hash;

$o->member_A='A';
ok( $o->member_A eq 'A', 'member_A eq A (HASH)' );

$o->member_A('B');
ok( $o->member_A eq 'B', 'member_B eq B (HASH)' );

$o->member_B=1;
ok( $o->member_B==1, 'member_B==1 (HASH)' );

$o->member_B(2);
ok( $o->member_B==2, 'member_B==2 (HASH)' );

$o=My::New::Package->new_glob;

$o->member_A='A';
ok( $o->member_A eq 'A', 'member_A eq A (GLOB)' );

$o->member_A('B');
ok( $o->member_A eq 'B', 'member_B eq B (GLOB)' );

$o->member_B=1;
ok( $o->member_B==1, 'member_B==1 (GLOB)' );

$o->member_B(2);
ok( $o->member_B==2, 'member_B==1 (GLOB)' );

ok( !eval {My::New::Package->member_A},
    'die if called as static' );

ok( $@=~/^My::New::Package::member_A must be called as instance method/,
    'exceptional message check' );

# Local Variables:
# mode: cperl
# End:
