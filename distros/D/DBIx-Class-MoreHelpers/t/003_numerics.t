use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(11);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Contraption';

fixtures_ok [
   Contraption => [
      [ 'id', 'color',   'size', 'quantity' ],
      [ '1',  'blue',    0, 0 ],
      [ '2',  'purple',  undef, 3 ],
      [ '3',  'green',   2, 4 ],
      [ '4',  'magenta', -1, 0 ],
      [ '5',  'brown', -3, 14 ],
      [ '6',  'puce', -1, -2 ],
      [ '7',  'pink', undef, 0 ],
   ],
], 'Installed fixtures';

subtest 'zero finds zero-value entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->zero('quantity')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 4 7/], 'Correct records found, in the right order');
};

subtest 'zero finds zero-value entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->zero([ 'size','quantity'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1/], 'Correct records found, in correct order');
};

subtest 'null_or_zero finds null_or_zero entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->null_or_zero('quantity')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 4 7/], 'Correct records found, in the right order');
};

subtest 'null_or_zero finds null_or_zero-value entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->null_or_zero([ 'size','quantity'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 2, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/1 7/], 'Correct records found, in correct order');
};

subtest 'nonzero finds nonzero entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->nonzero('quantity')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 4, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/2 3 5 6/], 'Correct records found, in the right order');
};

subtest 'nonzero finds nonzero-value entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->nonzero([ 'size','quantity'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/3 5 6/], 'Correct records found, in correct order');
};

subtest 'positive finds positive entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->positive('quantity')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 3, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/2 3 5/], 'Correct records found, in the right order');
};

subtest 'positive finds positive-value entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->positive([ 'size','quantity'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/3/], 'Correct records found, in correct order');
};

subtest 'negative finds negative entries for a single field properly' => sub {
   plan(3);
   my $rs = Contraption->negative('quantity')->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/6/], 'Correct records found, in the right order');
};

subtest 'negative finds negative-value entries for multiple fields properly' => sub {
   plan(3);
   my $rs = Contraption->negative([ 'size','quantity'])->search({}, {order_by => ['id']});
   ok (ref $rs eq 'TestSchema::ResultSet', 'returns a ResultSet');
   ok ($rs->count == 1, 'Correctly found the right number of records');
   my @ids = $rs->get_column('id')->all;
   is ( \@ids, [qw/6/], 'Correct records found, in correct order');
};

exit;

