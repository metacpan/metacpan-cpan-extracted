use 5.012;
use warnings;
use lib 't/lib';
use PLTest 'full';

*get_allocs = \&CPP::panda::lib::Test::String::get_allocs;

my $key1 = "key1" x 20;
my $key2 = "key2" x 30;
my $val1 = "1" x 40;
my $val2 = "2" x 50;
my $val3 = "3" x 60;
my $nokey = "nokey" x 20;

subtest 'string_map' => sub {
    CPP::panda::lib::Test::StringContainers::smap_fill({$key1 => $val1, $key2 => $val2});
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_find_sv($key1), $val1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smap_find_sv($key2), $val2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smap_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'at' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_at_sv($key1), $val1, "at ok");
        is(CPP::panda::lib::Test::StringContainers::smap_at_sv($key2), $val2, "at ok");
    };

    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_count_sv($key1), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smap_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smap_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smap_equal_range_sv($key1), [$val1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smap_equal_range_sv($key2), [$val2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smap_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'lower_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_lower_bound_sv("0"), $val1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smap_lower_bound_sv($key1), $val1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smap_lower_bound_sv($nokey), undef, "lower_bound ok");
    };

    subtest 'upper_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_upper_bound_sv("0"), $val1, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smap_upper_bound_sv($key1), $val2, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smap_upper_bound_sv($key2), undef, "upper_bound ok");
    };

    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::smap_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::smap_erase_sv($key1), 1, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smap_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smap_find_sv($key2), $val2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smap_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'string_multimap' => sub {
    CPP::panda::lib::Test::StringContainers::smmap_fill({$key1 => $val1, $key2 => $val2});
    CPP::panda::lib::Test::StringContainers::smmap_fill({$key1 => $val3});
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::smmap_find_sv($key1), $val1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_find_sv($key2), $val2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::smmap_count_sv($key1), 2, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smmap_equal_range_sv($key1), [$val1, $val3], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smmap_equal_range_sv($key2), [$val2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smmap_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'lower_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smmap_lower_bound_sv("0"), $val1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_lower_bound_sv($key1), $val1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_lower_bound_sv($nokey), undef, "lower_bound ok");
    };

    subtest 'upper_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smmap_upper_bound_sv("0"), $val1, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_upper_bound_sv($key1), $val2, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_upper_bound_sv($key2), undef, "upper_bound ok");
    };

    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::smmap_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::smmap_erase_sv($key1), 2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_find_sv($key2), $val2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smmap_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'unordered_string_map' => sub {
    CPP::panda::lib::Test::StringContainers::usmap_fill({$key1 => $val1, $key2 => $val2});
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmap_find_sv($key1), $val1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_find_sv($key2), $val2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'at' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmap_at_sv($key1), $val1, "at ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_at_sv($key2), $val2, "at ok");
    };

    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmap_count_sv($key1), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmap_equal_range_sv($key1), [$val1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmap_equal_range_sv($key2), [$val2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmap_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmap_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::usmap_erase_sv($key1), 1, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_find_sv($key2), $val2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmap_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'unordered_string_multimap' => sub {
    CPP::panda::lib::Test::StringContainers::usmmap_fill({$key1 => $val1, $key2 => $val2});
    CPP::panda::lib::Test::StringContainers::usmmap_fill({$key1 => $val3});
    get_allocs();
    
    subtest 'find' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmmap_find_sv($key1), any($val1, $val3), "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_find_sv($key2), $val2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmmap_count_sv($key1), 2, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmmap_equal_range_sv($key1), bag($val1, $val3), "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmmap_equal_range_sv($key2), [$val2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmmap_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmmap_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::usmmap_erase_sv($key1), 2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_find_sv($key2), $val2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmmap_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'string_set' => sub {
    CPP::panda::lib::Test::StringContainers::sset_fill([$key1, $key2]);
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::sset_find_sv($key1), $key1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::sset_find_sv($key2), $key2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::sset_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::sset_count_sv($key1), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::sset_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::sset_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::sset_equal_range_sv($key1), [$key1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::sset_equal_range_sv($key2), [$key2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::sset_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'lower_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::sset_lower_bound_sv("0"), $key1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::sset_lower_bound_sv($key1), $key1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::sset_lower_bound_sv($nokey), undef, "lower_bound ok");
    };

    subtest 'upper_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::sset_upper_bound_sv("0"), $key1, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::sset_upper_bound_sv($key1), $key2, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::sset_upper_bound_sv($key2), undef, "upper_bound ok");
    };

    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::sset_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::sset_erase_sv($key1), 1, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::sset_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::sset_find_sv($key2), $key2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::sset_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'string_multiset' => sub {
    CPP::panda::lib::Test::StringContainers::smset_fill([$key1, $key2, $key1]);
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::smset_find_sv($key1), $key1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smset_find_sv($key2), $key2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::smset_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::smset_count_sv($key1), 2, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smset_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::smset_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smset_equal_range_sv($key1), [$key1, $key1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smset_equal_range_sv($key2), [$key2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::smset_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'lower_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smset_lower_bound_sv("0"), $key1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smset_lower_bound_sv($key1), $key1, "lower_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smset_lower_bound_sv($nokey), undef, "lower_bound ok");
    };

    subtest 'upper_bound' => sub {
        is(CPP::panda::lib::Test::StringContainers::smset_upper_bound_sv("0"), $key1, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smset_upper_bound_sv($key1), $key2, "upper_bound ok");
        is(CPP::panda::lib::Test::StringContainers::smset_upper_bound_sv($key2), undef, "upper_bound ok");
    };

    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::smset_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::smset_erase_sv($key1), 2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smset_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smset_find_sv($key2), $key2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::smset_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'unordered_string_set' => sub {
    CPP::panda::lib::Test::StringContainers::usset_fill([$key1, $key2]);
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::usset_find_sv($key1), $key1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usset_find_sv($key2), $key2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usset_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::usset_count_sv($key1), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usset_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usset_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usset_equal_range_sv($key1), [$key1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usset_equal_range_sv($key2), [$key2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usset_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::usset_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::usset_erase_sv($key1), 1, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usset_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usset_find_sv($key2), $key2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usset_erase_sv($key1), 0, "erase ok");
    };
};

subtest 'unordered_string_multiset' => sub {
    CPP::panda::lib::Test::StringContainers::usmset_fill([$key1, $key2, $key1]);
    get_allocs();
    
    subtest 'find' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmset_find_sv($key1), $key1, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_find_sv($key2), $key2, "find ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_find_sv($nokey), undef, "find ok");
    };
    
    subtest 'count' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmset_count_sv($key1), 2, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_count_sv($key2), 1, "count ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_count_sv($nokey), 0, "count ok");
    };
    
    subtest 'equal_range' => sub {
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmset_equal_range_sv($key1), [$key1, $key1], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmset_equal_range_sv($key2), [$key2], "equal_range ok");
        cmp_deeply(CPP::panda::lib::Test::StringContainers::usmset_equal_range_sv($nokey), [], "equal_range ok");
    };
    
    subtest 'erase' => sub {
        is(CPP::panda::lib::Test::StringContainers::usmset_erase_sv($nokey), 0, "erase ok");
        my $a = get_allocs();
        cmp_deeply([values %$a], [(0) x 9], "no allocs");
        is(CPP::panda::lib::Test::StringContainers::usmset_erase_sv($key1), 2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_find_sv($key1), undef, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_find_sv($key2), $key2, "erase ok");
        is(CPP::panda::lib::Test::StringContainers::usmset_erase_sv($key1), 0, "erase ok");
    };
};

done_testing();