package App::lcpan::Cmd::dist_rdeps;

our $DATE = '2020-03-04'; # DATE
our $VERSION = '1.045'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use App::lcpan ();
use App::lcpan::Cmd::dist_mods;
use Hash::Subset qw(hash_subset hash_subset_without);

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List which distributions depend on specified distribution',
    description => <<'_',

This subcommand lists all modules of your specified distribution, then run
'deps' on all of those modules. So basically, this subcommand shows which
distributions depend on your specified distribution.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::dist_args,
        %App::lcpan::rdeps_rel_args,
        %App::lcpan::rdeps_phase_args,
        %App::lcpan::rdeps_level_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $res =  App::lcpan::Cmd::dist_mods::handle_cmd(
        hash_subset(\%args, \%App::lcpan::common_args),
        dist => $args{dist},
    );
    return [500, "Can't list modules of dist '$args{dist}': $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    App::lcpan::rdeps(
        hash_subset(\%args, \%App::lcpan::common_args),
        modules => $res->[2],
        hash_subset(\%args, \%App::lcpan::rdeps_rel_args),
        hash_subset(\%args, \%App::lcpan::rdeps_phase_args),
        hash_subset(\%args, \%App::lcpan::rdeps_level_args),
    );
}

1;
# ABSTRACT: List which distributions depend on specified distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::dist_rdeps - List which distributions depend on specified distribution

=head1 VERSION

This document describes version 1.045 of App::lcpan::Cmd::dist_rdeps (from Perl distribution App-lcpan), released on 2020-03-04.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List which distributions depend on specified distribution.

This subcommand lists all modules of your specified distribution, then run
'deps' on all of those modules. So basically, this subcommand shows which
distributions depend on your specified distribution.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dist>* => I<perl::distname>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<phase> => I<str> (default: "ALL")

=item * B<rel> => I<str> (default: "ALL")

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

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
