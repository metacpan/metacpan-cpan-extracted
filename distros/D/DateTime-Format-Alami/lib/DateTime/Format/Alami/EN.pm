package DateTime::Format::Alami::EN;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.16'; # VERSION

use 5.014000;
use strict;
use warnings;

use Parse::Number::EN qw(parse_number_en);

sub o_num       { $Parse::Number::EN::Pat }
sub _parse_num  { parse_number_en(text => $_[1]) }
sub w_year      { ["year", "years", "y"] }
sub w_month     { ["month", "months", "mon"] }
sub w_week      { ["week", "weeks", "wk", "wks"] }
sub w_day       { ["day", "days", "d"] }
sub w_hour      { ["hour", "hours", "h"] }
sub w_minute    { ["minute", "minutes", "min", "mins"] }
sub w_second    { ["second", "seconds", "sec", "secs", "s"] }

sub w_jan       { ["january", "jan"] }
sub w_feb       { ["february", "feb"] }
sub w_mar       { ["march", "mar"] }
sub w_apr       { ["april", "apr"] }
sub w_may       { ["may"] }
sub w_jun       { ["june", "jun"] }
sub w_jul       { ["july", "jul"] }
sub w_aug       { ["august", "aug"] }
sub w_sep       { ["september", "sept", "sep"] }
sub w_oct       { ["october", "oct"] }
sub w_nov       { ["november", "nov"] }
sub w_dec       { ["december", "dec"] }

sub w_monday    { ["monday", "mon"] }
sub w_tuesday   { ["tuesday", "tue"] }
sub w_wednesday { ["wednesday", "wed"] }
sub w_thursday  { ["thursday", "thu"] }
sub w_friday    { ["friday", "fri"] }
sub w_saturday  { ["saturday", "sat"] }
sub w_sunday    { ["sunday", "sun"] }

sub p_now          { "(?:(?:(?:right|just) \\s+ )?now|immediately)" }
sub p_today        { "(?:today|this \\s+ day)" }
sub p_tomorrow     { "(?:tomorrow|tom)" }
sub p_yesterday    { "(?:yesterday|yest)" }

sub o_cardinal_suffix { '(?:\s*(?:th|nd|st))' }

sub p_dateymd      { join(
    # we use the 'local' trick here in embedded code (see perlre) to be
    # backtrack-safe. we want to unset $m->{o_yearint} when date does not
    # contain year. $m->{o_yearint} might be set when we try the patterns but
    # might end up needing to be unset if the matching pattern ends up not
    # having year.
    "",
    '(?{ $DateTime::Format::Alami::_has_year = 0 })',
    '(?: <o_dayint><o_cardinal_suffix>? (?:\\s*|[ /-]) <o_monthname> | <o_monthname> (?:\\s*|[ /-]) <o_dayint><o_cardinal_suffix>?\\b | <o_monthint>[/-]<o_dayint>\\b )',
    '(?: \\s*[,/-]?\\s* <o_yearint> (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }))?',
    '(?{ delete $DateTime::Format::Alami::m->{o_yearint} unless $DateTime::Format::Alami::_has_year })',
)}

sub p_dateym      { join(
    "",
    '(?: <o_monthname> )',
    '(?:\s*[,/-]?\s* <o_year4int> | \s*\'<o_year2int>)',
)}

sub p_dur_ago      { "<o_dur> \\s+ (?:ago)" }
sub p_dur_later    { "<o_dur> \\s+ (?:later) | in \\s+ <o_dur>" }

sub p_which_dow    { join(
    "",
    '(?{ $DateTime::Format::Alami::_offset = 0 })',
    "(?:",
    '  (?: (?:last \s+)(?{ local $DateTime::Format::Alami::_offset = -1 }) | (?:next \s+)(?{ local $DateTime::Format::Alami::_offset = 1 }) | (?:this \s+)?)',
    '  <o_dow>',
    ")",
    '(?{ $DateTime::Format::Alami::m->{offset} = $DateTime::Format::Alami::_offset })',
)}

sub o_date         { "(?: <p_which_dow>|<p_today>|<p_tomorrow>|<p_yesterday>|<p_dateymd>)" }
sub o_ampm         { "(?: am|pm)" }
sub p_time         { "(?: <o_hour>[:.]<o_minute>(?: [:.]<o_second>)? \\s* <o_ampm>?)" } # XXX am/pm
sub p_date_time    { "(?:<o_date> \\s+ (?:(?:on|at) \\s+)? <p_time>)" }

# the ordering is a bit weird because: we need to apply role at compile-time
# before the precomputed $RE mentions $o & $m thus creating the package
# DateTime::Format::Alami and this makes Role::Tiny::With complains that DT:F:A
# is not a role. then, if we are to apply the role, we need to already declare
# the methods required by the role.

use Role::Tiny::With;
BEGIN { with 'DateTime::Format::Alami' };

our $RE_DT  = qr((?&top)(?(DEFINE)(?<top>(?&p_dur_later)|(?&p_dateym)|(?&p_date_time)|(?&p_dur_ago)|(?&p_time)|(?&p_which_dow)|(?&p_today)|(?&p_tomorrow)|(?&p_yesterday)|(?&p_dateymd)|(?&p_now))(?<p_dur_later> (\b (?&o_dur) \s+ (?:later) | in \s+ (?&o_dur) \b)(?{ $DateTime::Format::Alami::m->{p_dur_later} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dur_later"; $DateTime::Format::Alami::o->a_dur_later($DateTime::Format::Alami::m) }))(?<p_dateym> (\b (?: (?&o_monthname) )(?:\s*[,/-]?\s* (?&o_year4int) | \s*'(?&o_year2int)) \b)(?{ $DateTime::Format::Alami::m->{p_dateym} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dateym"; $DateTime::Format::Alami::o->a_dateym($DateTime::Format::Alami::m) }))(?<p_date_time> (\b (?:(?&o_date) \s+ (?:(?:on|at) \s+)? (?&p_time)) \b)(?{ $DateTime::Format::Alami::m->{p_date_time} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_date_time"; $DateTime::Format::Alami::o->a_date_time($DateTime::Format::Alami::m) }))(?<p_dur_ago> (\b (?&o_dur) \s+ (?:ago) \b)(?{ $DateTime::Format::Alami::m->{p_dur_ago} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dur_ago"; $DateTime::Format::Alami::o->a_dur_ago($DateTime::Format::Alami::m) }))(?<o_year4int> ((?:[0-9]{4}))(?{ $DateTime::Format::Alami::m->{o_year4int} = $^N }))(?<o_year2int> ((?:[0-9]{2}))(?{ $DateTime::Format::Alami::m->{o_year2int} = $^N }))(?<o_date> ((?: (?&p_which_dow)|(?&p_today)|(?&p_tomorrow)|(?&p_yesterday)|(?&p_dateymd)))(?{ $DateTime::Format::Alami::m->{o_date} = $^N }))(?<p_time> (\b (?: (?&o_hour)[:.](?&o_minute)(?: [:.](?&o_second))? \s* (?&o_ampm)?) \b)(?{ $DateTime::Format::Alami::m->{p_time} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_time"; $DateTime::Format::Alami::o->a_time($DateTime::Format::Alami::m) }))(?<o_dur> ((?:((?:[+-]?(?:(?:\d{1,3}(?:[,]\d{3})+|\d+)(?:[.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?)\s*(?:year|years|y|month|months|mon|week|weeks|wk|wks|day|days|d|hour|hours|h|minute|minutes|min|mins|second|seconds|sec|secs|s)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{o_dur} = $^N }))(?<p_which_dow> (\b (?{ $DateTime::Format::Alami::_offset = 0 })(?:  (?: (?:last \s+)(?{ local $DateTime::Format::Alami::_offset = -1 }) | (?:next \s+)(?{ local $DateTime::Format::Alami::_offset = 1 }) | (?:this \s+)?)  (?&o_dow))(?{ $DateTime::Format::Alami::m->{offset} = $DateTime::Format::Alami::_offset }) \b)(?{ $DateTime::Format::Alami::m->{p_which_dow} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_which_dow"; $DateTime::Format::Alami::o->a_which_dow($DateTime::Format::Alami::m) }))(?<p_today> (\b (?:today|this \s+ day) \b)(?{ $DateTime::Format::Alami::m->{p_today} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_today"; $DateTime::Format::Alami::o->a_today($DateTime::Format::Alami::m) }))(?<p_tomorrow> (\b (?:tomorrow|tom) \b)(?{ $DateTime::Format::Alami::m->{p_tomorrow} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_tomorrow"; $DateTime::Format::Alami::o->a_tomorrow($DateTime::Format::Alami::m) }))(?<p_yesterday> (\b (?:yesterday|yest) \b)(?{ $DateTime::Format::Alami::m->{p_yesterday} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_yesterday"; $DateTime::Format::Alami::o->a_yesterday($DateTime::Format::Alami::m) }))(?<p_dateymd> (\b (?{ $DateTime::Format::Alami::_has_year = 0 })(?: (?&o_dayint)(?&o_cardinal_suffix)? (?:\s*|[ /-]) (?&o_monthname) | (?&o_monthname) (?:\s*|[ /-]) (?&o_dayint)(?&o_cardinal_suffix)?\b | (?&o_monthint)[/-](?&o_dayint)\b )(?: \s*[,/-]?\s* (?&o_yearint) (?{ local $DateTime::Format::Alami::_has_year = $DateTime::Format::Alami::_has_year + 1 }))?(?{ delete $DateTime::Format::Alami::m->{o_yearint} unless $DateTime::Format::Alami::_has_year }) \b)(?{ $DateTime::Format::Alami::m->{p_dateymd} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_dateymd"; $DateTime::Format::Alami::o->a_dateymd($DateTime::Format::Alami::m) }))(?<o_hour> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_hour} = $^N }))(?<o_minute> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_minute} = $^N }))(?<o_second> ((?:[0-9][0-9]?))(?{ $DateTime::Format::Alami::m->{o_second} = $^N }))(?<o_ampm> ((?: am|pm))(?{ $DateTime::Format::Alami::m->{o_ampm} = $^N }))(?<o_dow> ((?:monday|mon|tuesday|tue|wednesday|wed|thursday|thu|friday|fri|saturday|sat|sunday|sun))(?{ $DateTime::Format::Alami::m->{o_dow} = $^N }))(?<o_monthname> ((?:january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec))(?{ $DateTime::Format::Alami::m->{o_monthname} = $^N }))(?<o_cardinal_suffix> ((?:\s*(?:th|nd|st)))(?{ $DateTime::Format::Alami::m->{o_cardinal_suffix} = $^N }))(?<o_monthint> ((?:0?[1-9]|1[012]))(?{ $DateTime::Format::Alami::m->{o_monthint} = $^N }))(?<o_dayint> ((?:[12][0-9]|3[01]|0?[1-9]))(?{ $DateTime::Format::Alami::m->{o_dayint} = $^N }))(?<o_yearint> ((?:[0-9]{4}|[0-9]{2}))(?{ $DateTime::Format::Alami::m->{o_yearint} = $^N }))(?<o_timedur> ((?:((?:[+-]?(?:(?:\d{1,3}(?:[,]\d{3})+|\d+)(?:[.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?)\s*(?:hour|hours|h|minute|minutes|min|mins|second|seconds|sec|secs|s)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{o_timedur} = $^N }))(?<p_now> (\b (?:(?:(?:right|just) \s+ )?now|immediately) \b)(?{ $DateTime::Format::Alami::m->{p_now} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "p_now"; $DateTime::Format::Alami::o->a_now($DateTime::Format::Alami::m) }))(?<o_durwords> ((?:year|years|y|month|months|mon|week|weeks|wk|wks|day|days|d|hour|hours|h|minute|minutes|min|mins|second|seconds|sec|secs|s))(?{ $DateTime::Format::Alami::m->{o_durwords} = $^N }))(?<o_num> ((?:[+-]?(?:(?:\d{1,3}(?:[,]\d{3})+|\d+)(?:[.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?))(?{ $DateTime::Format::Alami::m->{o_num} = $^N }))(?<o_timedurwords> ((?:hour|hours|h|minute|minutes|min|mins|second|seconds|sec|secs|s))(?{ $DateTime::Format::Alami::m->{o_timedurwords} = $^N }))))ix; # PRECOMPUTED FROM: do { DateTime::Format::Alami::EN->new; $DateTime::Format::Alami::EN::RE_DT  }
our $RE_DUR = qr((?&top)(?(DEFINE)(?<top>(?&pdur_dur))(?<pdur_dur> (\b (?:(?&odur_dur)) \b)(?{ $DateTime::Format::Alami::m->{pdur_dur} = $^N })(?{ $DateTime::Format::Alami::o->{_pat} = "pdur_dur"; $DateTime::Format::Alami::o->adur_dur($DateTime::Format::Alami::m) }))(?<odur_dur> ((?:((?:[+-]?(?:(?:\d{1,3}(?:[,]\d{3})+|\d+)(?:[.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?)\s*(?:year|years|y|month|months|mon|week|weeks|wk|wks|day|days|d|hour|hours|h|minute|minutes|min|mins|second|seconds|sec|secs|s)\s*(?:,\s*)?)+))(?{ $DateTime::Format::Alami::m->{odur_dur} = $^N }))))ix; # PRECOMPUTED FROM: do { DateTime::Format::Alami::EN->new; $DateTime::Format::Alami::EN::RE_DUR }
our $MAPS   = {dow=>{fri=>5,friday=>5,mon=>1,monday=>1,sat=>6,saturday=>6,sun=>7,sunday=>7,thu=>4,thursday=>4,tue=>2,tuesday=>2,wed=>3,wednesday=>3},months=>{apr=>4,april=>4,aug=>8,august=>8,dec=>12,december=>12,feb=>2,february=>2,jan=>1,january=>1,jul=>7,july=>7,jun=>6,june=>6,mar=>3,march=>3,may=>5,nov=>11,november=>11,oct=>10,october=>10,sep=>9,sept=>9,september=>9}}; # PRECOMPUTED FROM: do { DateTime::Format::Alami::EN->new; $DateTime::Format::Alami::EN::MAPS   }

1;
# ABSTRACT: Parse human date/time/duration expression (English)

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Alami::EN - Parse human date/time/duration expression (English)

=head1 VERSION

This document describes version 0.16 of DateTime::Format::Alami::EN (from Perl distribution DateTime-Format-Alami), released on 2017-07-10.

=head1 DESCRIPTION

List of known date/time expressions:

 # p_now
 (just|right)? now

 # p_today
 today|this day

 # p_tomorrow
 tommorow

 # p_yesterday
 yesterday

 # p_dur_ago, p_dur_later
 1 year 2 months 3 weeks 4 days 5 hours 6 minutes 7 seconds (ago|later)

 # p_dateymd
 may 28
 5/28
 28 may 2016
 may 28, 2016
 5/28/2016
 5-28-16

 # p_dateym
 apr 2017
 may-2018
 jun '17

 # p_which_dow
 (this|last|next) monday

 # p_time
 2pm
 3.45 am
 (on|at)? 15:00

 # p_date_time
 june 25 2pm
 2016-06-25 10:00:00

List of known duration expressions:

 # pdur_dur
 1 year 2 months 3 weeks 4 days 5 hours 6 minutes 7 seconds

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

L<DateTime::Format::Natural>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
