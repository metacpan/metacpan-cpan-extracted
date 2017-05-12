use strict;
use warnings;
use utf8;
use FindBin;

use Test::More;

use_ok 'Data::XLSX::Parser';

my $parser = Data::XLSX::Parser->new;
isa_ok $parser, 'Data::XLSX::Parser';

$parser->open("$FindBin::Bin/sample-data.xlsx");

my $shared_strings = $parser->shared_strings;

is $shared_strings->count, 323, 'count ok';

is $shared_strings->get(1), '(CC 3.0 BY-SA)', 'get 1 ok';
is $shared_strings->get(99), '銀朱', 'get 99 ok';


done_testing;
