use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

tzset('Europe/Moscow');

my @d1 = (56, 34, 20, 9, 11, 2019);
my @d2 = (3, 2, 1, 15, 6, 1983);
my $e1 = Date::timelocal(@d1);
my $e2 = Date::timelocal(@d2);

sub test ($$;$@) {
    my ($fmt, $val1, $val2, $custom) = @_;
    $val2 //= $val1;
    subtest "'$fmt'" => sub {
        is Date::strftime($fmt, @d1), $val1, "@d1 => '$val1'";
        is Date::strftime($fmt, $e1), $val1, "$e1 => '$val1'";
        is Date::strftime($fmt, @d2), $val2, "@d2 => '$val2'";
        is Date::strftime($fmt, $e2), $val2, "$e2 => '$val2'";
        $custom->() if $custom;
    };
}

test "", "";
test "%%", "%";
test "%a", "Mon", "Fri";
test "%A", "Monday", "Friday";
test "%b", "Dec", "Jul";
test "%B", "December", "July";
test "%c", "Mon Dec  9 20:34:56 2019", "Fri Jul 15 01:02:03 1983";
test "%C", "20", "19"; # century[00-99]
test "%d", "09", "15"; # mday[01-31]
test "%D", "12/09/19", "07/15/83";
test "%e", " 9", "15"; # mday[1-31]
test "%F", "2019-12-09", "1983-07-15";
test "%H", "20", "01"; # hour[00-23]
test "%I", "08", "01"; # hour[01-12]
test "%j", "343", "196"; # yday[001-366]
test "%k", "20", " 1"; # hour[0-23]
test "%l", " 8", " 1"; # hour[1-12]
test "%m", "12", "07"; # month[01-12]
test "%M", "34", "02"; # minute[00-59]
test "%n", "\n"; # newline char
test "%p", "PM", "AM"; # AMPM
test "%P", "pm", "am"; # ampm
test "%r", "08:34:56 PM", "01:02:03 AM";
test "%R", "20:34", "01:02";
test "%s", "1575912896", "427064523"; # epoch
test "%S", "56", "03"; # second[00-59]
test "%t", "\t"; # tab character
test "%T", "20:34:56", "01:02:03"; # HH:MM:SS
test "%u", "1", "5", sub { is Date::strftime("%u", $e2 + 86400*2), "7" }; # wday [1-7, Mon-Sun]
test "%w", "1", "5", sub { is Date::strftime("%w", $e2 + 86400*2), "0" }; # wday [0-6, Sun-Sat]
test "%X", "20:34:56", "01:02:03"; # preferred HMS style
test "%y", "19", "83"; # yr[00-99]
test "%Y", "2019", "1983"; # year[0000-9999]
test "%z", "+0300", "+0400"; # tzoff [+-]HHMM
test "%Z", "MSK", "MSD"; # tzabbr

subtest 'with static text' => sub {
    test '<%Y>', '<2019>', '<1983>';
    test '%Y/%m/%d', '2019/12/09', '1983/07/15';
};

subtest 'unpaired percent' => sub {
    test '%', '%';
    test '%m%', '12%', '07%';
};

subtest 'unknown modifier' => sub {
    test '%[', '[';
};

subtest 'combined' => sub {
    test "%a %b %e %H:%M:%S %Y", "Mon Dec  9 20:34:56 2019", "Fri Jul 15 01:02:03 1983";
};

subtest 'custom timezone' => sub {
    foreach my $zone ("GMT", tzget("GMT")) {
        is Date::strftime("%s", 0, 0, 3, 1, 0, 1970), "0";
        is Date::strftime("%s", 0, 0, 3, 1, 0, 1970, -1, $zone), "10800";
        is Date::strftime("%T", 61), "03:01:01";
        is Date::strftime("%T", 61, $zone), "00:01:01";
    }
};

done_testing();
