package App::lcpan::Cmd::rels;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = do {
    my $spec = clone($App::lcpan::SPEC{releases});
    $spec->{summary} = "Alias for 'releases'";
    $spec;
};
*handle_cmd = \&App::lcpan::releases;

1;
# ABSTRACT: Alias for 'releases'

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::rels - Alias for 'releases'

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::rels (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Alias for 'releases'.

The status field is the processing status of the file/release by lcpan. C<ok>
means file has been extracted and the meta files parsed, C<nofile> means file is
not found in mirror (possibly because the mirroring process excludes the file
e.g. due to file size too large), C<nometa> means file does not contain
META.{yml,json}, C<unsupported> means file archive format is not supported (e.g.
rar), C<err> means some other error in processing file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<full_path> => I<bool>

=item * B<has_buildpl> => I<bool>

=item * B<has_makefilepl> => I<bool>

=item * B<has_metajson> => I<bool>

=item * B<has_metayml> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<no_path> => I<bool>

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<sort> => I<array[str]> (default: ["name"])

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
