package App::lcpan::Cmd::scripts_from_same_dist;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Given a script, list all scripts in the same distribution',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::scripts_args,
        %App::lcpan::flatest_args,
        %App::lcpan::detail_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};

    my $escripts = join(",", map {$dbh->quote($_)} @{ $args{scripts} });
    my @where;
    push @where, "dist.name IN (SELECT name FROM dist WHERE file_id IN (SELECT file_id FROM script WHERE name IN ($escripts)))";
    if ($args{latest}) {
        push @where, "dist.is_latest";
    } elsif (defined $args{latest}) {
        push @where, "NOT(dist.is_latest)";
    }
    my $sth = $dbh->prepare("SELECT
  script.name name,
  dist.name dist,
  dist.version dist_version
FROM script
JOIN dist ON script.file_id=dist.file_id
WHERE ".join(" AND ", @where)."
ORDER BY name DESC");
    $sth->execute;
    my @res;
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{name};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name dist dist_version/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Given a script, list all scripts in the same distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::scripts_from_same_dist - Given a script, list all scripts in the same distribution

=head1 VERSION

This document describes version 1.034 of App::lcpan::Cmd::scripts_from_same_dist (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Given a script, list all scripts in the same distribution.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

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
