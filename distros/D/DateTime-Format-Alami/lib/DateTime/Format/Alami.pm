package DateTime::Format::Alami;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.16'; # VERSION

use 5.014000;
use strict;
use warnings;
use Log::ger;

use Role::Tiny;

my @short_mons = qw(jan feb mar apr may jun jul aug sep oct nov dec);
my @dow = qw(monday tuesday wednesday thursday friday saturday sunday);

requires 'o_num';
requires '_parse_num';

requires 'w_year';
requires 'w_month';
requires 'w_week';
requires 'w_day';
requires 'w_hour';
requires 'w_minute';
requires 'w_second';

requires "w_$_" for @short_mons;
requires "w_$_" for @dow;

requires 'p_now';
requires 'p_today';
requires 'p_yesterday';
requires 'p_tomorrow';
requires 'p_dateymd';
requires 'p_dateym';
requires 'o_date';
requires 'p_dur_ago';
requires 'p_dur_later';
requires 'p_which_dow';
requires 'p_time';
requires 'p_date_time';

our ($m, $o);
sub new {
    my $class = shift;
    if ($class eq __PACKAGE__) {
        die "Use one of the DateTime::Format::Alami::* instead, ".
            "e.g. DateTime::Format::Alami::EN";
    }
    my $self = bless {}, $class;
    no strict 'refs';
    unless (${"$class\::RE_DT"} && ${"$class\::RE_DUR"}) {
        require Class::Inspector;
        require Data::Graph::Util;

        my $meths = Class::Inspector->methods($class);
        my %pats;  # key = "p_..."
        my %pat_lengths; # key = "p_..."
        my %graph;
        for my $meth (@$meths) {
            next unless $meth =~ /^(odur|o|pdur|p)_/;
            my $pat = $self->$meth;
            my $is_p    = $meth =~ /^p_/;
            my $is_pdur = $meth =~ /^pdur_/;
            $pat =~ s/<(\w+)>/push @{$graph{$meth}}, $1; "(?\&$1)"/eg;
            my $action_meth = $meth;
            if ($is_pdur) { $action_meth =~ s/^pdur_/adur_/ } else { $action_meth =~ s/^p_/a_/ }
            #my $before_meth = $meth; $before_meth =~ s/^p_/before_p_/;
            #$before_meth = undef unless $is_p && $self->can($before_meth);
            $pat = join(
                "",
                "(",
                #($before_meth ? "(?{ ".($ENV{DEBUG} ? "say \"invoking $before_meth()\";" : "")."\$DateTime::Format::Alami::o->$before_meth(\$DateTime::Format::Alami::m) })" : ""),
                ($is_p || $is_pdur ? "\\b $pat \\b" : $pat), ")",

                # we capture ourselves instead of relying on named capture
                # because subpattern capture are discarded
                "(?{ \$DateTime::Format::Alami::m->{$meth} = \$^N })",

                ($is_p || $is_pdur ? "(?{ ".($ENV{DEBUG} ? "say \"invoking $action_meth(\$^N)\";" : "")."\$DateTime::Format::Alami::o->{_pat} = \"$meth\"; \$DateTime::Format::Alami::o->$action_meth(\$DateTime::Format::Alami::m) })" : ""),
            );
            $pats{$meth} = $pat;
            $pat_lengths{$meth} = length($pat);
        }
        my @pat_names_by_deps = Data::Graph::Util::toposort(\%graph);
        my %pat_name_dep_orders = map { $pat_names_by_deps[$_] => $_ }
            0..$#pat_names_by_deps;
        my @pat_names = sort {(
            ($pat_name_dep_orders{$a} // 9999) <=>
                ($pat_name_dep_orders{$b} // 9999)
                ||
                $pat_lengths{$b} <=> $pat_lengths{$a}) } keys %pats;
        my $nl = $ENV{DEBUG} ? "\n" : "";
        my $re_dt = join(
            "",
            "(?&top)", $nl,
            #"(?&p_dateymd)", $nl, # testing
            "(?(DEFINE)", $nl,
            "(?<top>", join("|",
                            map {"(?&$_)"} grep {/^p_/} @pat_names), ")$nl",
            (map { "(?<$_> $pats{$_})$nl" } grep {/^(o|p)_/} @pat_names),
            ")", # end of define
        );
        my $re_dur = join(
            "",
            "(?&top)", $nl,
            #"(?&pdur_dur)", $nl, # testing
            "(?(DEFINE)", $nl,
            "(?<top>", join("|",
                            map {"(?&$_)"} grep {/^pdur_/} @pat_names), ")$nl",
            (map { "(?<$_> $pats{$_})$nl" } grep {/^(odur|pdur)_/} @pat_names),
            ")", # end of define
        );
        {
            use re 'eval';
            ${"$class\::RE_DT"}  = qr/$re_dt/ix;
            ${"$class\::RE_DUR"} = qr/$re_dur/ix;
        }
    }
    unless (${"$class\::MAPS"}) {
        my $maps = {};
        # month names -> num
        {
            my $i = 0;
            for my $m (@short_mons) {
                ++$i;
                my $meth = "w_$m";
                for (@{ $self->$meth }) {
                    $maps->{months}{$_} = $i;
                }
            }
        }
        # day-of-week names -> num (monday=1, sunday=7)
        {
            my $i = 0;
            for my $m (@dow) {
                ++$i;
                my $meth = "w_$m";
                for (@{ $self->$meth }) {
                    $maps->{dow}{$_} = $i;
                }
            }
        }
        ${"$class\::MAPS"} = $maps;
    }

    # _time_zone is old name (<= 0.11) will be removed later
    $self->{time_zone} //= $self->{_time_zone};

    $self;
}

sub _reset {
    my $self = shift;
    undef $self->{_pat};
    undef $self->{_dt};
    undef $self->{_uses_time};
}

sub parse_datetime {
    no strict 'refs';

    # we require DateTime here, for all the a_* methods
    require DateTime;

    my ($self, $str, $opts) = @_;

    # allow calling as static method
    unless (ref $self) { $self = $self->new }

    $opts //= {};
    $opts->{format} //= 'DateTime';
    #$opts->{prefers} //= 'nearest';
    $opts->{returns} //= 'first';

    local $self->{time_zone} = $opts->{time_zone} if $opts->{time_zone};

    # we need /o to avoid repeated regcomp, but we need to make it work with all
    # subclasses, so we use eval() here.
    unless (defined *{ref($self).'::_code_match_dt'}) {
        *{ref($self).'::_code_match_dt'} = eval "sub { \$_[0] =~ /(\$".ref($self)."::RE_DT)/go; \$1 }";
        die if $@;
    }

    $o = $self;
    my @res;
    while (1) {
        $o->_reset;
        $m = {};
        my $match = &{ref($self).'::_code_match_dt'}($str) or last;
        $o->{_dt}->truncate(to=>'day') unless $o->{_uses_time};
        my $res = {
            verbatim => $match,
            pattern => $o->{_pat},
            pos => pos($str) - length($match),
            m => {%$m},
        };
        $res->{uses_time} = $o->{_uses_time} ? 1:0;
        $res->{DateTime}  = $o->{_dt};
        $res->{epoch}     = $o->{_dt}->epoch if
            $opts->{format} eq 'combined' || $opts->{format} eq 'epoch';
        push @res, $res;
        last if $opts->{returns} eq 'first';
    }

    die "Can't parse date '$str'" unless @res;

    @res = ($res[-1]) if $opts->{returns} eq 'last';

    if ($opts->{returns} =~ /\A(?:all_cron|earliest|latest)\z/) {
        # sort chronologically, note that by this time the DateTime module
        # should already have been loaded
        @res = sort {
            DateTime->compare($a->{DateTime}, $b->{DateTime})
        } @res;
    }

    if ($opts->{format} eq 'DateTime') {
        @res = map { $_->{DateTime} } @res;
    } elsif ($opts->{format} eq 'epoch') {
        @res = map { $_->{epoch} } @res;
    } elsif ($opts->{format} eq 'verbatim') {
        @res = map { $_->{verbatim} } @res;
    }

    if ($opts->{returns} =~ /\A(?:all|all_cron)\z/) {
        return \@res;
    } elsif ($opts->{returns} =~ /\A(?:first|earliest)\z/) {
        return $res[0];
    } elsif ($opts->{returns} =~ /\A(?:last|latest)\z/) {
        return $res[-1];
    } else {
        die "Unknown returns option '$opts->{returns}'";
    }
}

sub _reset_dur {
    my $self = shift;
    undef $self->{_pat};
    undef $self->{_dtdur};
}

sub parse_datetime_duration {
    # we require DateTime here, for all the adur_* methods
    require DateTime;
    require DateTime::Duration;

    no strict 'refs';

    my ($self, $str, $opts) = @_;

    # allow calling as static method
    unless (ref $self) { $self = $self->new }

    $opts //= {};
    $opts->{format}  //= 'Duration';
    $opts->{returns} //= 'first';

    # we need /o to avoid repeated regcomp, but we need to make it work with all
    # subclasses, so we use eval() here.
    unless (defined *{ref($self).'::_code_match_dur'}) {
        *{ref($self).'::_code_match_dur'} = eval "sub { \$_[0] =~ /(\$".ref($self)."::RE_DUR)/go; \$1 }";
        die if $@;
    }

    $o = $self;
    my @res;
    while (1) {
        $o->_reset_dur;
        $m = {};
        my $match = &{ref($self).'::_code_match_dur'}($str) or last;
        my $res = {
            verbatim => $match,
            pattern => $o->{_pat},
            pos => pos($str) - length($match),
            m => {%$m},
        };
        $res->{Duration}  = $o->{_dtdur};
        if ($opts->{format} eq 'combined' || $opts->{format} eq 'seconds') {
            my $d = $o->{_dtdur};
            $res->{seconds} =
                $d->years       *   365.25*86400 +
                $d->months      *  30.4375*86400 +
                $d->weeks       *        7*86400 +
                $d->days        *          86400 +
                $d->hours       *           3600 +
                $d->minutes     *             60 +
                $d->seconds                      +
                $d->nanoseconds *           1e-9;
        }
        push @res, $res;
        last if $opts->{returns} eq 'first';
    }

    die "Can't parse duration" unless @res;

    @res = ($res[-1]) if $opts->{returns} eq 'last';

    # XXX support returns largest, smallest, all_sorted
    if ($opts->{returns} =~ /\A(?:all_sorted|largest|smallest)\z/) {
        my $base_dt = DateTime->now;
        # sort from smallest to largest
        @res = sort {
            DateTime::Duration->compare($a->{Duration}, $b->{Duration}, $base_dt)
          } @res;
    }

    if ($opts->{format} eq 'Duration') {
        @res = map { $_->{Duration} } @res;
    } elsif ($opts->{format} eq 'seconds') {
        @res = map { $_->{seconds} } @res;
    } elsif ($opts->{format} eq 'verbatim') {
        @res = map { $_->{verbatim} } @res;
    }

    if ($opts->{returns} =~ /\A(?:all|all_sorted)\z/) {
        return \@res;
    } elsif ($opts->{returns} =~ /\A(?:first|smallest)\z/) {
        return $res[0];
    } elsif ($opts->{returns} =~ /\A(?:last|largest)\z/) {
        return $res[-1];
    } else {
        die "Unknown returns option '$opts->{returns}'";
    }
}

sub o_dayint { "(?:[12][0-9]|3[01]|0?[1-9])" }

sub o_monthint { "(?:0?[1-9]|1[012])" }

sub o_year2int { "(?:[0-9]{2})" }

sub o_year4int { "(?:[0-9]{4})" }

sub o_yearint { "(?:[0-9]{4}|[0-9]{2})" }

sub o_hour { "(?:[0-9][0-9]?)" }

sub o_minute { "(?:[0-9][0-9]?)" }

sub o_second { "(?:[0-9][0-9]?)" }

sub o_monthname {
    my $self = shift;
    "(?:" . join(
        "|",
        (map {my $meth="w_$_"; @{ $self->$meth }} @short_mons)
    ) . ")";
}

sub o_dow {
    my $self = shift;
    "(?:" . join(
        "|",
        (map {my $meth="w_$_"; @{ $self->$meth }} @dow)
    ) . ")";
}

sub o_durwords  {
    my $self = shift;
    "(?:" . join(
        "|",
        @{ $self->w_year }, @{ $self->w_month }, @{ $self->w_week },
        @{ $self->w_day },
        @{ $self->w_hour }, @{ $self->w_minute }, @{ $self->w_second },
    ) . ")";
}

sub o_dur {
    my $self = shift;
    "(?:(" . $self->o_num . "\\s*" . $self->o_durwords . "\\s*(?:,\\s*)?)+)";
}

sub odur_dur {
    my $self = shift;
    $self->o_dur;
}

sub pdur_dur {
    my $self = shift;
    "(?:<odur_dur>)";
}

# durations less than a day
sub o_timedurwords  {
    my $self = shift;
    "(?:" . join(
        "|",
        @{ $self->w_hour }, @{ $self->w_minute }, @{ $self->w_second },
    ) . ")";
}

sub o_timedur {
    my $self = shift;
    "(?:(" . $self->o_num . "\\s*" . $self->o_timedurwords . "\\s*(?:,\\s*)?)+)";
}

sub _parse_dur {
    use experimental 'smartmatch';

    my ($self, $str) = @_;

    #say "D:dur=$str";
    my %args;
    unless ($self->{_cache_re_parse_dur}) {
        my $o_num = $self->o_num;
        my $o_dw  = $self->o_durwords;
        $self->{_cache_re_parse_dur} = qr/($o_num)\s*($o_dw)/ix;
    }
    unless ($self->{_cache_w_second}) {
        $self->{_cache_w_second} = $self->w_second;
        $self->{_cache_w_minute} = $self->w_minute;
        $self->{_cache_w_hour}   = $self->w_hour;
        $self->{_cache_w_day}    = $self->w_day;
        $self->{_cache_w_week}   = $self->w_week;
        $self->{_cache_w_month}  = $self->w_month;
        $self->{_cache_w_year}   = $self->w_year;
    }
    while ($str =~ /$self->{_cache_re_parse_dur}/g) {
        my ($n, $unit) = ($1, $2);
        $n = $self->_parse_num($n);
        if ($unit ~~ $self->{_cache_w_second}) {
            $args{seconds} = $n;
            $self->{_uses_time} = 1;
        } elsif ($unit ~~ $self->{_cache_w_minute}) {
            $args{minutes} = $n;
            $self->{_uses_time} = 1;
        } elsif ($unit ~~ $self->{_cache_w_hour}) {
            $args{hours} = $n;
            $self->{_uses_time} = 1;
        } elsif ($unit ~~ $self->{_cache_w_day}) {
            $args{days} = $n;
        } elsif ($unit ~~ $self->{_cache_w_week}) {
            $args{weeks} = $n;
        } elsif ($unit ~~ $self->{_cache_w_month}) {
            $args{months} = $n;
        } elsif ($unit ~~ $self->{_cache_w_year}) {
            $args{years} = $n;
        }
    }
    DateTime::Duration->new(%args);
}

sub _now_if_unset {
    my $self = shift;
    $self->a_now unless $self->{_dt};
}

sub _today_if_unset {
    my $self = shift;
    $self->a_today unless $self->{_dt};
}

sub a_now {
    my $self = shift;
    $self->{_dt} = DateTime->now(
        (time_zone => $self->{time_zone}) x !!defined($self->{time_zone}),
    );
    $self->{_uses_time} = 1;
}

sub a_today {
    my $self = shift;
    $self->{_dt} = DateTime->today(
        (time_zone => $self->{time_zone}) x !!defined($self->{time_zone}),
    );
    $self->{_uses_time} = 0;
}

sub a_yesterday {
    my $self = shift;
    $self->a_today;
    $self->{_dt}->subtract(days => 1);
}

sub a_tomorrow {
    my $self = shift;
    $self->a_today;
    $self->{_dt}->add(days => 1);
}

sub a_dateymd {
    my ($self, $m) = @_;
    $self->a_today;
    my $y0 = $m->{o_yearint} // $m->{o_year4int} // $m->{o_year2int};
    if (defined $y0) {
        my $year;
        if (length($y0) == 2) {
            my $start_of_century_year = int($self->{_dt}->year / 100) * 100;
            $year = $start_of_century_year + $y0;
        } else {
            $year = $y0;
        }
        $self->{_dt}->set_year($year);
    }
    if (defined $m->{o_dayint}) {
        $self->{_dt}->set_day($m->{o_dayint});
    }
    if (defined $m->{o_monthint}) {
        $self->{_dt}->set_month($m->{o_monthint});
    }
    if (defined $m->{o_monthname}) {
        no strict 'refs';
        my $maps = ${ ref($self) . '::MAPS' };
        $self->{_dt}->set_month($maps->{months}{lc $m->{o_monthname}});
    }
}

sub a_dateym {
    my ($self, $m) = @_;
    $m->{o_dayint} = 1;
    $self->a_dateymd($m);
    delete $m->{o_dayint};
}

sub a_which_dow {
    no strict 'refs';

    my ($self, $m) = @_;
    $self->a_today;
    my $dow_num = $self->{_dt}->day_of_week;

    my $maps = ${ ref($self) . '::MAPS' };
    my $wanted_dow_num = $maps->{dow}{lc $m->{o_dow} };

    $self->{_dt}->add(days => ($wanted_dow_num-$dow_num));

    if ($m->{offset}) {
        $self->{_dt}->add(days => (7*$m->{offset}));
    }
}

sub adur_dur {
    my ($self, $m) = @_;
    $self->{_dtdur} = $self->_parse_dur($m->{odur_dur});
}

sub a_dur_ago {
    my ($self, $m) = @_;
    $self->a_now;
    my $dur = $self->_parse_dur($m->{o_dur});
    $self->{_dt}->subtract_duration($dur);
}

sub a_dur_later {
    my ($self, $m) = @_;
    $self->a_now;
    my $dur = $self->_parse_dur($m->{o_dur});
    $self->{_dt}->add_duration($dur);
}

sub a_time {
    my ($self, $m) = @_;
    $self->_now_if_unset;
    $self->{_uses_time} = 1;
    my $hour = $m->{o_hour};
    if ($m->{o_ampm}) {
        $hour += 12 if lc($m->{o_ampm}) eq 'pm' && $hour < 12;
        $hour =  0  if lc($m->{o_ampm}) eq 'am' && $hour == 12;
    }
    $self->{_dt}->set_hour($hour);
    $self->{_dt}->set_minute($m->{o_minute});
    $self->{_dt}->set_second($m->{o_second} // 0);
}

sub a_date_time {
    my ($self, $m) = @_;
}

1;
# ABSTRACT: Parse human date/time expression (base class)

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Alami - Parse human date/time expression (base class)

=head1 VERSION

This document describes version 0.16 of DateTime::Format::Alami (from Perl distribution DateTime-Format-Alami), released on 2017-07-10.

=head1 SYNOPSIS

For English:

 use DateTime::Format::Alami::EN;
 my $parser = DateTime::Format::Alami::EN->new();
 my $dt = $parser->parse_datetime("2 hours 13 minutes from now");

Or you can also call as class method:

 my $dt = DateTime::Format::Alami::EN->parse_datetime("yesterday");

To parse duration:

 my $dtdur = DateTime::Format::Alami::EN->parse_datetime_duration("2h"); # 2 hours

For Indonesian:

 use DateTime::Format::Alami::ID;
 my $parser = DateTime::Format::Alami::ID->new();
 my $dt = $parser->parse_datetime("5 jam lagi");

Or you can also call as class method:

 my $dt = DateTime::Format::Alami::ID->parse_datetime("hari ini");

To parse duration:

 my $dtdur = DateTime::Format::Alami::ID->parse_datetime_duration("2h"); # 2 days

=head1 DESCRIPTION

This class parses human/natural date/time/duration string and returns
L<DateTime> (or L<DateTime::Duration>) object. Currently it supports English and
Indonesian. The goal of this module is to make it easier to add support for
other human languages.

To actually use this class, you must use one of its subclasses for each
human language that you want to parse.

There are already some other DateTime human language parsers on CPAN and
elsewhere, see L</"SEE ALSO">.

=for Pod::Coverage ^((adur|a|pdur|p|odur|o|w)_.+)$

=head1 HOW IT WORKS

L<DateTime::Format::Alami> is base class. Each human language is implemented in
a separate C<< DateTime::Format::Alami::<ISO_CODE> >> module (e.g.
L<DateTime::Format::Alami::EN> and L<DateTime::Format::Alami::EN>) which is a
subclass.

Parsing is done using a single recursive regex (i.e. containing C<(?&NAME)> and
C<(?(DEFINE))> patterns, see L<perlre>). This regex is composed from pieces of
pattern strings in the C<p_*> and C<o_*> methods, to make it easier to override
in an OO-fashion.

A pattern string that is returned by the C<p_*> method is a normal regex pattern
string that will be compiled using the /x and /i regex modifier. The pattern
string can also refer to pattern in other C<o_*> or C<p_*> method using syntax
C<< <o_foo> >> or C<< <p_foo> >>. Example, C<o_today> for English might be
something like:

 sub p_today { "(?: today | this \s+ day )" }

Other examples:

 sub p_yesterday { "(?: yesterday )" }

 sub p_dateymd { join(
     "",
    '(?: <o_dayint> \\s* ?<o_monthname> | <o_monthname> \\s* <o_dayint>\\b|<o_monthint>[ /-]<o_dayint>\\b )',
    '(?: \\s*[,/-]?\\s* <o_yearint>)?'
 )}

 sub o_date { "(?: <p_today>|<p_yesterday>|<p_dateymd>)" }

 sub p_time { "(?: <o_hour>:<o_minute>(?:<o_second>)? \s* <o_ampm> )" }

 sub p_date_time { "(?: <o_date> (?:\s+ at)? <o_time> )" }

When a pattern from C<p_*> matches, a corresponding action method C<a_*> will be
invoked. Usually the method will set or modify a DateTime object in C<<
$self->{_dt} >>. For example, this is code for C<a_today>:

 sub a_today {
     my $self = shift;
     $self->{_dt} = DateTime->today;
 }

The patterns from all C<p_*> methods will be combined in an alternation to form
the final pattern.

An C<o_*> pattern is just like C<p_*>, but they will not be
combined into the final pattern and matching it won't execute a corresponding
C<a_*> method.

And there are also C<w_*> methods which return array of strings.

Parsing duration is similar, except the method names are C<pdur_*>, C<odur_*>
and C<adur_*>.

=head1 ADDING A NEW HUMAN LANGUAGE

See an example in existing C<DateTime::Format::Alami::*> module. Basically you
just need to supply the necessary patterns in the C<p_*> methods. If you want to
introduce new C<p_*> method, don't forget to supply the action too in the C<a_*>
method.

=head1 METHODS

=head2 new => obj

Constructor. You actually must instantiate subclass instead.

=head2 parse_datetime($str[ , \%opts ]) => obj

Parse/extract date/time expression in C<$str>. Die if expression cannot be
parsed. Otherwise return L<DateTime> object (or string/number if C<format>
option is C<verbatim>/C<epoch>, or hash if C<format> option is C<combined>) or
array of objects/strings/numbers (if C<returns> option is C<all>/C<all_cron>).

Known options:

=over

=item * time_zone => str

Will be passed to DateTime constructor.

=item * format => str (DateTime|verbatim|epoch|combined)

The default is C<DateTime>, which will return DateTime object. Other choices
include C<verbatim> (returns the original text), C<epoch> (returns Unix
timestamp), C<combined> (returns a hash containing keys like C<DateTime>,
C<verbatim>, C<epoch>, and other extra information: C<pos> [position of pattern
in the string], C<pattern> [pattern name], C<m> [raw named capture groups],
C<uses_time> [whether the date involves time of day]).

You might think that choosing C<epoch> or C<verbatim> could avoid the overhead
of DateTime, but actually you can't since DateTime is used as the primary format
during parsing. The epoch is retrieved from the DateTime object using the
C<epoch> method.

=item * prefers => str (nearest|future|past)

NOT YET IMPLEMENTED.

This option decides what happens when an ambiguous date appears in the input.
For example, "Friday" may refer to any number of Fridays. Possible choices are:
C<nearest> (prefer the nearest date, the default), C<future> (prefer the closest
future date), C<past> (prefer the closest past date).

=item * returns => str (first|last|earliest|latest|all|all_cron)

If the text has multiple possible dates, then this argument determines which
date will be returned. Possible choices are: C<first> (return the first date
found in the string, the default), C<last> (return the final date found in the
string), C<earliest> (return the date found in the string that chronologically
precedes any other date in the string), C<latest> (return the date found in the
string that chronologically follows any other date in the string), C<all>
(return all dates found in the string, in the order they were found in the
string), C<all_cron> (return all dates found in the string, in chronological
order).

When C<all> or C<all_cron> is chosen, function will return array(ref) of results
instead of a single result, even if there is only a single actual result.

=back

=head2 parse_datetime_duration($str[ , \%opts ]) => obj

Parse/extract duration expression in C<$str>. Die if expression cannot be
parsed. Otherwise return L<DateTime::Duration> object (or string/number if
C<format> option is C<verbatim>/C<seconds>, or hash if C<format> option is
C<combined>) or array of objects/strings/numbers (if C<returns> option is
C<all>/C<all_sorted>).

Known options:

=over

=item * format => str (Duration|verbatim|seconds|combined)

The default is C<Duration>, which will return DateTime::Duration object. Other
choices include C<verbatim> (returns the original text), C<seconds> (returns
number of seconds, approximated), C<combined> (returns a hash containing keys
like C<Duration>, C<verbatim>, C<seconds>, and other extra information: C<pos>
[position of pattern in the string], C<pattern> [pattern name], C<m> [raw named
capture groups]).

You might think that choosing C<seconds> or C<verbatim> could avoid the overhead
of DateTime::Duration, but actually you can't since DateTime::Duration is used
as the primary format during parsing. The number of seconds is calculated from
the DateTime::Duration object I<using an approximation> (for example, "1 month"
does not convert exactly to seconds).

=item * returns => str (first|last|smallest|largest|all|all_sorted)

If the text has multiple possible durations, then this argument determines which
date will be returned. Possible choices are: C<first> (return the first duration
found in the string, the default), C<last> (return the final duration found in
the string), C<smallest> (return the smallest duration), C<largest> (return the
largest duration), C<all> (return all durations found in the string, in the
order they were found in the string), C<all_sorted> (return all durations found
in the string, in smallest-to-largest order).

When C<all> or C<all_sorted> is chosen, function will return array(ref) of
results instead of a single result, even if there is only a single actual
result.

=back

=head1 FAQ

=head2 What does "alami" mean?

It is an Indonesian word, meaning "natural".

=head2 How does it compare to similar modules?

L<DateTime::Format::Natural> (DF:Natural) is a more established module (first
released on 2006) and can understand a bit more English expression like 'last
day of Sep'. Aside from English, it does not yet support other languages.

DFA:EN's C<parse_datetime_duration()> produces a L<DateTime::Duration> object
while DF:Natural's C<parse_datetime_duration()> returns two L<DateTime> objects
instead. In other words, DF:Natural can parse "from 23 Jun to 29 Jun" in
addition to "for 2 weeks".

DF:Natural in general is slightly more strict about the formats it accepts, e.g.
it rejects C<Jun 23st> (the error message even gives hints that the suffix must
be 'rd'). DF:Natural can give a detailed error message on why parsing has failed
(see its C<error()> method).

L<DateTime::Format::Flexible> (DF:Flexible) is another established module (first
released in 2007) that, aside from parsing human expression (like 'tomorrow',
'sep 1st') can also parse date/time in several other formats like RFC 822,
making it a convenient module to use as a 'one-stop' solution to parse date.
Compared to DF:Natural, it has better support for timezone but cannot parse some
English expressions. Aside from English, it currently supports German and
Spanish. It does not support parsing duration expression.

This module itself: B<DateTime::Format::Alami> (DF:Alami) is yet another
implementation. Internally, it uses recursive regex to make parsing simpler and
adding more languages easier. It requires perl 5.14.0 or newer due to the use of
C<(?{ ... })> code blocks inside regular expression (while DF:Natural and
DF:Flexible can run on perl 5.8+). It currently supports English and Indonesian.
It supports parsing duration expression and returns DateTime::Duration object.
It has the smallest startup time (see see
L<Bencher::Scenario::DateTimeFormatAlami::Startup>).

Performance-wise, all the modules are within the same order of magnitude (see
L<Bencher::Scenario::DateTimeFormatAlami::Parsing>).

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

=head2 Similar modules on CPAN

L<Date::Extract>. DateTime::Format::Alami has some features of Date::Extract so
it can be used to replace Date::Extract.

L<DateTime::Format::Flexible>. See L</"FAQ">.

For Indonesian: L<DateTime::Format::Indonesian>, L<Date::Extract::ID> (currently
this module uses DateTime::Format::Alami::ID as its backend).

For English: L<DateTime::Format::Natural>. See L</"FAQ">.

=head2 Other modules on CPAN

L<DateTime::Format::Human> deals with formatting and not parsing.

=head2 Similar non-Perl libraries

Natt Java library, which the last time I tried sometimes gives weird answer,
e.g. "32 Oct" becomes 1 Oct in the far future. http://natty.joestelmach.com/

Duckling Clojure library, which can parse date/time as well as numbers with some
other units like temperature. https://github.com/wit-ai/duckling

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
