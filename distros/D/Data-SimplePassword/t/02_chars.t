#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;

my $sp = Data::SimplePassword->new;

can_ok( $sp, 'chars' );

# success
ok( $sp->chars("0"), "set 0" );
ok( $sp->chars("1"), "set 1" );
ok( $sp->chars( 0..9 ), "set 0..9" );
ok( $sp->chars( '0'..'9' ), "set '0'..'9'" );
ok( $sp->chars( 0..9, 'a'..'Z' ), "set 0..9, 'a'..'Z'" );
ok( $sp->chars( 0..9, 'a'..'Z', qw(+ /) ), "set 0..9, 'a'..'Z', +, /" );

# failure
ok( ! eval { $sp->chars("") }, "empty" );
ok( ! eval { $sp->chars( qw(foo bar) ) }, "words" );
ok( ! eval { $sp->chars( -5..5 ) }, "invalid numbers" );

done_testing;

__END__
