package TestTypesStandard;

use strict;
use warnings;
use lib 'lib';
use Test::More;
use Data::Processor;

use Types::Standard -all;

my $schema = {
    foo => {
        validator => ArrayRef[Int],
        description => 'an arrayref of integers'
    }
};
my $processor;
eval { $processor = Data::Processor->new($schema) };
ok (! $@);

my $error_collection = $processor->validate({foo => [42, 32, 99, 'bla']});
my @errors = $error_collection->as_array();
ok (scalar(@errors)==1, '1 error found: "bla" is not an Int');

$error_collection = $processor->validate({foo => [42, 32, 99, 99.9]});
@errors = $error_collection->as_array();
ok (scalar(@errors)==1, '1 error found: "99.9" is not an Int');

$error_collection = $processor->validate({foo => [42, 32, 99, 9827456893475926589]});
ok ($error_collection->as_array == 0);

1;
