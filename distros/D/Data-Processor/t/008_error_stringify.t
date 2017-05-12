use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {};

my $data = {
    make_me => 'an_error',
};


my $validator = Data::Processor->new($schema);

my $error_collection = $validator->validate($data, verbose=>0);

ok ($error_collection->count==1, '1 error');

my $msg = $error_collection->{errors}[0]->stringify();
ok ($msg eq "root: key 'make_me' not found in schema\n",
    'correct error msg from stringify');


done_testing;
