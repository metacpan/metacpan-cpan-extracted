package App::lcpan::Cmd::mods_by_rdep_count;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone_list);

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List modules ranked by number of reverse dependencies',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::fauthor_args,
        clone_list(%App::lcpan::deps_phase_args),
        clone_list(%App::lcpan::deps_rel_args),
    },
};
delete $SPEC{'handle_cmd'}{args}{phase}{default};
delete $SPEC{'handle_cmd'}{args}{rel}{default};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @where;
    my @binds;
    if ($args{author}) {
        push @where, "(author=?)";
        push @binds, uc($args{author});
    }
    if ($args{phase} && $args{phase} ne 'ALL') {
        push @where, "(phase=?)";
        push @binds, $args{phase};
    }
    if ($args{rel} && $args{rel} ne 'ALL') {
        push @where, "(rel=?)";
        push @binds, $args{rel};
    }
    @where = (1) if !@where;

    my $sql = "SELECT
  m.name name,
  m.cpanid author,
  COUNT(*) AS rdep_count
FROM module m
JOIN dep dp ON dp.module_id=m.id
WHERE ".join(" AND ", @where)."
GROUP BY m.name
ORDER BY rdep_count DESC
";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@binds);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name author rdep_count/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List modules ranked by number of reverse dependencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mods_by_rdep_count - List modules ranked by number of reverse dependencies

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::mods_by_rdep_count (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List modules ranked by number of reverse dependencies.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<phase> => I<str>

=item * B<rel> => I<str>

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
