package CPAN::Changes::Cwalitee::Core;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.000'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use CPAN::Changes::CwaliteeCommon;

our %SPEC;

$SPEC{indicator_parsable} = {
    v => 1.1,
    summary => 'Parseable by CPAN::Changes',
    args => {
    },
    #'x.indicator.error'    => '', #
    #'x.indicator.remedy'   => '', #
    #'x.indicator.severity' => '', # 1-5
    #'x.indicator.status'   => '', # experimental, stable*
    'x.indicator.priority' => 10,
};
sub indicator_parsable {
    my %args = @_;
    my $r = $args{r};

    defined($r->{parsed}) ?
        [200, "OK", ''] : [200, "OK", 'Changes is not parsable'];
}

$SPEC{indicator_date_parsable} = {
    v => 1.1,
    summary => 'Dates are parsable by CPAN::Changes',
    args => {
    },
};
sub indicator_date_parsable {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    for my $v (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$v};
        if (!defined $rel->{date} && !length $rel->{_parsed_date}) {
            return [200, "OK", "Some dates are not parsable, e.g. for version $v"];
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_date_correct_format} = {
    v => 1.1,
    summary => 'Dates are specified in the correct specified format, e.g. YYYY-MM-DD',
    description => <<'_',

Although <pm:CPAN::Changes> can parse various forms of dates, the spec states
that dates should be in the format specified by
<http://www.w3.org/TR/NOTE-datetime>, which is one of:

    YYYY
    YYYY-MM
    YYYY-MM-DD
    YYYY-MM-DD"T"hh:mm<TZD>
    YYYY-MM-DD"T"hh:mm:ss<TZD>
    YYYY-MM-DD"T"hh:mm:ss.s<TZD>

The "T" marker is optional. TZD is time zone designator (either "Z", or "+hh:mm"
or "-hh:mm").

_
    args => {
    },
};
sub indicator_date_correct_format {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    for my $v (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$v};
        unless ($rel->{_parsed_date} =~
                    /\A
                     [0-9]{4}
                     (?:-[0-9]{2}
                         (?:-[0-9]{2}
                             (?: # time part
                                 [T ]?
                                 [0-9]{2}:[0-9]{2}
                                 (?: # second
                                     :[0-9]{2}
                                     (?:\.[0-9]+)?
                                 )?
                                 (?: # time zone indicator
                                     Z | [+-][0-9]{2}:[0-9]{2}
                                 )?
                             )?
                         )?
                     )?
                     \z/x) {

            return [200, "OK", "Some dates are not in the correct format, e.g. '$rel->{_parsed_date}'"];
        }
    }
    [200, "OK", ''];
}

# $SPEC{indicator_releases_in_descending_date_order} = {
#     v => 1.1,
#     summary => 'Releases are ordered descendingly by its date (newest first)',
#     description => <<'_',

# This order is, in my opinion, the best order optimized for reading by users.

# _
#     args => {
#     },
#     'x.indicator.severity' => 2,
# };
# sub indicator_releases_in_descending_date_order {
#     my %args = @_;
#     my $r = $args{r};

#     my $p = $r->{parsed};
#     defined $p or return [412];

#     for my $v (sort keys %{ $p->{releases} }) {
#         my $rel = $p->{releases}{$v};
#     }
#     [200, "OK", ''];
# }

# TODO: indicator_date_not_future
# TODO: indicator_preamble_english
# TODO: indicator_entries_english

1;
# ABSTRACT: A collection of core indicators for CPAN Changes cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Cwalitee::Core - A collection of core indicators for CPAN Changes cwalitee

=head1 VERSION

This document describes version 0.000 of CPAN::Changes::Cwalitee::Core (from Perl distribution CPAN-Changes-Cwalitee), released on 2019-07-03.

=head1 FUNCTIONS


=head2 indicator_date_correct_format

Usage:

 indicator_date_correct_format() -> [status, msg, payload, meta]

Dates are specified in the correct specified format, e.g. YYYY-MM-DD.

Although L<CPAN::Changes> can parse various forms of dates, the spec states
that dates should be in the format specified by
L<http://www.w3.org/TR/NOTE-datetime>, which is one of:

 YYYY
 YYYY-MM
 YYYY-MM-DD
 YYYY-MM-DD"T"hh:mm<TZD>
 YYYY-MM-DD"T"hh:mm:ss<TZD>
 YYYY-MM-DD"T"hh:mm:ss.s<TZD>

The "T" marker is optional. TZD is time zone designator (either "Z", or "+hh:mm"
or "-hh:mm").

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



=head2 indicator_date_parsable

Usage:

 indicator_date_parsable() -> [status, msg, payload, meta]

Dates are parsable by CPAN::Changes.

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



=head2 indicator_parsable

Usage:

 indicator_parsable() -> [status, msg, payload, meta]

Parseable by CPAN::Changes.

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

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Changes-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Changes-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Changes-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
