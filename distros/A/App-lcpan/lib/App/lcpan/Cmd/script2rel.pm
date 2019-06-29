package App::lcpan::Cmd::script2rel;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Get release(s) of script(s)',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::scripts_args,
        %App::lcpan::full_path_args,
        %App::lcpan::all_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $scripts = $args{scripts};
    my $scripts_s = join(",", map {$dbh->quote($_)} @$scripts);

    my $sth = $dbh->prepare("SELECT
  script.name script,
  file.cpanid author,
  file.name release
FROM script
LEFT JOIN file ON script.file_id=file.id
WHERE script.name IN ($scripts_s)
ORDER BY file.id DESC");
    $sth->execute;

    my @res;
    my %mem;
    while (my $row = $sth->fetchrow_hashref) {
        unless ($args{all}) {
            next if $mem{$row->{script}}++;
        }
        if ($args{full_path}) {
            $row->{release} = App::lcpan::_fullpath(
                $row->{release}, $state->{cpan}, $row->{author});
        } else {
            $row->{release} = App::lcpan::_relpath(
                $row->{release}, $row->{author});
        }
        delete $row->{author};
        push @res, $row;
    }

    if (@$scripts == 1) {
        @res = map { $_->{release} } @res;
        if (!@res) {
            return [404, "No such script"];
        } elsif (@res == 1) {
            return [200, "OK", $res[0]];
        } else {
            return [200, "OK", \@res];
        }
    }

    [200, "OK", \@res, {'table.fields' => [qw/script release/]}];
}

1;
# ABSTRACT: Get release(s) of script(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::script2rel - Get release(s) of script(s)

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::script2rel (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Get release(s) of script(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<full_path> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<scripts>* => I<array[str]>

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
