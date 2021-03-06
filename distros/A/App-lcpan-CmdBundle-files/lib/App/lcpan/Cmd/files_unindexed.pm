package App::lcpan::Cmd::files_unindexed;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List unindexed files',
    description => <<'_',

This subcommand lists authors' files that are unindexed and are candidates for
deletion if you want to keep a minimal mini CPAN mirror (which only contains the
latest/indexed releases).

To delete you, you can use something like:

    % lcpan files-unindexed | xargs -n 100 rm

_
    args => {
        %App::lcpan::common_args,
        #exclude_dev_releases => {
        #    schema => 'If true, will skip filenames that resemble dev/trial releases',
        #    schema => 'bool',
        #},
        # XXX include_authors (include certain authors only)
        # XXX exclude_authors (exclude certain authors)
        # XXX include_author_pattern (include only authors matching pattern)
        # XXX exclude_author_pattern (exclude authors matching pattern)
    },
};
sub handle_cmd {
    require File::Find;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    # load all indexed releases into a hash, for quick checking
    my %indexed_files;
    my $sth = $dbh->prepare("SELECT name FROM file");
    $sth->execute;
    while (my ($fname) = $sth->fetchrow_array) {
        $indexed_files{$fname}++;
    }

    my @res;

    local $CWD = "$state->{cpan}/authors/id";

    File::Find::find(
        {
            wanted => sub {
                return unless -f;
                return if $indexed_files{$_};

                my $relpath = "$File::Find::dir/$_";
                $relpath =~ s!\A\./!!;

                # skip CHECKSUMS
                return if $relpath =~ m!\A./../[^/]+/CHECKSUMS\z!;

                push @res, "$state->{cpan}/authors/id/$relpath";
            },
            #follow_fast => 1,
        },
        ".",
    );

    [200, "OK", \@res];
}

1;
# ABSTRACT: List unindexed files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::files_unindexed - List unindexed files

=head1 VERSION

This document describes version 0.03 of App::lcpan::Cmd::files_unindexed (from Perl distribution App-lcpan-CmdBundle-files), released on 2017-07-10.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<files-unindexed>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

List unindexed files.

This subcommand lists authors' files that are unindexed and are candidates for
deletion if you want to keep a minimal mini CPAN mirror (which only contains the
latest/indexed releases).

To delete you, you can use something like:

 % lcpan files-unindexed | xargs -n 100 rm

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-files>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-files>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-files>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
