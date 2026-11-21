package App::GHGen::Generator;

use v5.36;

use strict;
use warnings;
use autodie;

use Carp qw(carp croak);
use List::Util qw(uniq);
use Readonly;
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);

use Exporter 'import';
our @EXPORT_OK = qw(
	generate_workflow
	list_workflow_types
	parse_os_list
	parse_version_list
);

# A version is a single token: letters, digits and . + * - _ only.  Anything
# else (newlines, quotes, colons) could break out of the YAML scalar the
# version is written into.
Readonly my $VERSION_PATTERN => qr/\A[\w.+*-]+\z/;

# Short OS names accepted by --os, mapped to GitHub runner labels.
Readonly my %RUNNER_LABEL_FOR => (
	linux   => 'ubuntu-latest',
	ubuntu  => 'ubuntu-latest',
	macos   => 'macos-latest',
	windows => 'windows-latest',
);

# A literal runner label such as ubuntu-22.04 is passed through unchanged.
Readonly my $RUNNER_LABEL_PATTERN => qr/\A(?:ubuntu|macos|windows)-[\w.]+\z/;

# Generator types that expose a "<key>:" list of versions in their matrix.
Readonly my %MATRIX_KEY_FOR => (
	node   => 'node-version',
	python => 'python-version',
	ruby   => 'ruby-version',
	java   => 'java-version',
	php    => 'php-version',
);

# Types with no language version to vary at all.
Readonly my %VERSIONLESS_TYPE => map { $_ => 1 } qw(cpp docker static);

# The Go and Rust templates pin one version; these are the texts rewritten
# to turn that pin into a matrix.
Readonly my $GO_PINNED_VERSION   => qr/go-version: '1\.22'/;
Readonly my $RUST_TOOLCHAIN_STEP => qr/(uses: dtolnay\/rust-toolchain\@stable\n)/;

# Every user-facing message lives here so it can be translated or reworded
# without touching the logic.  Values are sprintf formats; see _message().
our %MESSAGES = (
	invalid_version  => "Invalid version '%s' for --versions",
	no_versions      => '--versions requires at least one version',
	unknown_os       => "Unknown OS '%s' for --os (use linux, macos, windows)",
	no_os            => '--os requires at least one operating system',
	versions_ignored => "--versions has no effect for type '%s'",
	unknown_message  => "Internal error: unknown message key '%s'",
);

our $VERSION = '0.13';

=encoding utf-8

=head1 NAME

App::GHGen::Generator - Generate GitHub Actions workflows

=head1 SYNOPSIS

    use App::GHGen::Generator qw(generate_workflow);
    use Path::Tiny;

    my $yaml = generate_workflow('perl');
    path('.github/workflows/ci.yml')->spew_utf8($yaml);

=head1 FUNCTIONS

=head2 generate_workflow($type, \%opts)

Generate a complete GitHub Actions workflow YAML string for the given project type.

=head3 Purpose

Dispatch to the appropriate language-specific workflow generator and return
the resulting YAML string ready to be written to a C<.github/workflows/> file.

=head3 Arguments

=over 4

=item C<$type> (Str, required)

A project-type identifier.  Supported values: C<perl>, C<node>, C<python>,
C<rust>, C<go>, C<ruby>, C<java>, C<cpp>, C<php>, C<docker>, C<static>.

=item C<$opts> (HashRef, optional)

=over 4

=item C<versions> (ArrayRef of Str)

Language/runtime versions to test against, replacing the default matrix.
Applies to C<perl>, C<node>, C<python>, C<ruby>, C<java>, C<php>, C<go>
(Go Go-versions) and C<rust> (toolchains, e.g. C<stable>, C<beta>, C<1.80>).
It is ignored for C<cpp>, C<docker> and C<static>, which have no version
matrix.  Each entry may contain only letters, digits, C<.>, C<->, C<+>,
C<*> and C<_>; anything else croaks.

Defaults when C<versions> is not given: perl 5.36, 5.38, 5.40, 5.42;
node 18.x, 20.x, 22.x; python 3.9-3.12; ruby 3.1-3.3; java 11, 17, 21;
php 8.1-8.3; go 1.22; rust stable.

=back

=back

=head3 Returns

A multi-line YAML string beginning with C<---> when C<$type> is recognised,
or C<undef> when the type is not supported.

=head3 Side Effects

The C<perl> type without C<versions> reads the current directory to detect
project requirements (via L<App::GHGen::PerlCustomizer>).  Passing
C<versions> for C<cpp>, C<docker> or C<static> emits a C<carp> warning.

=head3 Usage

    use App::GHGen::Generator qw(generate_workflow);
    my $yaml = generate_workflow('node') // die "unsupported type";
    path('.github/workflows/ci.yml')->spew_utf8($yaml);

=head3 EXAMPLE

    # Default matrix
    my $default = generate_workflow('python');

    # Only test the two newest Pythons
    my $custom = generate_workflow('python', { versions => ['3.12', '3.13'] });

    # Go pins one version by default; --versions turns it into a matrix
    my $go = generate_workflow('go', { versions => ['1.23', '1.24'] });

=head3 MESSAGES

=over 4

=item C<Invalid version '%s' for --versions> (croak)

An entry in C<versions> contains characters outside C<[A-Za-z0-9_.+*-]>.
Remove the offending characters.

=item C<--versions has no effect for type '%s'> (carp)

C<versions> was supplied for C<cpp>, C<docker> or C<static>, which have no
version matrix.  The YAML is returned unchanged; drop the option.

=back

=head3 API SPECIFICATION

=head4 Input

    {
        type => { type => 'scalar', required => 1 },
        opts => {
            type     => 'hashref',
            optional => 1,
            keys     => { versions => { type => 'arrayref', optional => 1 } },
        },
    }

=head4 Output

    known type   -> { type => 'scalar' }   # YAML string
    unknown type -> undef

=head3 FORMAL SPECIFICATION

    SupportedTypes ≔ { perl, node, python, rust, go, ruby, java, cpp, php, docker, static }

    generate_workflow : ℤ* → ℤ* ∪ { ⊥ }

    t ∈ SupportedTypes ∧ versions = ∅  → generators[t]()          (default matrix)
    t ∈ SupportedTypes ∧ versions ≠ ∅  → rewrite(generators[t](), versions)
    t ∉ SupportedTypes                 → ⊥                        (undef)

    ∀ v ∈ versions • v ∈ VersionToken      (else croak)

=head3 PSEUDOCODE

    look up the generator for $type; return undef when there is none
    when no versions were requested, return the generator's default YAML
    validate every requested version (croak on an unsafe one)
    warn when the type has no version matrix
    perl:        regenerate with the explicit version list
    node/python/ruby/java/php: replace the existing matrix list
    go/rust:     replace the pinned version with a matrix reference and
                 insert a one-key matrix under the job

=cut

sub generate_workflow($type, $opts = {}) {
	my %generators = (
		perl   => \&_generate_perl_workflow,
		node   => \&_generate_node_workflow,
		python => \&_generate_python_workflow,
		rust   => \&_generate_rust_workflow,
		go     => \&_generate_go_workflow,
		ruby   => \&_generate_ruby_workflow,
		java   => \&_generate_java_workflow,
		cpp    => \&_generate_cpp_workflow,
		php    => \&_generate_php_workflow,
		docker => \&_generate_docker_workflow,
		static => \&_generate_static_workflow,
	);

	my $generator = $generators{$type};
	my $versions = $opts->{versions};
	my $yaml;

	if (!$generator) {
		# Unknown type: documented to return undef rather than croak
		$yaml = undef;
	} elsif (!($versions && @{$versions})) {
		$yaml = $generator->();
	} else {
		# Validate before touching the template so a bad value never reaches YAML
		_validate_versions($versions);
		carp _message('versions_ignored', $type) if $VERSIONLESS_TYPE{$type};

		# Perl builds its matrix itself; the other types are rewritten text
		$yaml = ($type eq 'perl')
			? generate_custom_perl_workflow({ perl_versions => [ @{$versions} ] })
			: _apply_versions($type, $generator->(), $versions);
	}

	return $yaml;
}

=head2 parse_version_list($text)

Turn a comma-separated C<--versions> string into a validated list of versions.

=head3 Purpose

Give the command line and the API one definition of what a version list is,
so C<--versions=5.40, 5.42> means the same thing everywhere.

=head3 Arguments

=over 4

=item C<$text> (Str, required)

Comma-separated versions.  Whitespace around entries is ignored, empty
entries are dropped and duplicates are removed, keeping the first occurrence.

=back

=head3 Returns

An array reference of version strings, in the order given.

=head3 Side Effects

None.

=head3 Usage

    my $versions = parse_version_list($ARGV_versions);
    my $yaml = generate_workflow('node', { versions => $versions });

=head3 EXAMPLE

    parse_version_list('20, 22,20');    # ['20', '22']
    parse_version_list('5.40,5.42');    # ['5.40', '5.42']
    parse_version_list(',');            # croaks: needs at least one version

=head3 MESSAGES

=over 4

=item C<--versions requires at least one version> (croak)

C<$text> contained no entries.  Supply at least one version.

=item C<Invalid version '%s' for --versions> (croak)

An entry contains characters outside C<[A-Za-z0-9_.+*-]>.

=back

=head3 API SPECIFICATION

=head4 Input

    { text => { type => 'scalar', required => 1, min => 1 } }

=head4 Output

    { type => 'arrayref', min => 1, element_type => 'scalar' }

=head3 FORMAL SPECIFICATION

    VersionToken ≔ { s : seq CHAR | s ≠ ⟨⟩ ∧ ran s ⊆ [A-Za-z0-9_.+*-] }

    parse_version_list : TEXT ⇸ seq VersionToken

    items ≔ nodup(split(',', text) ∖ {⟨⟩})
    items ≠ ⟨⟩ ∧ items ⊆ VersionToken  ⊢  parse_version_list(text) = items

=cut

sub parse_version_list($text) {
	my $versions = _split_unique($text);

	# An empty list would silently fall back to the default matrix
	croak _message('no_versions') unless @{$versions};

	return _validate_versions($versions);
}

=head2 parse_os_list($text)

Turn a comma-separated C<--os> string into a list of GitHub runner labels.

=head3 Purpose

Let users write C<linux,macos> instead of C<ubuntu-latest,macos-latest>,
while still accepting a literal label such as C<ubuntu-22.04>.

=head3 Arguments

=over 4

=item C<$text> (Str, required)

Comma-separated names, case-insensitive: C<linux>, C<ubuntu>, C<macos>,
C<windows>, or a literal label matching C<(ubuntu|macos|windows)-...>.

=back

=head3 Returns

An array reference of runner labels, in the order given, without duplicates.

=head3 Side Effects

None.

=head3 Usage

    my $os = parse_os_list('linux,macos');   # no Windows jobs
    my $yaml = generate_custom_perl_workflow({ os => $os });

=head3 EXAMPLE

    parse_os_list('Linux, macOS');      # ['ubuntu-latest', 'macos-latest']
    parse_os_list('ubuntu,linux');      # ['ubuntu-latest']
    parse_os_list('ubuntu-22.04');      # ['ubuntu-22.04']
    parse_os_list('bsd');               # croaks: unknown OS

=head3 MESSAGES

=over 4

=item C<Unknown OS '%s' for --os (use linux, macos, windows)> (croak)

The name is neither a known short name nor a literal runner label.

=item C<--os requires at least one operating system> (croak)

C<$text> contained no entries.

=back

=head3 API SPECIFICATION

=head4 Input

    { text => { type => 'scalar', required => 1, min => 1 } }

=head4 Output

    { type => 'arrayref', min => 1, element_type => 'scalar' }

=head3 FORMAL SPECIFICATION

    Label ≔ { ubuntu-latest, macos-latest, windows-latest } ∪ LiteralLabel

    parse_os_list : TEXT ⇸ seq Label

    names ≔ split(',', lc text) ∖ {⟨⟩}
    labels ≔ nodup(runner ∘ names)       (runner is partial; undefined → croak)
    labels ≠ ⟨⟩  ⊢  parse_os_list(text) = labels

=cut

sub parse_os_list($text) {
	# Lower-case first so "Linux" and "LINUX" are accepted
	my @labels = uniq map { _runner_label($_) } @{ _split_unique(lc($text)) };

	croak _message('no_os') unless @labels;

	return \@labels;
}

# Purpose:      Split a comma-separated option value into trimmed, non-empty,
#               de-duplicated entries (first occurrence wins).
# Entry:        $text is a defined string.
# Exit status: Returns an array reference, possibly empty.
# Side effects: None.
sub _split_unique($text) {
	my @entries = grep { length } map { s/\A\s+|\s+\z//gr } split /,/, $text;

	return [ uniq @entries ];
}

# Purpose:      Map one --os name to a GitHub runner label.
# Entry:        $name is a trimmed, lower-case string.
# Exit status: Returns the label; croaks with 'unknown_os' otherwise.
# Side effects: None.
sub _runner_label($name) {
	my $label = $RUNNER_LABEL_FOR{$name}
		// ($name =~ $RUNNER_LABEL_PATTERN ? $name : undef);

	croak _message('unknown_os', $name) unless defined $label;

	return $label;
}

# Purpose:      Reject any version that could break out of a YAML scalar.
# Entry:        $versions is an array reference of strings.
# Exit status: Returns $versions unchanged; croaks with 'invalid_version'.
# Side effects: None.
sub _validate_versions($versions) {
	for my $version (@{$versions}) {
		croak _message('invalid_version', $version // 'undef')
			unless defined $version && $version =~ $VERSION_PATTERN;
	}

	return $versions;
}

# Purpose:      Format a message from %MESSAGES with sprintf interpolation.
# Entry:        $key is a key of %MESSAGES; @args fill its placeholders.
# Exit status: Returns the formatted string; an unknown key yields the
#               'unknown_message' text instead, so a typo cannot hide an error.
# Side effects: None.
sub _message($key, @args) {
	my $format = $MESSAGES{$key};

	return defined $format
		? sprintf($format, @args)
		: sprintf($MESSAGES{unknown_message}, $key);
}

# Purpose:      Render version entries as a YAML list at the given indent.
# Entry:        $indent is the dash column as spaces; $versions is an arrayref.
# Exit status: Returns the YAML text; every entry is single-quoted so that
#               3.10 stays a string and is not read as the number 3.1.
# Side effects: None.
sub _matrix_items($indent, $versions) {
	return join '', map { "$indent- '$_'\n" } @{$versions};
}

# Purpose:      Rewrite the version matrix of a generated workflow.
# Entry:        $type is a known generator type; $yaml is that type's template;
#               $versions has been validated.
# Exit status: Returns the rewritten YAML; types without a matrix (cpp,
#               docker, static) come back unchanged.
# Side effects: None.
sub _apply_versions($type, $yaml, $versions) {
	if (my $key = $MATRIX_KEY_FOR{$type}) {
		# Replace the existing list under "<key>:" keeping its indentation
		$yaml =~ s{^( +)\Q$key\E:\n(?: +- .*\n)+}{
			"$1$key:\n" . _matrix_items("$1  ", $versions)
		}me;
	} elsif ($type eq 'go') {
		$yaml =~ s{$GO_PINNED_VERSION}{go-version: \${{ matrix.go-version }}};
		$yaml = _insert_matrix($yaml, 'go-version', $versions);
	} elsif ($type eq 'rust') {
		# dtolnay/rust-toolchain reads the toolchain from "with:" when the
		# ref is not a version, so point it at the matrix value
		$yaml =~ s{$RUST_TOOLCHAIN_STEP}{$1        with:\n          toolchain: \${{ matrix.rust-version }}\n};
		$yaml = _insert_matrix($yaml, 'rust-version', $versions);
	}

	return $yaml;
}

# Purpose:      Add a one-key strategy matrix to the (single) ubuntu job.
# Entry:        $yaml has exactly one "    runs-on: ubuntu-latest" line.
# Exit status: Returns the YAML with the matrix inserted after that line.
# Side effects: None.
sub _insert_matrix($yaml, $key, $versions) {
	my $block = "    strategy:\n      matrix:\n        $key:\n"
		. _matrix_items('          ', $versions);

	$yaml =~ s{^(    runs-on: ubuntu-latest\n)}{$1$block}m;

	return $yaml;
}

=head2 list_workflow_types()

Return a flat hash of all supported workflow types and their descriptions.

=head3 Purpose

Enumerate every type that C<generate_workflow> can handle, with a one-line
human-readable description for each.

=head3 Arguments

None.

=head3 Returns

A flat hash (not a reference) mapping type strings to description strings.
Contains exactly eleven entries: C<perl>, C<node>, C<python>, C<rust>,
C<go>, C<ruby>, C<java>, C<cpp>, C<php>, C<docker>, C<static>.

=head3 Side Effects

None.  Pure function.

=head3 Usage Example

    my %types = list_workflow_types();
    say "$_: $types{$_}" for sort keys %types;

=head3 API SPECIFICATION

=head4 Input

    # No parameters.

=head4 Output

    { type => 'hashref', keys => { '*' => { type => 'scalar' } } }

=head3 FORMAL SPECIFICATION

    list_workflow_types : → ℤ* → ℤ*

    result ≔ { t ↦ desc(t) ∣ t ∈ SupportedTypes }
    |result| = 11

=cut

sub list_workflow_types() {
	return (
		node   => 'Node.js/npm projects with testing and linting',
		python => 'Python projects with pytest and coverage',
		rust   => 'Rust projects with cargo, clippy, and formatting',
		go     => 'Go projects with testing and race detection',
		ruby   => 'Ruby projects with bundler and rake',
		perl   => 'Perl projects with cpanm, prove, and coverage',
		java   => 'Java projects with Maven or Gradle',
		cpp    => 'C++ projects with CMake',
		php    => 'PHP projects with Composer and PHPUnit',
		docker => 'Docker image build and push workflow',
		static => 'Static site deployment to GitHub Pages',
	);
}

# Private workflow generators

sub _generate_perl_workflow() {
	# Try to detect requirements from project
	my $reqs = detect_perl_requirements();

	# Use detected min version or default to 5.36
	my $min_version = $reqs->{min_version} // '5.36';

	# Generate custom workflow with detected settings
	return generate_custom_perl_workflow({
		min_perl_version => $min_version,
		max_perl_version => '5.40',
		os => ['macos-latest', 'ubuntu-latest', 'windows-latest'],
		enable_critic => 1,
		enable_coverage => 1,
	});
}

sub _generate_node_workflow() {
	return <<'YAML';
---
name: Node.js CI

'on':
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version:
          - 18.x
          - 20.x
          - 22.x
    steps:
      - name: Checkout code
        uses: actions/checkout@76

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Cache dependencies
        uses: actions/cache@v6
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint --if-present

      - name: Run tests
        run: npm test

      - name: Build project
        run: npm run build --if-present
YAML
}

sub _generate_python_workflow() {
	return <<'YAML';
---
name: Python CI

'on':
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version:
          - '3.9'
          - '3.10'
          - '3.11'
          - '3.12'
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache pip packages
        uses: actions/cache@v6
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov flake8

      - name: Lint with flake8
        run: flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

      - name: Run tests with coverage
        run: pytest --cov=. --cov-report=xml
YAML
}

sub _generate_rust_workflow() {
	return <<'YAML';
---
name: Rust CI

'on':
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Cache cargo
        uses: actions/cache@v6
        with:
          path: |
            ~/.cargo/bin/
            ~/.cargo/registry/index/
            ~/.cargo/registry/cache/
            ~/.cargo/git/db/
            target/
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}

      - name: Check formatting
        run: cargo fmt -- --check

      - name: Run clippy
        run: cargo clippy -- -D warnings

      - name: Run tests
        run: cargo test --verbose

      - name: Build release
        run: cargo build --release --verbose
YAML
}

sub _generate_go_workflow() {
	return <<'YAML';
---
name: Go CI

'on':
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Cache Go modules
        uses: actions/cache@v6
        with:
          path: ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-

      - name: Download dependencies
        run: go mod download

      - name: Run go vet
        run: go vet ./...

      - name: Run tests
        run: go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

      - name: Build
        run: go build -v ./...
YAML
}

sub _generate_ruby_workflow() {
	return <<'YAML';
---
name: Ruby CI

'on':
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby-version:
          - '3.1'
          - '3.2'
          - '3.3'
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true

      - name: Run tests
        run: bundle exec rake test
YAML
}

sub _generate_docker_workflow() {
	return <<'YAML';
---
name: Docker Build

'on':
  push:
    branches:
      - main
    tags:
      - v*
  pull_request:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
        if: github.event_name != 'pull_request'

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: your-username/your-image

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
YAML
}

sub _generate_static_workflow() {
	return <<'YAML';
---
name: Deploy Static Site

'on':
  push:
    branches:
      - main

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Build
        run: echo "Add your build command here"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
YAML
}

sub _generate_java_workflow() {
	return <<'YAML';
---
name: Java CI

'on':
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        java-version:
          - '11'
          - '17'
          - '21'
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Set up JDK ${{ matrix.java-version }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java-version }}
          distribution: 'temurin'

      - name: Cache Maven packages
        uses: actions/cache@v6
        with:
          path: ~/.m2/repository
          key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
          restore-keys: |
            ${{ runner.os }}-maven-

      - name: Build with Maven
        run: mvn -B package --file pom.xml

      - name: Run tests
        run: mvn -B test

      - name: Generate test report
        if: always()
        run: mvn surefire-report:report
YAML
}

sub _generate_cpp_workflow() {
	return <<'YAML';
---
name: C++ CI

'on':
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os:
          - ubuntu-latest
          - macos-latest
          - windows-latest
        build-type:
          - Debug
          - Release
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Install CMake
        uses: lukka/get-cmake@latest

      - name: Cache build artifacts
        uses: actions/cache@v6
        with:
          path: |
            build
            ~/.cache/ccache
          key: ${{ runner.os }}-${{ matrix.build-type }}-${{ hashFiles('**/CMakeLists.txt') }}

      - name: Configure CMake
        run: cmake -B build -DCMAKE_BUILD_TYPE=${{ matrix.build-type }}

      - name: Build
        run: cmake --build build --config ${{ matrix.build-type }}

      - name: Run tests
        working-directory: build
        run: ctest -C ${{ matrix.build-type }} --output-on-failure
YAML
}

sub _generate_php_workflow() {
	return <<'YAML';
---
name: PHP CI

'on':
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php-version:
          - '8.1'
          - '8.2'
          - '8.3'
    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Setup PHP ${{ matrix.php-version }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          extensions: mbstring, xml, ctype, json
          coverage: xdebug

      - name: Validate composer.json
        run: composer validate --strict

      - name: Cache Composer packages
        uses: actions/cache@v6
        with:
          path: vendor
          key: ${{ runner.os }}-php-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            ${{ runner.os }}-php-

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run PHPUnit tests
        run: vendor/bin/phpunit --coverage-text

      - name: Run PHP CodeSniffer
        run: vendor/bin/phpcs --standard=PSR12 src tests
        continue-on-error: true
YAML
}

=head1 LIMITATIONS

=over 4

=item * Workflows are text templates, not data

Every generator except C<perl> is a heredoc, and C<--versions> works by
regex-rewriting that text.  It is tied to the exact layout of each template
(indentation, the C<ubuntu-latest> job line, the pinned Go and Rust lines)
and a template edit can silently stop it matching.  Building each workflow as
a Perl data structure and serialising it with L<YAML::XS> would remove the
whole class of problem; that is a rewrite of every generator, so it is not
done here.  The tests in F<t/versions_option.t> parse the output as YAML to
catch a broken rewrite.

=item * Default versions are fixed in the templates

The defaults are not validated against what the setup actions support today,
and some are end of life (node 18, python 3.9, ruby 3.1).  They are kept so
existing output does not change.

=item * One version list per run

C<--versions> applies to the single generated type.  There is no way to give
different lists to different jobs in one workflow.

=item * Messages are sprintf formats only

C<%MESSAGES> can be reworded or translated by replacing its values, but there
is no plural or grammatical-gender handling, and the table is a package
global rather than per-object configuration.  The messages here take only
strings, so none is needed yet.

=item * Version tokens are checked for safety, not meaning

C<9.9.9> is accepted for any language.  Whether the setup action can install
it is only discovered when the workflow runs.

=item * Perl ignores project detection when versions are given

C<generate_workflow('perl', { versions => ... })> uses exactly the list given;
the minimum Perl detected from F<cpanfile> or F<Makefile.PL> is not applied.

=back

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 COPYRIGHT AND LICENSE

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
