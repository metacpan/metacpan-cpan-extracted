package App::GHGen::Generator;

use v5.36;
use strict;
use warnings;
use Path::Tiny;
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);

use Exporter 'import';
our @EXPORT_OK = qw(
	generate_workflow
	list_workflow_types
	get_workflow_description
);

our $VERSION = '0.01';

=head1 NAME

App::GHGen::Generator - Generate GitHub Actions workflows

=head1 SYNOPSIS

    use App::GHGen::Generator qw(generate_workflow);

    my $yaml = generate_workflow('perl');
    path('.github/workflows/ci.yml')->spew_utf8($yaml);

=head1 FUNCTIONS

=head2 generate_workflow($type)

Generate a workflow for the specified type. Returns YAML as a string.

=cut

sub generate_workflow($type) {
    my %generators = (
        perl   => \&_generate_perl_workflow,
        node   => \&_generate_node_workflow,
        python => \&_generate_python_workflow,
        rust   => \&_generate_rust_workflow,
        go     => \&_generate_go_workflow,
        ruby   => \&_generate_ruby_workflow,
        php    => \&_generate_php_workflow,
        java   => \&_generate_java_workflow,
        cpp    => \&_generate_cpp_workflow,
        docker => \&_generate_docker_workflow,
        static => \&_generate_static_workflow,
    );

	return undef unless exists $generators{$type};
	return $generators{$type}->();
}

=head2 list_workflow_types()

Returns a hash of available workflow types and their descriptions.

=cut

sub list_workflow_types() {
    return (
        node   => 'Node.js/npm projects with testing and linting',
        python => 'Python projects with pytest and coverage',
        rust   => 'Rust projects with cargo, clippy, and formatting',
        go     => 'Go projects with testing and race detection',
        ruby   => 'Ruby projects with bundler and rake',
        perl   => 'Perl projects with cpanm, prove, and coverage',
        php    => 'PHP projects with Composer and PHPUnit',
        java   => 'Java projects with Maven or Gradle',
        cpp    => 'C/C++ projects with CMake and testing',
        docker => 'Docker image build and push workflow',
        static => 'Static site deployment to GitHub Pages',
    );
}

=head2 get_workflow_description($type)

Get the description for a specific workflow type.

=cut

sub get_workflow_description($type) {
    my %types = list_workflow_types();
    return $types{$type};
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
        uses: actions/checkout@v6

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Cache dependencies
        uses: actions/cache@v5
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
        uses: actions/checkout@v6

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache pip packages
        uses: actions/cache@v5
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
        uses: actions/checkout@v6

      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Cache cargo
        uses: actions/cache@v5
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
        uses: actions/checkout@v6

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Cache Go modules
        uses: actions/cache@v5
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
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true

      - name: Run tests
        run: bundle exec rake test
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
      - master
  pull_request:
    branches:
      - main
      - master

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
        uses: actions/checkout@v6

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          extensions: mbstring, xml, ctype, json
          coverage: xdebug
          tools: composer:v2

      - name: Validate composer.json
        run: composer validate --strict

      - name: Cache Composer packages
        uses: actions/cache@v5
        with:
          path: vendor
          key: ${{ runner.os }}-php-${{ matrix.php-version }}-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            ${{ runner.os }}-php-${{ matrix.php-version }}-

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run PHPStan
        run: composer exec phpstan analyse || true
        continue-on-error: true

      - name: Run tests
        run: composer exec phpunit

      - name: Run tests with coverage
        if: matrix.php-version == '8.3'
        run: composer exec phpunit -- --coverage-clover=coverage.xml
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
      - master
  pull_request:
    branches:
      - main
      - master

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
        uses: actions/checkout@v6

      - name: Set up JDK ${{ matrix.java-version }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java-version }}
          distribution: 'temurin'
          cache: 'maven'

      - name: Build with Maven
        run: mvn -B clean verify

      - name: Run tests
        run: mvn -B test

      - name: Generate coverage report
        if: matrix.java-version == '21'
        run: mvn -B jacoco:report
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
      - master
  pull_request:
    branches:
      - main
      - master

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
        uses: actions/checkout@v6

      - name: Install dependencies (Ubuntu)
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y cmake ninja-build

      - name: Install dependencies (macOS)
        if: runner.os == 'macOS'
        run: |
          brew install cmake ninja

      - name: Install dependencies (Windows)
        if: runner.os == 'Windows'
        run: |
          choco install cmake ninja

      - name: Configure CMake
        run: cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=${{ matrix.build-type }}

      - name: Build
        run: cmake --build build --config ${{ matrix.build-type }}

      - name: Run tests
        run: ctest --test-dir build -C ${{ matrix.build-type }} --output-on-failure
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
        uses: actions/checkout@v6

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
        uses: actions/checkout@v6

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

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
