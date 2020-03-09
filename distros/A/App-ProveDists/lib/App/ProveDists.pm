package App::ProveDists;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'App-ProveDists'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::ProveDirs ();
use File::chdir;
use File::Temp qw(tempdir);
use Hash::Subset qw(hash_subset);
our %SPEC;

sub _find_dist_dir {
    my ($dist, $dirs) = @_;

  DIR:
    for my $dir (@$dirs) {
        my @entries = do {
            opendir my $dh, $dir or do {
                warn "prove-dists: Can't opendir '$dir': $!\n";
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

# to be shared with prove-rdeps
our %args_common = (
    %App::ProveDirs::args_common,
    dists_dirs => {
        summary => 'Where to find the distributions directories',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'dists_dir',
        schema => ['array*', of=>'dirname*'],
        req => 1,
    },
    download => {
        summary => 'Whether to try download/extract distribution from local CPAN mirror (when not found in dists_dirs)',
        schema => 'bool*',
        default => 1,
    },
);

$SPEC{prove_dists} = {
    v => 1.1,
    summary => 'Prove Perl distributions',
    description => <<'_',

To use this utility, first create `~/.config/prove-dists.conf`:

    dists_dirs = ~/repos
    dists_dirs = ~/repos-other

The above tells *prove-dists* where to look for Perl distributions. Then:

    % prove-dists '^Games-Word-Wordlist-.+$'

This will search local CPAN mirror for all distributions that match that regex
pattern, then search the distributions in the distribution directories (or
download them from local CPAN mirror), `cd` to each and run `prove` in it.

You can run with `--dry-run` (`-n`) option first to not actually run `prove` but
just see what distributions will get tested. An example output:

    % prove-dists '^Games-Word-Wordlist-.+$' -n
    prove-dists: Found dist: Games-Word-Wordlist-Country
    prove-dists: Found dist: Games-Word-Wordlist-Enable
    prove-dists: Found dist: Games-Word-Wordlist-HSK
    prove-dists: Found dist: Games-Word-Wordlist-KBBI
    prove-dists: Found dist: Games-Word-Wordlist-SGB
    prove-dists: [DRY] [1/5] Running prove for distribution Games-Word-Wordlist-Country (directory /home/u1/repos/perl-Games-Word-Wordlist-Country) ...
    prove-dists: [DRY] [2/5] Running prove for distribution Games-Word-Wordlist-Enable (directory /tmp/AmYe5AHXpm/Games-Word-Wordlist-Enable-2010090401) ...
    prove-dists: [DRY] [3/5] Running prove for distribution Games-Word-Wordlist-HSK (directory /home/u1/repos/perl-Games-Word-Wordlist-HSK) ...
    prove-dists: [DRY] [4/5] Running prove for distribution Games-Word-Wordlist-KBBI (directory /home/u1/repos/perl-Games-Word-Wordlist-KBBI) ...
    prove-dists: [DRY] [5/5] Running prove for distribution Games-Word-Wordlist-SGB (directory /tmp/xHAvt5uAhM/Games-Word-Wordlist-SGB-2010091501) ...

The above example shows that I have the distribution directories locally on my
`~/repos`, except for `Games-Word-Wordlist-Enable` and
`Games-Word-Wordlist-SGB`, which *prove-dists* downloads and extracts from local
CPAN mirror and puts into temporary directories.

If we reinvoke the above command without the `-n`, *prove-dists* will actually
run `prove` on each directory and provide a summary at the end. Example output:

    % prove-dists '^Games-Word-Wordlist-.+$'
    +----------------------------------------------+---------------------------------------+-----------------------------------+--------+
    | dir                                          | label                                 | reason                            | status |
    +----------------------------------------------+---------------------------------------+-----------------------------------+--------+
    | /home/u1/repos/perl-Games-Word-Wordlist-KBBI | distribution Games-Word-Wordlist-KBBI | Test failed (Failed 1/1 subtests) | 500    |
    +----------------------------------------------+---------------------------------------+-----------------------------------+--------+

The above example shows that one distribution failed testing. You can scroll up
for the detailed `prove` output to see the detail of the failure, fix things,
and re-run.

To summarize not only failures but all successes as well, use `--summarize-all`
option:

    % prove-dists '^Games-Word-Wordlist-.+$' --summarize-all
    +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+
    | dir                                                   | label                                    | reason                            | status |
    +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+
    | /home/u1/repos/perl-Games-Word-Wordlist-Country       | distribution Games-Word-Wordlist-Country | PASS                              | 200    |
    | /tmp/rjjMJVgaXg/Games-Word-Wordlist-Enable-2010090401 | distribution Games-Word-Wordlist-Enable  | PASS                              | 200    |
    | /home/u1/repos/perl-Games-Word-Wordlist-HSK           | distribution Games-Word-Wordlist-HSK     | NOTESTS                           | 200    |
    | /home/u1/repos/perl-Games-Word-Wordlist-KBBI          | distribution Games-Word-Wordlist-KBBI    | Test failed (Failed 1/1 subtests) | 500    |
    | /tmp/_W8im6EvA0/Games-Word-Wordlist-SGB-2010091501    | distribution Games-Word-Wordlist-SGB     | PASS                              | 200    |
    +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+

How distribution directory is searched: first, the exact name (`My-Perl-Dist`)
is searched. If not found, then the name with different case (e.g.
`my-perl-dist`) is searched. If not found, a suffix match (e.g.
`p5-My-Perl-Dist` or `cpan-My-Perl-Dist`) is searched. If not found, a prefix
match (e.g. `My-Perl-Dist-perl`) is searched. If not found, *prove-dists* will
try to download the distribution tarball from local CPAN mirror and extract it
to a temporary directory. If `--no-dowload` is given, the *prove-dists* will not
download from local CPAN mirror and give up for that distribution.

When a distribution cannot be found or downloaded/extracted, this counts as a
412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

*prove-dists* will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

_
    args => {
        %args_common,
        dist_patterns => {
            summary => 'Distribution name patterns to find',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dist_pattern',
            schema => ['array*', of=>'re*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub prove_dists {
    require App::lcpan::Call;

    my %args = @_;
    my $arg_download = $args{download} // 1;

    my $res;
    if ($args{_res}) {
        $res = $args{_res};
    } else {
        $res = App::lcpan::Call::call_lcpan_script(
            argv => ['dists', '--latest', '-l', '-r', '--or', @{ $args{dist_patterns} }],
        );
        return [412, "Can't lcpan dists: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
    }

    my @fails;
    my @included_recs;
  REC:
    for my $rec (@{ $res->[2] }) {
        log_info "Found dist: %s", $rec->{dist};

        my $dir;
        {
            $dir = _find_dist_dir($rec->{dist}, $args{dists_dirs});
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

    App::ProveDirs::prove_dirs(
        hash_subset(\%args, \%App::ProveDirs::args_common),
        -dry_run => $args{-dry_run},
        _dirs => { map {$_->{dir} => "distribution $_->{dist}"} @included_recs },
    );
}

1;
# ABSTRACT: Prove Perl distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProveDists - Prove Perl distributions

=head1 VERSION

This document describes version 0.003 of App::ProveDists (from Perl distribution App-ProveDists), released on 2020-03-07.

=head1 SYNOPSIS

See the included script L<prove-dists>.

=head1 FUNCTIONS


=head2 prove_dists

Usage:

 prove_dists(%args) -> [status, msg, payload, meta]

Prove Perl distributions.

To use this utility, first create C<~/.config/prove-dists.conf>:

 dists_dirs = ~/repos
 dists_dirs = ~/repos-other

The above tells I<prove-dists> where to look for Perl distributions. Then:

 % prove-dists '^Games-Word-Wordlist-.+$'

This will search local CPAN mirror for all distributions that match that regex
pattern, then search the distributions in the distribution directories (or
download them from local CPAN mirror), C<cd> to each and run C<prove> in it.

You can run with C<--dry-run> (C<-n>) option first to not actually run C<prove> but
just see what distributions will get tested. An example output:

 % prove-dists '^Games-Word-Wordlist-.+$' -n
 prove-dists: Found dist: Games-Word-Wordlist-Country
 prove-dists: Found dist: Games-Word-Wordlist-Enable
 prove-dists: Found dist: Games-Word-Wordlist-HSK
 prove-dists: Found dist: Games-Word-Wordlist-KBBI
 prove-dists: Found dist: Games-Word-Wordlist-SGB
 prove-dists: [DRY] [1/5] Running prove for distribution Games-Word-Wordlist-Country (directory /home/u1/repos/perl-Games-Word-Wordlist-Country) ...
 prove-dists: [DRY] [2/5] Running prove for distribution Games-Word-Wordlist-Enable (directory /tmp/AmYe5AHXpm/Games-Word-Wordlist-Enable-2010090401) ...
 prove-dists: [DRY] [3/5] Running prove for distribution Games-Word-Wordlist-HSK (directory /home/u1/repos/perl-Games-Word-Wordlist-HSK) ...
 prove-dists: [DRY] [4/5] Running prove for distribution Games-Word-Wordlist-KBBI (directory /home/u1/repos/perl-Games-Word-Wordlist-KBBI) ...
 prove-dists: [DRY] [5/5] Running prove for distribution Games-Word-Wordlist-SGB (directory /tmp/xHAvt5uAhM/Games-Word-Wordlist-SGB-2010091501) ...

The above example shows that I have the distribution directories locally on my
C<~/repos>, except for C<Games-Word-Wordlist-Enable> and
C<Games-Word-Wordlist-SGB>, which I<prove-dists> downloads and extracts from local
CPAN mirror and puts into temporary directories.

If we reinvoke the above command without the C<-n>, I<prove-dists> will actually
run C<prove> on each directory and provide a summary at the end. Example output:

 % prove-dists '^Games-Word-Wordlist-.+$'
 +----------------------------------------------+---------------------------------------+-----------------------------------+--------+
 | dir                                          | label                                 | reason                            | status |
 +----------------------------------------------+---------------------------------------+-----------------------------------+--------+
 | /home/u1/repos/perl-Games-Word-Wordlist-KBBI | distribution Games-Word-Wordlist-KBBI | Test failed (Failed 1/1 subtests) | 500    |
 +----------------------------------------------+---------------------------------------+-----------------------------------+--------+

The above example shows that one distribution failed testing. You can scroll up
for the detailed C<prove> output to see the detail of the failure, fix things,
and re-run.

To summarize not only failures but all successes as well, use C<--summarize-all>
option:

 % prove-dists '^Games-Word-Wordlist-.+$' --summarize-all
 +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+
 | dir                                                   | label                                    | reason                            | status |
 +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+
 | /home/u1/repos/perl-Games-Word-Wordlist-Country       | distribution Games-Word-Wordlist-Country | PASS                              | 200    |
 | /tmp/rjjMJVgaXg/Games-Word-Wordlist-Enable-2010090401 | distribution Games-Word-Wordlist-Enable  | PASS                              | 200    |
 | /home/u1/repos/perl-Games-Word-Wordlist-HSK           | distribution Games-Word-Wordlist-HSK     | NOTESTS                           | 200    |
 | /home/u1/repos/perl-Games-Word-Wordlist-KBBI          | distribution Games-Word-Wordlist-KBBI    | Test failed (Failed 1/1 subtests) | 500    |
 | /tmp/_W8im6EvA0/Games-Word-Wordlist-SGB-2010091501    | distribution Games-Word-Wordlist-SGB     | PASS                              | 200    |
 +-------------------------------------------------------+------------------------------------------+-----------------------------------+--------+

How distribution directory is searched: first, the exact name (C<My-Perl-Dist>)
is searched. If not found, then the name with different case (e.g.
C<my-perl-dist>) is searched. If not found, a suffix match (e.g.
C<p5-My-Perl-Dist> or C<cpan-My-Perl-Dist>) is searched. If not found, a prefix
match (e.g. C<My-Perl-Dist-perl>) is searched. If not found, I<prove-dists> will
try to download the distribution tarball from local CPAN mirror and extract it
to a temporary directory. If C<--no-dowload> is given, the I<prove-dists> will not
download from local CPAN mirror and give up for that distribution.

When a distribution cannot be found or downloaded/extracted, this counts as a
412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

I<prove-dists> will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<dist_patterns>* => I<array[re]>

Distribution name patterns to find.

=item * B<dists_dirs>* => I<array[dirname]>

Where to find the distributions directories.

=item * B<download> => I<bool> (default: 1)

Whether to try downloadE<sol>extract distribution from local CPAN mirror (when not found in dists_dirs).

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ProveDists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProveDists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProveDists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<prove-dirs> in L<App::ProveDirs>

L<prove-mods> in L<App::ProveMods>

L<prove-rdeps> in L<App::ProveRdeps>

L<prove>

L<App::lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
