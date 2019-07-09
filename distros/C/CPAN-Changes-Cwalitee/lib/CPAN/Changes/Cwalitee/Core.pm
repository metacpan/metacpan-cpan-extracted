package CPAN::Changes::Cwalitee::Core;

our $DATE = '2019-07-08'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

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

            return [200, "OK", "Some dates are not in the correct format, e.g. in version $v"];
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_releases_in_descending_date_order} = {
    v => 1.1,
    summary => 'Releases are ordered descendingly by its date (newest first)',
    description => <<'_',

This order is, in my opinion, the best order optimized for reading by users.

_
    args => {
    },
};
sub indicator_releases_in_descending_date_order {
    require Data::Cmp;

    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    my @dates = map { $_->{date} } @{ $p->{_releases_array} // [] };
    if (grep { !defined($_) || !$_ } @dates) {
        return [412, "Some releases have unparsable dates"];
    }

    my @sorted_dates = sort { $b cmp $a } @dates;
    if (Data::Cmp::cmp_data(\@dates, \@sorted_dates) == 0) {
        return [200, "OK", ''];
    } else {
        return [200, "OK", "Releases are not ordered by descending date"];
    }
}

$SPEC{indicator_release_dates_not_future} = {
    v => 1.1,
    summary => 'No release dates are in the future',
    args => {
    },
};
sub indicator_release_dates_not_future {
    require DateTime;
    require DateTime::Format::ISO8601;

    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    my @dates        = map { $_->{date} }         @{ $p->{_releases_array} // [] };
    my @parsed_dates = map { $_->{_parsed_date} } @{ $p->{_releases_array} // [] };
    if (grep { !defined($_) || !$_ } @dates) {
        return [412, "Some releases have unparsable dates"];
    }

    my $dt_now = DateTime->now(time_zone => 'UTC');
    for my $i (0..$#dates) {
        my $date = $dates[$i];
        my $parsed_date = $parsed_dates[$i];
        my $dt_rel = DateTime::Format::ISO8601->parse_datetime($date);
        if (DateTime->compare($dt_now, $dt_rel) == -1) {
            return [200, "OK", "Release date '$parsed_date' ($date) is in the future"];
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_no_useless_text} = {
    v => 1.1,
    summary => 'No useless text in the change lines, e.g. "Release v1.23"',
    args => {
    },
};
sub indicator_no_useless_text {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    # XXX useless text in preamble, group

    for my $ver (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$ver};
        for my $chgroup (sort keys %{ $rel->{changes} }) {
            my $gchanges = $rel->{changes}{$chgroup}{changes};
            for my $change (@$gchanges) {
                if ($change =~
                        m!\A\s*(
                              (version \s+|v)? \d\S* \s+ released |
                              (release(d|s)? \s+)? (version \s+|v)? \d\S* |
                          )\s*(\.)?\s*\z!ix) {
                    return [200, "OK", "Useless change text: $change"];
                }
            }
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_not_all_caps} = {
    v => 1.1,
    summary => 'No all-caps (shouting) text in the change lines, e.g. "REMOVE THE BUG!"',
    args => {
    },
    'x.indicator.status' => 'optional',
};
sub indicator_not_all_caps {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    # XXX all-caps in group name? in preamble?

    my $code_is_all_caps = sub {
        my $text = shift;
        my $num_letters;
        my $num_capitals = 0;
        for (split //, $text) {
            if (/[A-Za-z]/) { $num_letters++  }
            if (/[A-Z]/)    { $num_capitals++ }
        }
        return unless $num_letters;
        $num_capitals / $num_letters >= 0.9;
    };

    for my $ver (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$ver};
        for my $chgroup (sort keys %{ $rel->{changes} }) {
            my $gchanges = $rel->{changes}{$chgroup}{changes};
            for my $change (@$gchanges) {
                if ($code_is_all_caps->($change)) {
                    return [200, "OK", "All-caps in text: $change"];
                }
            }
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_no_shouting} = {
    v => 1.1,
    summary => 'No shouting in the change lines, e.g. "dammit!!!"',
    args => {
    },
};
sub indicator_no_shouting {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    # XXX shouting in group name? shouting in preamble?

    for my $ver (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$ver};
        for my $chgroup (sort keys %{ $rel->{changes} }) {
            my $gchanges = $rel->{changes}{$chgroup}{changes};
            for my $change (@$gchanges) {
                if ($change =~ /(!\s*){3,}/) {
                    return [200, "OK", "Shouting in text: $change"];
                }
            }
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_no_empty_group} = {
    v => 1.1,
    summary => 'No empty change group',
    args => {
    },
};
sub indicator_no_empty_group {
    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

    for my $ver (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$ver};
        for my $chgroup (sort keys %{ $rel->{changes} }) {
            my $gchanges = $rel->{changes}{$chgroup}{changes};
            if (!@$gchanges) {
                return [200, "OK", "Empty change group '$chgroup' in release $rel"];
            }
        }
    }
    [200, "OK", ''];
}

$SPEC{indicator_not_too_wide} = {
    v => 1.1,
    summary => 'Text is not too wide',
    args => {
        max_width => {
            schema => 'uint*',
            default => 125,
        },
    },
    'x.indicator.priority' => 1, # before Changes file is parsed
};
sub indicator_not_too_wide {
    my %args = @_;
    my $r = $args{r};

    my $max_width = $args{max_width} // 125;

    my $longest = 0;
    for (split /^/m, $r->{file_content}) {
        chomp;
        $longest = length() if $longest < length();
    }

    if ($longest > $max_width) {
        return [200, "OK", "Some lines exceed $max_width characters ($longest)"];
    } else {
        [200, "OK", ''];
    }
}

$SPEC{indicator_english} = {
    v => 1.1,
    summary => 'Preamble and change entries are in English',
    args => {
    },
};
sub indicator_english {
    require Lingua::Identify::Any;

    my %args = @_;
    my $r = $args{r};

    my $p = $r->{parsed};
    defined $p or return [412];

  DETECT_PREAMBLE_LANGUAGE: {
        last unless $p->{preamble} =~ /\S/;
        my $dlres = Lingua::Identify::Any::detect_text_language(text=>$p->{preamble});
        return [412, "Cannot detect language of preamble: $dlres->[0] - $dlres->[1]"]
            unless $dlres->[0] == 200;
        if ($dlres->[2]{'lang_code'} ne 'en') {
            return [
                200,
                "OK", "Language of preamble not detected as English ".
                    sprintf("(%s, confidence %.2f)",
                            $dlres->[2]{lang_code},
                            $dlres->[2]{confidence} // 0,
                        ),
            ];
        }
    }

  DETECT_ENTRIES:

    for my $ver (sort keys %{ $p->{releases} }) {
        my $rel = $p->{releases}{$ver};
        for my $chgroup (sort keys %{ $rel->{changes} }) {
            my $gchanges = $rel->{changes}{$chgroup}{changes};
            for my $change (@$gchanges) {
                last unless $change =~ /\S/;
                my $dlres = Lingua::Identify::Any::detect_text_language(text=>$change);
                return [412, "Cannot detect language in release $ver: $dlres->[0] - $dlres->[1]"]
                    unless $dlres->[0] == 200;
                if ($dlres->[2]{'lang_code'} ne 'en') {
                    return [
                        200,
                        "OK", "Language in release $ver not detected as English ".
                            sprintf("(%s, confidence %.2f)",
                                    $dlres->[2]{lang_code},
                                    $dlres->[2]{confidence} // 0,
                                ),
                    ];
                }
            }
        }
    }
    [200, "OK", ''];
}

# TODO: indicator_sufficient_entries_length
# TODO: indicator_version_correct_format
# TODO: indicator_not_commit_logs
# TODO: indicator_name_preferred (e.g. Changes and not ChangeLog.txt)
# TODO: indicator_no_duplicate_version
# TODO: indicator_preamble_not_template
# TODO: indicator_entries_not_template
# TODO: indicator_entries_english_tense_consistent (all past tense, or all present tense)
# TODO: indicator_preamble_not_too_long (this could indicate misparsing releases as preamble, e.g. when each version is prefixed by a non-number, e.g. in XML-Compile)
# TODO: indicator_indentation_consistent

1;
# ABSTRACT: A collection of core indicators for CPAN Changes cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Cwalitee::Core - A collection of core indicators for CPAN Changes cwalitee

=head1 VERSION

This document describes version 0.004 of CPAN::Changes::Cwalitee::Core (from Perl distribution CPAN-Changes-Cwalitee), released on 2019-07-08.

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



=head2 indicator_english

Usage:

 indicator_english() -> [status, msg, payload, meta]

Preamble and change entries are in English.

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



=head2 indicator_no_empty_group

Usage:

 indicator_no_empty_group() -> [status, msg, payload, meta]

No empty change group.

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



=head2 indicator_no_shouting

Usage:

 indicator_no_shouting() -> [status, msg, payload, meta]

No shouting in the change lines, e.g. "dammit!!!".

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



=head2 indicator_no_useless_text

Usage:

 indicator_no_useless_text() -> [status, msg, payload, meta]

No useless text in the change lines, e.g. "Release v1.23".

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



=head2 indicator_not_all_caps

Usage:

 indicator_not_all_caps() -> [status, msg, payload, meta]

No all-caps (shouting) text in the change lines, e.g. "REMOVE THE BUG!".

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



=head2 indicator_not_too_wide

Usage:

 indicator_not_too_wide(%args) -> [status, msg, payload, meta]

Text is not too wide.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max_width> => I<uint> (default: 125)

=back

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



=head2 indicator_release_dates_not_future

Usage:

 indicator_release_dates_not_future() -> [status, msg, payload, meta]

No release dates are in the future.

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



=head2 indicator_releases_in_descending_date_order

Usage:

 indicator_releases_in_descending_date_order() -> [status, msg, payload, meta]

Releases are ordered descendingly by its date (newest first).

This order is, in my opinion, the best order optimized for reading by users.

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
