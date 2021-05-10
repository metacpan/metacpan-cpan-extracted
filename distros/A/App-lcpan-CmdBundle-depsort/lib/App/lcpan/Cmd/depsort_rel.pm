package App::lcpan::Cmd::depsort_rel;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-24'; # DATE
our $DIST = 'App-lcpan-CmdBundle-depsort'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Given a list of release tarball names, sort using dependency information (dependencies first)',
    description => <<'_',

Currently this routine only accepts release names in the form of:

    DISTNAME-VERSION.(tar.gz|tar.bz2|zip)

examples:

    App-IndonesianHolidayUtils-0.001.tar.gz
    Calendar-Indonesia-Holiday-1.446.tar.gz

_
    args => {
        releases => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'release',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        # TODO: arg: reverse
    },
};
sub handle_cmd {
    require App::lcpan::Cmd::depsort_dist;
    require Data::Graph::Util;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $rels = delete $args{releases};

    my @dists;
    my %reldists; # key = release name, val = dist name
    for my $rel (@$rels) {
        $rel =~ m!\A(?:.+/)?(\w+(?:-\w+)*)-(\d+(?:\.\d+)*)\.(tar\.gz|tar\.bz2|zip)\z!
            or return [400, "Unrecognized release name $rel, please use DISTNAME-VERSION.tar.gz"];
        $reldists{$rel} = $1;
        push @dists, $1;
    }
    log_trace "Depsorting dists: %s ...", \@dists;
    my $res = App::lcpan::Cmd::depsort_dist::handle_cmd(dists => \@dists);
    return $res unless $res->[0] == 200;
    my %distpos; # key = dist, val = index
    for my $i (0 .. $#{ $res->[2] }) {
        $distpos{ $res->[2][$i] } = $i;
    }

    my @sorted_rels = sort {
        $distpos{ $reldists{$a} } <=> $distpos{ $reldists{$b} } ||
            $a cmp $b
    } @$rels;
    [200, "OK", \@sorted_rels];
}

1;
# ABSTRACT: Given a list of release tarball names, sort using dependency information (dependencies first)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::depsort_rel - Given a list of release tarball names, sort using dependency information (dependencies first)

=head1 VERSION

This document describes version 0.004 of App::lcpan::Cmd::depsort_rel (from Perl distribution App-lcpan-CmdBundle-depsort), released on 2021-04-24.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<depsort-rel>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Given a list of release tarball names, sort using dependency information (dependencies first).

Currently this routine only accepts release names in the form of:

 DISTNAME-VERSION.(tar.gz|tar.bz2|zip)

examples:

 App-IndonesianHolidayUtils-0.001.tar.gz
 Calendar-Indonesia-Holiday-1.446.tar.gz

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<releases>* => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-depsort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-depsort>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-depsort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
