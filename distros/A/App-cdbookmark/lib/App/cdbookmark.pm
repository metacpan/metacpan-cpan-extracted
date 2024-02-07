package App::cdbookmark;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-19'; # DATE
our $DIST = 'App-cdbookmark'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{cdbookmark_backend} = {
    v => 1.1,
    summary => 'Change directory to one from the list',
    description => <<'MARKDOWN',

In `~/.config/cdbookmark.conf`, put your directory bookmarks:

    bookmarks = ~/dir1
    bookmarks = /etc/dir2
    bookmarks = /home/u1/Downloads

Then in your shell startup:

    cdbookmark() { cd `cdbookmark-backend "$1"`; }

To use:

    % cdbookmark 1; # cd to the first item (~/dir1)
    % cdbookmark Downloads;   # cd to the most similar item, which is /home/u1/Downloads

MARKDOWN
    args => {
        bookmarks => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'bookmark',
            schema => ['array*', of=>'dirname*'],
        },
        item => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub cdbookmark_backend {
    my %args = @_;
    defined(my $bookmarks = $args{bookmarks}) or return [200, "Error: please defined bookmarks", "."];
    defined(my $item = $args{item}) or return [200, "Error: please specify argument", "."];

    if ($item =~ /\A\d+\z/) {
        if (scalar(@$bookmarks) < $item) { return [200, "Error: no bookmark item #$item", "."] }
        return [200, "OK", $bookmarks->[$item-1]];
    }

    require Sort::BySimilarity;
    my @items = Sort::BySimilarity::sort_by_similarity(0, 0, {string=>$item}, @$bookmarks);
    return [200, "OK", $items[0]];
}

1;
# ABSTRACT: Change directory to one from the list

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cdbookmark - Change directory to one from the list

=head1 VERSION

This document describes version 0.001 of App::cdbookmark (from Perl distribution App-cdbookmark), released on 2024-01-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 cdbookmark_backend

Usage:

 cdbookmark_backend(%args) -> [$status_code, $reason, $payload, \%result_meta]

Change directory to one from the list.

In C<~/.config/cdbookmark.conf>, put your directory bookmarks:

 bookmarks = ~/dir1
 bookmarks = /etc/dir2
 bookmarks = /home/u1/Downloads

Then in your shell startup:

 cdbookmark() { cd C<cdbookmark-backend "$1">; }

To use:

 % cdbookmark 1; # cd to the first item (~/dir1)
 % cdbookmark Downloads;   # cd to the most similar item, which is /home/u1/Downloads

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bookmarks> => I<array[dirname]>

(No description)

=item * B<item>* => I<str>

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cdbookmark>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cdbookmark>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cdbookmark>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
