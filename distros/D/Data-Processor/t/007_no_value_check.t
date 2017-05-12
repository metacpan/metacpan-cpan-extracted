use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    probe_cfg => {
        description => 'some magic stuff',
        validator => sub {
            my $type = ref shift;
            return ((not $type or $type eq 'HASH')
                ? undef
                : 'expected a hash or a scalar');
        }
    }
};

my $data = {
    probe_cfg => 'dummy entry.',
};


my $p = Data::Processor->new($schema);

my $error_collection = $p->validate($data, verbose=>0);

ok ($error_collection->count==0, 'no errors');

$data = {
    probe_cfg => {
        some_fancy => [ 'dummy entry.']
    }
};

$error_collection = $p->validate($data, verbose=>0);

ok ($error_collection->count==0, 'still no errors');


done_testing;
