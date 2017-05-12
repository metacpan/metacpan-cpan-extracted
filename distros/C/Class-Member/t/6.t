use strict;
use Test::More tests=>5;

package My::New::Base;
use Class::Member::GLOB qw/member_BASE  -CLASS_MEMBERS  -NEW/;

package My::New::Package;
use Class::Member::GLOB qw/member_A member_B  -CLASS_MEMBERS -INIT=initx/;
use base qw/My::New::Base/;

sub initx {
  $_[0]->member_A=42;
}

package main;

my $o=My::New::Package->new(member_B=>43, member_BASE=>12);
ok( $o->member_A==42, 'member_A==42' );
ok( $o->member_B==43, 'member_B==43' );
ok( $o->member_BASE==12, 'member_BASE==12' );

$o->member_B++;
$o=$o->new(member_A=>12);
ok( $o->member_A==42, 'member_A==42' );
ok( $o->member_B==44, 'member_B==44' );

# Local Variables:
# mode: cperl
# End:
