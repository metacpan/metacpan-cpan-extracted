use strict;
use warnings;

use Test::More;

use DBIx::Lite;
my $dbix = DBIx::Lite->new();

# define custom object classes
$dbix->schema
     ->table('subjects')
     ->resultset_class('My::Subject::ResultSet');

my $rs = $dbix->table('subjects');
isa_ok($rs, 'My::Subject::ResultSet');
can_ok($rs, 'some_custom_method');

done_testing();

package My::Subject::ResultSet;

sub some_custom_method {}

