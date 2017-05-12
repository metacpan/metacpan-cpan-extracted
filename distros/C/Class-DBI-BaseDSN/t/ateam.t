#!perl -w
use strict;
use lib qw(t/lib);
use Test::More tests => 6;

my $pkg;
BEGIN { $pkg = 'Class::DBI::BaseDSN' };
use_ok( $pkg );
package Foo;
use base $pkg;
my $foo;
__PACKAGE__->set_db('Main', 'dbi:ATeam', \$foo);

package main;
is( $foo, 'Foo, you have found the A-team',
    "redispatched to the A-Team set_db" );
is( $Foo::ISA[0], 'Class::DBI::ATeam', 'Foo @ISA' );

package Bar;
use base $pkg;
__PACKAGE__->set_db('Main', 'dbi:AbsentAndUnlikey' );

package main;
is( $Bar::ISA[0], 'Class::DBI', 'Fallback to Class::DBI on absent class' );

package Baz;
use base $pkg;
eval { __PACKAGE__->set_db('Main', 'dbi:CompileError' ) };

package main;
like( $@, qr/^Global symbol "\$foo"/, 'error blows on compile error');

package Quux;
use base $pkg;
eval { __PACKAGE__->set_db('Main', 'dbi:UpwardsCompileError' ) };

package main;
like( $@, qr/^Can't locate IfThisExistsThenWe\/reScrewed\.pm /, 
     "don't hide upstream Can't locates.");
