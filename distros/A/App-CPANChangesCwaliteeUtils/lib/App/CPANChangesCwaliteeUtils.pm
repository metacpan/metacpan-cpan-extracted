package App::CPANChangesCwaliteeUtils;

our $DATE = '2019-08-02'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Cwalitee::Common;

our %SPEC;

$SPEC{calc_cpan_changes_cwalitee} = {
    v => 1.1,
    summary => 'Calculate CPAN Changes cwalitee',
    args => {
        Cwalitee::Common::args_calc('CPAN::Changes::'),
        path => {
            schema => 'pathname*',
            pos => 0,
            # in our version, path is optional. we try to look at files named
            # Changes, ChangeLog, etc and use that.
        },
    },
    examples => [
        {
            summary => 'Run against the the Changes of App-CPANChangesCwaliteeUtils distribution',
            args => {},
            test => 0,
        },
    ],
};
sub calc_cpan_changes_cwalitee {
    require CPAN::Changes::Cwalitee;

    my %args = @_;

    my $path = delete $args{path};
    {
        last if defined $path;

        for my $f (
            "Changes",
            "CHANGES",
            "ChangeLog",
            "CHANGELOG",
            (grep {/change|chn?g/i} glob("*")),
        ) {
            if (-f $f) {
                $path = $f;
                last;
            }
        }
    }
    unless ($path) {
        return [400, "Please specify path"];
    }

    CPAN::Changes::Cwalitee::calc_cpan_changes_cwalitee(
        path => $path,
        %args,
    );
}

1;
# ABSTRACT: CLI Utilities related to CPAN Changes cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANChangesCwaliteeUtils - CLI Utilities related to CPAN Changes cwalitee

=head1 VERSION

This document describes version 0.005 of App::CPANChangesCwaliteeUtils (from Perl distribution App-CPANChangesCwaliteeUtils), released on 2019-08-02.

=head1 DESCRIPTION

This distribution includes the following utilities:

=over

=item * L<calc-cpan-changes-cwalitee>

=item * L<cc-cwa>

=item * L<list-cpan-changes-cwalitee-indicators>

=back

=head1 FUNCTIONS


=head2 calc_cpan_changes_cwalitee

Usage:

 calc_cpan_changes_cwalitee(%args) -> [status, msg, payload, meta]

Calculate CPAN Changes cwalitee.

Examples:

=over

=item * Run against the the Changes of App-CPANChangesCwaliteeUtils distribution:

 calc_cpan_changes_cwalitee();

Result:

 [
   {
     indicator => "not_too_wide",
     num => 1,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "parsable",
     num => 2,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "date_correct_format",
     num => 3,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "date_parsable",
     num => 4,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "english",
     num => 5,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "has_releases",
     num => 6,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_duplicate_version",
     num => 7,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_empty_group",
     num => 8,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_shouting",
     num => 9,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_useless_text",
     num => 10,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "preamble_has_no_releases",
     num => 11,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "release_dates_not_future",
     num => 12,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "releases_in_descending_date_order",
     num => 13,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "Score",
     result => "100.00",
     result_summary => "13 out of 13",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

=item * B<include_indicator> => I<array[str]>

Only use these indicators.

=item * B<include_indicator_module> => I<array[perl::modname]>

Only use indicators from these modules.

=item * B<include_indicator_status> => I<array[str]> (default: ["stable"])

Only use indicators having these statuses.

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=item * B<path> => I<pathname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CPANChangesCwaliteeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPANChangesCwaliteeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANChangesCwaliteeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Changes::Cwalitee>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
