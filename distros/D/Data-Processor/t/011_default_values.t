use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    key_with_default_value => {
        default => 42
    }
};

my $schema_2 = {
    key_with_default_value => {
        default => 0
    }
};

my $data = {};

my $data_2 = {
    key_with_default_value => 0,
};

my $data_3 = {
    key_with_default_value => '',
};

my $p = Data::Processor->new($schema);

my $error_collection = $p->validate($data, verbose => 0);

ok ($data->{key_with_default_value} == 42,
    'key_with_default_value 42 inserted');

$error_collection = $p->validate($data_2, verbose => 0);

ok ($data_2->{key_with_default_value} eq '0',
    'default value not overriding 0');

$error_collection = $p->validate($data_3, verbose => 0);

ok ($data_3->{key_with_default_value} eq '',
    'default value not overriding empty string');

$p = Data::Processor->new($schema_2);

$data = {};

$error_collection = $p->validate($data, verbose => 0);

ok ($data->{key_with_default_value} eq '0',
    'key_with_default_value 0 inserted');

done_testing;
