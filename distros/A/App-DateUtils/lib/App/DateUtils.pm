package App::DateUtils;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '0.121'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my %time_zone_arg = (
    time_zone => {
        schema => 'str*',
        cmdline_aliases => {timezone=>{}},
    },
);

my %dates_arg = (
    dates => {
        schema => ['array*', of=>'str*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

my %durations_arg = (
    durations => {
        schema => ['array*', of=>'str*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

my %all_modules_arg = (
    all_modules => {
        summary => 'Parse using all installed modules and '.
            'return all the result at once',
        schema => ['bool*', is=>1],
        cmdline_aliases => {a=>{}},
    },
);

my @parse_date_modules = (
    'DateTime::Format::Alami::EN',
    'DateTime::Format::Alami::ID',
    'DateTime::Format::Flexible',
    'DateTime::Format::Flexible(de)',
    'DateTime::Format::Flexible(es)',
    'DateTime::Format::Natural',

    'Date::Parse',
);

my @parse_duration_modules = (
    'DateTime::Format::Alami::EN',
    'DateTime::Format::Alami::ID',
    'DateTime::Format::Natural',
    'Time::Duration::Parse',
);

$SPEC{parse_date} = {
    v => 1.1,
    summary => 'Parse date string(s) using one of several modules',
    args => {
        module => {
            schema  => ['str*', in=>\@parse_date_modules],
            default => 'DateTime::Format::Flexible',
            cmdline_aliases => {m=>{}},
        },
        %all_modules_arg,
        %time_zone_arg,
        %dates_arg,
    },
    examples => [
        {
            argv => ['23 sep 2015','tomorrow','foo'],
        },
    ],
};
sub parse_date {
    my %args = @_;

    my %mods; # val = 1 if installed
    if ($args{all_modules}) {
        require Module::Installed::Tiny;
        for my $mod0 (@parse_date_modules) {
            (my $mod = $mod0) =~ s/\(.+//;
            $mods{$mod0} = Module::Installed::Tiny::module_installed($mod) ?
                1:0;
        }
    } else {
        %mods = ($args{module} => 1);
    }

    my @res;
    for my $mod (sort keys %mods) {
        my $mod_is_installed = $mods{$mod};

        my $parser;
        if ($mod_is_installed) {
            if ($mod eq 'DateTime::Format::Alami::EN') {
                require DateTime::Format::Alami::EN;
                $parser = DateTime::Format::Alami::EN->new(
                    ( time_zone => $args{time_zone} ) x
                        !!(defined($args{time_zone})),
                );
            } elsif ($mod eq 'DateTime::Format::Alami::ID') {
                require DateTime::Format::Alami::ID;
                $parser = DateTime::Format::Alami::ID->new(
                    ( time_zone => $args{time_zone} ) x
                        !!(defined($args{time_zone})),
                );
            } elsif ($mod =~ /^DateTime::Format::Flexible/) {
                require DateTime::Format::Flexible;
                $parser = DateTime::Format::Flexible->new(
                );
            } elsif ($mod eq 'DateTime::Format::Natural') {
                require DateTime::Format::Natural;
                $parser = DateTime::Format::Natural->new(
                    ( time_zone => $args{time_zone} ) x
                        !!(defined($args{time_zone})),
                );
            } elsif ($mod eq 'Date::Parse') {
                require Date::Parse;
                require DateTime; # to show as_datetime_obj
            } else {
                return [400, "Unknown module '$mod'"];
            }
        }

      DATE:
        for my $date (@{ $args{dates} }) {
            my $rec = { original => $date, module => $mod };
            unless ($mod_is_installed) {
                $rec->{error_msg} = "module not installed";
                goto PUSH_RESULT;
            }
            if ($mod =~ /^DateTime::Format::Alami/) {
                my $res;
                eval { $res = $parser->parse_datetime($date, {format=>'combined'}) };
                if ($@) {
                    $rec->{is_parseable} = 0;
                } else {
                    $rec->{is_parseable} = 1;
                    $rec->{as_epoch} = $res->{epoch};
                    $rec->{as_datetime_obj} = "$res->{DateTime}";
                    $rec->{pattern} = $res->{pattern};
                }
            } elsif ($mod =~ /^DateTime::Format::Flexible/) {
                my $dt;
                my %opts;
                $opts{lang} = [$1] if $mod =~ /\((\w+)\)$/;
                eval { $dt = $parser->parse_datetime(
                    $date,
                    %opts,
                ) };
                my $err = $@;
                if (!$err) {
                    $rec->{is_parseable} = 1;
                    $rec->{as_epoch} = $dt->epoch;
                    $rec->{as_datetime_obj} = "$dt";
                } else {
                    $err =~ s/\n/ /g;
                    $rec->{is_parseable} = 0;
                    $rec->{error_msg} = $err;
                }
            } elsif ($mod =~ /^DateTime::Format::Natural/) {
                my $dt = $parser->parse_datetime($date);
                if ($parser->success) {
                    $rec->{is_parseable} = 1;
                    $rec->{as_epoch} = $dt->epoch;
                    $rec->{as_datetime_obj} = "$dt";
                } else {
                    $rec->{is_parseable} = 0;
                    $rec->{error_msg} = $parser->error;
                }
            } elsif ($mod eq 'Date::Parse') {
                my $time = Date::Parse::str2time($date);
                if (defined $time) {
                    $rec->{is_parseable} = 1;
                    $rec->{as_epoch} = $time;
                    $rec->{as_datetime_obj} = do { my $dt = DateTime->from_epoch(epoch => $time); "$dt" };
                } else {
                    $rec->{is_parseable} = 0;
                }
            }
          PUSH_RESULT:
            push @res, $rec;
        } # for dates
    } # for mods

    [200, "OK", \@res, {'table.fields'=>[qw/module original is_parseable as_epoch as_datetime_obj error_msg/]}];
}

$SPEC{parse_date_using_df_flexible} = {
    v => 1.1,
    summary => 'Parse date string(s) using DateTime::Format::Flexible',
    args => {
        %time_zone_arg,
        %dates_arg,
        lang => {
            schema => ['str*', in=>[qw/de en es/]],
            default => 'en',
        },
    },
    examples => [
        {args => {dates => ['23rd Jun']}},
        {args => {dates => ['23 Dez'], lang=>'de'}},
        {args => {dates => ['foo']}},
    ],
};
sub parse_date_using_df_flexible {
    my %args = @_;
    my $lang = $args{lang};
    my $module = 'DateTime::Format::Flexible';
    $module .= "(de)" if $lang eq 'de';
    $module .= "(es)" if $lang eq 'es';
    parse_date(module=>$module, %args);
}

$SPEC{parse_date_using_df_natural} = {
    v => 1.1,
    summary => 'Parse date string(s) using DateTime::Format::Natural',
    args => {
        %time_zone_arg,
        %dates_arg,
    },
    examples => [
        {args => {dates => ['23rd Jun']}},
        {args => {dates => ['foo']}},
    ],
    links => [
        {summary => 'The official CLI for DateTime::Format::Natural', url=>'dateparse'},
    ],
};
sub parse_date_using_df_natural {
    my %args = @_;
    parse_date(module=>'DateTime::Format::Natural', %args);
}

$SPEC{parse_date_using_df_alami_en} = {
    v => 1.1,
    summary => 'Parse date string(s) using DateTime::Format::Alami::EN',
    args => {
        %time_zone_arg,
        %dates_arg,
    },
    examples => [
        {args => {dates => ['23 May']}},
        {args => {dates => ['foo']}},
    ],
};
sub parse_date_using_df_alami_en {
    my %args = @_;
    parse_date(module=>'DateTime::Format::Alami::EN', %args);
}

$SPEC{parse_date_using_df_alami_id} = {
    v => 1.1,
    summary => 'Parse date string(s) using DateTime::Format::Alami::ID',
    args => {
        %time_zone_arg,
        %dates_arg,
    },
    examples => [
        {args => {dates => ['23 Mei']}},
        {args => {dates => ['foo']}},
    ],
};
sub parse_date_using_df_alami_id {
    my %args = @_;
    parse_date(module=>'DateTime::Format::Alami::ID', %args);
}

$SPEC{parse_duration} = {
    v => 1.1,
    summary => 'Parse duration string(s) using one of several modules',
    args => {
        module => {
            schema  => ['str*', in=>\@parse_duration_modules],
            default => 'Time::Duration::Parse',
            cmdline_aliases => {m=>{}},
        },
        %durations_arg,
        %all_modules_arg,
    },
};
sub parse_duration {
    my %args = @_;

    my %mods; # val = 1 if installed
    if ($args{all_modules}) {
        require Module::Installed::Tiny;
        for my $mod0 (@parse_duration_modules) {
            (my $mod = $mod0) =~ s/\(.+//;
            $mods{$mod0} = Module::Installed::Tiny::module_installed($mod) ?
                1:0;
        }
    } else {
        %mods = ($args{module} => 1);
    }

    my @res;
    for my $mod (sort keys %mods) {
        my $mod_is_installed = $mods{$mod};

        my $parser;
        if ($mod_is_installed) {
            if ($mod eq 'DateTime::Format::Alami::EN') {
                require DateTime::Format::Alami::EN;
                $parser = DateTime::Format::Alami::EN->new();
            } elsif ($mod eq 'DateTime::Format::Alami::ID') {
                require DateTime::Format::Alami::ID;
                $parser = DateTime::Format::Alami::ID->new();
            } elsif ($mod eq 'DateTime::Format::Natural') {
                require DateTime::Format::Natural;
                $parser = DateTime::Format::Natural->new();
            } elsif ($mod eq 'Time::Duration::Parse') {
                require Time::Duration::Parse;
            }
        }

      DURATION:
        for my $dur (@{ $args{durations} }) {
            my $rec = { original => $dur, module => $mod };
            unless ($mod_is_installed) {
                $rec->{error_msg} = "module not installed";
                goto PUSH_RESULT;
            }
            if ($mod =~ /^DateTime::Format::Alami/) {
                my $res;
                eval { $res = $parser->parse_datetime_duration($dur, {format=>'combined'}) };
                if ($@) {
                    $rec->{is_parseable} = 0;
                } else {
                    require DateTime::Format::Duration::ISO8601;
                    my $dtdurf = DateTime::Format::Duration::ISO8601->new;
                    $rec->{is_parseable} = 1;
                    $rec->{as_dtdur_obj} = $dtdurf->format_duration($res->{Duration});
                    $rec->{as_secs} = $res->{seconds};
                }
            } elsif ($mod =~ /^DateTime::Format::Natural/) {
                my @dt = $parser->parse_datetime_duration($dur);
                if (@dt > 1) {
                    require DateTime::Format::Duration::ISO8601;
                    my $dtdurf = DateTime::Format::Duration::ISO8601->new;
                    my $dtdur = $dt[1]->subtract_datetime($dt[0]);
                    $rec->{is_parseable} = 1;
                    $rec->{date1} = "$dt[0]";
                    $rec->{date2} = "$dt[1]";
                    $rec->{as_dtdur_obj} = $dtdurf->format_duration($dtdur);
                    $rec->{as_secs} =
                        $dtdur->years * 365.25*86400 +
                        $dtdur->months * 30.4375*86400 +
                        $dtdur->weeks * 7*86400 +
                        $dtdur->days * 86400 +
                        $dtdur->hours * 3600 +
                        $dtdur->minutes * 60 +
                        $dtdur->seconds +
                        $dtdur->nanoseconds * 1e-9;
                } else {
                    $rec->{is_parseable} = 0;
                    $rec->{error_msg} = $parser->error;
                }
            } elsif ($mod eq 'Time::Duration::Parse') {
                my $secs;
                eval { $secs = Time::Duration::Parse::parse_duration($dur) };
                if ($@) {
                    $rec->{is_parseable} = 0;
                    $rec->{error_msg} = $@;
                    $rec->{error_msg} =~ s/\n+/ /g;
                } else {
                    $rec->{is_parseable} = 1;
                    $rec->{as_secs} = $secs;
                }
            }
          PUSH_RESULT:
            push @res, $rec;
        } # for durations
    } # for modules

    [200, "OK", \@res, {'table.fields'=>[qw/module original is_parseable as_secs as_dtdur_obj error_msg/]}];
}

$SPEC{parse_duration_using_df_alami_en} = {
    v => 1.1,
    summary => 'Parse duration string(s) using DateTime::Format::Alami::EN',
    args => {
        %durations_arg,
    },
    examples => [
        {args => {durations => ['2h, 3mins']}},
        {args => {durations => ['foo']}},
    ],
};
sub parse_duration_using_df_alami_en {
    my %args = @_;
    parse_duration(module=>'DateTime::Format::Alami::EN', %args);
}

$SPEC{parse_duration_using_df_alami_id} = {
    v => 1.1,
    summary => 'Parse duration string(s) using DateTime::Format::Alami::ID',
    args => {
        %durations_arg,
    },
    examples => [
        {args => {durations => ['2j, 3mnt']}},
        {args => {durations => ['foo']}},
    ],
};
sub parse_duration_using_df_alami_id {
    my %args = @_;
    parse_duration(module=>'DateTime::Format::Alami::ID', %args);
}

$SPEC{parse_duration_using_df_natural} = {
    v => 1.1,
    summary => 'Parse duration string(s) using DateTime::Format::Natural',
    args => {
        %durations_arg,
    },
    examples => [
        {args => {durations => ['for 2 weeks']}},
        {args => {durations => ['from 23 Jun to 29 Jun']}},
        {args => {durations => ['foo']}},
    ],
};
sub parse_duration_using_df_natural {
    my %args = @_;
    parse_duration(module=>'DateTime::Format::Natural', %args);
}

$SPEC{parse_duration_using_td_parse} = {
    v => 1.1,
    summary => 'Parse duration string(s) using Time::Duration::Parse',
    args => {
        %durations_arg,
    },
    examples => [
        {args => {durations => ['2 days 13 hours']}},
        {args => {durations => ['foo']}},
    ],
};
sub parse_duration_using_td_parse {
    my %args = @_;
    parse_duration(module=>'Time::Duration::Parse', %args);
}

$SPEC{dateconv} = {
    v => 1.1,
    summary => 'Convert date to another format',
    args => {
        date => {
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['str_alami'],
            }],
            req => 1,
            pos => 0,
        },
        to => {
            schema => ['str*', in=>[qw/epoch ymd/]], # XXX: iso8601, ...
            default => 'epoch',
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Convert "today" to epoch',
            args => {date => 'today'},
            test => 0,
        },
        {
            summary => 'Convert epoch to ymd',
            args => {date => '1463702400', to=>'ymd'},
            result => '2016-05-20',
        },
    ],
};
sub dateconv {
    my %args = @_;
    my $date = $args{date};
    my $to   = $args{to};

    if ($to eq 'epoch') {
        return $date->epoch;
    } elsif ($to eq 'ymd') {
        return $date->ymd;
    } else {
        die "Unknown format '$to'";
    }
}

$SPEC{durconv} = {
    v => 1.1,
    summary => 'Convert duration to another format',
    args => {
        duration => {
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
            }],
            req => 1,
            pos => 0,
        },
        to => {
            schema => ['str*', in=>[qw/secs hash/]], # XXX: iso8601, ...
            default => 'secs',
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Convert "3h2m" to number of seconds',
            args => {duration => '3h2m'},
            result => 10920,
        },
    ],
};
sub durconv {
    my %args = @_;
    my $dur = $args{duration};
    my $to  = $args{to};

    if ($to eq 'secs') {
        # approximation
        return (
            $dur->years       * 365*86400 +
            $dur->months      *  30*86400 +
            $dur->weeks       *   7*86400 +
            $dur->days        *     86400 +
            $dur->hours       *      3600 +
            $dur->minutes     *        60 +
            $dur->seconds     *         1 +
            $dur->nanoseconds *      1e-9
        );
    } elsif ($to eq 'hash') {
        my $h = {
            years => $dur->years,
            months => $dur->months,
            weeks => $dur->weeks,
            days => $dur->days,
            hours => $dur->hours,
            minutes => $dur->minutes,
            seconds => $dur->seconds,
            nanoseconds => $dur->nanoseconds,
        };
        for (keys %$h) {
            delete $h->{$_} if $h->{$_} == 0;
        }
        return $h;
    } else {
        die "Unknown format '$to'";
    }
}

$SPEC{datediff} = {
    v => 1.1,
    summary => 'Diff (subtract) two dates, show as ISO8601 duration',
    args => {
        date1 => {
            schema => ['date*', {
                'x.perl.coerce_rules' => ['str_natural','str_iso8601','float_epoch'],
                'x.perl.coerce_to' => 'DateTime',
            }],
            req => 1,
            pos => 0,
        },
        date2 => {
            schema => ['date*', {
                'x.perl.coerce_rules' => ['str_natural','str_iso8601','float_epoch'],
                'x.perl.coerce_to' => 'DateTime',
            }],
            req => 1,
            pos => 1,
        },
        as => {
            schema => ['str*', in=>['iso8601', 'concise_hms', 'hms', 'seconds']],
            default => 'iso8601',
        },
    },
    result_naked => 1,
    examples => [
        {
            argv => [qw/2019-06-18T20:08:42 2019-06-19T06:02:03/],
            result => 'PT9H53M21S',
        },
        {
            argv => [qw/2019-06-18T20:08:42 2019-06-19T06:02:03 --as hms/],
            result => '09:53:21',
        },
        {
            argv => [qw/2019-06-18T20:08:42 2019-06-22T06:02:03 --as concise_hms/],
            result => '3d 09:53:21',
        },
        {
            argv => [qw/2019-06-18T20:08:42 2019-06-19T06:02:03 --as seconds/],
            result => '35601',
        },
    ],
};
sub datediff {
    my %args = @_;
    my $date1 = $args{date1};
    my $date2 = $args{date2};
    my $as = $args{as} // 'iso8601';

    my $dur = $date1->subtract_datetime($date2);

    if ($as eq 'seconds') {
        $dur->years  * 365.25 * 86400 +
        $dur->months * 30.5   * 86400 +
        $dur->days            * 86400 +
        $dur->hours           *  3600 +
        $dur->minutes         *    60 +
        $dur->seconds;
    } elsif ($as eq 'concise_hms' || $as eq 'hms') {
        require DateTime::Format::Duration::ConciseHMS;
        DateTime::Format::Duration::ConciseHMS->format_duration($dur);
    } else {
        require DateTime::Format::Duration::ISO8601;
        DateTime::Format::Duration::ISO8601->format_duration($dur);
    }
}

1;
# ABSTRACT: An assortment of date-/time-related CLI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DateUtils - An assortment of date-/time-related CLI utilities

=head1 VERSION

This document describes version 0.121 of App::DateUtils (from Perl distribution App-DateUtils), released on 2019-06-19.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
date/time:

=over

=item * L<dateconv>

=item * L<datediff>

=item * L<durconv>

=item * L<parse-date>

=item * L<parse-date-using-df-alami-en>

=item * L<parse-date-using-df-alami-id>

=item * L<parse-date-using-df-flexible>

=item * L<parse-date-using-df-natural>

=item * L<parse-duration>

=item * L<parse-duration-using-df-alami-en>

=item * L<parse-duration-using-df-alami-id>

=item * L<parse-duration-using-df-natural>

=item * L<parse-duration-using-td-parse>

=back

=head1 FUNCTIONS


=head2 dateconv

Usage:

 dateconv(%args) -> any

Convert date to another format.

Examples:

=over

=item * Convert "today" to epoch:

 dateconv(date => "today"); # -> [200, "OK", 1560902400]

=item * Convert epoch to ymd:

 dateconv(date => 1463702400, to => "ymd"); # -> "2016-05-20"

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

=item * B<to> => I<str> (default: "epoch")

=back

Return value:  (any)



=head2 datediff

Usage:

 datediff(%args) -> any

Diff (subtract) two dates, show as ISO8601 duration.

Examples:

=over

=item * Example #1:

 datediff( date1 => "2019-06-18T20:08:42", date2 => "2019-06-19T06:02:03"); # -> "PT9H53M21S"

=item * Example #2:

 datediff(
   date1 => "2019-06-18T20:08:42",
   date2 => "2019-06-19T06:02:03",
   as => "hms"
 );

Result:

 "09:53:21"

=item * Example #3:

 datediff(
   date1 => "2019-06-18T20:08:42",
   date2 => "2019-06-22T06:02:03",
   as => "concise_hms"
 );

Result:

 "3d 09:53:21"

=item * Example #4:

 datediff(
   date1 => "2019-06-18T20:08:42",
   date2 => "2019-06-19T06:02:03",
   as => "seconds"
 );

Result:

 35601

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<as> => I<str> (default: "iso8601")

=item * B<date1>* => I<date>

=item * B<date2>* => I<date>

=back

Return value:  (any)



=head2 durconv

Usage:

 durconv(%args) -> any

Convert duration to another format.

Examples:

=over

=item * Convert "3h2m" to number of seconds:

 durconv(duration => "3h2m"); # -> 10920

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

=item * B<to> => I<str> (default: "secs")

=back

Return value:  (any)



=head2 parse_date

Usage:

 parse_date(%args) -> [status, msg, payload, meta]

Parse date string(s) using one of several modules.

Examples:

=over

=item * Example #1:

 parse_date( dates => ["23 sep 2015", "tomorrow", "foo"]);

Result:

 [
   {
     module          => "DateTime::Format::Flexible",
     original        => "23 sep 2015",
     is_parseable    => 1,
     as_epoch        => 1442966400,
     as_datetime_obj => "2015-09-23T00:00:00",
   },
   {
     module          => "DateTime::Format::Flexible",
     original        => "tomorrow",
     is_parseable    => 1,
     as_epoch        => 1560988800,
     as_datetime_obj => "2019-06-20T00:00:00",
   },
   {
     module       => "DateTime::Format::Flexible",
     original     => "foo",
     is_parseable => 0,
     error_msg    => "Invalid date format: foo at /home/s1/perl5/perlbrew/perls/perl-5.28.2/lib/site_perl/5.28.2/Perinci/Access.pm line 81. ",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_modules> => I<bool>

Parse using all installed modules and return all the result at once.

=item * B<dates>* => I<array[str]>

=item * B<module> => I<str> (default: "DateTime::Format::Flexible")

=item * B<time_zone> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_date_using_df_alami_en

Usage:

 parse_date_using_df_alami_en(%args) -> [status, msg, payload, meta]

Parse date string(s) using DateTime::Format::Alami::EN.

Examples:

=over

=item * Example #1:

 parse_date_using_df_alami_en(dates => ["23 May"]);

Result:

 [
   {
     module          => "DateTime::Format::Alami::EN",
     original        => "23 May",
     is_parseable    => 1,
     as_epoch        => 1558569600,
     as_datetime_obj => "2019-05-23T00:00:00",
     pattern         => "p_dateymd",
   },
 ]

=item * Example #2:

 parse_date_using_df_alami_en(dates => ["foo"]);

Result:

 [
   {
     module => "DateTime::Format::Alami::EN",
     original => "foo",
     is_parseable => 0,
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

=item * B<time_zone> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_date_using_df_alami_id

Usage:

 parse_date_using_df_alami_id(%args) -> [status, msg, payload, meta]

Parse date string(s) using DateTime::Format::Alami::ID.

Examples:

=over

=item * Example #1:

 parse_date_using_df_alami_id(dates => ["23 Mei"]);

Result:

 [
   {
     module          => "DateTime::Format::Alami::ID",
     original        => "23 Mei",
     is_parseable    => 1,
     as_epoch        => 1558569600,
     as_datetime_obj => "2019-05-23T00:00:00",
     pattern         => "p_dateymd",
   },
 ]

=item * Example #2:

 parse_date_using_df_alami_id(dates => ["foo"]);

Result:

 [
   {
     module => "DateTime::Format::Alami::ID",
     original => "foo",
     is_parseable => 0,
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

=item * B<time_zone> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_date_using_df_flexible

Usage:

 parse_date_using_df_flexible(%args) -> [status, msg, payload, meta]

Parse date string(s) using DateTime::Format::Flexible.

Examples:

=over

=item * Example #1:

 parse_date_using_df_flexible(dates => ["23rd Jun"]);

Result:

 [
   {
     module          => "DateTime::Format::Flexible",
     original        => "23rd Jun",
     is_parseable    => 1,
     as_epoch        => 1561248000,
     as_datetime_obj => "2019-06-23T00:00:00",
   },
 ]

=item * Example #2:

 parse_date_using_df_flexible(dates => ["23 Dez"], lang => "de");

Result:

 [
   {
     module          => "DateTime::Format::Flexible(de)",
     original        => "23 Dez",
     is_parseable    => 1,
     as_epoch        => 1577059200,
     as_datetime_obj => "2019-12-23T00:00:00",
   },
 ]

=item * Example #3:

 parse_date_using_df_flexible(dates => ["foo"]);

Result:

 [
   {
     module       => "DateTime::Format::Flexible",
     original     => "foo",
     is_parseable => 0,
     error_msg    => "Invalid date format: foo at /home/s1/perl5/perlbrew/perls/perl-5.28.2/lib/site_perl/5.28.2/Perinci/Access.pm line 81. ",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

=item * B<lang> => I<str> (default: "en")

=item * B<time_zone> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_date_using_df_natural

Usage:

 parse_date_using_df_natural(%args) -> [status, msg, payload, meta]

Parse date string(s) using DateTime::Format::Natural.

Examples:

=over

=item * Example #1:

 parse_date_using_df_natural(dates => ["23rd Jun"]);

Result:

 [
   {
     module          => "DateTime::Format::Natural",
     original        => "23rd Jun",
     is_parseable    => 1,
     as_epoch        => 1561248000,
     as_datetime_obj => "2019-06-23T00:00:00",
   },
 ]

=item * Example #2:

 parse_date_using_df_natural(dates => ["foo"]);

Result:

 [
   {
     module       => "DateTime::Format::Natural",
     original     => "foo",
     is_parseable => 0,
     error_msg    => "'foo' does not parse (perhaps you have some garbage?)",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

=item * B<time_zone> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_duration

Usage:

 parse_duration(%args) -> [status, msg, payload, meta]

Parse duration string(s) using one of several modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_modules> => I<bool>

Parse using all installed modules and return all the result at once.

=item * B<durations>* => I<array[str]>

=item * B<module> => I<str> (default: "Time::Duration::Parse")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_duration_using_df_alami_en

Usage:

 parse_duration_using_df_alami_en(%args) -> [status, msg, payload, meta]

Parse duration string(s) using DateTime::Format::Alami::EN.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_alami_en(durations => ["2h, 3mins"]);

Result:

 [
   {
     module       => "DateTime::Format::Alami::EN",
     original     => "2h, 3mins",
     is_parseable => 1,
     as_secs      => 7380,
     as_dtdur_obj => "PT2H3M",
   },
 ]

=item * Example #2:

 parse_duration_using_df_alami_en(durations => ["foo"]);

Result:

 [
   {
     module => "DateTime::Format::Alami::EN",
     original => "foo",
     is_parseable => 0,
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_duration_using_df_alami_id

Usage:

 parse_duration_using_df_alami_id(%args) -> [status, msg, payload, meta]

Parse duration string(s) using DateTime::Format::Alami::ID.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_alami_id(durations => ["2j, 3mnt"]);

Result:

 [
   {
     module       => "DateTime::Format::Alami::ID",
     original     => "2j, 3mnt",
     is_parseable => 1,
     as_secs      => 7380,
     as_dtdur_obj => "PT2H3M",
   },
 ]

=item * Example #2:

 parse_duration_using_df_alami_id(durations => ["foo"]);

Result:

 [
   {
     module => "DateTime::Format::Alami::ID",
     original => "foo",
     is_parseable => 0,
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_duration_using_df_natural

Usage:

 parse_duration_using_df_natural(%args) -> [status, msg, payload, meta]

Parse duration string(s) using DateTime::Format::Natural.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_natural(durations => ["for 2 weeks"]);

Result:

 [
   {
     module => "DateTime::Format::Natural",
     original => "for 2 weeks",
     is_parseable => 1,
     as_secs => 1209600,
     as_dtdur_obj => "P14D",
     date2 => "2019-07-03T13:29:56",
     date1 => "2019-06-19T13:29:56",
   },
 ]

=item * Example #2:

 parse_duration_using_df_natural(durations => ["from 23 Jun to 29 Jun"]);

Result:

 [
   {
     module => "DateTime::Format::Natural",
     original => "from 23 Jun to 29 Jun",
     is_parseable => 1,
     as_secs => 815404,
     as_dtdur_obj => "P9DT10H30M4S",
     date2 => "2019-06-29T00:00:00",
     date1 => "2019-06-19T13:29:56",
   },
 ]

=item * Example #3:

 parse_duration_using_df_natural(durations => ["foo"]);

Result:

 [
   {
     module       => "DateTime::Format::Natural",
     original     => "foo",
     is_parseable => 0,
     error_msg    => "'foo' does not parse (perhaps you have some garbage?)",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_duration_using_td_parse

Usage:

 parse_duration_using_td_parse(%args) -> [status, msg, payload, meta]

Parse duration string(s) using Time::Duration::Parse.

Examples:

=over

=item * Example #1:

 parse_duration_using_td_parse(durations => ["2 days 13 hours"]);

Result:

 [
   {
     module       => "Time::Duration::Parse",
     original     => "2 days 13 hours",
     is_parseable => 1,
     as_secs      => 219600,
   },
 ]

=item * Example #2:

 parse_duration_using_td_parse(durations => ["foo"]);

Result:

 [
   {
     module       => "Time::Duration::Parse",
     original     => "foo",
     is_parseable => 0,
     error_msg    => "Unknown timespec: foo at lib/App/DateUtils.pm line 372. ",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DateUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DateUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DateUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<dateparse>. The official CLI for DateTime::Format::Natural.

L<App::datecalc>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
