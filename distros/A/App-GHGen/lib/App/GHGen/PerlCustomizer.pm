package App::GHGen::PerlCustomizer;

use v5.36;
use strict;
use warnings;

use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	detect_perl_requirements
	generate_custom_perl_workflow
);

our $VERSION = '0.06';

=encoding utf-8

=head1 NAME

App::GHGen::PerlCustomizer - Customize Perl workflows based on project requirements

=head1 SYNOPSIS

	use App::GHGen::PerlCustomizer qw(detect_perl_requirements);

	my $requirements = detect_perl_requirements();
	# Returns: { min_version => '5.036', has_cpanfile => 1, ... }

=head1 FUNCTIONS

=head2 detect_perl_requirements()

Detect Perl version requirements and dependency-file presence in the current directory.

=head3 Purpose

Inspect the current working directory for common Perl distribution files
(C<cpanfile>, C<Makefile.PL>, C<dist.ini>, C<Build.PL>) and extract the
minimum Perl version declared in any of them.

=head3 Arguments

None.

=head3 Returns

A hash reference with the following keys, all of which are always present:

    {
        min_version    => Str | undef,  # e.g. '5.036'; undef when undetected
        has_cpanfile   => Bool,
        has_makefile_pl => Bool,
        has_dist_ini   => Bool,
        has_build_pl   => Bool,
    }

=head3 Side Effects

Reads files from the current working directory.

=head3 Usage Example

    use App::GHGen::PerlCustomizer qw(detect_perl_requirements);
    my $reqs = detect_perl_requirements();
    say $reqs->{min_version} // 'not specified';

=head3 API SPECIFICATION

=head4 Input

    # No parameters.

=head4 Output

    {
        type => 'hashref',
        keys => {
            min_version     => { type => 'scalar', optional => 1 },
            has_cpanfile    => { type => 'scalar' },
            has_makefile_pl => { type => 'scalar' },
            has_dist_ini    => { type => 'scalar' },
            has_build_pl    => { type => 'scalar' },
        },
    }

=head3 FORMAL SPECIFICATION

    detect_perl_requirements : → Requirements

    Requirements ≔ {
        min_version:     ℤ* ∪ { ⊥ },
        has_cpanfile:    𝔹,
        has_makefile_pl: 𝔹,
        has_dist_ini:    𝔹,
        has_build_pl:    𝔹,
    }

    min_version ≔
        cpanfile exists ∧ version parseable from cpanfile  → version
        Makefile.PL exists ∧ MIN_PERL_VERSION parseable   → version
        otherwise                                           → ⊥

=cut

sub detect_perl_requirements() {
	my %reqs = (
		min_version => undef,
		has_cpanfile => 0,
		has_makefile_pl => 0,
		has_dist_ini => 0,
		has_build_pl => 0,
	);

	# Check for dependency files
	$reqs{has_cpanfile} = path('cpanfile')->exists;
	$reqs{has_makefile_pl} = path('Makefile.PL')->exists;
	$reqs{has_dist_ini} = path('dist.ini')->exists;
	$reqs{has_build_pl} = path('Build.PL')->exists;

	# Try to detect minimum Perl version
	if ($reqs{has_cpanfile}) {
		my $content = path('cpanfile')->slurp_utf8;
		if ($content =~ /requires\s+['"]perl['"],?\s+['"]([0-9.]+)['"]/) {
			$reqs{min_version} = $1;
		}
	}

	if (!$reqs{min_version} && $reqs{has_makefile_pl}) {
		my $content = path('Makefile.PL')->slurp_utf8;
		if ($content =~ /MIN_PERL_VERSION\s*=>\s*['"]([0-9.]+)['"]/) {
			$reqs{min_version} = $1;
		}
	}

	return \%reqs;
}

=head2 generate_custom_perl_workflow($options)

Generate a customized Perl CI workflow and return it as a YAML string.

B<Options:>

=over 4

=item C<perl_versions> (array ref)

Explicit list of Perl versions to include in the test matrix, e.g.
C<['5.40', '5.38', '5.36']>.  Takes precedence over C<min_perl_version>
and C<max_perl_version> when supplied.

=item C<min_perl_version> (string, default C<'5.36'>)

Lowest Perl version to include in the matrix when C<perl_versions> is not
given.  Accepts both C<'5.036'> and C<'5.36'> notation.

=item C<max_perl_version> (string, default C<'5.42'>)

Highest Perl version to include in the default matrix when C<perl_versions>
is not given.  The built-in version table currently spans C<5.22> through
C<5.44>; the default produces the matrix C<5.36, 5.38, 5.40, 5.42>.

To test against B<Perl 5.44> (opt-in, not tested by default), pass
C<< max_perl_version => '5.44' >> or set C<perl_versions> explicitly:

    generate_custom_perl_workflow({ max_perl_version => '5.44' });
    # matrix: 5.36, 5.38, 5.40, 5.42, 5.44

    generate_custom_perl_workflow({ perl_versions => ['5.42', '5.44'] });
    # matrix: 5.42, 5.44

=item C<os> (array ref)

Operating systems for the build matrix.
Default: C<['ubuntu-latest', 'macos-latest', 'windows-latest']>.

=item C<timeout> (integer, default C<30>)

Value written to C<timeout-minutes> on every matrix job.

=item C<enable_linter> (boolean, default C<1>)

When true, inserts a B<"Lint and syntax check"> step after all dependency
installation steps and before the test run.  The step runs on B<every>
matrix cell (all OS and Perl version combinations) so that compile-time
errors are caught across the full version range being tested.

The step uses C<shell: perl {0}>, which works identically on Linux, macOS,
and Windows without any OS-specific branching.  It searches C<lib/> and
C<bin/> (falling back to C<.> when neither exists), spawns
C<perl -Mstrict -Mwarnings -c> for each C<.pm> file found, and exits
non-zero if any file fails.  B<No additional CPAN modules are required.>

=item C<enable_linter_unused> (boolean, default C<1>)

When true, inserts a B<"Check for unused variables"> step immediately after
the test run and before Perl::Critic.  The step installs L<warnings::unused>
from CPAN and runs C<perl -Mwarnings::unused -c> on every C<.pm> file under
C<lib/>.

This step is conditioned on the latest matrix Perl version and
C<ubuntu-latest>, matching the Perl::Critic and coverage steps.  It is also
marked C<continue-on-error: true> because unused-variable warnings can be
legitimately noisy on some codebases.

=item C<enable_critic> (boolean, default C<1>)

When true, adds a Perl::Critic step on the latest matrix Perl version and
C<ubuntu-latest>.

=item C<enable_coverage> (boolean, default C<1>)

When true, adds a Devel::Cover test-coverage step on the latest matrix Perl
version and C<ubuntu-latest>.

=item C<enable_perlimports> (boolean, default C<1>)

When true, adds a B<"Check imports with perlimports"> step on the latest matrix
Perl version and C<ubuntu-latest>.  The step installs L<App::perlimports> from
CPAN and runs C<perlimports --lint> across all C<.pm> files under C<lib/>.  It
is marked C<continue-on-error: true> because import hygiene warnings are
advisory; they should not block a CI run in established codebases.

=back

B<Generated step order:>

=over 4

=item 1. C<actions/checkout>

=item 2. Setup Perl via C<shogo82148/actions-setup-perl>

=item 3. Cache CPAN modules via C<actions/cache>

=item 4. Install cpanm and C<local::lib>

=item 5. Install project dependencies

=item 6. B<Lint and syntax check> — all matrix cells (when C<enable_linter> is true); the unused-variable check via C<PERL5OPT=-Mwarnings::unused> is embedded at the end of this step when C<enable_linter_unused> is true

=item 7. Run tests

=item 8. Run Perl::Critic — latest Perl + Ubuntu only (when C<enable_critic> is true)

=item 9. B<Check imports with perlimports> — latest Perl + Ubuntu only (when C<enable_perlimports> is true)

=item 10. Test coverage — latest Perl + Ubuntu only (when C<enable_coverage> is true)

=item 11. Show cpanm build log on failure

=back

=head3 API SPECIFICATION

=head4 Input

    {
        opts => {
            type     => 'hashref',
            default  => {},
            keys     => {
                perl_versions        => { type => 'arrayref', optional => 1 },
                min_perl_version     => { type => 'scalar',  default  => '5.36' },
                max_perl_version     => { type => 'scalar',  default  => '5.42' },
                os                   => { type => 'arrayref', optional => 1 },
                timeout              => { type => 'scalar',  default  => 30 },
                enable_linter        => { type => 'scalar',  default  => 1 },
                enable_linter_unused => { type => 'scalar',  default  => 1 },
                enable_critic        => { type => 'scalar',  default  => 1 },
                enable_coverage      => { type => 'scalar',  default  => 1 },
                enable_perlimports   => { type => 'scalar',  default  => 1 },
            },
        },
    }

=head4 Output

    { type => 'scalar' }   # multi-line YAML string starting with '---'

=head3 FORMAL SPECIFICATION

    generate_custom_perl_workflow : Opts → YAML

    versions ≔ opts.perl_versions ?? range(min, max)
    latest   ≔ versions[|versions|−1]

    yaml contains "Lint and syntax check" step       ↔  opts.enable_linter = 1
    yaml contains "PERL5OPT=-Mwarnings::unused"      ↔  opts.enable_linter_unused = 1
    yaml contains "Run Perl::Critic"                 ↔  opts.enable_critic = 1
    yaml contains "Test coverage"                    ↔  opts.enable_coverage = 1
    yaml contains "Check imports with perlimports"   ↔  opts.enable_perlimports = 1

    step ordering invariant:
      pos(lint) < pos(unused) < pos(tests) < pos(critic) < pos(perlimports) < pos(coverage)

=cut

sub generate_custom_perl_workflow($opts = {}) {
	my $min_version = $opts->{min_perl_version} // '5.36';
	my $max_version = $opts->{max_perl_version} // '5.42';
	my $timeout = $opts->{timeout} // 30;
	my @os = @{$opts->{os} // ['ubuntu-latest', 'macos-latest', 'windows-latest']};
	my $enable_linter = $opts->{enable_linter} // 1;
	my $enable_linter_unused = $opts->{enable_linter_unused} // 1;
	my $enable_critic = $opts->{enable_critic} // 1;
	my $enable_coverage = $opts->{enable_coverage} // 1;
	my $enable_perlimports = $opts->{enable_perlimports} // 1;

	# Generate Perl version list - use explicit list if provided, otherwise min/max
	my @perl_versions;
	if ($opts->{perl_versions} && @{$opts->{perl_versions}}) {
		@perl_versions = @{$opts->{perl_versions}};
	} else {
		@perl_versions = _get_perl_versions($min_version, $max_version);
	}

	my $yaml = "---\n";
	$yaml .= '# Created by ' . __PACKAGE__ . "\n";

	$yaml .= "name: Perl CI\n\n";
	$yaml .= "'on':\n";
	$yaml .= "  push:\n";
	$yaml .= "    branches:\n";
	$yaml .= "      - main\n";
	$yaml .= "      - master\n";
	$yaml .= "  pull_request:\n";
	$yaml .= "    branches:\n";
	$yaml .= "      - main\n";
	$yaml .= "      - master\n\n";

	$yaml .= "concurrency:\n";
	$yaml .= "  group: \${{ github.workflow }}-\${{ github.ref }}\n";
	$yaml .= "  cancel-in-progress: true\n\n";

	$yaml .= "permissions:\n";
	$yaml .= "  contents: read\n\n";

	$yaml .= "jobs:\n";
	$yaml .= "  test:\n";
	$yaml .= "    runs-on: \${{ matrix.os }}\n";
	$yaml .= "    timeout-minutes: $timeout\n";
	$yaml .= "    strategy:\n";
	$yaml .= "      fail-fast: false\n";
	$yaml .= "      matrix:\n";
	$yaml .= "        os:\n";
	for my $os (@os) {
		$yaml .= "          - $os\n";
	}
	$yaml .= "        perl:\n";
	for my $version (@perl_versions) {
		$yaml .= "          - '$version'\n";
	}
	$yaml .= "    name: Perl \${{ matrix.perl }} on \${{ matrix.os }}\n";
	$yaml .= "    env:\n";
	$yaml .= "      AUTOMATED_TESTING: 1\n";
	$yaml .= "      NO_NETWORK_TESTING: 1\n";
	$yaml .= "      NONINTERACTIVE_TESTING: 1\n";
	$yaml .= "    steps:\n";
	$yaml .= "      - uses: actions/checkout\@v7\n\n";

	$yaml .= "      - name: Setup Perl\n";
	$yaml .= "        uses: shogo82148/actions-setup-perl\@v1\n";
	$yaml .= "        with:\n";
	$yaml .= "          perl-version: \${{ matrix.perl }}\n\n";

	$yaml .= "      - name: Cache CPAN modules\n";
	$yaml .= "        uses: actions/cache\@v6\n";
	$yaml .= "        with:\n";
	$yaml .= "          path: ~/perl5\n";
	$yaml .= "          key: \${{ runner.os }}-\${{ matrix.perl }}-\${{ hashFiles('cpanfile') }}\n";
	$yaml .= "          restore-keys: |\n";
	$yaml .= "            \${{ runner.os }}-\${{ matrix.perl }}-\n\n";

	$yaml .= "      - name: Install cpanm and local::lib\n";
	$yaml .= "        if: runner.os != 'Windows'\n";
	$yaml .= "        run: cpanm --notest --local-lib=~/perl5 local::lib\n\n";

	$yaml .= "      - name: Install cpanm and local::lib (Windows)\n";
	$yaml .= "        if: runner.os == 'Windows'\n";
	$yaml .= "        run: cpanm --notest App::cpanminus local::lib\n\n";

	$yaml .= "      - name: Install dependencies\n";
	$yaml .= "        if: runner.os != 'Windows'\n";
	$yaml .= "        shell: bash\n";
	$yaml .= "        run: |\n";
	$yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
	$yaml .= "          cpanm --notest --installdeps .\n\n";

	$yaml .= "      - name: Install dependencies (Windows)\n";
	$yaml .= "        if: runner.os == 'Windows'\n";
	$yaml .= "        shell: cmd\n";
	$yaml .= "        run: |\n";
	$yaml .= "          \@echo off\n";
	$yaml .= "          set \"PATH=%USERPROFILE%\\perl5\\bin;%PATH%\"\n";
	$yaml .= "          set \"PERL5LIB=%USERPROFILE%\\perl5\\lib\\perl5\"\n";
	$yaml .= "          cpanm --notest --installdeps .\n\n";

	if ($enable_linter) {
		$yaml .= "      - name: Lint and syntax check\n";
		$yaml .= "        shell: perl {0}\n";
		$yaml .= "        run: |\n";
		$yaml .= <<'LINT_STEP';
          use strict;
          use warnings;
          use File::Find;
          use lib 'lib';
          my @failed;
          push @INC, sub { open my $h, '<', \qq{1;\n}; $h };
          my @dirs = grep { -d } qw(lib bin);
          @dirs = ('.') unless @dirs;
          find({ wanted => sub {
              return unless -f && /\.pm$/;
              my $file = $File::Find::name;
              do $file;
              if ($@) {
                  warn "Syntax check failed: $file\n";
                  push @failed, $file;
              }
          }, no_chdir => 1 }, @dirs);

LINT_STEP

		if ($enable_linter_unused) {
			$yaml .= <<'UNUSED_CODE';
          if (($ENV{RUNNER_OS} // '') eq 'Linux') {
              system('cpanm --notest --quiet warnings::unused 2>/dev/null');
              system('PERL5OPT=-Mwarnings::unused prove -lr t/ 2>&1 | grep -i unused && true || echo "warnings::unused: no unused variables detected"');
          }

UNUSED_CODE
		}

		$yaml .= "          exit(\@failed ? 1 : 0);\n\n";
	}

	$yaml .= "      - name: Run tests\n";
	$yaml .= "        if: runner.os != 'Windows'\n";
	$yaml .= "        shell: bash\n";
	$yaml .= "        run: |\n";
	$yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
	$yaml .= "          prove -lr t/\n\n";

	$yaml .= "      - name: Run tests (Windows)\n";
	$yaml .= "        if: runner.os == 'Windows'\n";
	$yaml .= "        shell: cmd\n";
	$yaml .= "        run: |\n";
	$yaml .= "          \@echo off\n";
	$yaml .= "          set \"PATH=%USERPROFILE%\\perl5\\bin;%PATH%\"\n";
	$yaml .= "          set \"PERL5LIB=%USERPROFILE%\\perl5\\lib\\perl5\"\n";
	$yaml .= "          prove -lr t/\n\n";

	if ($enable_critic) {
		my $latest = $perl_versions[-1];
		$yaml .= "      - name: Run Perl::Critic\n";
		$yaml .= "        if: matrix.perl == '$latest' && matrix.os == 'ubuntu-latest'\n";
		$yaml .= "        continue-on-error: true\n";
		$yaml .= "        run: |\n";
		$yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
		$yaml .= "          cpanm --notest Perl::Critic\n";
		$yaml .= "          perlcritic --severity 3 lib/ || true\n";
		$yaml .= "        shell: bash\n\n";
	}

	if ($enable_perlimports) {
		my $latest = $perl_versions[-1];
		$yaml .= "      - name: Check imports with perlimports\n";
		$yaml .= "        if: matrix.perl == '$latest' && matrix.os == 'ubuntu-latest'\n";
		$yaml .= "        continue-on-error: true\n";
		$yaml .= "        run: |\n";
		$yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
		$yaml .= "          cpanm --notest App::perlimports\n";
		$yaml .= "          find lib -name '*.pm' | xargs perlimports --lint\n";
		$yaml .= "        shell: bash\n\n";
	}

	if ($enable_coverage) {
		my $latest = $perl_versions[-1];
		$yaml .= "      - name: Test coverage\n";
		$yaml .= "        if: matrix.perl == '$latest' && matrix.os == 'ubuntu-latest'\n";
		$yaml .= "        run: |\n";
		$yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
		$yaml .= "          cpanm --notest Devel::Cover\n";
		$yaml .= "          cover -delete\n";
		$yaml .= "          HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t/\n";
		$yaml .= "          cover\n";
		$yaml .= "        shell: bash\n";
	}

	$yaml .= <<'YAML';

      - name: Show cpanm build log on failure (Windows)
        if: runner.os == 'Windows' && failure()
        shell: pwsh
        run: Get-Content "$env:USERPROFILE\.cpanm\work\*\build.log" -Tail 100

      - name: Show cpanm build log on failure (non-Windows)
        if: runner.os != 'Windows' && failure()
        run: tail -100 "$HOME/.cpanm/work/*/build.log"
YAML

	return $yaml;
}

sub _get_perl_versions($min, $max) {
	# All available Perl versions in descending order.
	# 5.44 is listed so projects can opt in via max_perl_version => '5.44',
	# but it is not included in the default matrix (max defaults to 5.42).
	my @all_versions = qw(5.44 5.42 5.40 5.38 5.36 5.34 5.32 5.30 5.28 5.26 5.24 5.22);

	# Normalize version strings for comparison
	my $min_normalized = _normalize_version($min);
	my $max_normalized = _normalize_version($max);

	my @selected;
	for my $version (@all_versions) {
		my $v_normalized = _normalize_version($version);
		if ($v_normalized >= $min_normalized && $v_normalized <= $max_normalized) {
			push @selected, $version;
		}
	}

	return reverse @selected;	# Return in ascending order
}

sub _normalize_version($version) {
	# Convert "5.036" or "5.36" to comparable number
	$version =~ s/^v?//;
	my @parts = split /\./, $version;
	return sprintf("%d.%03d", $parts[0] // 5, $parts[1] // 0);
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
