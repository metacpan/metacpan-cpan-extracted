package App::PickArgs;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-05-22'; # DATE
our $DIST = 'App-PickArgs'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{pick_args} = {
    v => 1.1,
    summary => 'Pick one or more items from command-line arguments',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        args => {
            schema => ['array*', of=>'str*'],
            'x.name.is_plural' => 1,
            pos => 0,
            slurpy => 1,
        },
        allow_duplicates => {
            schema => 'bool*',
            default => 0,
            cmdline_aliases => {d=>{}},
        },
        # TODO: weights
        num_items => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
            description => <<'MARKDOWN',

If there are fewer command-line arguments than the requested number of items,
then will only return as many items as available.

MARKDOWN
        },
    },
    links => [
        {
            url=>'pm:Data::Unixish::pick',
            description => <<'MARKDOWN'

This is for picking random lines from input. Can be invoked from the
command-line using:

    % dux pick ...

MARKDOWN
        },
        {
            url=>'prog:pick',
            description => <<'MARKDOWN'

This is also for picking random lines from input, from <pm:App::PickRandomLines>.

MARKDOWN
        },
        {
            url=>'prog:shuf',
            summary=>'The venerable Unix utility',
            description => <<'MARKDOWN'

`shuf -n` is a Unix idiom for when wanting to pick one or several lines from an
input. So you can do:

    % ( echo item1; echo item2; echo item3; echo item4) | shuf -n1

MARKDOWN
        },
        {
            url=>'pm:Acme::CPANModules::PickingRandomItemsFromList',
            description => <<'MARKDOWN'

List of Perl modules to pick random items from a list.

MARKDOWN
        },
    ],
};
sub pick_args {
    my %args = @_;

    my $args = $args{args} or return [400, "Please specify arguments"];
    ref($args) eq 'ARRAY' or return [400, "Please specify array arguments"];
    @$args or return [400, "Please specify one or more arguments"];
    my $n = $args{num_items} // 1; $n = int($n);
    $n > 0 or return [400, "Please specify a positive number of items"];
    my $allow_duplicates = $args{allow_duplicates};

    my @res;
    if ($allow_duplicates) {
        push @res, $args->[rand @$args] for 1..$n;
    } else {
        require List::Util;
        @res = List::Util::sample($n, @$args);
    }
    if ($n == 1) {
        [200, "OK", $res[0]];
    } else {
        [200, "OK", \@res];
    }
}

1;
# ABSTRACT: Pick one or more items from command-line arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PickArgs - Pick one or more items from command-line arguments

=head1 VERSION

This document describes version 0.001 of App::PickArgs (from Perl distribution App-PickArgs), released on 2025-05-22.

=head1 SYNOPSIS

See command-line included in this distribution: L<pick-args>.

=head1 FUNCTIONS


=head2 pick_args

Usage:

 pick_args(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pick one or more items from command-line arguments.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_duplicates> => I<bool> (default: 0)

(No description)

=item * B<args> => I<array[str]>

(No description)

=item * B<num_items> => I<int> (default: 1)

If there are fewer command-line arguments than the requested number of items,
then will only return as many items as available.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PickArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PickArgs>.

=head1 SEE ALSO


L<Data::Unixish::pick>. This is for picking random lines from input. Can be invoked from the
command-line using:

 % dux pick ...

L<Acme::CPANModules::PickingRandomItemsFromList>. List of Perl modules to pick random items from a list.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PickArgs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
