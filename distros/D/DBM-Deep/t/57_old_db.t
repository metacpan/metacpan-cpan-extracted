use strict;
use warnings FATAL => 'all';

use File::Spec::Functions 'catfile';
use Test::More;
use t::common qw( new_fh );

use DBM::Deep;

tie my %db, "DBM::Deep", catfile(< t etc db-1-0003 >);

is join("-", keys %db), "foo", '1.0003 db has one key';
is "@{$db{foo}}", "1 2 3", 'values in 1.0003 db';

is tied(%db)->db_version, '1.0003', 'db_version on old db';
my ($fh, $filename) = new_fh;
is new DBM::Deep file => $filename, fh=>$fh =>->db_version, '2',
 'db_version on new db';

done_testing;
