package App::lcpan::Cmd::delete_rel;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Delete a release record in the database',
    description => <<'_',

Will delete records associated with a release in the database (including in the
`file` table, `module`, `dist`, `dep`, and so on). If `--delete-file` option is
specified, will also remove the file from the local mirror.

But currently will not remove/update the `modules/02packages.details.txt.gz`
index.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::rel_args,
        delete_file => {
            summary => 'Whether to delete the release file from the filesystem too',
            schema => ['bool*', is=>1],
        },
    },
    tags => ['write-to-db', 'write-to-fs'],
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'rw');
    my $dbh = $state->{dbh};

    my $row = $dbh->selectrow_hashref("SELECT id,cpanid FROM file WHERE name=?", {}, $args{release})
        or return [404, "No such release"];

    $dbh->begin_work;
    App::lcpan::_delete_releases_records($dbh, $row->{id});
    $dbh->commit;

    if ($args{delete_file}) {
        my $path = App::lcpan::_fullpath(
            $args{release}, $state->{cpan}, $row->{cpanid});
        log_info("Deleting file %s ...", $path);
        unlink $path;
    }

    [200, "OK"];
}

1;
# ABSTRACT: Delete a release record in the database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::delete_rel - Delete a release record in the database

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::delete_rel (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Delete a release record in the database.

Will delete records associated with a release in the database (including in the
C<file> table, C<module>, C<dist>, C<dep>, and so on). If C<--delete-file> option is
specified, will also remove the file from the local mirror.

But currently will not remove/update the C<modules/02packages.details.txt.gz>
index.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<delete_file> => I<bool>

Whether to delete the release file from the filesystem too.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<release>* => I<str>

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
