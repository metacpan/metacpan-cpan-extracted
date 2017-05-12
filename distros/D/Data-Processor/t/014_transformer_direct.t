use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    transform_here => {
        transformer => sub {
            return 42
        }
    }
};

my $data = {
    transform_here => 'I will be transformed into 42'
};

my $v = Data::Processor::Validator->new($schema, data=>$data);
my $p = Data::Processor->new($schema);
my $error_collection = $p->transform_data('transform_here', 'transform_here', $v);

is ($data->{transform_here},42, 'transformed into 42');

done_testing;
