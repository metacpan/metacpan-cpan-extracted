#! perl
use Test::More 0.88;
use Date::Calc::Iterator;

my @TESTS = (

    # 2018 wasn't a leap year
    {
            from => '2018-02-27',
              to => '2018-03-01',
        expected => '2018-02-27|2018-02-28|2018-03-01',
    },

    # 2016 was a leap year
    {
            from => '2016-02-27',
              to => '2016-03-01',
        expected => '2016-02-27|2016-02-28|2016-02-29|2016-03-01',
    },

    # across year boundary
    {
            from => '2015-12-30',
              to => '2016-01-02',
        expected => '2015-12-30|2015-12-31|2016-01-01|2016-01-02',
    },

    # same 3 tests again, but without dashes in the date strings

    # 2018 wasn't a leap year
    {
            from => '20180227',
              to => '20180301',
        expected => '20180227|20180228|20180301',
    },

    # 2016 was a leap year
    {
            from => '20160227',
              to => '20160301',
        expected => '20160227|20160228|20160229|20160301',
    },

    # across year boundary
    {
            from => '20151230',
              to => '20160102',
        expected => '20151230|20151231|20160101|20160102',
    },

);

foreach my $test (@TESTS) {
    my @dates;
    my $iterator = Date::Calc::Iterator->new(
                       from => $test->{from},
                         to => $test->{to},
                   );
    while (my $date = $iterator->next) {
        push(@dates, $date);
    }
    my $dates_as_string = join('|', @dates);
    is($dates_as_string, $test->{expected});
}

done_testing();
