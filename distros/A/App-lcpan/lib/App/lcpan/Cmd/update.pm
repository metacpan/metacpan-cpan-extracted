package App::lcpan::Cmd::update;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '1.017'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = $App::lcpan::SPEC{update};
*handle_cmd = \&App::lcpan::update;

1;
# ABSTRACT: Create/update local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::update - Create/update local CPAN mirror

=head1 VERSION

This document describes version 1.017 of App::lcpan::Cmd::update (from Perl distribution App-lcpan), released on 2017-02-03.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

Create/update local CPAN mirror.

This subcommand first create/update the mirror files by downloading from a
remote CPAN mirror, then update the index.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<exclude_author> => I<array[str]>

Exclude files from certain author(s).

=item * B<force_update_index> => I<bool>

Update the index even though there is no change in files.

=item * B<include_author> => I<array[str]>

Only include files from certain author(s).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<max_file_size> => I<int>

If set, skip downloading files larger than this.

=item * B<remote_url> => I<str>

Select CPAN mirror to download from.

=item * B<skip_file_indexing_pass_1> => I<bool>

=item * B<skip_file_indexing_pass_2> => I<bool>

=item * B<skip_file_indexing_pass_3> => I<bool>

=item * B<skip_index_files> => I<array[str]>

Skip one or more files from being indexed.

=item * B<skip_sub_indexing> => I<bool> (default: 1)

Since sub indexing is still experimental, it is not enabled by default. To
enable it, pass the C<--no-skip-sub-indexing> option.

=item * B<update_files> => I<bool> (default: 1)

Update the files.

=item * B<update_index> => I<bool> (default: 1)

Update the index.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
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

This software is copyright (c) 2015-2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
