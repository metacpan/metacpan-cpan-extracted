#!/perl

use strict;
use warnings;

use Test::Most;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";


use_ok 'Test::SchemaMock';

isa_ok my $schema_mock = Test::SchemaMock->new(), 'Test::SchemaMock';
isa_ok my $schema = $schema_mock->schema, 'Test::Schema';

done_testing;
