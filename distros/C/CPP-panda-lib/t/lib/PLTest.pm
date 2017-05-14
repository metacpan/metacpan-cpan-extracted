package PLTest;
use 5.018;
use warnings;
use Config;
use Test::More;
use Test::Deep;
use Data::Dumper;
use CPP::panda::lib;

sub import {
    my ($class, @reqs) = @_;
    if (@reqs) {
        require_full();
        no strict 'refs';
        &{"require_$_"}() for @reqs;
    }
    
    my $caller = caller();
    foreach my $sym_name (qw/Config is cmp_deeply ok done_testing skip isnt Dumper noclass subtest cmp_ok ignore any bag/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
    }
    
}

sub require_full {
    plan skip_all => 'rebuild Makefile.PL adding TEST_FULL=1 to enable all tests'
        unless CPP::panda::lib::Test::String->can('new_empty');
}

sub require_threads {
    plan skip_all => 'threaded perl required to run these tests'
        unless eval "use threads; use threads::shared; 1;";
}

1;
