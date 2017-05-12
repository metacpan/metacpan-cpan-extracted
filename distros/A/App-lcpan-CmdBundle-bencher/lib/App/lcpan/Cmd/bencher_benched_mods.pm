package App::lcpan::Cmd::bencher_benched_mods;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List all modules that are participants in at least one Bencher::Scenario::* module',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::detail_args,
    },
};
sub handle_cmd {
    my %args = @_;
    my $mod = $args{module};

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $res = App::lcpan::modules(%args, namespaces => ['Bencher::Scenario']);
    return $res if $res->[0] != 200;
    return [200, "OK", []] unless @{ $res->[2] };

    App::lcpan::deps(%args, modules => $res->[2], rel => 'x_benchmarks', phase => 'x_benchmarks', flatten => 1);
}

1;
# ABSTRACT: List all modules that are participants in at least one Bencher::Scenario::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::bencher_benched_mods - List all modules that are participants in at least one Bencher::Scenario::* module

=head1 VERSION

This document describes version 0.001 of App::lcpan::Cmd::bencher_benched_mods (from Perl distribution App-lcpan-CmdBundle-bencher), released on 2017-01-25.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<bencher-benched-mods>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List all modules that are participants in at least one Bencher::Scenario::* module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

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
