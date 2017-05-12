use strict;
use warnings;

use Test::More tests => 2;

use lib qw(t/lib);
use DBIC::Test;

my $schema = DBIC::Test->init_schema;
my $row;

$row = $schema->resultset('DBIC::Test::Schema::Test')
    ->create({ name => 'Some Silly Book' });

is($row->token, 'some_silly_book', "Basic Tokenize works");

$row = $schema->resultset('DBIC::Test::Schema::Test')
    ->create({ name => 'Some Silly Book, Volume 2.3-1' });
is($row->token, 'some_silly_book__volume_2_3_1', "Other characters escape properly");
