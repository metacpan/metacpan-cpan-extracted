package CellFunc::File::stat_row;

use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-10'; # DATE
our $DIST = 'CellFunc-File-stat_row'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

our @st_fields = (
    "dev",     # 0
    "ino",     # 1
    "mode",    # 2
    "nlink",   # 3
    "uid",     # 4
    "gid",     # 5
    "rdev",    # 6
    "size",    # 7
    "atime",   # 8
    "mtime",   # 9
    "ctime",   # 10
    "blksize", # 11
    "blocks",  # 12
);

our @st_field_formats = (
    "number", # 0 "dev",
    "number", # 1 "ino",
    "", # 2 "mode",
    "number", # 3 "nlink",
    "number", # 4 "uid",
    "number", # 5 "gid",
    "number", # 6 "rdev",
    "filesize", # 7 "size",
    "iso8601_datetime", # 8 "atime",
    "iso8601_datetime", # 9 "mtime",
    "iso8601_datetime", # 10 "ctime",
    "number", # 11 "blksize",
    "number", # 12 "blocks",
);

our $resmeta = {
    'table.fields' => \@st_fields,
    'table.field_formats' => \@st_field_formats,
};

$SPEC{func} = {
    v => 1.1,
    summary => 'Take input value as filename, generate a row from stat()',
    description => <<'MARKDOWN',

When file does not exist or cannot be `stat()`'d, will emit a warning and return
an undefined value instead of a row.

MARKDOWN
    args => {
        value => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        follow_symlink => {
            schema => 'bool*',
            default => 1,
            description => <<'MARKDOWN',

If set to false, will do an `lstat()` instead of `stat()`.

MARKDOWN
        },
    },
};
sub func {
    my %args = @_;

    my @st = ($args{follow_symlink} // 1) ?  stat($args{value}) : lstat($args{value});
    unless (@st) {
        log_warn "Can't stat/lstat(%s): %s", $args{value}, $!;
        return [200, "OK"];
    }
    [200, "OK", \@st, $resmeta];
}

1;
# ABSTRACT: Take input value as filename, generate a row from stat()

__END__

=pod

=encoding UTF-8

=head1 NAME

CellFunc::File::stat_row - Take input value as filename, generate a row from stat()

=head1 VERSION

This document describes version 0.001 of CellFunc::File::stat_row (from Perl distribution CellFunc-File-stat_row), released on 2024-12-10.

=head1 FUNCTIONS


=head2 func

Usage:

 func(%args) -> [$status_code, $reason, $payload, \%result_meta]

Take input value as filename, generate a row from stat().

When file does not exist or cannot be C<stat()>'d, will emit a warning and return
an undefined value instead of a row.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<follow_symlink> => I<bool> (default: 1)

If set to false, will do an C<lstat()> instead of C<stat()>.

=item * B<value>* => I<filename>

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

Please visit the project's homepage at L<https://metacpan.org/release/CellFunc-File-stat_row>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CellFunc-File-stat_row>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CellFunc-File-stat_row>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
