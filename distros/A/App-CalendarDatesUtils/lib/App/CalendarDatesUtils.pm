package App::CalendarDatesUtils;

our $DATE = '2019-05-28'; # DATE
our $VERSION = '0.005'; # VERSION

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
        year => {
            summary => 'Specify year of dates to list',
            description => <<'_',

The default is to list dates in the current year. You can specify all_years
instead to list dates from all available years.

_
            schema => 'int*',
            pos => 0,
        },
        month => {
            schema => ['int*', in=>[1, 12]],
            pos => 1,
        },
        day => {
            schema => ['int*', in=>[1, 31]],
            pos => 2,
        },
        all_years => {
            summary => 'List dates from all available years '.
                'instead of a single year',
            schema => 'true*',
        },
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'modules',
            schema => ['array*', of=>'perl::modname*'],
            cmdline_aliases => {m=>{}},
            'x.element_completion' => [perl_modname => {ns_prefix=>'Calendar::Dates::'}],
        },
        all_modules => {
            summary => 'Use all installed Calendar::Dates::* modules',
            schema => 'true*',
        },
        params => {
            summary => 'Specify parameters',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'param',
            'schema' => ['hash*', of=>'str*'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        past => {
            schema => 'bool*',
            'summary' => "Filter entries that are less than (at least) today's date",
        },
    },
    args_rels => {
        'req_one&' => [
            ['modules', 'all_modules'],
        ],
        'choose_one&' => [
            ['year', 'all_years'],
        ],
    },
};
sub list_calendar_dates {
    my %args = @_;

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
    } else {
        $modules = $args{modules};
    }

    my @rows;
    for my $mod (@$modules) {
        $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        my $years;
        if ($args{all_years}) {
            $years = [ $mod->get_min_year .. $mod->get_max_year ];
        } else {
            $years = [ $year ];
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

This document describes version 0.005 of App::CalendarDatesUtils (from Perl distribution App-CalendarDatesUtils), released on 2019-05-28.

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

=item * B<all_modules> => I<true>

Use all installed Calendar::Dates::* modules.

=item * B<all_years> => I<true>

List dates from all available years instead of a single year.

=item * B<day> => I<int>

=item * B<detail> => I<bool>

=item * B<modules> => I<array[perl::modname]>

=item * B<month> => I<int>

=item * B<params> => I<hash>

Specify parameters.

=item * B<past> => I<bool>

Filter entries that are less than (at least) today's date.

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
