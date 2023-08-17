use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(9);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Contraption';

fixtures_ok [
   Contraption => [
      [ 'id', 'color',   'status', 'note' ],
      [ '1',  'blue',    '', 'Where am I?' ],
      [ '2',  'brown',   '', 'Where am I?' ],
      [ '3',  'purple',  'Packaged', '' ],
      [ '4',  'green',   'Shipped', undef ],
      [ '5',  'magenta', 'Packaged', '' ],
      [ '6',  'black',   'Shipped', undef ],
      [ '7',  'fuscia',  undef, undef ],
      [ '8',  'puce', '', '' ],
      [ '9',  'white', 'Sold', 'Shipped on Jun 8'],
   ],
], 'Installed fixtures';

subtest 'blank finds blank entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->blank('note')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/3 5 8/], 'Correct records found, in the right order');
};

subtest 'blank finds blank entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->blank([ 'status', 'note'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/8/], 'Correct records found, in correct order');
};

subtest 'not_blank finds not_blank entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->not_blank('note')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 6, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 2 4 6 7 9/], 'Correct records found, in the right order');
};

subtest 'not_blank finds not_blank entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->not_blank([ 'status', 'note'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 4, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/4 6 7 9/], 'Correct records found, in the right order');
};

subtest 'blank_or_null finds blank_or_null entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->blank_or_null('note')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 6, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/3 4 5 6 7 8/], 'Correct records found, in the right order');
};

subtest 'blank_or_null finds blank_or_null entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->blank_or_null([ 'status', 'note'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 2, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/7 8/], 'Correct records found, in the correct order');
};

subtest 'not_blank_or_null finds not_blank_or_null entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->not_blank_or_null('note')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 2 9/], 'Correct records found, in the right order');
};

subtest 'not_blank_or_null finds not_blank_or_null entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->not_blank_or_null([ 'status', 'note'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/9/], 'Correct records found, in the correct order');
};

exit;

