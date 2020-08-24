package App::lcpan::Cmd::scripts_for;

our $DATE = '2020-08-22'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::lcpan;
use Clone::Util qw(clone);
use Hash::Subset qw(hash_subset);

our %SPEC;

my %rel_args   = %{ clone \%App::lcpan::rdeps_rel_args };
$rel_args{rel}{default} = 'requires';
my %phase_args = %{ clone \%App::lcpan::rdeps_phase_args };
$phase_args{phase}{default} = 'runtime';
my %level_args = %{ clone \%App::lcpan::rdeps_level_args };
delete $level_args{level}{cmdline_aliases}{l};

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Try to find whether there are scripts (CLIs) for a module',
    description => <<'_',

Utilizing distribution metadata information, this subcommand basically just
tries to find distributions that depend on the module and has some scripts as
well. It's not terribly accurate, but it's better than nothing. Another
alternative might be to scan the script's source code finding use/require
statement for the module, but that method has its drawbacks too.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_args,
        %App::lcpan::detail_args,
        %rel_args,
        %phase_args,
        %level_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};

    my $res = App::lcpan::rdeps(
        hash_subset(\%args, \%App::lcpan::common_args),
        modules => [$args{module}],
        phase   => $args{phase},
        rel     => $args{rel},
        level   => $args{level},
    );

    return [500, "Can't rdeps: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    return [200, "OK", []] unless @{ $res->[2] };

    my $sth = $dbh->prepare("SELECT
  script.name name,
  file.dist_name dist,
  script.abstract abstract
FROM script
LEFT JOIN file ON script.file_id=file.id
WHERE file.dist_name IN (".join(",", map {$dbh->quote($_->{dist})} @{$res->[2]}).")
ORDER BY name DESC");
    $sth->execute();

    my @res;
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{name};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name dist abstract/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Try to find whether there are scripts (CLIs) for a module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::scripts_for - Try to find whether there are scripts (CLIs) for a module

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::scripts_for (from Perl distribution App-lcpan-CmdBundle-scripts), released on 2020-08-22.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<scripts-for>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Try to find whether there are scripts (CLIs) for a module.

Utilizing distribution metadata information, this subcommand basically just
tries to find distributions that depend on the module and has some scripts as
well. It's not terribly accurate, but it's better than nothing. Another
alternative might be to scan the script's source code finding use/require
statement for the module, but that method has its drawbacks too.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<module>* => I<perl::modname>

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-scripts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-scripts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-scripts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
