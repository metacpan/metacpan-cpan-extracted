package App::CalendarDatesUtils;

our $DATE = '2019-06-28'; # DATE
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::ger;

our %SPEC;

$SPEC{list_calendar_dates_modules} = {
    v => 1.1,
    summary => 'List Calendar::Dates::* modules, without the prefix',
};
sub list_calendar_dates_modules {
    require PERLANCAR::Module::List;

    my $mods = PERLANCAR::Module::List::list_modules(
        "Calendar::Dates::", {list_modules=>1, recurse=>1});
    my @res = sort keys %$mods;
    for (@res) { s/\ACalendar::Dates::// }
    [200, "OK" ,\@res];
}

$SPEC{list_calendar_dates} = {
    v => 1.1,
    summary => 'List dates from one or more Calendar::Dates::* modules',
    args => {
        action => {
            schema => ['str*', in=>['list-dates', 'list-modules']],
            default => 'list-dates',
            cmdline_aliases => {
                L => {is_flag=>1, summary=>'List all Calendar::Dates modules (eqv to --action=list-modules)', code=>sub { $_[0]{action} = 'list-modules' }},
            },
        },
        year => {
            summary => 'Specify year of dates to list',
            description => <<'_',

The default is to list dates in the current year. You can specify all_years
instead to list dates from all available years.

_
            schema => 'int*',
            pos => 0,
            cmdline_aliases => {Y=>{}},
            tags => ['category:entry-filtering'],
        },
        min_year => {
            schema => 'int*',
            tags => ['category:entry-filtering'],
        },
        max_year => {
            schema => 'int*',
            tags => ['category:entry-filtering'],
        },
        month => {
            schema => ['int*', between=>[1, 12]],
            pos => 1,
            cmdline_aliases => {M=>{}},
            tags => ['category:entry-filtering'],
        },
        day => {
            schema => ['int*', between=>[1, 31]],
            pos => 2,
            cmdline_aliases => {D=>{}},
            tags => ['category:entry-filtering'],
        },
        all_years => {
            summary => 'List dates from all available years '.
                'instead of a single year',
            schema => 'true*',
            tags => ['category:entry-filtering'],
            description => <<'_',

Note that by default, following common usage pattern, dates with years that are
too old (< 10 years ago) or that are too far into the future (> 10 years from
now) are not included, unless you combine this option with --all-entries (-A).

_
        },
        modules => {
            summary => 'Name(s) of Calendar::Dates::* module (without the prefix)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'modules',
            schema => ['array*', of=>'perl::modname*'],
            cmdline_aliases => {m=>{}},
            'x.element_completion' => [perl_modname => {ns_prefix=>'Calendar::Dates::'}],
            tags => ['category:module-selection'],
        },
        all_modules => {
            summary => 'Use all installed Calendar::Dates::* modules',
            schema => 'true*',
            cmdline_aliases => {a=>{}},
            tags => ['category:module-selection'],
        },
        all_entries => {
            summary => 'Return all entries (include low-priority ones)',
            schema => 'true*',
            cmdline_aliases => {A=>{}},
            description => <<'_',

By default, low-priority entries (entries tagged `low-priority`) are not
included. This option will include those entries.

When combined with --all-years, this option will also cause all very early years
and all years far into the future to be included also.

_
            tags => ['category:entry-filtering'],
        },
        include_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_tag',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {t=>{}},
            tags => ['category:entry-filtering'],
        },
        exclude_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'exclude_tag',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {T=>{}},
            tags => ['category:entry-filtering'],
        },
        params => {
            summary => 'Specify parameters',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'param',
            'schema' => ['hash*', of=>'str*'],
        },
        detail => {
            summary => 'Whether to show detailed record for each date',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        past => {
            schema => 'bool*',
            'summary' => "Only show entries that are less than (at least) today's date",
            'summary.alt.bool.not' => "Filter entries that are less than (at least) today's date",
            tags => ['category:entry-filtering'],
        },
    },
    args_rels => {
        'choose_one&' => [
            ['modules', 'all_modules'],
            ['year', 'all_years'],
            ['year', 'min_year'],
            ['year', 'max_year'],
        ],
        'choose_all&' => [
        ],
    },
};
sub list_calendar_dates {
    my %args = @_;

    my $action = $args{action} // 'list-dates';
    if ($action eq 'list-modules') {
        return list_calendar_dates_modules();
    }

    my @lt = localtime;
    my $year_today = $lt[5]+1900;
    my $mon_today  = $lt[4]+1;
    my $day_today  = $lt[3];
    #log_trace "date_today: %04d-%02d-%02d", $year_today, $mon_today, $day_today;
    #my $date_today = sprintf "%04d-%02d-%02d", $year_today, $mon_today, $day_today;

    my $year = $args{year} // $year_today;
    my $mon  = $args{month};
    my $day  = $args{day};

    my $modules;
    if ($args{all_modules}) {
        $modules = list_calendar_dates_modules()->[2];
    } elsif ($args{modules}) {
        $modules = $args{modules};
    } else {
        return [400, "Please specify modules or all_modules"];
    }

    my $params = {};
    $params->{include_tags} = delete $args{include_tags}
        if $args{include_tags};
    $params->{exclude_tags} = delete $args{exclude_tags}
        if $args{exclude_tags};
    $params->{all} = delete $args{all_entries};

    my @rows;
    for my $mod (@$modules) {
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        my $years;
        my $min = $mod->get_min_year;
        my $max = $mod->get_max_year;
        if ($args{all_years}) {
            if ($min < $year_today - 10 && !$args{all_entries}) {
                warn "Warning: There are dates with year earlier than ".
                    ($year_today - 10). " that are not included, ".
                    "use --all-entries to include them\n";
                $min = $year_today - 10;
            }
            if ($max > $year_today + 10 && !$args{all_entries}) {
                warn "Warning: There are dates with year later than ".
                    ($year_today + 10). " that are not included, ".
                    "use --all-entries to include them\n";
                $max = $year_today + 10;
            }
            $years = [$min..$max];
        } elsif (defined $args{min_year} || defined $args{max_year}) {
            $years = [($args{min_year} // $year_today) .. ($args{max_year} // $year_today)];
        } elsif (defined $args{year}) {
            $years = [ $year ];
        } else {
            return [400, "Please specify year, or min_year/max_year, or all_years"];
        }

        for my $y (@$years) {
            my $res;
            eval {
                my @args = ($y, $mon, $day);
                if ($args{params} && keys %{$args{params}}) {
                    unshift @args, $args{params};
                }
                $res = $mod->get_entries(@args);
            };
            if ($@) {
                warn "Can't get entries from $mod (year=$y): $@, skipped";
                next;
            }
            for my $item (@$res) {
                if (defined $args{past}) {
                    my $date_cmp =
                        $item->{year}  <=> $year_today ||
                        $item->{month} <=> $mon_today  ||
                        $item->{day}   <=> $day_today;
                    next if  $args{past} &&  $date_cmp >  0;
                    next if !$args{past} &&  $date_cmp <= 0;
                }
                push @rows, $item;
            }
        }
    }

    unless ($args{detail}) {
        @rows = map {$_->{date}} @rows;
    }

    [200, "OK", \@rows];
}

1;
# ABSTRACT: Utilities related to Calendar::Dates

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CalendarDatesUtils - Utilities related to Calendar::Dates

=head1 VERSION

This document describes version 0.009 of App::CalendarDatesUtils (from Perl distribution App-CalendarDatesUtils), released on 2019-06-28.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<list-calendar-dates>

=item * L<list-calendar-dates-modules>

=back

=head1 FUNCTIONS


=head2 list_calendar_dates

Usage:

 list_calendar_dates(%args) -> [status, msg, payload, meta]

List dates from one or more Calendar::Dates::* modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "list-dates")

=item * B<all_entries> => I<true>

Return all entries (include low-priority ones).

By default, low-priority entries (entries tagged C<low-priority>) are not
included. This option will include those entries.

When combined with --all-years, this option will also cause all very early years
and all years far into the future to be included also.

=item * B<all_modules> => I<true>

Use all installed Calendar::Dates::* modules.

=item * B<all_years> => I<true>

List dates from all available years instead of a single year.

Note that by default, following common usage pattern, dates with years that are
too old (< 10 years ago) or that are too far into the future (> 10 years from
now) are not included, unless you combine this option with --all-entries (-A).

=item * B<day> => I<int>

=item * B<detail> => I<bool>

Whether to show detailed record for each date.

=item * B<exclude_tags> => I<array[str]>

=item * B<include_tags> => I<array[str]>

=item * B<max_year> => I<int>

=item * B<min_year> => I<int>

=item * B<modules> => I<array[perl::modname]>

Name(s) of Calendar::Dates::* module (without the prefix).

=item * B<month> => I<int>

=item * B<params> => I<hash>

Specify parameters.

=item * B<past> => I<bool>

Only show entries that are less than (at least) today's date.

=item * B<year> => I<int>

Specify year of dates to list.

The default is to list dates in the current year. You can specify all_years
instead to list dates from all available years.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_calendar_dates_modules

Usage:

 list_calendar_dates_modules() -> [status, msg, payload, meta]

List Calendar::Dates::* modules, without the prefix.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CalendarDatesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CalendarDatesUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CalendarDatesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
