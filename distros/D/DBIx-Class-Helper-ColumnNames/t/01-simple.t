use v5.20;
use warnings;

use Test2::V0;

use DBD::SQLite;

use lib 't/lib';

use Test::Schema;

my $schema = Test::Schema->deploy_or_connect('dbi:SQLite::memory:')
  or bail_out("Cannot deploy in-memory schema");

my $rs0 = $schema->resultset("Artist");
is [ $rs0->get_column_names ], [ $rs0->result_source->columns ], "default columns";

my $rs1 = $rs0->search_rs( undef, { join => 'cd' } );
is [ $rs1->get_column_names ], [ $rs1->result_source->columns ], "default columns with a join but no columns defined";

my $rs2 = $rs1->search_rs( undef, { columns => [qw/ name fingers /] } );
is [ $rs2->get_column_names ], [qw/ name fingers /], "simple columns with no aliases";

my $rs3 = $rs1->search_rs( undef, { columns => [ { 'proper_name' => \ 'UPPER(name)' }, "fingers" ] } );
is [ $rs3->get_column_names ], [qw/ proper_name fingers /], "alias for some columns";

my $rs4 = $rs3->search_rs( undef, { "+columns" => ["hats"] } );
is [ $rs4->get_column_names ], [qw/ proper_name fingers hats /], "alias for some columns added by +columns";

my $rs5 =
  $rs0->search_rs( undef, { columns => [ { id => 'artistid' } ], select => [ { count => 'fingers' } ], as => ['finger_count'] } );
is [ $rs5->get_column_names ], [qw/ id finger_count /], "columns and select";

my $rs6 = $rs0->search_rs( undef,
    { columns => [ { id => 'artistid' } ], '+select' => [ { count => 'fingers' } ], '+as' => ['finger_count'] } );
is [ $rs6->get_column_names ], [qw/ id finger_count /], "columns and +select";

my $rs7 = $rs0->search_rs( undef, { columns => { id => 'artistid', nn => 'name' } } );
is [ sort $rs7->get_column_names ], [qw/ id nn /], "columns hashref";

done_testing;
