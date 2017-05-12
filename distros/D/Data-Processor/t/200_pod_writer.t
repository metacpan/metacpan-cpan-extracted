use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    level_1 => {
        description => 'An element on level 1',
        members => {
            level_2_1 => {
                description => 'element 1 on level 2',
                optional => 1,
                members => {
                    level_3 => {
                        description => 'element on level 3',
                        default     => '42'
                    }
                }
            },
            level_2_2 => {
                description => 'element 2 on level 1'
            }
        }
    }
};

my $p = Data::Processor->new($schema);
my $pod = $p->pod_write();
print $pod;

ok (1);
# XXX make real test here

done_testing;
