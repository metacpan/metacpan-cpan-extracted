package App::lcpan::Cmd::bencher_scenarios_for_mod;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List Bencher::Scenario::* modules related to specified module',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_args,
        %App::lcpan::detail_args,
    },
};
sub handle_cmd {
    my %args = @_;
    my $mod = $args{module};

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $res = App::lcpan::rdeps(%args, modules => [$mod], rel => 'x_benchmarks', phase => 'x_benchmarks');
    return $res if $res->[0] != 200;
    return [200, "OK", []] unless @{ $res->[2] };

    my @mods;
    my $sth = $dbh->prepare(
        "SELECT m.name AS module, d.name AS dist, m.abstract AS abstract FROM module m JOIN dist d ON m.file_id=d.file_id".
            " WHERE d.name IN (".
                join(",", map {$dbh->quote($_->{dist})} @{ $res->[2] }).")");
    $sth->execute;
    my @rows;
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/module dist abstract/] if $args{detail};
    while (my $row = $sth->fetchrow_hashref) {
        next unless $row->{module} =~ /^Bencher::Scenario::/;
        if ($args{detail}) {
            push @rows, $row;
        } else {
            push @rows, $row->{module};
        }
    }

    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: List Bencher::Scenario::* modules related to specified module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::bencher_scenarios_for_mod - List Bencher::Scenario::* modules related to specified module

=head1 VERSION

This document describes version 0.002 of App::lcpan::Cmd::bencher_scenarios_for_mod (from Perl distribution App-lcpan-CmdBundle-bencher), released on 2017-07-10.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<bencher-scenarios-for-mod>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

List Bencher::Scenario::* modules related to specified module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<module>* => I<perl::modname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-bencher>

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
