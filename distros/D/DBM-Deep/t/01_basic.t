use strict;
use warnings FATAL => 'all';

use Test::More;

use t::common qw( new_fh );

diag "Testing DBM::Deep against Perl $] located at $^X";

use_ok( 'DBM::Deep' );

##
# basic file open
##
my ($fh, $filename) = new_fh();
my $db = eval {
    local $SIG{__DIE__};
    DBM::Deep->new( $filename );
}; if ( $@ ) {
	diag "ERROR: $@";
    Test::More->builder->BAIL_OUT( "Opening a new file fails." );
}

isa_ok( $db, 'DBM::Deep' );
ok(1, "We can successfully open a file!" );

$db->{foo} = 'bar';
is( $db->{foo}, 'bar', 'We can write and read.' );

done_testing;
