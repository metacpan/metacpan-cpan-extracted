package App::lcpan::Cmd::mods;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = do {
    my $spec = clone($App::lcpan::SPEC{modules});
    $spec->{summary} = "Alias for 'modules'";
    $spec;
};
*handle_cmd = \&App::lcpan::modules;

1;
# ABSTRACT: Alias for 'modules'

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mods - Alias for 'modules'

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::mods (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Alias for 'modules'.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<namespaces> => I<array[str]>

Select modules belonging to certain namespace(s).

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<perl_version> => I<str> (default: "v5.26.1")

Set base Perl version for determining core modules.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<sort> => I<array[str]> (default: ["module"])

Sort the result.

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


By default will return an array of package names. If you set C<detail> to true,
will return array of records.

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
