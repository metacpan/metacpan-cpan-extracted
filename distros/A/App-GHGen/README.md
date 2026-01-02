# NAME

App::GHGen - Comprehensive GitHub Actions workflow generator, analyzer, and optimizer

# SYNOPSIS

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

# DESCRIPTION

App::GHGen is a comprehensive toolkit for creating, analyzing, and optimizing GitHub Actions workflows.
It combines intelligent project detection, workflow generation, security analysis, cost optimization,
and automatic fixing into a single powerful tool.

## Key Features

- **🤖 Auto-detect project type** - Intelligently scans your repository to detect language and dependencies
- **🚀 Generate optimized workflows** - Creates workflows with caching, security, concurrency, and best practices built-in
- **🔍 Analyze existing workflows** - Comprehensive analysis for performance, security, cost, and maintenance issues
- **🔧 Auto-fix issues** - Automatically applies fixes for detected problems (adds caching, updates versions, adds permissions, etc.)
- **🎯 Interactive customization** - Guided workflow creation with smart defaults and multi-select options
- **💰 Cost estimation** - Estimates current CI minutes usage and calculates potential savings from optimizations
- **🔄 GitHub Action integration** - Run as a GitHub Action to analyze PRs, comment with suggestions, and create fix PRs
- **📊 Per-workflow breakdown** - Detailed analysis of each workflow's cost and optimization potential

# INSTALLATION

## From CPAN (when published)

    cpanm App::GHGen

## From Source

    git clone https://github.com/nigelhorne/ghgen.git
    cd ghgen
    cpanm --installdeps .
    perl Makefile.PL
    make
    make test
    make install

## Quick Install Script

    curl -L https://cpanmin.us | perl - App::GHGen

# QUICK START

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

# WORKFLOW GENERATION

## Auto-Detection

GHGen can automatically detect your project type by scanning for indicator files:

    ghgen generate --auto

Detection looks for:

- **Perl**: cpanfile, dist.ini, Makefile.PL, Build.PL, lib/\*.pm
- **Node.js**: package.json, package-lock.json, yarn.lock
- **Python**: requirements.txt, setup.py, pyproject.toml
- **Rust**: Cargo.toml, Cargo.lock
- **Go**: go.mod, go.sum
- **Ruby**: Gemfile, Rakefile
- **Docker**: Dockerfile, docker-compose.yml

If multiple types are detected, it shows alternatives:

    ✓ Detected project type: PERL
      Evidence: cpanfile, lib, t

    Other possibilities:
      • docker (confidence: 65%)

    Generate PERL workflow? [Y/n]:

## Specify Project Type

Generate for a specific language:

    ghgen generate --type=perl
    ghgen generate --type=node
    ghgen generate --type=python
    ghgen generate --type=rust
    ghgen generate --type=go
    ghgen generate --type=ruby
    ghgen generate --type=docker
    ghgen generate --type=static

## Interactive Mode

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

## Interactive Customization

Customize workflows with guided prompts:

    ghgen generate --type=perl --customize

For Perl, you'll be asked:

- **Perl versions to test** - Select from 5.22 through 5.40 (multi-select with defaults)
- **Operating systems** - Ubuntu, macOS, Windows (multi-select)
- **Enable Perl::Critic** - Code quality analysis (yes/no)
- **Enable Devel::Cover** - Test coverage (yes/no)
- **Branch configuration** - Which branches to run on

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

## List Available Types

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

# WORKFLOW ANALYSIS

## Basic Analysis

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

- **Performance Issues**
    - - Missing dependency caching (npm, pip, cargo, go, bundler, cpanm)
    - - Jobs that could run in parallel
- **Security Issues**
    - - Unpinned action versions (@master, @main)
    - - Missing permissions declarations
    - - Overly broad permissions (contents: write when read is sufficient)
- **Cost Issues**
    - - Missing concurrency controls (wasted CI on superseded runs)
    - - Overly broad triggers (runs on every push without filters)
    - - Inefficient matrix strategies
- **Maintenance Issues**
    - - Outdated action versions (v4 → v5, v5 → v6)
    - - Outdated runner versions (ubuntu-18.04 → ubuntu-latest)

## Auto-Fix

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

- **Add caching** - Detects project type and adds appropriate dependency caching
- **Update actions** - Updates to latest versions (cache@v4→v5, checkout@v5→v6, etc.)
- **Pin versions** - Converts @master/@main to specific version tags
- **Add permissions** - Adds `permissions: contents: read` for security
- **Add concurrency** - Adds concurrency groups to cancel superseded runs
- **Optimize triggers** - Adds branch and path filters
- **Update runners** - Changes ubuntu-18.04 to ubuntu-latest

The auto-fix feature is safe:

- Only fixes well-understood issues
- Preserves YAML structure and comments
- Changes are easily reviewable with `git diff`
- Can be reverted if needed

## Cost Estimation

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

- Workflow trigger frequency (push, PR, schedule)
- Estimated duration per run (based on steps and commands)
- Matrix build multipliers (e.g., 3 OS × 8 Perl versions = 24 jobs)
- Parallel vs sequential job execution
- GitHub Actions pricing ($0.008/minute for private repos, 2000 free minutes/month)

# GITHUB ACTION INTEGRATION

Use GHGen as a GitHub Action to analyze workflows automatically.

## Mode 1: Comment on Pull Requests

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

## Mode 2: Auto-Fix with Pull Request

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

## Mode 3: CI Quality Gate

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

# SUPPORTED LANGUAGES

## Perl

Comprehensive Perl testing with modern best practices.

**Features:**

- Multi-OS testing (Ubuntu, macOS, Windows)
- Multiple Perl versions (5.22 through 5.40, customizable)
- Smart version detection from cpanfile, Makefile.PL, dist.ini
- CPAN module caching with local::lib
- Perl::Critic integration for code quality
- Devel::Cover for test coverage
- Proper environment variables (AUTOMATED\_TESTING, NO\_NETWORK\_TESTING, NONINTERACTIVE\_TESTING)
- Cross-platform compatibility (bash for Unix, cmd for Windows)

**Example:**

    ghgen generate --type=perl --customize

**Generated workflow includes:**

- actions/checkout@v6
- actions/cache@v5 for CPAN modules
- shogo82148/actions-setup-perl@v1
- Matrix testing across OS and Perl versions
- Conditional Perl::Critic (latest Perl + Ubuntu only)
- Conditional coverage (latest Perl + Ubuntu only)
- Security permissions
- Concurrency controls

## Node.js

Modern Node.js workflows with npm/yarn/pnpm support.

**Features:**

- Multiple Node.js versions (18.x, 20.x, 22.x)
- Package manager selection (npm, yarn, pnpm)
- Dependency caching (~/.npm, ~/.yarn, ~/.pnpm)
- Optional linting (ESLint)
- Optional build step
- Lock file hash-based cache keys

**Customization options:**

- Node.js versions to test
- Package manager preference
- Enable/disable linting
- Enable/disable build step

## Python

Python testing with virtual environment support.

**Features:**

- Multiple Python versions (3.9, 3.10, 3.11, 3.12, 3.13)
- pip caching (~/.cache/pip)
- flake8 linting
- pytest with coverage
- Optional black formatter checking
- requirements.txt hash-based cache

## Rust

Rust workflows with cargo, clippy, and formatting.

**Features:**

- Cargo registry and target caching
- cargo fmt formatting check
- Clippy linting with -D warnings
- Comprehensive test suite
- Optional release builds
- Cargo.lock hash-based cache

## Go

Go testing with modules and race detection.

**Features:**

- Configurable Go version
- Go modules caching (~/go/pkg/mod)
- go vet for static analysis
- Race detector (-race flag)
- Test coverage with atomic mode
- go.sum hash-based cache

## Ruby

Ruby testing with Bundler integration.

**Features:**

- Multiple Ruby versions (3.1, 3.2, 3.3)
- Automatic Bundler caching (built into setup-ruby)
- Gemfile.lock hash-based cache
- Rake integration

## Docker

Docker image building and publishing.

**Features:**

- Docker Buildx for multi-platform builds
- GitHub Container Registry (GHCR) support
- Docker Hub support
- Automatic tag extraction from git
- Layer caching with GitHub Actions cache
- Only pushes on non-PR events

## Static Sites

Static site deployment to GitHub Pages.

**Features:**

- GitHub Pages deployment
- Configurable build command
- Configurable build directory
- Artifact upload
- Proper Pages permissions
- Separate build and deploy jobs

# CONFIGURATION DETECTION

GHGen automatically detects configuration and adjusts workflows accordingly.

## Minimum Version Detection

For Perl, minimum version is detected from:

- cpanfile: `requires 'perl', '5.036'`
- Makefile.PL: `MIN_PERL_VERSION => '5.036'`
- dist.ini: `perl = 5.036`

Only compatible Perl versions are tested (e.g., if min is 5.36, won't test 5.32 or 5.34).

## Dependency Files

Caching is based on dependency files:

- Perl: cpanfile, dist.ini, Makefile.PL, Build.PL
- Node: package-lock.json, yarn.lock, pnpm-lock.yaml
- Python: requirements.txt, Pipfile.lock
- Rust: Cargo.lock
- Go: go.sum
- Ruby: Gemfile.lock

# BEST PRACTICES

## Workflow Generation

- **Use --auto for quick start** - Let GHGen detect your project
- **Use --customize for fine control** - Customize versions, OS, and features
- **Review before committing** - Always review generated workflows
- **Test locally first** - Use tools like `act` to test locally
- **Start with defaults** - Customize only when needed

## Workflow Analysis

- **Run analyze regularly** - Weekly `ghgen analyze` catches issues early
- **Use --estimate** - Monitor CI costs over time
- **Enable in CI** - Catch issues in PRs automatically
- **Review auto-fixes** - Always review changes before committing
- **Fix incrementally** - Don't fix everything at once if unsure

## Cost Optimization

- **Add caching** - Biggest time/cost savings
- **Add concurrency** - Cancel superseded runs
- **Filter triggers** - Only run on relevant changes
- **Optimize matrix** - Don't test unnecessary combinations
- **Run coverage once** - Only on one OS/version combination

# EXAMPLES

## Example 1: New Perl Module

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

## Example 2: Optimize Existing Project

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

## Example 3: Multi-Language Project

    # Project with both Node.js and Docker
    cd fullstack-app/

    # Generate Node.js workflow
    ghgen generate --type=node --output=.github/workflows/frontend-ci.yml

    # Generate Docker workflow
    ghgen generate --type=docker --output=.github/workflows/backend-build.yml

    # Analyze both
    ghgen analyze

## Example 4: Custom Perl Testing Matrix

    # Interactive customization
    ghgen generate --type=perl --customize

    # Choose:
    # Perl versions: 5.36, 5.38, 5.40 (skip older)
    # OS: Ubuntu, macOS (skip Windows if not needed)
    # Perl::Critic: Yes
    # Coverage: Yes
    # Branches: main

## Example 5: CI Quality Gate

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

# COMMAND REFERENCE

## generate

    ghgen generate [OPTIONS]

Generate a new GitHub Actions workflow.

**Options:**

- `--auto, -a`

    Auto-detect project type from repository contents.

- `--type=TYPE, -t TYPE`

    Specify project type: perl, node, python, rust, go, ruby, docker, static.

- `--customize, -c`

    Enable interactive customization mode.

- `--interactive, -i`

    Interactively select project type from menu.

- `--output=FILE, -o FILE`

    Specify output file (default: .github/workflows/TYPE-ci.yml).

- `--list, -l`

    List all available workflow types with descriptions.

**Examples:**

    ghgen generate --auto
    ghgen generate --type=perl --customize
    ghgen generate --interactive
    ghgen generate --type=node --output=custom.yml

## analyze

    ghgen analyze [OPTIONS]

Analyze existing workflows for issues and optimization opportunities.

**Options:**

- `--fix, -f`

    Automatically apply fixes to detected issues.

- `--estimate, -e`

    Show cost estimates and potential savings.

**Examples:**

    ghgen analyze
    ghgen analyze --fix
    ghgen analyze --estimate
    ghgen analyze --fix --estimate

# TROUBLESHOOTING

## Installation Issues

**Problem:** `cpanm` fails to install dependencies

**Solution:**

    # Install build tools first
    # On Debian/Ubuntu:
    sudo apt-get install build-essential

    # On macOS:
    xcode-select --install

    # Then retry
    cpanm App::GHGen

## Generation Issues

**Problem:** "No .github/workflows directory"

**Solution:**

    mkdir -p .github/workflows
    ghgen generate --auto

**Problem:** Auto-detect doesn't find my project type

**Solution:**

    # Specify type explicitly
    ghgen generate --type=perl

    # Or ensure indicator files exist
    touch cpanfile  # for Perl
    touch package.json  # for Node.js

## Analysis Issues

**Problem:** "Failed to parse YAML"

**Solution:**

    # Validate YAML syntax first
    yamllint .github/workflows/*.yml

    # Fix YAML errors, then retry
    ghgen analyze

**Problem:** Cost estimates seem wrong

**Solution:**

Cost estimates are approximations based on:

- Typical commit/PR frequency
- Average workflow duration
- Standard GitHub Actions pricing

Actual costs depend on your specific usage patterns.

## Auto-Fix Issues

**Problem:** Auto-fix didn't fix everything

**Solution:**

Some issues can't be auto-fixed:

- Complex workflow logic
- Custom actions
- Project-specific configurations

Review the remaining suggestions and apply manually.

## GitHub Action Issues

**Problem:** "Permission denied" errors

**Solution:**

    # Ensure correct permissions in workflow
    permissions:
      contents: write        # For auto-fix
      pull-requests: write   # For comments

**Problem:** Action not triggering

**Solution:**

    # For scheduled workflows, ensure:
    on:
      schedule:
        - cron: '0 9 * * 1'
      workflow_dispatch:  # Allows manual trigger

    # Test with manual trigger first

# DEPENDENCIES

## Runtime Dependencies

- Perl 5.36 or higher
- [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) - Fast YAML parsing and generation
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) - File and directory operations
- [Term::ANSIColor](https://metacpan.org/pod/Term%3A%3AANSIColor) - Colored terminal output
- [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) - Command-line option parsing

## Test Dependencies

- [Test::More](https://metacpan.org/pod/Test%3A%3AMore) - Testing framework
- [Test::Exception](https://metacpan.org/pod/Test%3A%3AException) - Exception testing

## Optional Dependencies

- [Pod::Markdown](https://metacpan.org/pod/Pod%3A%3AMarkdown) - For generating README from POD

# SEE ALSO

## GitHub Actions Documentation

- [Workflow Syntax](https://docs.github.com/actions/reference/workflow-syntax-for-github-actions)
- [GitHub Actions Pricing](https://docs.github.com/billing/managing-billing-for-github-actions)
- [Security Hardening](https://docs.github.com/actions/security-guides/security-hardening-for-github-actions)
- [Caching Dependencies](https://docs.github.com/actions/using-workflows/caching-dependencies-to-speed-up-workflows)

## Related Tools

- [act](https://github.com/nektos/act) - Run GitHub Actions locally
- [actionlint](https://github.com/rhysd/actionlint) - Linter for GitHub Actions
- [yamllint](https://github.com/adrienverge/yamllint) - YAML linter

# CONTRIBUTING

Contributions are welcome! GHGen is open source and hosted on GitHub.

## Ways to Contribute

- **Report bugs** - [GitHub Issues](https://github.com/nigelhorne/ghgen/issues)
- **Suggest features** - Open an issue with your idea
- **Add language support** - Contribute new workflow templates
- **Improve documentation** - Fix typos, add examples
- **Submit pull requests** - Code contributions

## Development Setup

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

## Adding a New Language

To add support for a new language:

1\. Create generator function in `lib/App/GHGen/Generator.pm`

2\. Add detection logic in `lib/App/GHGen/Detector.pm`

3\. Add customization in `lib/App/GHGen/Interactive.pm`

4\. Add tests in `t/`

5\. Update documentation

# SUPPORT

## Getting Help

- [GitHub Issues](https://github.com/nigelhorne/ghgen/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/nigelhorne/ghgen/discussions) - Questions and community
- Email: [njh@nigelhorne.com](mailto:njh@nigelhorne.com)

## Commercial Support

For commercial support, consulting, or custom development, contact the author.

# AUTHOR

Nigel Horne <njh@nigelhorne.com>

[https://github.com/nigelhorne](https://github.com/nigelhorne)

# CONTRIBUTORS

Thanks to all contributors who have helped improve GHGen!

See [https://github.com/nigelhorne/ghgen/graphs/contributors](https://github.com/nigelhorne/ghgen/graphs/contributors)

# COPYRIGHT AND LICENSE

Copyright 2025 Nigel Horne.

Usage is subject to license terms.

The license terms of this software are as follows:
