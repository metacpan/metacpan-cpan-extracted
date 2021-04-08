use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[mksec]");

sub is_approx ($$;$) {
    my ($testv, $v, $name) = @_;
    cmp_ok abs($testv - $v), '<', 0.000001;
}

subtest "zero ctor" => sub {
    my $date = Date->new(0);
    is($date->epoch, 0);
    is($date->mksec, 0);
    is($date->to_string, "1970-01-01 03:00:00");
};

subtest "billion ctor" => sub {
    my $date = Date->new(1_000_000_000);
    is($date, "2001-09-09 05:46:40");
    is($date->mksec, 0);
    is($date->epoch, 1000000000);
};

subtest "double & string ctors" => sub {
    my $date = Date->new(1_000_000_000.000001);
    is_approx $date->epoch, 1_000_000_000.000001;
    is($date->to_string, "2001-09-09 05:46:40.000001");
    isnt($date, "2001-09-09 05:46:40");
    is($date, Date->new("2001-09-09 05:46:40.000001"));
    is("$date", "2001-09-09 05:46:40.000001");
    is($date->_year, 101);
    is($date->yr, 1);
    is($date->mksec, 1);
    is($date->to_number, 1000000000);
    $date = Date->new($date);
    is_approx($date->epoch, 1_000_000_000.000001);
};

subtest "hash ctor" => sub {
	my $date = date_ymd(year => 2018, month => 6, day => 27, hour => 22, min => 12, sec => 20, mksec => 340230);
	is_approx($date->epoch, 1530126740.34023);
    is($date->mksec, 340230);
};

subtest "array ctor" => sub {
    my $date = date_ymd(2018, 6, 27, 22, 12, 20, 340230);
    is_approx($date->epoch, 1530126740.34023);
    is($date->mksec, 340230);
};

subtest "relations" => sub {
    my $d1 = Date->new("2001-09-09 05:46:40");
    my $d2 = Date->new("2001-09-09 05:46:40.01");
    ok $d1 < $d2;
    ok $d2 > $d1;
    $d1 = Date->new("2001-09-09 05:46:40.01");
    ok $d1 == $d2;
};

subtest "assignment" => sub {
    my $date = Date->new(1);
    $date->epoch(1_000_000_000.000001);
    is_approx $date->epoch, 1_000_000_000.000001;
    $date->set("2001-09-09 05:46:40.000002");
    is_approx $date->epoch, 1_000_000_000.000002;
    my $d1 = Date->new("2001-09-09 05:46:40");
    $date->set($d1);
    is($date, $d1);

    my $d2 = Date->new(1_000_000_000.000003);
    $date->set($d2);
    is($date, $d2);
    is($date->mksec, 3);
};

subtest "now_hires" => sub {
	my $date1 = Date::now_hires();
	select undef, undef, undef, 0.001;
	my $date2 = Date::now_hires();
	ok $date2 > $date1;
	ok $date1->mksec || $date2->mksec;
};

done_testing;
