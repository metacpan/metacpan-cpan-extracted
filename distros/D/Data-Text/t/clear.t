use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Data::Text') }

my $dt = Data::Text->new('This is a test');

isa_ok($dt, 'Data::Text', 'Object created');
is($dt->as_string(), 'This is a test', 'Initial text is correct');

$dt->clear();

ok(!defined($dt->as_string()), 'Text is cleared');
is($dt->length(), 0, 'Length after clear is 0');

# Check that file, line, and clean are cleared
ok(!exists $dt->{file}, 'File metadata is cleared');
ok(!exists $dt->{line}, 'Line metadata is cleared');

done_testing();
