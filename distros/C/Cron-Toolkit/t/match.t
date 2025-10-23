#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Time::Moment;
use Cron::Toolkit;

sub utc_epoch {
    my (%components) = @_;
    return Time::Moment->new(%components)->epoch;
}

#plan tests => 38;

# Existing tests (1-34)
my $cron_utc = Cron::Toolkit->new(expression => "0 30 14 * * ?");
is $cron_utc->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 14, minute => 30, second => 0)), 1, "1. UTC 14:30";
is $cron_utc->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 14, minute => 31, second => 0)), 0, "2. UTC 14:31";

my $cron_ny = Cron::Toolkit->new(expression => "0 30 14 * * ?", utc_offset => -300);
is $cron_ny->utc_offset, -300, "3. NY offset";
is $cron_ny->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 19, minute => 30, second => 0)), 1, "4. NY 14:30";

my $step_cron = Cron::Toolkit->new(expression => "*/15 * * * * ?");
is $step_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 12, minute => 0, second => 0)), 1, "5. step 0";
is $step_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 12, minute => 15, second => 0)), 1, "6. step 15";
is $step_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 12, minute => 0, second => 7)), 0, "7. step 7";

my $range_cron = Cron::Toolkit->new(expression => "0 0 10-14 * * ?");
is $range_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 12, minute => 0, second => 0)), 1, "8. range 12";
is $range_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 9, minute => 0, second => 0)), 0, "9. range 9";

my $list_cron = Cron::Toolkit->new(expression => "0 0 0 1,15 * * ?");
is $list_cron->is_match(utc_epoch(year => 2023, month => 10, day => 1, hour => 0, minute => 0, second => 0)), 1, "10. list 1";
is $list_cron->is_match(utc_epoch(year => 2023, month => 10, day => 15, hour => 0, minute => 0, second => 0)), 1, "11. list 15";
is $list_cron->is_match(utc_epoch(year => 2023, month => 10, day => 10, hour => 0, minute => 0, second => 0)), 0, "12. list 10";

my $dow_cron = Cron::Toolkit->new(expression => "0 0 0 * * 2 ?");
is $dow_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 0, minute => 0, second => 0)), 1, "13. Monday";

my $dow_q_cron = Cron::Toolkit->new(expression => "0 0 0 * * ? *");
is $dow_q_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 0, minute => 0, second => 0)), 1, "14. DOW ?";

my $last_cron = Cron::Toolkit->new(expression => "0 0 0 L * ? *");
is $last_cron->is_match(utc_epoch(year => 2023, month => 10, day => 31, hour => 0, minute => 0, second => 0)), 1, "15. Oct 31 last";
is $last_cron->is_match(utc_epoch(year => 2023, month => 10, day => 30, hour => 0, minute => 0, second => 0)), 0, "16. Oct 30 not last";

my $l2_cron = Cron::Toolkit->new(expression => "0 0 0 L-2 * ? *");
is $l2_cron->is_match(utc_epoch(year => 2023, month => 10, day => 29, hour => 0, minute => 0, second => 0)), 1, "17. L-2 Oct 29";

my $lw_cron = Cron::Toolkit->new(expression => "0 0 0 LW * ? *");
is $lw_cron->is_match(utc_epoch(year => 2023, month => 10, day => 31, hour => 0, minute => 0, second => 0)), 1, "18. LW Oct 31";

my $nth_cron = Cron::Toolkit->new(expression => "0 0 0 * * 1#2 ?");
is $nth_cron->is_match(utc_epoch(year => 2023, month => 10, day => 8, hour => 0, minute => 0, second => 0)), 1, "19. 2nd Sunday";

my $nw_cron = Cron::Toolkit->new(expression => "0 0 0 16W * ? *");
is $nw_cron->is_match(utc_epoch(year => 2023, month => 10, day => 16, hour => 0, minute => 0, second => 0)), 1, "20. 16W Oct 16";

# Tests for next(), previous(), and next_n()
is $cron_utc->next(utc_epoch(year => 2023, month => 10, day => 16, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 10, day => 16, hour => 14, minute => 30, second => 0),
   "21. next: Oct 16 10:00 -> Oct 16 14:30";

is $cron_utc->previous(utc_epoch(year => 2023, month => 10, day => 16, hour => 15, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 10, day => 15, hour => 14, minute => 30, second => 0),
   "22. previous: Oct 16 15:00 -> Oct 15 14:30";

is $cron_utc->next(utc_epoch(year => 2023, month => 10, day => 31, hour => 23, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 11, day => 1, hour => 14, minute => 30, second => 0),
   "23. next: Oct 31 23:00 -> Nov 1 14:30";

is $last_cron->next(utc_epoch(year => 2023, month => 10, day => 31, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 11, day => 30, hour => 0, minute => 0, second => 0),
   "24. next: Oct 31 10:00 (L) -> Nov 30 00:00";

is $nth_cron->next(utc_epoch(year => 2023, month => 10, day => 8, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 11, day => 12, hour => 0, minute => 0, second => 0),
   "25. next: Oct 8 10:00 (1#2) -> Nov 12 00:00 (2nd Sunday)";

is $cron_ny->next(utc_epoch(year => 2023, month => 10, day => 16, hour => 15, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 10, day => 16, hour => 19, minute => 30, second => 0),
   "26. next: NY Oct 16 10:00 -> NY Oct 16 14:30";

is $cron_utc->next(utc_epoch(year => 2023, month => 10, day => 16, hour => 14, minute => 30, second => 7)),
   utc_epoch(year => 2023, month => 10, day => 17, hour => 14, minute => 30, second => 0),
   "27. next: Oct 16 14:30:07 (0 30 14) -> Oct 17 14:30";

is $lw_cron->next(utc_epoch(year => 2023, month => 10, day => 14, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 10, day => 31, hour => 0, minute => 0, second => 0),
   "28. next: Oct 14 (Sat) (LW) -> Oct 31 00:00";

is $nw_cron->next(utc_epoch(year => 2023, month => 10, day => 15, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 10, day => 16, hour => 0, minute => 0, second => 0),
   "29. next: Oct 15 (Sun) (15W) -> Oct 16 00:00 (Mon)";

my $every_cron = Cron::Toolkit->new(expression => "* * * * * ? *");
is $every_cron->next(utc_epoch(year => 2023, month => 12, day => 25, hour => 10, minute => 0, second => 0)),
   utc_epoch(year => 2023, month => 12, day => 25, hour => 10, minute => 0, second => 1),
   "30. next: Dec 25 10:00:00 (every second) -> 10:00:01";

is_deeply $cron_utc->next_n(utc_epoch(year => 2023, month => 10, day => 16, hour => 10, minute => 0, second => 0), 3),
   [ utc_epoch(year => 2023, month => 10, day => 16, hour => 14, minute => 30, second => 0),
     utc_epoch(year => 2023, month => 10, day => 17, hour => 14, minute => 30, second => 0),
     utc_epoch(year => 2023, month => 10, day => 18, hour => 14, minute => 30, second => 0) ],
   "31. next_n: Oct 16 10:00 -> next 3 at 14:30";

# New tests for no-match and leap year
my $year_constrained = Cron::Toolkit->new(expression => "0 0 0 * * ? 2023");
is $year_constrained->next(utc_epoch(year => 2099, month => 1, day => 1, hour => 0, minute => 0, second => 0)),
   undef,
   "32. next: No match beyond 2023";

my $leap_cron = Cron::Toolkit->new(expression => "0 0 0 29 FEB ? *");
is $leap_cron->next(utc_epoch(year => 2024, month => 2, day => 26, hour => 12, minute => 0, second => 0)),
   utc_epoch(year => 2024, month => 2, day => 29, hour => 0, minute => 0, second => 0),
   "33. next: Feb 28 2024 12:00 -> Feb 29 2024 00:00";

# Robustness test for year boundary
my $year_boundary = Cron::Toolkit->new(expression => "0 0 0 1 JAN ? *");
is $year_boundary->next(utc_epoch(year => 2023, month => 12, day => 31, hour => 23, minute => 0, second => 0)),  # FIXED: month=12 (Dec), not 11
   utc_epoch(year => 2024, month => 1, day => 1, hour => 0, minute => 0, second => 0),
   "34. next: Dec 31 2023 23:00 -> Jan 1 2024 00:00";

# LW fix: Weekend-ending month (2024-06-30=Sun, LW=28=Fri)
my $lw_jun_cron = Cron::Toolkit->new(expression => "0 0 0 LW 6 ? *");
is $lw_jun_cron->is_match(utc_epoch(year => 2024, month => 6, day => 28, hour => 0, minute => 0, second => 0)), 1, "35. LW Jun 2024 28 (Fri)";
is $lw_jun_cron->is_match(utc_epoch(year => 2024, month => 6, day => 29, hour => 0, minute => 0, second => 0)), 0, "36. LW Jun 2024 29 (Sat)";
is $lw_jun_cron->is_match(utc_epoch(year => 2024, month => 6, day => 30, hour => 0, minute => 0, second => 0)), 0, "37. LW Jun 2024 30 (Sun)";

# Wrap-month next() for LW: Oct 31 (Tue) post-match → Nov 30 (Thu)
my $lw_wrap_cron = Cron::Toolkit->new(expression => "0 0 0 LW * ? *");
is $lw_wrap_cron->next(utc_epoch(year => 2023, month => 10, day => 31, hour => 0, minute => 0, second => 1)), 
   utc_epoch(year => 2023, month => 11, day => 30, hour => 0, minute => 0, second => 0), 
   "38. next LW: Oct 31 00:01 → Nov 30 00:00 (wrap-month)";

# Range bounds tests
my $bounded_cron = Cron::Toolkit->new(expression => "0 0 * * * ?");
$bounded_cron->begin_epoch(utc_epoch(year => 2025, month => 1, day => 1));
$bounded_cron->end_epoch(utc_epoch(year => 2025, month => 1, day => 2));
is $bounded_cron->begin_epoch, utc_epoch(year => 2025, month => 1, day => 1), "39. begin_epoch getter returns set value";
is $bounded_cron->end_epoch, utc_epoch(year => 2025, month => 1, day => 2), "40. end_epoch getter returns set value";
is $bounded_cron->next(utc_epoch(year => 2024, month => 12, day => 31, hour => 23, minute => 59, second => 59)), utc_epoch(year => 2025, month => 1, day => 1), "41. next clamped to begin_epoch";
is $bounded_cron->next(utc_epoch(year => 2025, month => 1, day => 2, hour => 0, minute => 0, second => 1)), undef, "42. next after end_epoch returns undef";

subtest 'Phase 2 utils' => sub {
    plan tests => 6;  # Include warn check
    my $cron = Cron::Toolkit->new(expression => '0 0 * * * ?');
    is $cron->as_string, '0 0 * * * ? *', 'as_string normalized';
    like $cron->to_json, qr/"expression":"0 0 \* \* \* \? \*"/, 'to_json expr';
    is_deeply $cron->next_occurrences(1), $cron->next_n(1), 'next_occurrences alias';
    # dump_tree no die (capture output for check)
    local *STDOUT;
    open my $out_fh, '>', \my $out or die $!;
    *STDOUT = $out_fh;
    $cron->dump_tree;
    close $out_fh;
    like $out, qr/Root/, 'dump_tree output';
    # Locale stub (warn expected, but desc still works)
    my $warn;
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    like $cron->describe(locale => 'fr'), qr/AM/, 'locale fallback English desc';  # Matches "12:00:00 AM"
    like $warn // '', qr/Locale 'fr' not supported/, 'locale warn fires';
};

done_testing;
