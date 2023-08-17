use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(7);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Contraption';

fixtures_ok [
   Contraption => [
      [ 'id', 'color',   'active', 'blocked' ],
      [ '1',  'blue',    'true', 'false' ],
      [ '2',  'purple',  'true', 'true' ],
      [ '3',  'green',   'false', 'true' ],
      [ '4',  'magenta', 'false', 'false' ],
   ],
], 'Installed fixtures';

subtest 'is finds true entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->is('active')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 2, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 2/], 'Correct records found, in the right order');
};

subtest 'is finds true entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->is([ 'active', 'blocked'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/2/], 'Correct records found, in correct order');
};

subtest 'is_not finds false entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->is_not('active')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 2, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/3 4/], 'Correct records found, in the right order');
};

subtest 'is_not finds false entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->is_not([ 'active', 'blocked'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/4/], 'Correct records found, in correct order');
};

subtest 'is_any dies if you send it a single field' => sub {
   plan(1);
   my $rs;
   like( dies{ $rs = Contraption->is_any('active')->search({}, {order_by => ['id']}); },
         qr/Why would you only send one column to is_any\?/);
};

subtest 'is_any finds true entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->is_any([ 'active', 'blocked'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 2 3/], 'Correct records found, in correct order');
};


exit;

