package App::lcpan::Cmd::rdeps_scripts;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-05'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.068'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List scripts that depend on specified modules',
    description => <<'_',

This is currently implemented as rdeps + dist_scripts (find distributions that
depend on specified modules, and list all scripts in those distributions):

    % lcpan rdeps Some::Module | td select dist | xargs lcpan dist-scripts Some::Module

so not really accurate.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,
        %App::lcpan::rdeps_rel_args,
        %App::lcpan::rdeps_phase_args,
        %App::lcpan::rdeps_level_args,
        %App::lcpan::fauthor_args,
    },
};
sub handle_cmd {
    require App::lcpan::Cmd::mod2dist;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $res;

    my @dists;
    $res = App::lcpan::Cmd::mod2dist::handle_cmd(%args); # XXX subset
    return [500, "Can't mod2dist: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    if (ref $res->[2] eq 'HASH') {
        push @dists, values %{ $res->[2] };
    } else {
        push @dists, $res->[2] if defined $res->[2];
    }
    return [404, "No dists found for the module(s) specified"] unless @dists;

    $res = App::lcpan::rdeps(%args, flatten=>1);
    return [500, "Can't mod2dist: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    push @dists, $_->{dist} for @{ $res->[2] };

    my @where;
    push @where, "file.dist_name IN (".
        join(",", map { $dbh->quote($_) } @dists).")";
    push @where, "file.cpanid=".$dbh->quote($args{author})
        if defined $args{author};
    my $sql = "SELECT
  script.name name,
  file.dist_name dist,
  script.cpanid author,
  script.abstract abstract
FROM script
LEFT JOIN file ON script.file_id=file.id
WHERE ".join(" AND ", @where)."
";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name dist author abstract/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List scripts that depend on specified modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::rdeps_scripts - List scripts that depend on specified modules

=head1 VERSION

This document describes version 1.068 of App::lcpan::Cmd::rdeps_scripts (from Perl distribution App-lcpan), released on 2021-06-05.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List scripts that depend on specified modules.

This is currently implemented as rdeps + dist_scripts (find distributions that
depend on specified modules, and list all scripts in those distributions):

 % lcpan rdeps Some::Module | td select dist | xargs lcpan dist-scripts Some::Module

so not really accurate.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<modules>* => I<array[perl::modname]>

=item * B<phase> => I<str> (default: "ALL")

=item * B<rel> => I<str> (default: "ALL")

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
