package App::lcpan::Cmd::depsort_dist;

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
    summary => 'Given a list of dist names, sort using dependency information (dependencies first)',
    args => {
        %App::lcpan::dists_args,
        # TODO: arg: reverse
    },
};
sub handle_cmd {
    require App::lcpan::Cmd::mod2dist;
    require Data::Graph::Util;
    require List::Util;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $dists = delete $args{dists};
    $dists = [List::Util::uniq(@$dists)];
    return [200, "OK (no sorting needed)", $dists] unless @$dists > 1;

    my %seen_dists;
    my %seen_mods;
    my %deps; # key = dependency (what must comes first), val = dependent (which depends on the dependency)

    my @dists_to_check = @$dists;
    while (@dists_to_check) {
        my $dist = shift @dists_to_check;
        next if $seen_dists{$dist}++;
        my $res = App::lcpan::deps(dists => [$dist], dont_uniquify=>1);
        return [500, "Cannot get dependency for dist $dist: $res->[0] - $res->[1]"] unless $res->[0] == 200;
      ENTRY:
        for my $entry (@{ $res->[2] }) {
            next if $entry->{module} =~ /^(perl|Config)$/;
            next if $seen_mods{$entry->{module}}++;

            my $res2 = App::lcpan::Cmd::mod2dist::handle_cmd(modules => [$entry->{module}]);
            return [500, "Cannot get the distribution name for module '$entry->{module}': $res2->[0] - $res2->[1]"]
                unless $res2->[0] == 200;
            do {
                log_warn "There is no distribution for module '$entry->{module}', skipped";
                next ENTRY;
            } unless $res2->[2];
            my $dependency_dist = ref $res2->[2] ? $res2->[2]{ $entry->{module} } : $res2->[2];
            $deps{$dependency_dist} //= [];
            push @{ $deps{$dependency_dist} }, $dist;
            push @dists_to_check, $dependency_dist unless $seen_dists{$dependency_dist};
        }
    } # while @dists_to_check
    #return [200, "TMP", \%deps];

    log_trace "Toposorting %s with dependency information %s ...", $dists, \%deps;
    my @sorted_dists;
    eval {
        @sorted_dists = Data::Graph::Util::toposort(
            \%deps,
            $dists,
        );
    };
    return [500, "Cannot sort dists, probably there are circular dependencies"]
        if $@;
    [200, "OK", \@sorted_dists];
}

1;
# ABSTRACT: Given a list of dist names, sort using dependency information (dependencies first)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::depsort_dist - Given a list of dist names, sort using dependency information (dependencies first)

=head1 VERSION

This document describes version 0.004 of App::lcpan::Cmd::depsort_dist (from Perl distribution App-lcpan-CmdBundle-depsort), released on 2021-04-24.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<depsort-dist>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Given a list of dist names, sort using dependency information (dependencies first).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dists>* => I<array[perl::distname]>

Distribution names (e.g. Foo-Bar).


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
