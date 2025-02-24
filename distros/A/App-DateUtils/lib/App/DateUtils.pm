package App::DateUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'App-DateUtils'; # DIST
our $VERSION = '0.128'; # VERSION

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
    #'DateTime::Format::Alami::EN',
    #'DateTime::Format::Alami::ID',
    'DateTime::Format::Flexible',
    'DateTime::Format::Flexible(de)',
    'DateTime::Format::Flexible(es)',
    'DateTime::Format::Natural',

    'Date::Parse',
);

my @parse_duration_modules = (
    #'DateTime::Format::Alami::EN',
    #'DateTime::Format::Alami::ID',
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
    require DateTime::Format::ISO8601::Format;

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
                    $rec->{as_datetime_obj_tz_local} = DateTime::Format::ISO8601::Format->new->format_datetime($res->{DateTime}->set_time_zone("local"));
                    $rec->{as_datetime_obj_tz_utc}   = DateTime::Format::ISO8601::Format->new->format_datetime($res->{DateTime}->set_time_zone("UTC"));
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
                    $rec->{as_datetime_obj_tz_local} = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("local"));
                    $rec->{as_datetime_obj_tz_utc}   = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("UTC"));
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
                    $rec->{as_datetime_obj_tz_local} = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("local"));
                    $rec->{as_datetime_obj_tz_utc}   = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("UTC"));
                } else {
                    $rec->{is_parseable} = 0;
                    $rec->{error_msg} = $parser->error;
                }
            } elsif ($mod eq 'Date::Parse') {
                my $time = Date::Parse::str2time($date);
                if (defined $time) {
                    $rec->{is_parseable} = 1;
                    $rec->{as_epoch} = $time;
                    my $dt = DateTime->from_epoch(epoch => $time);
                    $rec->{as_datetime_obj} = "$dt";
                    $rec->{as_datetime_obj_tz_local} = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("local"));
                    $rec->{as_datetime_obj_tz_utc}   = DateTime::Format::ISO8601::Format->new->format_datetime($dt->set_time_zone("UTC"));
                } else {
                    $rec->{is_parseable} = 0;
                }
            }
          PUSH_RESULT:
            push @res, $rec;
        } # for dates
    } # for mods

    [200, "OK", \@res, {'table.fields'=>[qw/module original is_parseable as_epoch as_datetime_obj as_datetime_obj_tz_local as_datetime_obj_tz_utc error_msg/]}];
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
    summary => 'Convert date from one format to another',
    args => {
        date => {
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['From_str::iso8601', 'From_str::natural'],
            }],
            req => 1,
            pos => 0,
        },
        to => {
            schema => ['str*', in=>[qw/epoch ymd iso8601 ALL/]],
            default => 'epoch',
            cmdline_aliases => {
                a => {is_flag=>1, summary => 'Shortcut for --to=ALL', code => sub {$_[0]{to} = 'ALL'}},
            },
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
        {
            summary => 'Convert epoch to iso8601',
            args => {date => '1580446441', to=>'iso8601'},
            result => '2020-01-31T04:54:01Z',
        },
        {
            summary => 'Convert iso8601 to epoch',
            args => {date => '2020-01-31T04:54:01Z', to=>'epoch'},
            result => '1580446441',
        },
        {
            summary => 'Show all possible conversions',
            args => {date => 'now', to => 'ALL'},
            test => 0,
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
    } elsif ($to eq 'iso8601') {
        require DateTime::Format::ISO8601::Format;
        return DateTime::Format::ISO8601::Format->new->format_datetime($date);
    } elsif ($to eq 'ALL') {
        return {
            epoch => $date->epoch,
            ymd   => $date->ymd,
            iso8601 => do {
                require DateTime::Format::ISO8601::Format;
                DateTime::Format::ISO8601::Format->new->format_datetime($date);
            },
        };
    } else {
        die "Unknown format '$to'";
    }
}

$SPEC{strftime} = {
    v => 1.1,
    summary => 'Format date using strftime()',
    args => {
        format => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        date => {
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['From_str::iso8601', 'From_str::natural'],
            }],
            pos => 1,
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Format current time as yyyy-mm-dd',
            args => {format => '%Y-%m-%d'},
            test => 0,
        },
        {
            summary => 'Format a specific time as yyyy-mm-dd',
            args => {format => '%Y-%m-%d', date => 'tomorrow'},
            test => 0,
        },
    ],
};
sub strftime {
    require DateTime;
    require POSIX;

    my %args = @_;
    my $format = $args{format};
    my $date   = $args{date} // DateTime->now;

    POSIX::strftime($format, localtime($date->epoch));
}

$SPEC{strftimeq} = {
    v => 1.1,
    summary => 'Format date using strftimeq()',
    description => <<'_',

strftimeq() is like POSIX's strftime(), but allows an extra conversion `%(...)q`
to insert Perl code, for flexibility in customizing format. For more details,
read <pm:Date::strftimeq>.

_
    args => {
        format => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        date => {
            schema => ['date*', {
                'x.perl.coerce_to' => 'DateTime',
                'x.perl.coerce_rules' => ['From_str::iso8601', 'From_str::natural'],
            }],
            pos => 1,
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Format current time as yyyy-mm-dd but add "Sun" when the date is Sunday',
            args => {format => '%Y-%m-%d%( require Date::DayOfWeek; Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 0 ? "sun":"" )q'},
            test => 0,
        },
    ],
};
sub strftimeq {
    require DateTime;
    require Date::strftimeq;
    require POSIX;

    my %args = @_;
    my $format = $args{format};
    my $date   = $args{date} // DateTime->now;

    Date::strftimeq::strftimeq($format, localtime($date->epoch));
}

$SPEC{durconv} = {
    v => 1.1,
    summary => 'Convert duration from one format to another',
    args => {
        duration => {
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
            }],
            req => 1,
            pos => 0,
        },
        to => {
            schema => ['str*', in=>[qw/secs hash iso8601 ALL/]],
            default => 'secs',
            cmdline_aliases => {
                a => {is_flag=>1, summary => 'Shortcut for --to=ALL', code => sub {$_[0]{to} = 'ALL'}},
            },
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Convert "3h2m" to number of seconds',
            args => {duration => '3h2m'},
            result => 10920,
        },
        {
            summary => 'Convert "3h2m" to iso8601',
            args => {duration => '3h2m', to=>'iso8601'},
            result => 'PT3H2M',
        },
        {
            summary => 'Show all possible conversions',
            args => {duration => '3h2m', to => 'ALL'},
            test => 0,
        },
    ],
};
sub durconv {
    my %args = @_;
    my $dur = $args{duration};
    my $to  = $args{to};

    my $code_secs = sub {
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
    };

    my $code_hash = sub {
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
    };

    my $code_iso8601 = sub {
        require DateTime::Format::Duration::ISO8601;
        DateTime::Format::Duration::ISO8601->new->format_duration($dur);
    };

    if ($to eq 'secs') {
        return $code_secs->();
    } elsif ($to eq 'hash') {
        return $code_hash->();
    } elsif ($to eq 'hash') {
        return $code_hash->();
    } elsif ($to eq 'iso8601') {
        return $code_iso8601->();
    } elsif ($to eq 'ALL') {
        return {
            secs => $code_secs->(),
            hash => $code_hash->(),
            iso8601 => $code_iso8601->(),
        };
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
                'x.perl.coerce_rules' => ['From_str::natural','From_str::iso8601','From_float::epoch'],
                'x.perl.coerce_to' => 'DateTime',
            }],
            req => 1,
            pos => 0,
        },
        date2 => {
            schema => ['date*', {
                'x.perl.coerce_rules' => ['From_str::natural','From_str::iso8601','From_float::epoch'],
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

This document describes version 0.128 of App::DateUtils (from Perl distribution App-DateUtils), released on 2024-03-07.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
date/time:

=over

=item 1. L<dateconv>

=item 2. L<datediff>

=item 3. L<durconv>

=item 4. L<parse-date>

=item 5. L<parse-date-using-df-alami-en>

=item 6. L<parse-date-using-df-alami-id>

=item 7. L<parse-date-using-df-flexible>

=item 8. L<parse-date-using-df-natural>

=item 9. L<parse-duration>

=item 10. L<parse-duration-using-df-alami-en>

=item 11. L<parse-duration-using-df-alami-id>

=item 12. L<parse-duration-using-df-natural>

=item 13. L<parse-duration-using-td-parse>

=item 14. L<strftime>

=item 15. L<strftimeq>

=back

=head1 FUNCTIONS


=head2 dateconv

Usage:

 dateconv(%args) -> any

Convert date from one format to another.

Examples:

=over

=item * Convert "today" to epoch:

 dateconv(date => "today"); # -> 1709769600

=item * Convert epoch to ymd:

 dateconv(date => 1463702400, to => "ymd"); # -> "2016-05-20"

=item * Convert epoch to iso8601:

 dateconv(date => 1580446441, to => "iso8601"); # -> "2020-01-31T04:54:01Z"

=item * Convert iso8601 to epoch:

 dateconv(date => "2020-01-31T04:54:01Z", to => "epoch"); # -> 1580446441

=item * Show all possible conversions:

 dateconv(date => "now", to => "ALL");

Result:

 {
   epoch => 1709802621,
   iso8601 => "2024-03-07T09:10:21.491146Z",
   ymd => "2024-03-07",
 }

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

(No description)

=item * B<to> => I<str> (default: "epoch")

(No description)


=back

Return value:  (any)



=head2 datediff

Usage:

 datediff(%args) -> any

Diff (subtract) two dates, show as ISO8601 duration.

Examples:

=over

=item * Example #1:

 datediff(date1 => "2019-06-18T20:08:42", date2 => "2019-06-19T06:02:03"); # -> "PT9H53M21S"

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

(No description)

=item * B<date1>* => I<date>

(No description)

=item * B<date2>* => I<date>

(No description)


=back

Return value:  (any)



=head2 durconv

Usage:

 durconv(%args) -> any

Convert duration from one format to another.

Examples:

=over

=item * Convert "3h2m" to number of seconds:

 durconv(duration => "3h2m"); # -> 10920

=item * Convert "3h2m" to iso8601:

 durconv(duration => "3h2m", to => "iso8601"); # -> "PT3H2M"

=item * Show all possible conversions:

 durconv(duration => "3h2m", to => "ALL");

Result:

 {
   hash    => { hours => 3, minutes => 2 },
   iso8601 => "PT3H2M",
   secs    => 10920,
 }

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

(No description)

=item * B<to> => I<str> (default: "secs")

(No description)


=back

Return value:  (any)



=head2 parse_date

Usage:

 parse_date(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse date string(s) using one of several modules.

Examples:

=over

=item * Example #1:

 parse_date(dates => ["23 sep 2015", "tomorrow", "foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Flexible",
       original => "23 sep 2015",
       is_parseable => 1,
       as_epoch => 1442966400,
       as_datetime_obj => "2015-09-23T00:00:00",
       as_datetime_obj_tz_local => "2015-09-23T00:00:00+07:00",
       as_datetime_obj_tz_utc => "2015-09-22T17:00:00Z",
     },
     {
       module => "DateTime::Format::Flexible",
       original => "tomorrow",
       is_parseable => 1,
       as_epoch => 1709856000,
       as_datetime_obj => "2024-03-08T00:00:00",
       as_datetime_obj_tz_local => "2024-03-08T00:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-03-07T17:00:00Z",
     },
     {
       module       => "DateTime::Format::Flexible",
       original     => "foo",
       is_parseable => 0,
       error_msg    => "Invalid date format: foo at /home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/Perinci/Access.pm line 81. ",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_modules> => I<bool>

Parse using all installed modules and return all the result at once.

=item * B<dates>* => I<array[str]>

(No description)

=item * B<module> => I<str> (default: "DateTime::Format::Flexible")

(No description)

=item * B<time_zone> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_date_using_df_alami_en

Usage:

 parse_date_using_df_alami_en(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse date string(s) using DateTime::Format::Alami::EN.

Examples:

=over

=item * Example #1:

 parse_date_using_df_alami_en(dates => ["23 May"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::EN",
       original => "23 May",
       is_parseable => 1,
       as_epoch => 1716422400,
       as_datetime_obj => "2024-05-23T00:00:00",
       as_datetime_obj_tz_local => "2024-05-23T07:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-05-23T00:00:00Z",
       pattern => "p_dateymd",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_date_using_df_alami_en(dates => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::EN",
       original => "foo",
       is_parseable => 0,
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

(No description)

=item * B<time_zone> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_date_using_df_alami_id

Usage:

 parse_date_using_df_alami_id(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse date string(s) using DateTime::Format::Alami::ID.

Examples:

=over

=item * Example #1:

 parse_date_using_df_alami_id(dates => ["23 Mei"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::ID",
       original => "23 Mei",
       is_parseable => 1,
       as_epoch => 1716422400,
       as_datetime_obj => "2024-05-23T00:00:00",
       as_datetime_obj_tz_local => "2024-05-23T07:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-05-23T00:00:00Z",
       pattern => "p_dateymd",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_date_using_df_alami_id(dates => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::ID",
       original => "foo",
       is_parseable => 0,
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

(No description)

=item * B<time_zone> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_date_using_df_flexible

Usage:

 parse_date_using_df_flexible(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse date string(s) using DateTime::Format::Flexible.

Examples:

=over

=item * Example #1:

 parse_date_using_df_flexible(dates => ["23rd Jun"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Flexible",
       original => "23rd Jun",
       is_parseable => 1,
       as_epoch => 1719100800,
       as_datetime_obj => "2024-06-23T00:00:00",
       as_datetime_obj_tz_local => "2024-06-23T00:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-06-22T17:00:00Z",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_date_using_df_flexible(dates => ["23 Dez"], lang => "de");

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Flexible(de)",
       original => "23 Dez",
       is_parseable => 1,
       as_epoch => 1734912000,
       as_datetime_obj => "2024-12-23T00:00:00",
       as_datetime_obj_tz_local => "2024-12-23T00:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-12-22T17:00:00Z",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=item * Example #3:

 parse_date_using_df_flexible(dates => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "DateTime::Format::Flexible",
       original     => "foo",
       is_parseable => 0,
       error_msg    => "Invalid date format: foo at /home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/Perinci/Access.pm line 81. ",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

(No description)

=item * B<lang> => I<str> (default: "en")

(No description)

=item * B<time_zone> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_date_using_df_natural

Usage:

 parse_date_using_df_natural(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse date string(s) using DateTime::Format::Natural.

Examples:

=over

=item * Example #1:

 parse_date_using_df_natural(dates => ["23rd Jun"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Natural",
       original => "23rd Jun",
       is_parseable => 1,
       as_epoch => 1719100800,
       as_datetime_obj => "2024-06-23T00:00:00",
       as_datetime_obj_tz_local => "2024-06-23T00:00:00+07:00",
       as_datetime_obj_tz_utc => "2024-06-22T17:00:00Z",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_date_using_df_natural(dates => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "DateTime::Format::Natural",
       original     => "foo",
       is_parseable => 0,
       error_msg    => "'foo' does not parse (perhaps you have some garbage?)",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_epoch",
       "as_datetime_obj",
       "as_datetime_obj_tz_local",
       "as_datetime_obj_tz_utc",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[str]>

(No description)

=item * B<time_zone> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_duration

Usage:

 parse_duration(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse duration string(s) using one of several modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_modules> => I<bool>

Parse using all installed modules and return all the result at once.

=item * B<durations>* => I<array[str]>

(No description)

=item * B<module> => I<str> (default: "Time::Duration::Parse")

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_duration_using_df_alami_en

Usage:

 parse_duration_using_df_alami_en(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse duration string(s) using DateTime::Format::Alami::EN.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_alami_en(durations => ["2h, 3mins"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "DateTime::Format::Alami::EN",
       original     => "2h, 3mins",
       is_parseable => 1,
       as_secs      => 7380,
       as_dtdur_obj => "PT2H3M",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_duration_using_df_alami_en(durations => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::EN",
       original => "foo",
       is_parseable => 0,
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_duration_using_df_alami_id

Usage:

 parse_duration_using_df_alami_id(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse duration string(s) using DateTime::Format::Alami::ID.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_alami_id(durations => ["2j, 3mnt"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "DateTime::Format::Alami::ID",
       original     => "2j, 3mnt",
       is_parseable => 1,
       as_secs      => 7380,
       as_dtdur_obj => "PT2H3M",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_duration_using_df_alami_id(durations => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Alami::ID",
       original => "foo",
       is_parseable => 0,
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_duration_using_df_natural

Usage:

 parse_duration_using_df_natural(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse duration string(s) using DateTime::Format::Natural.

Examples:

=over

=item * Example #1:

 parse_duration_using_df_natural(durations => ["for 2 weeks"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Natural",
       original => "for 2 weeks",
       is_parseable => 1,
       as_secs => 1209600.000768,
       as_dtdur_obj => "P14DT0.000768S",
       date2 => "2024-03-21T09:10:21",
       date1 => "2024-03-07T09:10:21",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_duration_using_df_natural(durations => ["from 23 Jun to 29 Jun"]);

Result:

 [
   200,
   "OK",
   [
     {
       module => "DateTime::Format::Natural",
       original => "from 23 Jun to 29 Jun",
       is_parseable => 1,
       as_secs => 9757178.285926,
       as_dtdur_obj => "P3M21DT14H49M38.285926S",
       date1 => "2024-03-07T09:10:21",
       date2 => "2024-06-29T00:00:00",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=item * Example #3:

 parse_duration_using_df_natural(durations => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "DateTime::Format::Natural",
       original     => "foo",
       is_parseable => 0,
       error_msg    => "'foo' does not parse (perhaps you have some garbage?)",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_duration_using_td_parse

Usage:

 parse_duration_using_td_parse(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse duration string(s) using Time::Duration::Parse.

Examples:

=over

=item * Example #1:

 parse_duration_using_td_parse(durations => ["2 days 13 hours"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "Time::Duration::Parse",
       original     => "2 days 13 hours",
       is_parseable => 1,
       as_secs      => 219600,
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=item * Example #2:

 parse_duration_using_td_parse(durations => ["foo"]);

Result:

 [
   200,
   "OK",
   [
     {
       module       => "Time::Duration::Parse",
       original     => "foo",
       is_parseable => 0,
       error_msg    => "Unknown timespec: foo at (eval 2220) line 385. ",
     },
   ],
   {
     "table.fields" => [
       "module",
       "original",
       "is_parseable",
       "as_secs",
       "as_dtdur_obj",
       "error_msg",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<durations>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 strftime

Usage:

 strftime(%args) -> any

Format date using strftime().

Examples:

=over

=item * Format current time as yyyy-mm-dd:

 strftime(format => "%Y-%m-%d"); # -> "2024-03-07"

=item * Format a specific time as yyyy-mm-dd:

 strftime(format => "%Y-%m-%d", date => "tomorrow"); # -> "2024-03-08"

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<date>

(No description)

=item * B<format>* => I<str>

(No description)


=back

Return value:  (any)



=head2 strftimeq

Usage:

 strftimeq(%args) -> any

Format date using strftimeq().

Examples:

=over

=item * Format current time as yyyy-mm-dd but add "Sun" when the date is Sunday:

 strftimeq(format => "%Y-%m-%d%( require Date::DayOfWeek; Date::DayOfWeek::dayofweek(\$_[3], \$_[4]+1, \$_[5]+1900) == 0 ? \"sun\":\"\" )q");

Result:

 "2024-03-07"

=back

strftimeq() is like POSIX's strftime(), but allows an extra conversion C<%(...)q>
to insert Perl code, for flexibility in customizing format. For more details,
read L<Date::strftimeq>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<date>

(No description)

=item * B<format>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DateUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DateUtils>.

=head1 SEE ALSO


L<dateparse>. Perinci::To::POD=HASH(0x555af311e1c8).

L<App::datecalc>

L<App::TimeZoneUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2021, 2020, 2019, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DateUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
