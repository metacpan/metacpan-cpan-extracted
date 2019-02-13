package App::CalendarDatesUtils;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

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
    summary => 'List dates from a Calendar::Dates::* module',
    args => {
        year => {
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
        module => {
            schema => 'perl::modname*',
            req => 1,
            cmdline_aliases => {m=>{}},
            'x.completion' => [perl_modname => {ns_prefix=>'Calendar::Dates'}],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_calendar_dates {
    my %args = @_;

    my $year = $args{year} // (localtime)[5]+1900;
    my $mon  = $args{month};
    my $day  = $args{day};

    my $mod = $args{module};
    $mod = "Calendar::Dates::$mod" unless $mod =~ /\ACalendar::Dates::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $rows = $mod->get_entries($year, $mon, $day);

    unless ($args{detail}) {
        $rows = [map {$_->{date}} @$rows];
    }

    [200, "OK", $rows];
}

1;
# ABSTRACT: Utilities related to Calendar::Dates

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CalendarDatesUtils - Utilities related to Calendar::Dates

=head1 VERSION

This document describes version 0.001 of App::CalendarDatesUtils (from Perl distribution App-CalendarDatesUtils), released on 2019-02-13.

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

List dates from a Calendar::Dates::* module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<day> => I<int>

=item * B<detail> => I<bool>

=item * B<module>* => I<perl::modname>

=item * B<month> => I<int>

=item * B<year> => I<int>

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
