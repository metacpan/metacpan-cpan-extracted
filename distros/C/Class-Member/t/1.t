use strict;
use Test::More tests=>7;

package My::New::Package;
use Class::Member::HASH qw/member_A member_B -CLASS_MEMBERS/;

sub new {
  bless {}=>shift;
}

package main;

ok( eq_array( \@My::New::Package::CLASS_MEMBERS,
	      [qw/member_A member_B/] ), '-CLASS_MEMBERS' );

my $o=My::New::Package->new;

$o->member_A='A';
ok( $o->member_A eq 'A', 'member_A eq A' );

$o->member_A('B');
ok( $o->member_A eq 'B', 'member_B eq B' );

$o->member_B=1;
ok( $o->member_B==1, 'member_B==1' );

$o->member_B(2);
ok( $o->member_B==2, 'member_B==2' );

ok( !eval {My::New::Package->member_A},
    'die if called as static' );

ok( $@=~/^My::New::Package::member_A must be called as instance method/,
    'exceptional message check' );

# Local Variables:
# mode: cperl
# End:
