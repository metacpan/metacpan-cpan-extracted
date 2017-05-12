use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use t::common qw( new_fh );
use utf8;

use_ok( 'DBM::Deep' );

my ($fh, $filename) = new_fh();
my $db = DBM::Deep->new( $filename );

is( $db->_dump_file, <<"__END_DUMP__", "Dump of initial file correct" );
NumTxns: 1
Chains(B):
Chains(D):
Chains(I):
00000030: H  0064 REF: 1
__END_DUMP__

$db->{foo} = 'bar';

is( $db->_dump_file, <<"__END_DUMP__", "Dump of file after single assignment" );
NumTxns: 1
Chains(B):
Chains(D):
Chains(I):
00000030: H  0064 REF: 1
00000094: D  0064 bar
00000158: B  0387
    00000545 00000094
00000545: D  0064 foo
__END_DUMP__

$db->{ḟoo} = 'bār';

is( $db->_dump_file, <<"__END_DUMP__", "Dump after Unicode assignment" );
NumTxns: 1
Chains(B):
Chains(D):
Chains(I):
00000030: H  0064 REF: 1
00000094: D  0064 bar
00000158: B  0387
    00000545 00000094
    00000673 00000609
00000545: D  0064 foo
00000609: U  0064 bār
00000673: U  0064 ḟoo
__END_DUMP__

done_testing;
