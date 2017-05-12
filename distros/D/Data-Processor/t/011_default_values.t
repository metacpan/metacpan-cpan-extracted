use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    key_with_default_value => {
        default => 42
    }
};

my $data = {};


my $p = Data::Processor->new($schema);

my $error_collection = $p->validate($data, verbose=>0);

ok ($data->{key_with_default_value}==42,
    'key_with_default_value 42 inserted');


done_testing;
