package App::CaseUtils;

use strict;
use warnings;
#use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-09'; # DATE
our $DIST = 'App-CaseUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{uppercase} = {
    v => 1.1,
    summary => 'Change input to upper case',
    description => <<'MARKDOWN',

This is basically a simple shortcut for something like:

    % perl -ne'print uc' INPUT ...
    % perl -pe'$_ = uc' INPUT ...

with some additional options.

MARKDOWN
    args => {
    },
};
sub uppercase {
    my %args = @_;

    while (<>) {
        print uc $_;
    }

    [200];
}

$SPEC{lowercase} = {
    v => 1.1,
    summary => 'Change input to lower case',
    description => <<'MARKDOWN',

This is basically a simple shortcut for something like:

    % perl -ne'print lc' INPUT ...
    % perl -pe'$_ = lc' INPUT ...

with some additional options.

MARKDOWN
    args => {
    },
};
sub lowercase {
    my %args = @_;

    while (<>) {
        print lc $_;
    }

    [200];
}

$SPEC{togglecase} = {
    v => 1.1,
    summary => 'Toggle case of input (lowercase to uppercase, while uppercase to lowercase)',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
    },
};
sub togglecase {
    my %args = @_;

    while (<>) {
        s{(?:(\p{Lu})|(\p{Ll}))}{lc($1 // "") . uc($2 // "")}eg;
        print;
    }

    [200];
}

$SPEC{titlecase} = {
    v => 1.1,
    summary => 'Change case of input to title case (uppercase start of the word, lowercase the rest)',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
    },
};
sub titlecase {
    my %args = @_;

    while (<>) {
        s/\b(\w)(\w*)\b/uc($1) . lc($2)/eg;
        print;
    }

    [200];
}

1;
# ABSTRACT: CLI utilities related to case (uppercase/lowercase)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CaseUtils - CLI utilities related to case (uppercase/lowercase)

=head1 VERSION

This document describes version 0.001 of App::CaseUtils (from Perl distribution App-CaseUtils), released on 2026-02-09.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to case
(uppercase/lowercase):

=over

=item * L<lowercase>

=item * L<titlecase>

=item * L<togglecase>

=item * L<uppercase>

=back

=head1 FUNCTIONS


=head2 lowercase

Usage:

 lowercase() -> [$status_code, $reason, $payload, \%result_meta]

Change input to lower case.

This is basically a simple shortcut for something like:

 % perl -ne'print lc' INPUT ...
 % perl -pe'$_ = lc' INPUT ...

with some additional options.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 titlecase

Usage:

 titlecase() -> [$status_code, $reason, $payload, \%result_meta]

Change case of input to title case (uppercase start of the word, lowercase the rest).

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 togglecase

Usage:

 togglecase() -> [$status_code, $reason, $payload, \%result_meta]

Toggle case of input (lowercase to uppercase, while uppercase to lowercase).

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 uppercase

Usage:

 uppercase() -> [$status_code, $reason, $payload, \%result_meta]

Change input to upper case.

This is basically a simple shortcut for something like:

 % perl -ne'print uc' INPUT ...
 % perl -pe'$_ = uc' INPUT ...

with some additional options.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CaseUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CaseUtils>.

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CaseUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
