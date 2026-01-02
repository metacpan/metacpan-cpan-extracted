package App::GHGen;

use v5.36;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

App::GHGen - Comprehensive GitHub Actions workflow generator, analyzer, and optimizer

=head1 SYNOPSIS

    # Generate workflows
    ghgen generate --auto                    # Auto-detect project type
    ghgen generate --type=perl              # Generate Perl workflow
    ghgen generate --type=perl --customize  # Interactive customization
    ghgen generate --interactive            # Choose type interactively

    # Analyze workflows
    ghgen analyze                           # Analyze for issues
    ghgen analyze --fix                     # Auto-fix issues
    ghgen analyze --estimate                # Show cost estimates

    # List available types
    ghgen generate --list

=head1 DESCRIPTION

App::GHGen is a comprehensive toolkit for creating, analyzing, and optimizing GitHub Actions workflows.
It combines intelligent project detection, workflow generation, security analysis, cost optimization,
and automatic fixing into a single powerful tool.

=head2 Key Features

=encoding utf-8

=over 4

=item * B<🤖 Auto-detect project type> - Intelligently scans your repository to detect language and dependencies

=item * B<🚀 Generate optimized workflows> - Creates workflows with caching, security, concurrency, and best practices built-in

=item * B<🔍 Analyze existing workflows> - Comprehensive analysis for performance, security, cost, and maintenance issues

=item * B<🔧 Auto-fix issues> - Automatically applies fixes for detected problems (adds caching, updates versions, adds permissions, etc.)

=item * B<🎯 Interactive customization> - Guided workflow creation with smart defaults and multi-select options

=item * B<💰 Cost estimation> - Estimates current CI minutes usage and calculates potential savings from optimizations

=item * B<🔄 GitHub Action integration> - Run as a GitHub Action to analyze PRs, comment with suggestions, and create fix PRs

=item * B<📊 Per-workflow breakdown> - Detailed analysis of each workflow's cost and optimization potential

=back

=head1 INSTALLATION

=head2 From CPAN (when published)

    cpanm App::GHGen

=head2 From Source

    git clone https://github.com/nigelhorne/ghgen.git
    cd ghgen
    cpanm --installdeps .
    perl Makefile.PL
    make
    make test
    make install

=head2 Quick Install Script

    curl -L https://cpanmin.us | perl - App::GHGen

=head1 QUICK START

The fastest way to get started:

    # Navigate to your project
    cd my-project/

    # Auto-detect and generate workflow
    ghgen generate --auto

    # Review the generated workflow
    cat .github/workflows/*-ci.yml

    # Commit and push
    git add .github/workflows/
    git commit -m "Add CI workflow"
    git push

That's it! GHGen will detect your project type and create an optimized workflow.

=head1 WORKFLOW GENERATION

=head2 Auto-Detection

GHGen can automatically detect your project type by scanning for indicator files:

    ghgen generate --auto

Detection looks for:

=over 4

=item * B<Perl>: cpanfile, dist.ini, Makefile.PL, Build.PL, lib/*.pm

=item * B<Node.js>: package.json, package-lock.json, yarn.lock

=item * B<Python>: requirements.txt, setup.py, pyproject.toml

=item * B<Rust>: Cargo.toml, Cargo.lock

=item * B<Go>: go.mod, go.sum

=item * B<Ruby>: Gemfile, Rakefile

=item * B<Docker>: Dockerfile, docker-compose.yml

=back

If multiple types are detected, it shows alternatives:

    ✓ Detected project type: PERL
      Evidence: cpanfile, lib, t

    Other possibilities:
      • docker (confidence: 65%)

    Generate PERL workflow? [Y/n]:

=head2 Specify Project Type

Generate for a specific language:

    ghgen generate --type=perl
    ghgen generate --type=node
    ghgen generate --type=python
    ghgen generate --type=rust
    ghgen generate --type=go
    ghgen generate --type=ruby
    ghgen generate --type=docker
    ghgen generate --type=static

=head2 Interactive Mode

Choose from a menu of available types:

    ghgen generate --interactive

    GitHub Actions Workflow Generator
    ==================================================

    Select a project type:

      1. Node.js/npm
      2. Python
      3. Rust
      4. Go
      5. Ruby
      6. Perl
      7. Docker
      8. Static site (GitHub Pages)

    Enter number (1-8):

=head2 Interactive Customization

Customize workflows with guided prompts:

    ghgen generate --type=perl --customize

For Perl, you'll be asked:

=over 4

=item * B<Perl versions to test> - Select from 5.22 through 5.40 (multi-select with defaults)

=item * B<Operating systems> - Ubuntu, macOS, Windows (multi-select)

=item * B<Enable Perl::Critic> - Code quality analysis (yes/no)

=item * B<Enable Devel::Cover> - Test coverage (yes/no)

=item * B<Branch configuration> - Which branches to run on

=back

Example session:

    === Workflow Customization: PERL ===

    Perl Versions to Test:
    Which Perl versions?
    (Enter numbers separated by commas, or 'all')
      ✓ 1. 5.40
      ✓ 2. 5.38
      ✓ 3. 5.36
        4. 5.34
        5. 5.32

    Enter choices [1,2,3]: 1,2,3

    Operating Systems:
    Which operating systems?
      ✓ 1. ubuntu-latest
      ✓ 2. macos-latest
      ✓ 3. windows-latest

    Enter choices [1,2,3]: 1,2

    Enable Perl::Critic? [Y/n]: y
    Enable test coverage? [Y/n]: y

Each language has its own customization options appropriate to its ecosystem.

=head2 List Available Types

See all supported project types:

    ghgen generate --list

    Available workflow templates:

      node       - Node.js/npm projects with testing and linting
      python     - Python projects with pytest and coverage
      rust       - Rust projects with cargo, clippy, and formatting
      go         - Go projects with testing and race detection
      ruby       - Ruby projects with bundler and rake
      perl       - Perl projects with cpanm, prove, and coverage
      docker     - Docker image build and push workflow
      static     - Static site deployment to GitHub Pages

=head1 WORKFLOW ANALYSIS

=head2 Basic Analysis

Scan all workflows in your repository for issues:

    ghgen analyze

    GitHub Actions Workflow Analyzer
    ==================================================

    📄 Analyzing: perl-ci.yml
      ⚠ No dependency caching found - increases build times
         💡 Fix:
         - uses: actions/cache@v5
           with:
             path: ~/perl5
             key: ${{ runner.os }}-${{ matrix.perl }}-${{ hashFiles('cpanfile') }}

      ⚠ Found 2 outdated action(s)
         💡 Fix:
         Update to latest versions:
           actions/cache@v4 → actions/cache@v5

    ==================================================
    Summary:
      Workflows analyzed: 1
      Total issues found: 2

The analyzer checks for:

=over 4

=item * B<Performance Issues>

=over 8

=item - Missing dependency caching (npm, pip, cargo, go, bundler, cpanm)

=item - Jobs that could run in parallel

=back

=item * B<Security Issues>

=over 8

=item - Unpinned action versions (@master, @main)

=item - Missing permissions declarations

=item - Overly broad permissions (contents: write when read is sufficient)

=back

=item * B<Cost Issues>

=over 8

=item - Missing concurrency controls (wasted CI on superseded runs)

=item - Overly broad triggers (runs on every push without filters)

=item - Inefficient matrix strategies

=back

=item * B<Maintenance Issues>

=over 8

=item - Outdated action versions (v4 → v5, v5 → v6)

=item - Outdated runner versions (ubuntu-18.04 → ubuntu-latest)

=back

=back

=head2 Auto-Fix

Automatically apply fixes to your workflows:

    ghgen analyze --fix

    GitHub Actions Workflow Analyzer
    (Auto-fix mode enabled)
    ==================================================

    📄 Analyzing: perl-ci.yml
      ⚙ Applying 3 fix(es)...
      ✓ Applied 3 fix(es)

    ==================================================
    Summary:
      Workflows analyzed: 1
      Total issues found: 3
      Fixes applied: 3

Auto-fix can:

=over 4

=item * B<Add caching> - Detects project type and adds appropriate dependency caching

=item * B<Update actions> - Updates to latest versions (cache@v4→v5, checkout@v5→v6, etc.)

=item * B<Pin versions> - Converts @master/@main to specific version tags

=item * B<Add permissions> - Adds C<permissions: contents: read> for security

=item * B<Add concurrency> - Adds concurrency groups to cancel superseded runs

=item * B<Optimize triggers> - Adds branch and path filters

=item * B<Update runners> - Changes ubuntu-18.04 to ubuntu-latest

=back

The auto-fix feature is safe:

=over 4

=item * Only fixes well-understood issues

=item * Preserves YAML structure and comments

=item * Changes are easily reviewable with C<git diff>

=item * Can be reverted if needed

=back

=head2 Cost Estimation

See your current CI usage and potential savings:

    ghgen analyze --estimate

    GitHub Actions Workflow Analyzer
    (Cost estimation mode)
    ==================================================

    📊 Estimating current CI usage...

    Current Monthly Usage:
      Total CI minutes: 1,247
      Billable minutes: 0 (after 2,000 free tier)
      Estimated cost: $0.00

    Per-Workflow Breakdown:
      Perl CI      840 min/month (100 runs × 8.4 min/run)
      Node.js CI   300 min/month ( 60 runs × 5.0 min/run)
      Docker       107 min/month ( 20 runs × 5.4 min/run)

    📄 Analyzing: node-ci.yml
      ⚠ No dependency caching found
      ⚠ No concurrency group defined

    ==================================================
    Summary:
      Workflows analyzed: 3
      Total issues found: 2

    💰 Potential Savings:
      With recommended changes: 647 CI minutes/month
      Reduction: -600 minutes (48%)
      Cost savings: $4.80/month (for private repos)

      Breakdown:
        • Adding dependency caching: ~75 min/month
        • Adding concurrency controls: ~525 min/month

The cost estimator considers:

=over 4

=item * Workflow trigger frequency (push, PR, schedule)

=item * Estimated duration per run (based on steps and commands)

=item * Matrix build multipliers (e.g., 3 OS × 8 Perl versions = 24 jobs)

=item * Parallel vs sequential job execution

=item * GitHub Actions pricing ($0.008/minute for private repos, 2000 free minutes/month)

=back

=head1 GITHUB ACTION INTEGRATION

Use GHGen as a GitHub Action to analyze workflows automatically.

=head2 Mode 1: Comment on Pull Requests

Automatically comment on PRs that modify workflows:

    # .github/workflows/ghgen-comment.yml
    name: Analyze Workflows

    on:
      pull_request:
        paths:
          - '.github/workflows/**'

    permissions:
      contents: read
      pull-requests: write

    jobs:
      analyze:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v6
          - uses: nigelhorne/ghgen-action@v1
            with:
              github-token: ${{ secrets.GITHUB_TOKEN }}
              mode: comment

This posts a comment like:

    ## 🔍 GHGen Workflow Analysis

    | Category | Count | Auto-fixable |
    |----------|-------|--------------|
    | ⚡ Performance | 2 | 2 |
    | 🔒 Security | 1 | 1 |

    ### 💰 Potential Savings
    - ⏱️ Save **~650 CI minutes/month**
    - 💵 Save **~$5/month** (private repos)

    ### 💡 How to Fix
    Run locally: `ghgen analyze --fix`

=head2 Mode 2: Auto-Fix with Pull Request

Automatically create PRs with fixes on a schedule:

    # .github/workflows/ghgen-autofix.yml
    name: Weekly Workflow Optimization

    on:
      schedule:
        - cron: '0 9 * * 1'  # Monday 9am UTC
      workflow_dispatch:     # Manual trigger

    permissions:
      contents: write
      pull-requests: write

    jobs:
      optimize:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v6
          - uses: nigelhorne/ghgen-action@v1
            with:
              github-token: ${{ secrets.GITHUB_TOKEN }}
              auto-fix: true
              create-pr: true

This creates a PR titled "🤖 Optimize GitHub Actions workflows" with all fixes applied.

=head2 Mode 3: CI Quality Gate

Fail builds if workflow issues are found:

    # .github/workflows/ghgen-check.yml
    name: Workflow Quality Check

    on:
      pull_request:
        paths:
          - '.github/workflows/**'

    permissions:
      contents: read

    jobs:
      check:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v6
          - uses: nigelhorne/ghgen-action@v1
            id: check
          - name: Fail if issues found
            if: steps.check.outputs.issues-found > 0
            run: |
              echo "Found ${{ steps.check.outputs.issues-found }} issues"
              exit 1

=head1 SUPPORTED LANGUAGES

=head2 Perl

Comprehensive Perl testing with modern best practices.

B<Features:>

=over 4

=item * Multi-OS testing (Ubuntu, macOS, Windows)

=item * Multiple Perl versions (5.22 through 5.40, customizable)

=item * Smart version detection from cpanfile, Makefile.PL, dist.ini

=item * CPAN module caching with local::lib

=item * Perl::Critic integration for code quality

=item * Devel::Cover for test coverage

=item * Proper environment variables (AUTOMATED_TESTING, NO_NETWORK_TESTING, NONINTERACTIVE_TESTING)

=item * Cross-platform compatibility (bash for Unix, cmd for Windows)

=back

B<Example:>

    ghgen generate --type=perl --customize

B<Generated workflow includes:>

=over 4

=item * actions/checkout@v6

=item * actions/cache@v5 for CPAN modules

=item * shogo82148/actions-setup-perl@v1

=item * Matrix testing across OS and Perl versions

=item * Conditional Perl::Critic (latest Perl + Ubuntu only)

=item * Conditional coverage (latest Perl + Ubuntu only)

=item * Security permissions

=item * Concurrency controls

=back

=head2 Node.js

Modern Node.js workflows with npm/yarn/pnpm support.

B<Features:>

=over 4

=item * Multiple Node.js versions (18.x, 20.x, 22.x)

=item * Package manager selection (npm, yarn, pnpm)

=item * Dependency caching (~/.npm, ~/.yarn, ~/.pnpm)

=item * Optional linting (ESLint)

=item * Optional build step

=item * Lock file hash-based cache keys

=back

B<Customization options:>

=over 4

=item * Node.js versions to test

=item * Package manager preference

=item * Enable/disable linting

=item * Enable/disable build step

=back

=head2 Python

Python testing with virtual environment support.

B<Features:>

=over 4

=item * Multiple Python versions (3.9, 3.10, 3.11, 3.12, 3.13)

=item * pip caching (~/.cache/pip)

=item * flake8 linting

=item * pytest with coverage

=item * Optional black formatter checking

=item * requirements.txt hash-based cache

=back

=head2 Rust

Rust workflows with cargo, clippy, and formatting.

B<Features:>

=over 4

=item * Cargo registry and target caching

=item * cargo fmt formatting check

=item * Clippy linting with -D warnings

=item * Comprehensive test suite

=item * Optional release builds

=item * Cargo.lock hash-based cache

=back

=head2 Go

Go testing with modules and race detection.

B<Features:>

=over 4

=item * Configurable Go version

=item * Go modules caching (~/go/pkg/mod)

=item * go vet for static analysis

=item * Race detector (-race flag)

=item * Test coverage with atomic mode

=item * go.sum hash-based cache

=back

=head2 Ruby

Ruby testing with Bundler integration.

B<Features:>

=over 4

=item * Multiple Ruby versions (3.1, 3.2, 3.3)

=item * Automatic Bundler caching (built into setup-ruby)

=item * Gemfile.lock hash-based cache

=item * Rake integration

=back

=head2 Docker

Docker image building and publishing.

B<Features:>

=over 4

=item * Docker Buildx for multi-platform builds

=item * GitHub Container Registry (GHCR) support

=item * Docker Hub support

=item * Automatic tag extraction from git

=item * Layer caching with GitHub Actions cache

=item * Only pushes on non-PR events

=back

=head2 Static Sites

Static site deployment to GitHub Pages.

B<Features:>

=over 4

=item * GitHub Pages deployment

=item * Configurable build command

=item * Configurable build directory

=item * Artifact upload

=item * Proper Pages permissions

=item * Separate build and deploy jobs

=back

=head1 CONFIGURATION DETECTION

GHGen automatically detects configuration and adjusts workflows accordingly.

=head2 Minimum Version Detection

For Perl, minimum version is detected from:

=over 4

=item * cpanfile: C<requires 'perl', '5.036'>

=item * Makefile.PL: C<MIN_PERL_VERSION =E<gt> '5.036'>

=item * dist.ini: C<perl = 5.036>

=back

Only compatible Perl versions are tested (e.g., if min is 5.36, won't test 5.32 or 5.34).

=head2 Dependency Files

Caching is based on dependency files:

=over 4

=item * Perl: cpanfile, dist.ini, Makefile.PL, Build.PL

=item * Node: package-lock.json, yarn.lock, pnpm-lock.yaml

=item * Python: requirements.txt, Pipfile.lock

=item * Rust: Cargo.lock

=item * Go: go.sum

=item * Ruby: Gemfile.lock

=back

=head1 BEST PRACTICES

=head2 Workflow Generation

=over 4

=item * B<Use --auto for quick start> - Let GHGen detect your project

=item * B<Use --customize for fine control> - Customize versions, OS, and features

=item * B<Review before committing> - Always review generated workflows

=item * B<Test locally first> - Use tools like C<act> to test locally

=item * B<Start with defaults> - Customize only when needed

=back

=head2 Workflow Analysis

=over 4

=item * B<Run analyze regularly> - Weekly C<ghgen analyze> catches issues early

=item * B<Use --estimate> - Monitor CI costs over time

=item * B<Enable in CI> - Catch issues in PRs automatically

=item * B<Review auto-fixes> - Always review changes before committing

=item * B<Fix incrementally> - Don't fix everything at once if unsure

=back

=head2 Cost Optimization

=over 4

=item * B<Add caching> - Biggest time/cost savings

=item * B<Add concurrency> - Cancel superseded runs

=item * B<Filter triggers> - Only run on relevant changes

=item * B<Optimize matrix> - Don't test unnecessary combinations

=item * B<Run coverage once> - Only on one OS/version combination

=back

=head1 EXAMPLES

=head2 Example 1: New Perl Module

    # In your new Perl module directory
    cd My-Module/

    # Create cpanfile
    echo "requires 'perl', '5.036';" > cpanfile

    # Auto-detect and generate
    ghgen generate --auto

    # Review and commit
    cat .github/workflows/perl-ci.yml
    git add .github/workflows/perl-ci.yml cpanfile
    git commit -m "Add CI workflow"
    git push

=head2 Example 2: Optimize Existing Project

    # Clone project
    git clone https://github.com/user/project.git
    cd project/

    # Analyze with cost estimation
    ghgen analyze --estimate

    # Review suggestions, then fix
    ghgen analyze --fix

    # Review changes
    git diff .github/workflows/

    # Commit improvements
    git add .github/workflows/
    git commit -m "Optimize CI: add caching, update actions, add permissions"
    git push

=head2 Example 3: Multi-Language Project

    # Project with both Node.js and Docker
    cd fullstack-app/

    # Generate Node.js workflow
    ghgen generate --type=node --output=.github/workflows/frontend-ci.yml

    # Generate Docker workflow
    ghgen generate --type=docker --output=.github/workflows/backend-build.yml

    # Analyze both
    ghgen analyze

=head2 Example 4: Custom Perl Testing Matrix

    # Interactive customization
    ghgen generate --type=perl --customize

    # Choose:
    # Perl versions: 5.36, 5.38, 5.40 (skip older)
    # OS: Ubuntu, macOS (skip Windows if not needed)
    # Perl::Critic: Yes
    # Coverage: Yes
    # Branches: main

=head2 Example 5: CI Quality Gate

Add workflow quality checks to your CI:

    # .github/workflows/ci-quality.yml
    name: CI Quality Check

    on:
      pull_request:
        paths:
          - '.github/workflows/**'

    jobs:
      check:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v6
          - name: Install GHGen
            run: cpanm --notest App::GHGen
          - name: Check workflows
            run: |
              if ! ghgen analyze; then
                echo "::error::Workflow quality issues found"
                echo "Run 'ghgen analyze --fix' locally to fix"
                exit 1
              fi

=head1 COMMAND REFERENCE

=head2 generate

    ghgen generate [OPTIONS]

Generate a new GitHub Actions workflow.

B<Options:>

=over 4

=item C<--auto, -a>

Auto-detect project type from repository contents.

=item C<--type=TYPE, -t TYPE>

Specify project type: perl, node, python, rust, go, ruby, docker, static.

=item C<--customize, -c>

Enable interactive customization mode.

=item C<--interactive, -i>

Interactively select project type from menu.

=item C<--output=FILE, -o FILE>

Specify output file (default: .github/workflows/TYPE-ci.yml).

=item C<--list, -l>

List all available workflow types with descriptions.

=back

B<Examples:>

    ghgen generate --auto
    ghgen generate --type=perl --customize
    ghgen generate --interactive
    ghgen generate --type=node --output=custom.yml

=head2 analyze

    ghgen analyze [OPTIONS]

Analyze existing workflows for issues and optimization opportunities.

B<Options:>

=over 4

=item C<--fix, -f>

Automatically apply fixes to detected issues.

=item C<--estimate, -e>

Show cost estimates and potential savings.

=back

B<Examples:>

    ghgen analyze
    ghgen analyze --fix
    ghgen analyze --estimate
    ghgen analyze --fix --estimate

=head1 TROUBLESHOOTING

=head2 Installation Issues

B<Problem:> C<cpanm> fails to install dependencies

B<Solution:>

    # Install build tools first
    # On Debian/Ubuntu:
    sudo apt-get install build-essential

    # On macOS:
    xcode-select --install

    # Then retry
    cpanm App::GHGen

=head2 Generation Issues

B<Problem:> "No .github/workflows directory"

B<Solution:>

    mkdir -p .github/workflows
    ghgen generate --auto

B<Problem:> Auto-detect doesn't find my project type

B<Solution:>

    # Specify type explicitly
    ghgen generate --type=perl

    # Or ensure indicator files exist
    touch cpanfile  # for Perl
    touch package.json  # for Node.js

=head2 Analysis Issues

B<Problem:> "Failed to parse YAML"

B<Solution:>

    # Validate YAML syntax first
    yamllint .github/workflows/*.yml

    # Fix YAML errors, then retry
    ghgen analyze

B<Problem:> Cost estimates seem wrong

B<Solution:>

Cost estimates are approximations based on:

=over 4

=item * Typical commit/PR frequency

=item * Average workflow duration

=item * Standard GitHub Actions pricing

=back

Actual costs depend on your specific usage patterns.

=head2 Auto-Fix Issues

B<Problem:> Auto-fix didn't fix everything

B<Solution:>

Some issues can't be auto-fixed:

=over 4

=item * Complex workflow logic

=item * Custom actions

=item * Project-specific configurations

=back

Review the remaining suggestions and apply manually.

=head2 GitHub Action Issues

B<Problem:> "Permission denied" errors

B<Solution:>

    # Ensure correct permissions in workflow
    permissions:
      contents: write        # For auto-fix
      pull-requests: write   # For comments

B<Problem:> Action not triggering

B<Solution:>

    # For scheduled workflows, ensure:
    on:
      schedule:
        - cron: '0 9 * * 1'
      workflow_dispatch:  # Allows manual trigger

    # Test with manual trigger first

=head1 DEPENDENCIES

=head2 Runtime Dependencies

=over 4

=item * Perl 5.36 or higher

=item * L<YAML::XS> - Fast YAML parsing and generation

=item * L<Path::Tiny> - File and directory operations

=item * L<Term::ANSIColor> - Colored terminal output

=item * L<Getopt::Long> - Command-line option parsing

=back

=head2 Test Dependencies

=over 4

=item * L<Test::More> - Testing framework

=item * L<Test::Exception> - Exception testing

=back

=head2 Optional Dependencies

=over 4

=item * L<Pod::Markdown> - For generating README from POD

=back

=head1 SEE ALSO

=head2 GitHub Actions Documentation

=over 4

=item * L<Workflow Syntax|https://docs.github.com/actions/reference/workflow-syntax-for-github-actions>

=item * L<GitHub Actions Pricing|https://docs.github.com/billing/managing-billing-for-github-actions>

=item * L<Security Hardening|https://docs.github.com/actions/security-guides/security-hardening-for-github-actions>

=item * L<Caching Dependencies|https://docs.github.com/actions/using-workflows/caching-dependencies-to-speed-up-workflows>

=back

=head2 Related Tools

=over 4

=item * L<act|https://github.com/nektos/act> - Run GitHub Actions locally

=item * L<actionlint|https://github.com/rhysd/actionlint> - Linter for GitHub Actions

=item * L<yamllint|https://github.com/adrienverge/yamllint> - YAML linter

=back

=head1 CONTRIBUTING

Contributions are welcome! GHGen is open source and hosted on GitHub.

=head2 Ways to Contribute

=over 4

=item * B<Report bugs> - L<GitHub Issues|https://github.com/nigelhorne/ghgen/issues>

=item * B<Suggest features> - Open an issue with your idea

=item * B<Add language support> - Contribute new workflow templates

=item * B<Improve documentation> - Fix typos, add examples

=item * B<Submit pull requests> - Code contributions

=back

=head2 Development Setup

    # Fork and clone
    git clone https://github.com/YOUR-USERNAME/ghgen.git
    cd ghgen

    # Install dependencies
    cpanm --installdeps .

    # Run tests
    prove -lr t/

    # Make changes
    # ... edit files ...

    # Test your changes
    perl -Ilib bin/ghgen generate --type=perl
    prove -lr t/

    # Commit and push
    git add .
    git commit -m "Description of changes"
    git push origin your-branch

    # Open pull request on GitHub

=head2 Adding a New Language

To add support for a new language:

1. Create generator function in C<lib/App/GHGen/Generator.pm>

2. Add detection logic in C<lib/App/GHGen/Detector.pm>

3. Add customization in C<lib/App/GHGen/Interactive.pm>

4. Add tests in C<t/>

5. Update documentation

=head1 SUPPORT

=head2 Getting Help

=over 4

=item * L<GitHub Issues|https://github.com/nigelhorne/ghgen/issues> - Bug reports and feature requests

=item * L<GitHub Discussions|https://github.com/nigelhorne/ghgen/discussions> - Questions and community

=item * Email: L<njh@nigelhorne.com|mailto:njh@nigelhorne.com>

=back

=head2 Commercial Support

For commercial support, consulting, or custom development, contact the author.

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 CONTRIBUTORS

Thanks to all contributors who have helped improve GHGen!

See L<https://github.com/nigelhorne/ghgen/graphs/contributors>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Nigel Horne.

Usage is subject to license terms.

The license terms of this software are as follows:

=cut

1;
