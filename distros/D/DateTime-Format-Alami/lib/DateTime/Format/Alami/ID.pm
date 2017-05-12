package DateTime::Format::Alami::ID;

our $DATE = '2017-04-25'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.014000;
use strict;
use warnings;

# XXX holidays -> christmas | new year | ...
# XXX WIB in time, e.g. 13.00 WIB
# XXX *se*minggu (instead of 1 minggu), etc

use Parse::Number::ID qw(parse_number_id);

sub o_num       { $Parse::Number::ID::Pat }
sub _parse_num  { parse_number_id(text => $_[1]) }
sub w_year      { ["tahun", "thn", "th"] }
sub w_month     { ["bulan", "bul", "bln", "bl"] }
sub w_week      { ["minggu", "mgg", "mg"] }
sub w_day       { ["hari", "hr", "h"] }
sub w_hour      { ["jam", "j"] }
sub w_minute    { ["menit", "mnt"] }
sub w_second    { ["detik", "det", "dtk", "dt"] }

sub w_jan       { ["januari", "jan"] }
sub w_feb       { ["februari", "pebruari", "feb", "peb"] }
sub w_mar       { ["maret", "mar"] }
sub w_apr       { ["april", "apr"] }
sub w_may       { ["mei"] }
sub w_jun       { ["juni", "jun"] }
sub w_jul       { ["juli", "jul"] }
sub w_aug       { ["agustus", "agu", "agt"] }
sub w_sep       { ["september", "sept", "sep"] }
sub w_oct       { ["oktober", "okt"] }
sub w_nov       { ["november", "nopember", "nov", "nop"] }
sub w_dec       { ["desember", "des"] }

sub w_monday    { ["senin", "sen"] }
sub w_tuesday   { ["selasa", "sel"] }
sub w_wednesday { ["rabu", "rab"] }
sub w_thursday  { ["kamis", "kam"] }
sub w_friday    { ["jumat", "jum'at", "jum"] }
sub w_saturday  { ["sabtu", "sab"] }
sub w_sunday    { ["minggu", "min"] }

sub p_now            { "(?:saat \\s+ ini|sekarang|skrg?)" }
sub p_today          { "(?:hari \\s+ ini)" }
sub p_tomorrow       { "(?:b?esok|bsk)" }
sub p_yesterday      { "(?:kemar[ei]n|kmrn)" }
sub p_dateymd        { join(
    # we use the 'local' trick here in embedded code (see perlre) to be
    # backtrack-safe. we want to unset $m->{o_yearint} when date does not
    # contain year. $m->{o_yearint} might be set when we try the patterns but
    # might end up needing to be unset if the matching pattern ends up not
    # having year.
    "",
    '(?{ $DateTime::Format::Alami::_has_year = 0 })',
    '(?: <o_dayint>(?:\s+|-|/)?<o_monthname> | <o_dayint>(?:\s+|-|/)<o_monthint>\b )',
    '(?: \s*[,/-]?\s* <o_yearint>  (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }))?',
    '(?{ delete $DateTime::Format::Alami::m->{o_yearint} unless $DateTime::Format::Alami::_has_year })',
)}

sub p_dateym        { join(
    "",
    '(?: <o_monthname> )',
    '(?: (?:\s*[,/-]?\s* <o_year4int> | \s*\'<o_year2int>\\b) (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }) )',
)}

sub p_dur_ago        { "<o_dur> \\s+ (?:(?:(?:yang|yg) \\s+)?lalu|tadi|td|yll?)" }
sub p_dur_later      { "<o_dur> \\s+ (?:(?:(?:yang|yg) \\s+)?akan \\s+ (?:datang|dtg)|yad|lagi|lg)" }

sub p_which_dow    { join(
    "",
    '(?{ $DateTime::Format::Alami::_offset = 0 })',
    "(?:",
    '  <o_dow>',
    '  (?: (?:\s+ (?:(?:minggu|mgg|mg)\s+)? (?:lalu))(?{ local $DateTime::Format::Alami::_offset = -1 }) | (?:\s+ (?:(?:minggu|mgg|mg)\s+)? (?:depan|dpn))(?{ local $DateTime::Format::Alami::_offset = 1 }) | (?:\s+ (?:(?:minggu|mgg|mg)\s+)? ini)?)',
    ")",
    '(?{ $DateTime::Format::Alami::m->{offset} = $DateTime::Format::Alami::_offset })',
)}

sub o_date           { "(?: <p_which_dow>|<p_today>|<p_tomorrow>|<p_yesterday>|<p_dateymd>)" }
sub p_time           { "(?: <o_hour>[:.]<o_minute>(?: [:.]<o_second>)?)" }
sub p_date_time      { "(?:<o_date> \\s+ (?:(?:pada \\s+)? (jam|j|pukul|pkl?)\\s*)? <p_time>)" }

# the ordering is a bit weird because: we need to apply role at compile-time
# before the precomputed $RE mentions $o & $m thus creating the package
# DateTime::Format::Alami and this makes Role::Tiny::With complains that DT:F:A
# is not a role. then, if we are to apply the role, we need to already declare
# the methods required by the role.

use Role::Tiny::With;
BEGIN { with 'DateTime::Format::Alami' };

our $RE_DT  = qr((?&top)(?(DEFINE)(?<top>(?&p_date_time)|(?&p_dur_later)|(?&p_dateym)|(?&p_dur_ago)|(?&p_time)|(?&p_which_dow)|(?&p_today)|(?&p_tomorrow)|(?&p_yesterday)|(?&p_dateymd)|(?&p_now))(?<p_date_time> (\b (?:(?&o_date) \s+ (?:(?:pada \s+)? (jam|j|pukul|pkl?)\s*)? (?&p_time)) \b)(?{ $DateTime::Format::Alami::m->{p_date_time} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_date_time"; $DateTime::Format::Alami::o->a_date_time($DateTime::Format::Alami::m) }))(?<p_dur_later> (\b (?&o_dur) \s+ (?:(?:(?:yang|yg) \s+)?akan \s+ (?:datang|dtg)|yad|lagi|lg) \b)(?{ $DateTime::Format::Alami::m->{p_dur_later} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dur_later"; $DateTime::Format::Alami::o->a_dur_later($DateTime::Format::Alami::m) }))(?<p_dateym> (\b (?: (?&o_monthname) )(?: (?:\s*[,/-]?\s* (?&o_year4int) | \s*'(?&o_year2int)\b) (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }) ) \b)(?{ $DateTime::Format::Alami::m->{p_dateym} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dateym"; $DateTime::Format::Alami::o->a_dateym($DateTime::Format::Alami::m) }))(?<p_dur_ago> (\b (?&o_dur) \s+ (?:(?:(?:yang|yg) \s+)?lalu|tadi|td|yll?) \b)(?{ $DateTime::Format::Alami::m->{p_dur_ago} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dur_ago"; $DateTime::Format::Alami::o->a_dur_ago($DateTime::Format::Alami::m) }))(?<o_date> ((?: (?&p_which_dow)|(?&p_today)|(?&p_tomorrow)|(?&p_yesterday)|(?&p_dateymd)))(?{ $DateTime::Format::Alami::m->{o_date} = $^N }))(?<p_time> (\b (?: (?&o_hour)[:.](?&o_minute)(?: [:.](?&o_second))?) \b)(?{ $DateTime::Format::Alami::m->{p_time} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_time"; $DateTime::Format::Alami::o->a_time($DateTime::Format::Alami::m) }))(?<o_year4int> ((?:[0-9]{4}))(?{ $DateTime::Format::Alami::m->{o_year4int} = $^N }))(?<o_year2int> ((?:[0-9]{2}))(?{ $DateTime::Format::Alami::m->{o_year2int} = $^N }))(?<o_dur> ((?:((?:[+-]?(?:\d{1,2}(?:[.]\d{3})*(?:[,]\d*)?|\d{1,2}(?:[,]\d{3})*(?:[.]\d*)?|[,.]\d+|\d+)(?:[Ee][+-]?\d+)?)\s*(?:tahun|thn|th|bulan|bul|bln|bl|minggu|mgg|mg|hari|hr|h|jam|j|menit|mnt|detik|det|dtk|dt)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{o_dur} = $^N }))(?<p_which_dow> (\b (?{ $DateTime::Format::Alami::_offset = 0 })(?:  (?&o_dow)  (?: (?:\s+ (?:(?:minggu|mgg|mg)\s+)? (?:lalu))(?{ local $DateTime::Format::Alami::_offset = -1 }) | (?:\s+ (?:(?:minggu|mgg|mg)\s+)? (?:depan|dpn))(?{ local $DateTime::Format::Alami::_offset = 1 }) | (?:\s+ (?:(?:minggu|mgg|mg)\s+)? ini)?))(?{ $DateTime::Format::Alami::m->{offset} = $DateTime::Format::Alami::_offset }) \b)(?{ $DateTime::Format::Alami::m->{p_which_dow} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_which_dow"; $DateTime::Format::Alami::o->a_which_dow($DateTime::Format::Alami::m) }))(?<p_today> (\b (?:hari \s+ ini) \b)(?{ $DateTime::Format::Alami::m->{p_today} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_today"; $DateTime::Format::Alami::o->a_today($DateTime::Format::Alami::m) }))(?<p_tomorrow> (\b (?:b?esok|bsk) \b)(?{ $DateTime::Format::Alami::m->{p_tomorrow} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_tomorrow"; $DateTime::Format::Alami::o->a_tomorrow($DateTime::Format::Alami::m) }))(?<p_yesterday> (\b (?:kemar[ei]n|kmrn) \b)(?{ $DateTime::Format::Alami::m->{p_yesterday} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_yesterday"; $DateTime::Format::Alami::o->a_yesterday($DateTime::Format::Alami::m) }))(?<p_dateymd> (\b (?{ $DateTime::Format::Alami::_has_year = 0 })(?: (?&o_dayint)(?:\s+|-|/)?(?&o_monthname) | (?&o_dayint)(?:\s+|-|/)(?&o_monthint)\b )(?: \s*[,/-]?\s* (?&o_yearint)  (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }))?(?{ delete $DateTime::Format::Alami::m->{o_yearint} unless $DateTime::Format::Alami::_has_year }) \b)(?{ $DateTime::Format::Alami::m->{p_dateymd} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dateymd"; $DateTime::Format::Alami::o->a_dateymd($DateTime::Format::Alami::m) }))(?<o_hour> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_hour} = $^N }))(?<o_minute> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_minute} = $^N }))(?<o_second> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_second} = $^N }))(?<o_dow> ((?:senin|sen|selasa|sel|rabu|rab|kamis|kam|jumat|jum'at|jum|sabtu|sab|minggu|min))(?{ $DateTime::Format::Alami::m->{o_dow} = $^N }))(?<o_monthname> ((?:januari|jan|februari|pebruari|feb|peb|maret|mar|april|apr|mei|juni|jun|juli|jul|agustus|agu|agt|september|sept|sep|oktober|okt|november|nopember|nov|nop|desember|des))(?{ $DateTime::Format::Alami::m->{o_monthname} = $^N }))(?<o_dayint> ((?:[12][0-9]|3[01]|0?[1-9]))(?{ $DateTime::Format::Alami::m->{o_dayint} = $^N }))(?<o_monthint> ((?:0?[1-9]|1[012]))(?{ $DateTime::Format::Alami::m->{o_monthint} = $^N }))(?<o_yearint> ((?:[0-9]{4}|[0-9]{2}))(?{ $DateTime::Format::Alami::m->{o_yearint} = $^N }))(?<o_timedur> ((?:((?:[+-]?(?:\d{1,2}(?:[.]\d{3})*(?:[,]\d*)?|\d{1,2}(?:[,]\d{3})*(?:[.]\d*)?|[,.]\d+|\d+)(?:[Ee][+-]?\d+)?)\s*(?:jam|j|menit|mnt|detik|det|dtk|dt)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{o_timedur} = $^N }))(?<p_now> (\b (?:saat \s+ ini|sekarang|skrg?) \b)(?{ $DateTime::Format::Alami::m->{p_now} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_now"; $DateTime::Format::Alami::o->a_now($DateTime::Format::Alami::m) }))(?<o_num> ((?:[+-]?(?:\d{1,2}(?:[.]\d{3})*(?:[,]\d*)?|\d{1,2}(?:[,]\d{3})*(?:[.]\d*)?|[,.]\d+|\d+)(?:[Ee][+-]?\d+)?))(?{ $DateTime::Format::Alami::m->{o_num} = $^N }))(?<o_durwords> ((?:tahun|thn|th|bulan|bul|bln|bl|minggu|mgg|mg|hari|hr|h|jam|j|menit|mnt|detik|det|dtk|dt))(?{ $DateTime::Format::Alami::m->{o_durwords} = $^N }))(?<o_timedurwords> ((?:jam|j|menit|mnt|detik|det|dtk|dt))(?{ $DateTime::Format::Alami::m->{o_timedurwords} = $^N }))))ix; # PRECOMPUTED FROM: do { DateTime::Format::Alami::ID->new; $DateTime::Format::Alami::ID::RE_DT  }
our $RE_DUR = qr((?&top)(?(DEFINE)(?<top>(?&pdur_dur))(?<pdur_dur> (\b (?:(?&odur_dur)) \b)(?{ $DateTime::Format::Alami::m->{pdur_dur} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "pdur_dur"; $DateTime::Format::Alami::o->adur_dur($DateTime::Format::Alami::m) }))(?<odur_dur> ((?:((?:[+-]?(?:\d{1,2}(?:[.]\d{3})*(?:[,]\d*)?|\d{1,2}(?:[,]\d{3})*(?:[.]\d*)?|[,.]\d+|\d+)(?:[Ee][+-]?\d+)?)\s*(?:tahun|thn|th|bulan|bul|bln|bl|minggu|mgg|mg|hari|hr|h|jam|j|menit|mnt|detik|det|dtk|dt)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{odur_dur} = $^N }))))ix; # PRECOMPUTED FROM: do { DateTime::Format::Alami::ID->new; $DateTime::Format::Alami::ID::RE_DUR }
our $MAPS   = {dow=>{jum=>5,"jum'at"=>5,jumat=>5,kam=>4,kamis=>4,min=>7,minggu=>7,rab=>3,rabu=>3,sab=>6,sabtu=>6,sel=>2,selasa=>2,sen=>1,senin=>1},months=>{agt=>8,agu=>8,agustus=>8,apr=>4,april=>4,des=>12,desember=>12,feb=>2,februari=>2,jan=>1,januari=>1,jul=>7,juli=>7,jun=>6,juni=>6,mar=>3,maret=>3,mei=>5,nop=>11,nopember=>11,nov=>11,november=>11,okt=>10,oktober=>10,peb=>2,pebruari=>2,sep=>9,sept=>9,september=>9}}; # PRECOMPUTED FROM: do { DateTime::Format::Alami::ID->new; $DateTime::Format::Alami::ID::MAPS   }

1;
# ABSTRACT: Parse human date/time/duration expression (Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Alami::ID - Parse human date/time/duration expression (Indonesian)

=head1 VERSION

This document describes version 0.14 of DateTime::Format::Alami::ID (from Perl distribution DateTime-Format-Alami), released on 2017-04-25.

=head1 DESCRIPTION

List of known date/time expressions:

 # p_now
 sekarang
 saat ini

 # p_today
 hari ini

 # p_tomorrow
 besok

 # p_yesterday
 kemarin

 # p_dur_ago, p_dur_later
 1 tahun 2 bulan 3 minggu 4 hari 5 jam 6 menit 7 detik (lalu|lagi|nanti|yang akan datang)

 # p_dateymd
 28 mei
 28/5
 28 mei 2016
 28-5-2016
 28-5-16

 # p_dateym
 apr 2017
 mei-2018
 jun '17

 # p_which_dow
 senin (minggu|mgg)? (ini|lalu|depan)

 # p_time
 (pukul|jam)? 10.00
 23:05:44

 # p_date_time
 24 juni pk 13.00
 24 juni 2015 13:00

List of known duration expressions:

 # pdur_dur
 1 tahun 2 bulan 3 minggu 4 hari 5 jam 6 menit 7 detik

=for Pod::Coverage ^((adur|a|pdur|p|odur|o|w)_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-Alami>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-Alami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Alami>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Format::Indonesian>

L<Date::Extract::ID>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
