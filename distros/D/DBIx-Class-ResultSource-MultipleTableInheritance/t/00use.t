use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 16;
use Module::Find;

BEGIN {
    use_ok 'DBIx::Class::ResultSource::MultipleTableInheritance';

    for (qw/LoadTest NoSequenceSalad CafeInsertion/) {
        use_ok $_;
        my @modules = findallmod $_;
        for my $result_class (@modules) {
            use_ok $result_class;
        }
    }
}
