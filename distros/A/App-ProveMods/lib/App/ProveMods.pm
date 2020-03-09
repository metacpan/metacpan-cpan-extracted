package App::ProveMods;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'App-ProveMods'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::ProveDists ();
use Hash::Subset qw(hash_subset);

our %SPEC;

$SPEC{prove_mods} = {
    v => 1.1,
    summary => "Prove Perl modules' distributions",
    description => <<'_',

To use this utility, first create `~/.config/prove-mods.conf`:

    dists_dirs = ~/repos
    dists_dirs = ~/repos-other

The above tells *prove-mods* where to look for Perl distributions. Then:

    % prove-mods '^Regexp::Pattern.*'

This will search local CPAN mirror for all modules that match that regex
pattern, then search the distributions in the distribution directories (or
download them from local CPAN mirror), `cd` to each and run `prove` in it.

You can run with `--dry-run` (`-n`) option first to not actually run `prove` but
just see what distributions will get tested. An example output:

    % prove-mods '^Regexp::Pattern' -n
    prove-mods: Found module: Regexp::Pattern (dist=Regexp-Pattern)
    prove-mods: Found module: Regexp::Pattern::CPAN (dist=Regexp-Pattern-CPAN)
    prove-mods: Found module: Regexp::Pattern::Example (dist=Regexp-Pattern)
    prove-mods: Found module: Regexp::Pattern::Git (dist=Regexp-Pattern-Git)
    prove-mods: Found module: Regexp::Pattern::JSON (dist=Regexp-Pattern-JSON)
    prove-mods: Found module: Regexp::Pattern::License (dist=Regexp-Pattern-License)
    prove-mods: Found module: Regexp::Pattern::License::Parts (dist=Regexp-Pattern-License)
    prove-mods: Found module: Regexp::Pattern::Net (dist=Regexp-Pattern-Net)
    prove-mods: Found module: Regexp::Pattern::OS (dist=Regexp-Pattern-OS)
    prove-mods: Found module: Regexp::Pattern::Path (dist=Regexp-Pattern-Path)
    prove-mods: Found module: Regexp::Pattern::RegexpCommon (dist=Regexp-Pattern-RegexpCommon)
    prove-mods: Found module: Regexp::Pattern::Test::re_engine (dist=Regexp-Pattern-Test-re_engine)
    prove-mods: Found module: Regexp::Pattern::Twitter (dist=Regexp-Pattern-Twitter)
    prove-mods: Found module: Regexp::Pattern::YouTube (dist=Regexp-Pattern-YouTube)
    prove-mods: Found dist: Regexp-Pattern
    prove-mods: Found dist: Regexp-Pattern-CPAN
    prove-mods: Found dist: Regexp-Pattern-Git
    prove-mods: Found dist: Regexp-Pattern-JSON
    prove-mods: Found dist: Regexp-Pattern-License
    prove-mods: Found dist: Regexp-Pattern-Net
    prove-mods: Found dist: Regexp-Pattern-OS
    prove-mods: Found dist: Regexp-Pattern-Path
    prove-mods: Found dist: Regexp-Pattern-RegexpCommon
    prove-mods: Found dist: Regexp-Pattern-Test-re_engine
    prove-mods: Found dist: Regexp-Pattern-Twitter
    prove-mods: Found dist: Regexp-Pattern-YouTube
    prove-mods: [DRY] [1/12] Running prove for distribution Regexp-Pattern (directory /home/u1/repos/perl-Regexp-Pattern) ...
    prove-mods: [DRY] [2/12] Running prove for distribution Regexp-Pattern-CPAN (directory /home/u1/repos/perl-Regexp-Pattern-CPAN) ...
    prove-mods: [DRY] [3/12] Running prove for distribution Regexp-Pattern-Git (directory /home/u1/repos/perl-Regexp-Pattern-Git) ...
    prove-mods: [DRY] [4/12] Running prove for distribution Regexp-Pattern-JSON (directory /home/u1/repos/perl-Regexp-Pattern-JSON) ...
    prove-mods: [DRY] [5/12] Running prove for distribution Regexp-Pattern-License (directory /tmp/hEa7jnla5M/Regexp-Pattern-License-v3.2.0) ...
    prove-mods: [DRY] [6/12] Running prove for distribution Regexp-Pattern-Net (directory /home/u1/repos/perl-Regexp-Pattern-Net) ...
    prove-mods: [DRY] [7/12] Running prove for distribution Regexp-Pattern-OS (directory /home/u1/repos/perl-Regexp-Pattern-OS) ...
    prove-mods: [DRY] [8/12] Running prove for distribution Regexp-Pattern-Path (directory /home/u1/repos/perl-Regexp-Pattern-Path) ...
    prove-mods: [DRY] [9/12] Running prove for distribution Regexp-Pattern-RegexpCommon (directory /home/u1/repos/perl-Regexp-Pattern-RegexpCommon) ...
    prove-mods: [DRY] [10/12] Running prove for distribution Regexp-Pattern-Test-re_engine (directory /home/u1/repos/perl-Regexp-Pattern-Test-re_engine) ...
    prove-mods: [DRY] [11/12] Running prove for distribution Regexp-Pattern-Twitter (directory /home/u1/repos/perl-Regexp-Pattern-Twitter) ...
    prove-mods: [DRY] [12/12] Running prove for distribution Regexp-Pattern-YouTube (directory /home/u1/repos/perl-Regexp-Pattern-YouTube) ...

The above example shows that I have the distribution directories locally on my
`~/repos`, except for one 'Regexp::Pattern::License'.

If we reinvoke the above command without the `-n`, *prove-rdeps* will actually
run `prove` on each directory and provide a summary at the end. Example output:

    % prove-mods '^Regexp::Pattern'
    ...
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
    | dir                                           | label                               | reason                            | status |
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
    | /tmp/2GOBZuxird/Regexp-Pattern-License-v3.2.0 | distribution Regexp-Pattern-License | Test failed (Failed 1/2 subtests) | 500    |
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+

The above example shows that one distribution failed testing. You can scroll up
for the detailed `prove` output to see the details of failure failed, fix
things, and re-run.

How distribution directory is searched: see <pm:App::ProveDists> documentation.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

*prove-rdeps* will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

_
    args => {
        %App::ProveDists::args_common,
        modules => {
            summary => 'Module names to prove',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'re*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub prove_mods {
    require App::lcpan::Call;

    my %args = @_;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ['mods', '-l', '-r', '--latest', '--or', @{ $args{modules} }],
    );

    return [412, "Can't lcpan mods: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    my @included_recs;
  REC:
    for my $rec (@{ $res->[2] }) {
        log_info "Found module: %s (dist=%s)", $rec->{module}, $rec->{dist};
        next if grep { $rec->{dist} eq $_->{dist} } @included_recs;
        push @included_recs, {dist=>$rec->{dist}};
    }

    App::ProveDists::prove_dists(
        hash_subset(\%args, \%App::ProveDists::args_common),
        -dry_run => $args{-dry_run},
        _res => [200, "OK", \@included_recs],
    );
}

1;
# ABSTRACT: Prove Perl modules' distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProveMods - Prove Perl modules' distributions

=head1 VERSION

This document describes version 0.001 of App::ProveMods (from Perl distribution App-ProveMods), released on 2020-03-07.

=head1 SYNOPSIS

See the included script L<prove-mods>.

=head1 FUNCTIONS


=head2 prove_mods

Usage:

 prove_mods(%args) -> [status, msg, payload, meta]

Prove Perl modules' distributions.

To use this utility, first create C<~/.config/prove-mods.conf>:

 dists_dirs = ~/repos
 dists_dirs = ~/repos-other

The above tells I<prove-mods> where to look for Perl distributions. Then:

 % prove-mods '^Regexp::Pattern.*'

This will search local CPAN mirror for all modules that match that regex
pattern, then search the distributions in the distribution directories (or
download them from local CPAN mirror), C<cd> to each and run C<prove> in it.

You can run with C<--dry-run> (C<-n>) option first to not actually run C<prove> but
just see what distributions will get tested. An example output:

 % prove-mods '^Regexp::Pattern' -n
 prove-mods: Found module: Regexp::Pattern (dist=Regexp-Pattern)
 prove-mods: Found module: Regexp::Pattern::CPAN (dist=Regexp-Pattern-CPAN)
 prove-mods: Found module: Regexp::Pattern::Example (dist=Regexp-Pattern)
 prove-mods: Found module: Regexp::Pattern::Git (dist=Regexp-Pattern-Git)
 prove-mods: Found module: Regexp::Pattern::JSON (dist=Regexp-Pattern-JSON)
 prove-mods: Found module: Regexp::Pattern::License (dist=Regexp-Pattern-License)
 prove-mods: Found module: Regexp::Pattern::License::Parts (dist=Regexp-Pattern-License)
 prove-mods: Found module: Regexp::Pattern::Net (dist=Regexp-Pattern-Net)
 prove-mods: Found module: Regexp::Pattern::OS (dist=Regexp-Pattern-OS)
 prove-mods: Found module: Regexp::Pattern::Path (dist=Regexp-Pattern-Path)
 prove-mods: Found module: Regexp::Pattern::RegexpCommon (dist=Regexp-Pattern-RegexpCommon)
 prove-mods: Found module: Regexp::Pattern::Test::re_engine (dist=Regexp-Pattern-Test-re_engine)
 prove-mods: Found module: Regexp::Pattern::Twitter (dist=Regexp-Pattern-Twitter)
 prove-mods: Found module: Regexp::Pattern::YouTube (dist=Regexp-Pattern-YouTube)
 prove-mods: Found dist: Regexp-Pattern
 prove-mods: Found dist: Regexp-Pattern-CPAN
 prove-mods: Found dist: Regexp-Pattern-Git
 prove-mods: Found dist: Regexp-Pattern-JSON
 prove-mods: Found dist: Regexp-Pattern-License
 prove-mods: Found dist: Regexp-Pattern-Net
 prove-mods: Found dist: Regexp-Pattern-OS
 prove-mods: Found dist: Regexp-Pattern-Path
 prove-mods: Found dist: Regexp-Pattern-RegexpCommon
 prove-mods: Found dist: Regexp-Pattern-Test-re_engine
 prove-mods: Found dist: Regexp-Pattern-Twitter
 prove-mods: Found dist: Regexp-Pattern-YouTube
 prove-mods: [DRY] [1/12] Running prove for distribution Regexp-Pattern (directory /home/u1/repos/perl-Regexp-Pattern) ...
 prove-mods: [DRY] [2/12] Running prove for distribution Regexp-Pattern-CPAN (directory /home/u1/repos/perl-Regexp-Pattern-CPAN) ...
 prove-mods: [DRY] [3/12] Running prove for distribution Regexp-Pattern-Git (directory /home/u1/repos/perl-Regexp-Pattern-Git) ...
 prove-mods: [DRY] [4/12] Running prove for distribution Regexp-Pattern-JSON (directory /home/u1/repos/perl-Regexp-Pattern-JSON) ...
 prove-mods: [DRY] [5/12] Running prove for distribution Regexp-Pattern-License (directory /tmp/hEa7jnla5M/Regexp-Pattern-License-v3.2.0) ...
 prove-mods: [DRY] [6/12] Running prove for distribution Regexp-Pattern-Net (directory /home/u1/repos/perl-Regexp-Pattern-Net) ...
 prove-mods: [DRY] [7/12] Running prove for distribution Regexp-Pattern-OS (directory /home/u1/repos/perl-Regexp-Pattern-OS) ...
 prove-mods: [DRY] [8/12] Running prove for distribution Regexp-Pattern-Path (directory /home/u1/repos/perl-Regexp-Pattern-Path) ...
 prove-mods: [DRY] [9/12] Running prove for distribution Regexp-Pattern-RegexpCommon (directory /home/u1/repos/perl-Regexp-Pattern-RegexpCommon) ...
 prove-mods: [DRY] [10/12] Running prove for distribution Regexp-Pattern-Test-re_engine (directory /home/u1/repos/perl-Regexp-Pattern-Test-re_engine) ...
 prove-mods: [DRY] [11/12] Running prove for distribution Regexp-Pattern-Twitter (directory /home/u1/repos/perl-Regexp-Pattern-Twitter) ...
 prove-mods: [DRY] [12/12] Running prove for distribution Regexp-Pattern-YouTube (directory /home/u1/repos/perl-Regexp-Pattern-YouTube) ...

The above example shows that I have the distribution directories locally on my
C<~/repos>, except for one 'Regexp::Pattern::License'.

If we reinvoke the above command without the C<-n>, I<prove-rdeps> will actually
run C<prove> on each directory and provide a summary at the end. Example output:

 % prove-mods '^Regexp::Pattern'
 ...
 +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
 | dir                                           | label                               | reason                            | status |
 +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
 | /tmp/2GOBZuxird/Regexp-Pattern-License-v3.2.0 | distribution Regexp-Pattern-License | Test failed (Failed 1/2 subtests) | 500    |
 +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+

The above example shows that one distribution failed testing. You can scroll up
for the detailed C<prove> output to see the details of failure failed, fix
things, and re-run.

How distribution directory is searched: see L<App::ProveDists> documentation.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

I<prove-rdeps> will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<dists_dirs>* => I<array[dirname]>

Where to find the distributions directories.

=item * B<download> => I<bool> (default: 1)

Whether to try downloadE<sol>extract distribution from local CPAN mirror (when not found in dists_dirs).

=item * B<modules>* => I<array[re]>

Module names to prove.

=item * B<prove_opts> => I<array[str]> (default: ["-l"])

Options to pass to the prove command.

=item * B<summarize_all> => I<bool>

If true, also summarize successes in addition to failures.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ProveMods>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProveMods>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProveMods>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<prove>

L<App::lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
