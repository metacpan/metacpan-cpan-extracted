package App::ProveRdeps;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-30'; # DATE
our $DIST = 'App-ProveRdeps'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use File::Temp qw(tempdir);

our %SPEC;

sub _find_dist_dir {
    my ($dist, $dirs) = @_;

  DIR:
    for my $dir (@$dirs) {
        my @entries = do {
            opendir my $dh, $dir or do {
                warn "prove-rdeps: Can't opendir '$dir': $!\n";
                next DIR;
            };
            my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
            closedir $dh;
            @entries;
        };
        #log_trace("entries: %s", \@entries);
      FIND:
        {
            my @res;

            # exact match
            @res = grep { $_ eq $dist } @entries;
            #log_trace("exact matches: %s", \@res);
            return "$dir/$res[0]" if @res == 1;

            # case-insensitive match
            my $dist_lc = lc $dist;
            @res = grep { lc($_) eq $dist_lc } @entries;
            return "$dir/$res[0]" if @res == 1;

            # suffix match, e.g. perl-DIST or cpan_DIST
            @res = grep { /\A\w+[_-]\Q$dist\E\z/ } @entries;
            #log_trace("suffix matches: %s", \@res);
            return "$dir/$res[0]" if @res == 1;

            # prefix match, e.g. DIST-perl
            @res = grep { /\A\Q$dist\E[_-]\w+\z/ } @entries;
            return "$dir/$res[0]" if @res == 1;
        }
    }
    undef;
}

# return directory
sub _download_dist {
    my ($dist) = @_;
    require App::lcpan::Call;

    my $tempdir = tempdir(CLEANUP=>1);

    local $CWD = $tempdir;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ['extract-dist', $dist],
    );

    return [412, "Can't lcpan extract-dist: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    my @dirs = glob "*";
    return [412, "Can't find extracted dist (found ".join(", ", @dirs).")"]
        unless @dirs == 1 && (-d $dirs[0]);

    [200, "OK", "$tempdir/$dirs[0]"];
}

sub _prove {
    require IPC::System::Options;

    my $opts = shift;

    my $stdout = "";
    my $stderr = "";

    my $act_stdout;
    my $act_stderr;
    if (log_is_warn()) {
        $act_stdout = "tee_stdout";
        $act_stderr = "tee_stderr";
    } else {
        $act_stdout = "capture_stdout";
        $act_stderr = "capture_stderr";
    }
    IPC::System::Options::system(
        {
            log=>1,
            ($act_stdout => \$stdout) x !!$act_stdout,
            ($act_stderr => \$stderr) x !!$act_stderr,
        },
        "prove", @{ $opts || [] },
        log_is_debug() ? ("-v") : (),
    );
    if ($?) {
        if ($stdout =~ /^Result: FAIL/m) {
            my $detail = "";
            if ($stdout =~ m!^(Failed \d+/\d+ subtests|No subtests run)!m) {
                $detail = " ($1)";
            }
            [500, "Test failed". $detail];
        } else {
            [500, "Non-zero exit code (".($? >> 8).")"];
        }
    } else {
        if ($stdout =~ /^Result: PASS/m) {
            [200, "PASS"];
        } elsif ($stdout =~ /^Result: NOTESTS/m) {
            [200, "NOTESTS"];
        } else {
            [500, "No PASS marker"];
        }
    }
}

$SPEC{prove_rdeps} = {
    v => 1.1,
    summary => 'Prove all distributions depending on specified module(s)',
    description => <<'_',

To use this utility, first create `~/.config/prove-rdeps.conf`:

    dist_dirs = ~/repos
    dist_dirs = ~/repos-other

The above tells *prove-rdeps* where to look for Perl distributions. Then:

    % prove-rdeps Regexp::Pattern

This will search local CPAN mirror for all distributions that depend on
<pm:Log::ger> (by default for phase=runtime and rel=requires), then search the
distributions in the distribution directories (or download them from local CPAN
mirror), `cd` to each and run `prove` in it.

You can run with `--dry-run` (`-n`) option first to not actually run `prove` but
just see what distributions will get tested. An example output:

    % prove-rdeps Regexp::Pattern -n
    prove-rdeps: Found dep: Acme-DependOnEverything (runtime requires)
    prove-rdeps: Found dep: App-BlockWebFlooders (runtime requires)
    prove-rdeps: Found dep: App-Licensecheck (runtime requires)
    prove-rdeps: Found dep: Pod-Weaver-Plugin-Regexp-Pattern (develop x_spec)
    prove-rdeps: Dep Pod-Weaver-Plugin-Regexp-Pattern skipped (phase not included)
    ...
    prove-rdeps: [DRY] [1/8] Running prove for dist 'Acme-DependOnEverything' in '/tmp/BP3l0kiuZH/Acme-DependOnEverything-0.06' ...
    prove-rdeps: [DRY] [2/8] Running prove for dist 'App-BlockWebFlooders' in '/home/u1/repos/perl-App-BlockWebFlooders' ...
    prove-rdeps: [DRY] [3/8] Running prove for dist 'App-Licensecheck' in '/tmp/pw1hBzUIaZ/App-Licensecheck-v3.0.40' ...
    prove-rdeps: [DRY] [4/8] Running prove for dist 'App-RegexpPatternUtils' in '/home/u1/repos/perl-App-RegexpPatternUtils' ...
    prove-rdeps: [DRY] [5/8] Running prove for dist 'Bencher-Scenarios-RegexpPattern' in '/home/u1/repos/perl-Bencher-Scenarios-RegexpPattern' ...
    prove-rdeps: [DRY] [6/8] Running prove for dist 'Regexp-Common-RegexpPattern' in '/home/u1/repos/perl-Regexp-Common-RegexpPattern' ...
    prove-rdeps: [DRY] [7/8] Running prove for dist 'Release-Util-Git' in '/home/u1/repos/perl-Release-Util-Git' ...
    prove-rdeps: [DRY] [8/8] Running prove for dist 'Test-Regexp-Pattern' in '/home/u1/repos/perl-Test-Regexp-Pattern' ...

The above example shows that I have the distribution directories locally on my
`~/repos`, except for `Acme-DependOnEverything` and `App-Licensecheck`, which
*prove-rdeps* downloads and extracts from local CPAN mirror and puts into
temporary directories.

If we reinvoke the above command without the `-n`, *prove-rdeps* will actually
run `prove` on each directory and provide a summary at the end. Example output:

    % prove-rdeps Regexp::Pattern
    ...
    +-----------------------------+-----------------------------------+--------+
    | dist                        | reason                            | status |
    +-----------------------------+-----------------------------------+--------+
    | Acme-DependOnEverything     | Test failed (Failed 1/1 subtests) | 500    |
    | App-Licensecheck            | Test failed (No subtests run)     | 500    |
    | Regexp-Common-RegexpPattern | Non-zero exit code (2)            | 500    |
    +-----------------------------+-----------------------------------+--------+

The above example shows that three distributions failed testing. You can scroll
up for the detailed `prove` output to see why they failed, fix things, and
re-run. To skip some dists from being tested, use `--exclude-dist`:

    % prove-rdeps Regexp::Pattern --exclude-dist Acme-DependOnEverything

Or you can also put these lines in the configuration file:

    exclude_dists = Acme-DependOnEverything
    exclude_dists = Regexp-Common-RegexpPattern

How distribution directory is searched: first, the exact name (`My-Perl-Dist`)
is searched. If not found, then the name with different case (e.g.
`my-perl-dist`) is searched. If not found, a suffix match (e.g.
`p5-My-Perl-Dist` or `cpan-My-Perl-Dist`) is searched. If not found, a prefix
match (e.g. `My-Perl-Dist-perl`) is searched. If not found, *prove-rdeps* will
try to download the distribution tarball from local CPAN mirror and extract it
to a temporary directory. If `--no-dowload` is given, the *prove-deps* will not
download from local CPAN mirror and give up for that distribution.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

*prove-deps* will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

_
    args => {
        modules => {
            summary => 'Module names to find dependents of',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'perl::modname*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        prove_opts => {
            summary => 'Options to pass to the prove command',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'prove_opt',
            schema => ['array*', of=>'str*'],
            default => ['-l'],
        },
        dist_dirs => {
            summary => 'Where to find the distributions',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dist_dir',
            schema => ['array*', of=>'dirname*'],
            req => 1,
        },
        download => {
            summary => 'Whether to try download/extract distribution from local CPAN mirror (when not found in dist_dirs)',
            schema => 'bool*',
            default => 1,
        },

        phases => {
            summary => 'Only select dists that depend in these phases',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'phase',
            schema => ['array*', of=>'str*'],
            default => ['runtime'],
            tags => ['category:filtering'],
        },
        rels => {
            summary => 'Only select dists that depend using these relationships',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'rel',
            schema => ['array*', of=>'str*'],
            default => ['requires'],
            tags => ['category:filtering'],
        },

        exclude_dists => {
            summary => 'Distributions to skip',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'exclude_dist',
            schema => ['array*', of=>'perl::distname*', 'x.perl.coerce_rules'=>["From_str::comma_sep"]],
            tags => ['category:filtering'],
        },
        include_dists => {
            summary => 'If specified, only include these distributions',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_dist',
            schema => ['array*', of=>'perl::distname*', 'x.perl.coerce_rules'=>["From_str::comma_sep"]],
            tags => ['category:filtering'],
        },
        exclude_dist_pattern => {
            summary => 'Distribution name pattern to skip',
            schema => 're*',
            tags => ['category:filtering'],
        },
        include_dist_pattern => {
            summary => 'If specified, only include distributions with this pattern',
            schema => 're*',
            tags => ['category:filtering'],
        },

        # XXX add arg: level, currently direct dependents only
        # XXX add arg: dzil test instead of prove
    },
    deps => {
        prog => 'prove',
    },
    features => {
        dry_run => 1,
    },
};
sub prove_rdeps {
    require App::lcpan::Call;

    my %args = @_;
    my $arg_download = $args{download} // 1;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ['rdeps', @{ $args{modules} }],
    );

    return [412, "Can't lcpan rdeps: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    my @fails;
    my @included_recs;
  REC:
    for my $rec (@{ $res->[2] }) {
        log_info "Found dep: %s (%s %s)", $rec->{dist}, $rec->{phase}, $rec->{rel};
        if (defined $args{phases} && @{ $args{phases} }) {
            do { log_info "Dep %s skipped (phase not included)", $rec->{dist}; next REC } unless grep {$rec->{phase} eq $_} @{ $args{phases} };
        }
        if (defined $args{rel} && @{ $args{rel} }) {
            do { log_info "Dep %s skipped (rel not included)", $rec->{dist}; next REC } unless grep {$rec->{rel} eq $_} @{ $args{rel} };
        }
        if (defined $args{include_dists} && @{ $args{include_dists} }) {
            do { log_info "Dep %s skipped (not in include_dists)", $rec->{dist}; next REC } unless grep {$rec->{dist} eq $_} @{ $args{include_dists} };
        }
        if (defined $args{include_dist_pattern}) {
            do { log_info "Dep %s skipped (does not match include_dist_pattern)", $rec->{dist}; next REC } unless $rec->{dist} =~ /$args{include_dist_pattern}/;
        }
        if (defined $args{exclude_dists} && @{ $args{exclude_dists} }) {
            do { log_info "Dep %s skipped (in exclude_dists)", $rec->{dist}; next REC } if grep {$rec->{dist} eq $_} @{ $args{exclude_dists} };
        }
        if (defined $args{exclude_dist_pattern}) {
            do { log_info "Dep %s skipped (matches exclude_dist_pattern)", $rec->{dist}; next REC } if $rec->{dist} =~ /$args{exclude_dist_pattern}/;
        }

        my $dir;
        {
            $dir = _find_dist_dir($rec->{dist}, $args{dist_dirs});
            last if defined $dir;
            unless ($arg_download) {
                log_error "Can't find dir for dist '%s', skipped", $rec->{dist};
                push @fails, {dist=>$rec->{dist}, status=>412, reason=>"Can't find dist dir"};
                next REC2;
            }
            my $dlres = _download_dist($rec->{dist});
            unless ($dlres->[0] == 200) {
                log_error "Can't download/extract dist '%s' from local CPAN mirror: %s - %s",
                    $rec->{dist}, $dlres->[0], $dlres->[1];
                push @fails, {dist=>$rec->{dist}, status=>$dlres->[0], reason=>"Can't download/extract: $dlres->[1]"};
                next REC2;
            }
            $dir = $dlres->[2];
        }

        $rec->{dir} = $dir;
        push @included_recs, $rec;
    }

    my $i = 0;
  REC2:
    for my $rec (@included_recs) {
        $i++;
        if ($args{-dry_run}) {
            log_info("[DRY] [%d/%d] Running prove for dist '%s' in '%s' ...",
                     $i, scalar(@included_recs),
                     $rec->{dist}, $rec->{dir});
            next REC2;
        }

        {
            local $CWD = $rec->{dir};
            log_warn("[%d/%d] Running prove for dist '%s' in '%s' ...",
                     $i, scalar(@included_recs),
                     $rec->{dist}, $rec->{dir});
            my $pres = _prove($args{prove_opts});
            log_debug("Prove result: %s", $pres);
            if ($pres->[0] == 200) {
                # success
            } else {
                log_error "Test for dist '%s' failed: %s",
                    $rec->{dist}, $pres->[1];
                push @fails, {dist=>$rec->{dist}, status=>500, reason=>$pres->[1]};
            }
        }
    }

    [
        @{@fails == 0 ? [200, "All succeeded"] : @fails == @{$res} ? [200, "All failed"] : [200, "Some failed"]},
        \@fails,
        {'cmdline.exit_code' => @fails ? 1:0},
    ];
}

1;
# ABSTRACT: Prove all distributions depending on specified module(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProveRdeps - Prove all distributions depending on specified module(s)

=head1 VERSION

This document describes version 0.006 of App::ProveRdeps (from Perl distribution App-ProveRdeps), released on 2020-01-30.

=head1 SYNOPSIS

See the included script L<prove-rdeps>.

=head1 FUNCTIONS


=head2 prove_rdeps

Usage:

 prove_rdeps(%args) -> [status, msg, payload, meta]

Prove all distributions depending on specified module(s).

To use this utility, first create C<~/.config/prove-rdeps.conf>:

 dist_dirs = ~/repos
 dist_dirs = ~/repos-other

The above tells I<prove-rdeps> where to look for Perl distributions. Then:

 % prove-rdeps Regexp::Pattern

This will search local CPAN mirror for all distributions that depend on
L<Log::ger> (by default for phase=runtime and rel=requires), then search the
distributions in the distribution directories (or download them from local CPAN
mirror), C<cd> to each and run C<prove> in it.

You can run with C<--dry-run> (C<-n>) option first to not actually run C<prove> but
just see what distributions will get tested. An example output:

 % prove-rdeps Regexp::Pattern -n
 prove-rdeps: Found dep: Acme-DependOnEverything (runtime requires)
 prove-rdeps: Found dep: App-BlockWebFlooders (runtime requires)
 prove-rdeps: Found dep: App-Licensecheck (runtime requires)
 prove-rdeps: Found dep: Pod-Weaver-Plugin-Regexp-Pattern (develop x_spec)
 prove-rdeps: Dep Pod-Weaver-Plugin-Regexp-Pattern skipped (phase not included)
 ...
 prove-rdeps: [DRY] [1/8] Running prove for dist 'Acme-DependOnEverything' in '/tmp/BP3l0kiuZH/Acme-DependOnEverything-0.06' ...
 prove-rdeps: [DRY] [2/8] Running prove for dist 'App-BlockWebFlooders' in '/home/u1/repos/perl-App-BlockWebFlooders' ...
 prove-rdeps: [DRY] [3/8] Running prove for dist 'App-Licensecheck' in '/tmp/pw1hBzUIaZ/App-Licensecheck-v3.0.40' ...
 prove-rdeps: [DRY] [4/8] Running prove for dist 'App-RegexpPatternUtils' in '/home/u1/repos/perl-App-RegexpPatternUtils' ...
 prove-rdeps: [DRY] [5/8] Running prove for dist 'Bencher-Scenarios-RegexpPattern' in '/home/u1/repos/perl-Bencher-Scenarios-RegexpPattern' ...
 prove-rdeps: [DRY] [6/8] Running prove for dist 'Regexp-Common-RegexpPattern' in '/home/u1/repos/perl-Regexp-Common-RegexpPattern' ...
 prove-rdeps: [DRY] [7/8] Running prove for dist 'Release-Util-Git' in '/home/u1/repos/perl-Release-Util-Git' ...
 prove-rdeps: [DRY] [8/8] Running prove for dist 'Test-Regexp-Pattern' in '/home/u1/repos/perl-Test-Regexp-Pattern' ...

The above example shows that I have the distribution directories locally on my
C<~/repos>, except for C<Acme-DependOnEverything> and C<App-Licensecheck>, which
I<prove-rdeps> downloads and extracts from local CPAN mirror and puts into
temporary directories.

If we reinvoke the above command without the C<-n>, I<prove-rdeps> will actually
run C<prove> on each directory and provide a summary at the end. Example output:

 % prove-rdeps Regexp::Pattern
 ...
 +-----------------------------+-----------------------------------+--------+
 | dist                        | reason                            | status |
 +-----------------------------+-----------------------------------+--------+
 | Acme-DependOnEverything     | Test failed (Failed 1/1 subtests) | 500    |
 | App-Licensecheck            | Test failed (No subtests run)     | 500    |
 | Regexp-Common-RegexpPattern | Non-zero exit code (2)            | 500    |
 +-----------------------------+-----------------------------------+--------+

The above example shows that three distributions failed testing. You can scroll
up for the detailed C<prove> output to see why they failed, fix things, and
re-run. To skip some dists from being tested, use C<--exclude-dist>:

 % prove-rdeps Regexp::Pattern --exclude-dist Acme-DependOnEverything

Or you can also put these lines in the configuration file:

 exclude_dists = Acme-DependOnEverything
 exclude_dists = Regexp-Common-RegexpPattern

How distribution directory is searched: first, the exact name (C<My-Perl-Dist>)
is searched. If not found, then the name with different case (e.g.
C<my-perl-dist>) is searched. If not found, a suffix match (e.g.
C<p5-My-Perl-Dist> or C<cpan-My-Perl-Dist>) is searched. If not found, a prefix
match (e.g. C<My-Perl-Dist-perl>) is searched. If not found, I<prove-rdeps> will
try to download the distribution tarball from local CPAN mirror and extract it
to a temporary directory. If C<--no-dowload> is given, the I<prove-deps> will not
download from local CPAN mirror and give up for that distribution.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

I<prove-deps> will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<dist_dirs>* => I<array[dirname]>

Where to find the distributions.

=item * B<download> => I<bool> (default: 1)

Whether to try downloadE<sol>extract distribution from local CPAN mirror (when not found in dist_dirs).

=item * B<exclude_dist_pattern> => I<re>

Distribution name pattern to skip.

=item * B<exclude_dists> => I<array[perl::distname]>

Distributions to skip.

=item * B<include_dist_pattern> => I<re>

If specified, only include distributions with this pattern.

=item * B<include_dists> => I<array[perl::distname]>

If specified, only include these distributions.

=item * B<modules>* => I<array[perl::modname]>

Module names to find dependents of.

=item * B<phases> => I<array[str]> (default: ["runtime"])

Only select dists that depend in these phases.

=item * B<prove_opts> => I<array[str]> (default: ["-l"])

Options to pass to the prove command.

=item * B<rels> => I<array[str]> (default: ["requires"])

Only select dists that depend using these relationships.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ProveRdeps>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProveDeps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProveRdeps>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<prove>

L<App::lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
