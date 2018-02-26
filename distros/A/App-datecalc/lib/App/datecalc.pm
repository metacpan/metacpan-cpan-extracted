package App::datecalc;

our $DATE = '2018-02-21'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use MarpaX::Simple qw(gen_parser);
use Scalar::Util qw(blessed);

# XXX there should already be an existing module that does this
sub __fmtduriso {
    my $dur = shift;
    my $res = join(
        '',
        "P",
        ($dur->years  ? $dur->years  . "Y" :  ""),
        ($dur->months ? $dur->months . "M" :  ""),
        ($dur->weeks  ? $dur->weeks  . "W" :  ""),
        ($dur->days   ? $dur->days   . "D" :  ""),
    );
    if ($dur->hours || $dur->minutes || $dur->seconds) {
        $res .= join(
            '',
            'T',
            ($dur->hours   ? $dur->hours   . "H" : ""),
            ($dur->minutes ? $dur->minutes . "M" : ""),
            ($dur->seconds ? $dur->seconds . "S" : ""),
        );
    }

    $res = "P0Y" if $res eq 'P';

    $res;
}

sub new {
    state $parser = gen_parser(
        grammar => <<'_',
:default             ::= action=>::first
lexeme default         = latm=>1
:start               ::= answer

answer               ::= date_expr
                       | dur_expr
#                       | str_expr
                       | num_expr

num_expr             ::= num_add
num_add              ::= num_mult
                       | num_add op_addsub num_add                        action=>num_add
num_mult             ::= num_unary
                       | num_mult op_multdiv num_mult                     action=>num_mult
num_unary            ::= num_pow
                      || op_unary num_unary                               action=>num_unary assoc=>right
num_pow              ::= num_term
                      || num_pow '**' num_pow                             action=>num_pow assoc=>right
num_term             ::= num_literal
                       | func_inum_onum
                       | func_idate_onum
                       | func_idur_onum
                       | ('(') num_expr (')')

date_expr            ::= date_add_dur
date_add_dur         ::= date_term
                       | date_add_dur op_addsub dur_term                  action=>date_add_dur
date_term            ::= date_literal
#                       | date_variable
#                       | func_idate_odate
                       | ('(') date_expr (')')

func_inum_onum_names   ~ 'abs' | 'round'
func_inum_onum       ::= func_inum_onum_names ('(') num_expr (')')        action=>func_inum_onum

func_idate_onum_names  ~ 'year' | 'month' | 'day' | 'dow' | 'quarter'
                       | 'doy' | 'wom' | 'woy' | 'doq'
                       | 'hour' | 'minute' | 'second'
func_idate_onum      ::= func_idate_onum_names ('(') date_expr (')')      action=>func_idate_onum

func_idur_onum_names   ~ 'years' | 'months' | 'weeks' | 'days'
                       | 'hours' | 'minutes' | 'seconds'
                       | 'totdays'
func_idur_onum       ::= func_idur_onum_names ('(') dur_expr (')')        action=>func_idur_onum

date_literal         ::= iso_date_literal                                 action=>datelit_iso
                       | 'now'                                            action=>datelit_special
                       | 'today'                                          action=>datelit_special
                       | 'yesterday'                                      action=>datelit_special
                       | 'tomorrow'                                       action=>datelit_special

year4                  ~ [\d][\d][\d][\d]
mon2                   ~ [\d][\d]
day2                   ~ [\d][\d]
iso_date_literal       ~ year4 '-' mon2 '-' day2

dur_expr             ::= dur_add_dur
                       | date_sub_date
dur_add_dur          ::= dur_mult_num
                       | dur_add_dur op_addsub dur_add_dur                action=>dur_add_dur
date_sub_date        ::= date_add_dur
                       | date_sub_date '-' date_sub_date                  action=>date_sub_date

dur_mult_num         ::= dur_term
                       | dur_mult_num op_multdiv num_expr                 action=>dur_mult_num
                       | num_expr op_mult dur_mult_num                    action=>dur_mult_num
dur_term             ::= dur_literal
#                       | dur_variable
                       | '(' dur_expr ')'
dur_literal          ::= nat_dur_literal
                       | iso_dur_literal

unit_year              ~ 'year' | 'years' | 'y'
unit_month             ~ 'month' | 'months' | 'mon' | 'mons'
unit_week              ~ 'week' | 'weeks' | 'w'
unit_day               ~ 'day' | 'days' | 'd'
unit_hour              ~ 'hour' | 'hours' | 'h'
unit_minute            ~ 'minute' | 'minutes' | 'min' | 'mins'
unit_second            ~ 'second' | 'seconds' | 'sec' | 'secs' | 's'

ndl_year               ~ num ws_opt unit_year
ndl_year_opt           ~ num ws_opt unit_year
ndl_year_opt           ~

ndl_month              ~ num ws_opt unit_month
ndl_month_opt          ~ num ws_opt unit_month
ndl_month_opt          ~

ndl_week               ~ num ws_opt unit_week
ndl_week_opt           ~ num ws_opt unit_week
ndl_week_opt           ~

ndl_day                ~ num ws_opt unit_day
ndl_day_opt            ~ num ws_opt unit_day
ndl_day_opt            ~

ndl_hour               ~ num ws_opt unit_hour
ndl_hour_opt           ~ num ws_opt unit_hour
ndl_hour_opt           ~

ndl_minute             ~ num ws_opt unit_minute
ndl_minute_opt         ~ num ws_opt unit_minute
ndl_minute_opt         ~

ndl_second             ~ num ws_opt unit_second
ndl_second_opt         ~ num ws_opt unit_second
ndl_second_opt         ~

# need at least one element specified. XXX not happy with this
nat_dur_literal      ::= nat_dur_literal0                                 action=>durlit_nat
nat_dur_literal0       ~ ndl_year     ws_opt ndl_month_opt ws_opt ndl_week_opt ws_opt ndl_day_opt ws_opt ndl_hour_opt ws_opt ndl_minute_opt ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month     ws_opt ndl_week_opt ws_opt ndl_day_opt ws_opt ndl_hour_opt ws_opt ndl_minute_opt ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month_opt ws_opt ndl_week     ws_opt ndl_day_opt ws_opt ndl_hour_opt ws_opt ndl_minute_opt ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month_opt ws_opt ndl_week_opt ws_opt ndl_day     ws_opt ndl_hour_opt ws_opt ndl_minute_opt ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month_opt ws_opt ndl_week_opt ws_opt ndl_day_opt ws_opt ndl_hour     ws_opt ndl_minute_opt ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month_opt ws_opt ndl_week_opt ws_opt ndl_day_opt ws_opt ndl_hour_opt ws_opt ndl_minute     ws_opt ndl_second_opt
                       | ndl_year_opt ws_opt ndl_month_opt ws_opt ndl_week_opt ws_opt ndl_day_opt ws_opt ndl_hour_opt ws_opt ndl_minute_opt ws_opt ndl_second

idl_year               ~ posnum 'Y'
idl_year_opt           ~ posnum 'Y'
idl_year_opt           ~

idl_month              ~ posnum 'M'
idl_month_opt          ~ posnum 'M'
idl_month_opt          ~

idl_week               ~ posnum 'W'
idl_week_opt           ~ posnum 'W'
idl_week_opt           ~

idl_day                ~ posnum 'D'
idl_day_opt            ~ posnum 'D'
idl_day_opt            ~

idl_hour               ~ posnum 'H'
idl_hour_opt           ~ posnum 'H'
idl_hour_opt           ~

idl_minute             ~ posnum 'M'
idl_minute_opt         ~ posnum 'M'
idl_minute_opt         ~

idl_second             ~ posnum 'S'
idl_second_opt         ~ posnum 'S'
idl_second_opt         ~

# also need at least one element specified like in nat_dur_literal
iso_dur_literal      ::= iso_dur_literal0                                 action=>durlit_iso
iso_dur_literal0       ~ 'P' idl_year     idl_month_opt idl_week_opt idl_day_opt
                       | 'P' idl_year_opt idl_month     idl_week_opt idl_day_opt
                       | 'P' idl_year_opt idl_month_opt idl_week     idl_day_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour     idl_minute_opt idl_second_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour_opt idl_minute     idl_second_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour_opt idl_minute_opt idl_second

sign                   ~ [+-]
digits                 ~ [\d]+
num_literal            ~ num
num                    ~ digits
                       | sign digits
                       | digits '.' digits
                       | sign digits '.' digits
posnum                 ~ digits
                       | digits '.' digits

op_unary               ~ [+-]
op_addsub              ~ [+-]

op_mult                ~ [*]
op_multdiv             ~ [*/]

:discard               ~ ws
ws                     ~ [\s]+
ws_opt                 ~ [\s]*

_
        actions => {
            datelit_iso => sub {
                my $h = shift;
		my @date = split /-/, $_[0];
                DateTime->new(year=>$date[0], month=>$date[1], day=>$date[2]);
            },
            date_sub_date => sub {
                my $h = shift;
                $_[0]->delta_days($_[2]);
            },
            datelit_special => sub {
                my $h = shift;
                if ($_[0] eq 'now') {
                    DateTime->now;
                } elsif ($_[0] eq 'today') {
                    DateTime->today;
                } elsif ($_[0] eq 'yesterday') {
                    DateTime->today->subtract(days => 1);
                } elsif ($_[0] eq 'tomorrow') {
                    DateTime->today->add(days => 1);
                } else {
                    die "BUG: Unknown date literal '$_[0]'";
                }
            },
            date_add_dur => sub {
                my $h = shift;
                if ($_[1] eq '+') {
                    $_[0] + $_[2];
                } else {
                    $_[0] - $_[2];
                }
            },
            dur_add_dur => sub {
                my $h = shift;
                $_[0] + $_[2];
            },
            dur_mult_num => sub {
                my $h = shift;
                if (ref $_[0]) {
                    my $d0 = $_[0];
                    if ($_[1] eq '*') {
                        # dur*num
                        DateTime::Duration->new(
                            years   => $d0->years   * $_[2],
                            months  => $d0->months  * $_[2],
                            weeks   => $d0->weeks   * $_[2],
                            days    => $d0->days    * $_[2],
                            hours   => $d0->hours   * $_[2],
                            minutes => $d0->minutes * $_[2],
                            seconds => $d0->seconds * $_[2],
                        );
                    } else {
                        # dur/num
                        DateTime::Duration->new(
                            years   => $d0->years   / $_[2],
                            months  => $d0->months  / $_[2],
                            weeks   => $d0->weeks   / $_[2],
                            days    => $d0->days    / $_[2],
                            hours   => $d0->hours   / $_[2],
                            minutes => $d0->minutes / $_[2],
                            seconds => $d0->seconds / $_[2],
                        );
                    }
                } else {
                    my $d0 = $_[2];
                    # num * dur
                    DateTime::Duration->new(
                        years   => $d0->years   * $_[0],
                        months  => $d0->months  * $_[0],
                        weeks   => $d0->weeks   * $_[0],
                        days    => $d0->days    * $_[0],
                        hours   => $d0->hours   * $_[0],
                        minutes => $d0->minutes * $_[0],
                        seconds => $d0->seconds * $_[0],
                    );
                }
            },
            durlit_nat => sub {
                my $h = shift;
                local $_ = $_[0];
                my %params;
                $params{years} = $1 if /(-?\d+(?:\.\d+)?)\s*(years?|y)/;
                $params{months} = $1 if /(-?\d+(?:\.\d+)?)\s*(mons?|months?)/;
                $params{weeks} = $1 if /(-?\d+(?:\.\d+)?)\s*(weeks?|w)/;
                $params{days} = $1 if /(-?\d+(?:\.\d+)?)\s*(days?|d)/;
                $params{hours} = $1 if /(-?\d+(?:\.\d+)?)\s*(hours?|h)/;
                $params{minutes} = $1 if /(-?\d+(?:\.\d+)?)\s*(mins?|minutes?)/;
                $params{seconds} = $1 if /(-?\d+(?:\.\d+)?)\s*(s|secs?|seconds?)/;
                DateTime::Duration->new(%params);
            },
            durlit_iso => sub {
                my $h = shift;
                # split between date and time
                my $d = $_[0] =~ /P(.+?)(?:T|\z)/ ? $1 : '';
                my $t = $_[0] =~ /T(.*)/ ? $1 : '';
                #say "D = $d, T = $t";
                my %params;
                $params{years} = $1 if $d =~ /(-?\d+(?:\.\d+)?)Y/i;
                $params{months} = $1 if $d =~ /(-?\d+(?:\.\d+)?)M/i;
                $params{weeks} = $1 if $d =~ /(-?\d+(?:\.\d+)?)W/;
                $params{days} = $1 if $d =~ /(-?\d+(?:\.\d+)?)D/;
                $params{hours} = $1 if $t =~ /(-?\d+(?:\.\d+)?)H/i;
                $params{minutes} = $1 if $t =~ /(-?\d+(?:\.\d+)?)M/i;
                $params{seconds} = $1 if $t =~ /(-?\d+(?:\.\d+)?)S/i;
                DateTime::Duration->new(%params);
            },
            func_inum_onum => sub {
                my $h = shift;
                my $fn = $_[0];
                my $num = $_[1];
                if ($fn eq 'abs') {
                    abs($num);
                } elsif ($fn eq 'round') {
                    sprintf("%.0f", $num);
                } else {
                    die "BUG: Unknown number function $fn";
                }
            },
            func_idate_onum => sub {
                my $h = shift;
                my $fn = $_[0];
                my $d = $_[1];
                if ($fn eq 'year') {
                    $d->year;
                } elsif ($fn eq 'month') {
                    $d->month;
                } elsif ($fn eq 'day') {
                    $d->day;
                } elsif ($fn eq 'dow') {
                    $d->day_of_week;
                } elsif ($fn eq 'quarter') {
                    $d->quarter;
                } elsif ($fn eq 'doy') {
                    $d->day_of_year;
                } elsif ($fn eq 'wom') {
                    $d->week_of_month;
                } elsif ($fn eq 'woy') {
                    $d->week_number;
                } elsif ($fn eq 'doq') {
                    $d->day_of_quarter;
                } elsif ($fn eq 'hour') {
                    $d->hour;
                } elsif ($fn eq 'minute') {
                    $d->minute;
                } elsif ($fn eq 'second') {
                    $d->second;
                } else {
                    die "BUG: Unknown date function $fn";
                }
            },
            func_idur_onum => sub {
                my $h = shift;
                my $fn = $_[0];
                my $dur = $_[1];
                if ($fn eq 'years') {
                    $dur->years;
                } elsif ($fn eq 'months') {
                    $dur->months;
                } elsif ($fn eq 'weeks') {
                    $dur->weeks;
                } elsif ($fn eq 'days') {
                    $dur->days;
                } elsif ($fn eq 'totdays') {
                    $dur->in_units("days");
                } elsif ($fn eq 'hours') {
                    $dur->hours;
                } elsif ($fn eq 'minutes') {
                    $dur->minutes;
                } elsif ($fn eq 'seconds') {
                    $dur->seconds;
                } else {
                    die "BUG: Unknown duration function $fn";
                }
            },
            num_add => sub {
                my $h = shift;
                if ($_[1] eq '+') {
                    $_[0] + $_[2];
                } else {
                    $_[0] - $_[2];
                }
            },
            num_mult => sub {
                my $h = shift;
                if ($_[1] eq '*') {
                    $_[0] * $_[2];
                } else {
                    $_[0] / $_[2];
                }
            },
            num_unary => sub {
                my $h = shift;
                my $op = $_[0];
                my $num = $_[1];
                if ($op eq '+') {
                    $num;
                } else {
                    # -
                    -$num;
                }
            },
            num_pow => sub {
                my $h = shift;
                $_[0] ** $_[2];
            },
        },
        trace_terminals => $ENV{DEBUG},
        trace_values => $ENV{DEBUG},
    );

    bless {parser=>$parser}, shift;
}

sub eval {
    my ($self, $str) = @_;
    my $res = $self->{parser}->($str);

    if (blessed($res) && $res->isa('DateTime::Duration')) {
        __fmtduriso($res);
    } elsif (blessed($res) && $res->isa('DateTime')) {
        $res->ymd . "#".$res->day_abbr;
    } else {
        "$res";
    }
}

1;
# ABSTRACT: Date calculator

__END__

=pod

=encoding UTF-8

=head1 NAME

App::datecalc - Date calculator

=head1 VERSION

This document describes version 0.08 of App::datecalc (from Perl distribution App-datecalc), released on 2018-02-21.

=head1 SYNOPSIS

 use App::datecalc;
 my $calc = App::datecalc->new;
 say $calc->eval('2014-05-13 + 2 days'); # -> 2014-05-15

=head1 DESCRIPTION

B<This is an early release. More features and documentation will follow in
subsequent releases.>

This module provides a date calculator, for doing date-related calculations. You
can write date literals in ISO 8601 format (though not all format variants are
supported), e.g. C<2014-05-13>. Date duration can be specified using the natural
syntax e.g. C<2 days 13 hours> or using the ISO 8601 format e.g. C<P2DT13H>.

Currently supported calculations:

=over

=item * date literals

 2014-05-19
 now
 today
 tomorrow

=item * (NOT YET) time and date-time literals

=item * duration literals, either in ISO 8601 format or natural syntax

 P3M2D
 3 months 2 days

=item * date addition/subtraction with a duration

 2014-05-19 - 2 days
 2014-05-19 + P29W

=item * date subtraction with another date

 2014-05-19 - 2013-12-25

=item * duration addition/subtraction with another duration

 1 week 1 day + P10D

=item * duration multiplication/division with a number

 P2D * 2
 2 * P2D

=item * extract elements from date

 year(2014-05-20)
 quarter(today)
 month(today)
 day(today)
 dow(today)
 doy(today)
 doq(today)
 wom(today)
 woy(today)
 hour(today)
 minute(today)
 second(today)

=item * extract elements from duration

 years(P22D)
 months(P22D)
 weeks(P22D)
 days(P22D)       # 1, because P22D normalizes to P3W1D
 totdays(P22D)    # 22
 days(P1M1D)      # 1
 totdays(P1M1D)   # 1, because months cannot be converted to days
 hours(P22D)
 minutes(P22D)
 seconds(P22D)

=item * some simple number arithmetics

 3+4.5
 2**3 * P1D
 abs(2-5)         # 3
 round(1.6+3)     # 5

=item * (NOT YET) date comparison

 today >= 2014-05-20

=item * (NOT YET) duration comparison

 P20D < P3W

=back

=head1 METHODS

=head2 new

=head2 eval

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-datecalc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-datecalc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-datecalc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime> and L<DateTime::Format::ISO8601>, the backend modules used to do the
actual date calculation.

L<Marpa::R2> is used to generate the parser.

L<Date::Calc> another date module on CPAN. No relation except the similarity of
name.

L<http://en.wikipedia.org/wiki/ISO_8601> for more information about the ISO 8601
format.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
