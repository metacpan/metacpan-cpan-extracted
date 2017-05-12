use strict;
use Test::More tests=>5;

package My::New::Base;
use Class::Member::HASH qw/member_BASE  -CLASS_MEMBERS -INIT/;

package My::New::Package;
use Class::Member::HASH qw/member_A member_B -CLASS_MEMBERS -NEW=newx/;
use base qw/My::New::Base/;

sub init {
  $_[0]->member_A=42;
}

package main;

my $o=My::New::Package->newx(member_B=>43);
ok( $o->member_A==42, 'member_A==42' );
ok( $o->member_B==43, 'member_B==43' );

$o->member_B++;
$o=$o->newx(member_A=>12, member_BASE=>12);
ok( $o->member_A==42, 'member_A==42' );
ok( $o->member_B==44, 'member_B==44' );
ok( $o->member_BASE==12, 'member_BASE==12' );

# Local Variables:
# mode: cperl
# End:
