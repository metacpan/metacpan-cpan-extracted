package App::lcpan::Cmd::weaver_sections_by_rdep_count;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List Pod::Weaver sections ranked by number of reverse dependencies',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::fauthor_args,
        %App::lcpan::deps_phase_arg,
        %App::lcpan::deps_rel_arg,
    },
};
delete $SPEC{'handle_cmd'}{args}{phase}{default};
delete $SPEC{'handle_cmd'}{args}{rel}{default};
sub handle_cmd {
    my %args = @_;

    App::lcpan::_set_args_default(\%args);
    my $cpan = $args{cpan};
    my $index_name = $args{index_name};

    my $dbh = App::lcpan::_connect_db('ro', $cpan, $index_name);

    my @where;
    my @binds;
    push @where, "(name LIKE 'Pod::Weaver::Section::%')";
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
        $row->{name} =~ s/^Pod::Weaver::Section:://;
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name author rdep_count/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List Pod::Weaver sections ranked by number of reverse dependencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::weaver_sections_by_rdep_count - List Pod::Weaver sections ranked by number of reverse dependencies

=head1 VERSION

This document describes version 0.02 of App::lcpan::Cmd::weaver_sections_by_rdep_count (from Perl distribution App-lcpan-CmdBundle-weaver), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<weaver-sections-by-rdep-count>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List Pod::Weaver sections ranked by number of reverse dependencies.

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

=item * B<phase> => I<any>

=item * B<rel> => I<any>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-weaver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-weaver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-weaver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
