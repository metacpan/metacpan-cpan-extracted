# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**App-dozo** is a generic Docker runner that simplifies running commands in Docker containers. The product name is **Dôzo**, which comes from the Japanese word "dôzo" (どうぞ) meaning "please" or "go ahead", and also stands for "**D**ocker with **Z**ero **O**verhead". The command name is `dozo` for ease of typing. It's a Perl distribution that includes a Bash script (`script/dozo`) as the main executable.

The tool automatically handles tedious Docker configuration (volumes, environment variables, working directories, interactive terminal settings), allowing users to focus on the command they want to run. It's git-friendly, automatically mounting the git top directory when available.

## Build System and Tools

This project uses **Minilla** for Perl module distribution management.

### Common Commands

**Build and install locally:**
```bash
minil build
```

**Run tests:**
```bash
prove -lr t
```

**Run a single test:**
```bash
prove -v t/03_dozo.t
```

**Run author tests (requires Docker):**
```bash
prove -v xt/author/docker_dozo.t
```

**Install dependencies:**
```bash
cpanm --installdeps .
```

**Release (maintainer only):**
```bash
minil release
```

Note: The release process has hooks (in `minil.toml`) that:
1. Update version number in `script/dozo` using the App::Greple::xlate module
2. Extract POD documentation from `script/dozo` and append it to `lib/App/dozo.pm`

## Architecture

### Core Components

1. **script/dozo** - The main Bash script that does all the work
   - Uses `getoptlong.sh` (from `Getopt::Long::Bash` CPAN package) for option parsing
   - Implements container lifecycle management for persistent containers (`-L` flag)
   - Handles `.dozorc` configuration file loading from multiple locations
   - Auto-detects git repository and mounts git top directory by default

2. **lib/App/dozo.pm** - Minimal Perl module wrapper
   - Contains only version number and POD documentation
   - The POD is auto-generated from `script/dozo` during release

### Key Design Patterns

**Mounting Strategy:**
- Priority: Git top directory > current directory > explicit mount with `-W`/`-H`
- When git top != current directory, mounts git top and sets working directory to relative path
- This allows git commands to work from any subdirectory

**Configuration Cascade:**
- Loads `.dozorc` from: `$HOME` → git top dir → current dir → command line
- Single-value options (e.g., `-I`, `-N`) override earlier values
- Repeatable options (e.g., `-E`, `-V`, `-P`, `-O`) accumulate

**Live Container Lifecycle:**
- Container name format: `<image_name>.<mount_directory>`
- States handled: not-exist → create, running → exec/attach, exited → start, paused → unpause
- With command args: uses `docker exec`, without: uses `docker attach`

**Environment Variable Inheritance:**
- Auto-inherits: `LANG`, `TZ`, proxy settings, terminal settings, AI API keys
- Sets in container: `DOZO_RUNNING_ON_DOCKER=1`, `XLATE_RUNNING_ON_DOCKER=1`

### Testing Strategy

- **t/00_compile.t** - Basic compilation check
- **t/03_dozo.t** - Unit tests for dozo script functionality
  - Uses temp directories to isolate from real `.dozorc` files
  - Tests option parsing, `.dozorc` loading, and error handling
  - Uses `-n` (dryrun) to avoid actual Docker execution
- **xt/author/docker_dozo.t** - Integration tests requiring Docker
  - Tests live container lifecycle (create, exec, start, kill)
  - Tests dryrun mode output

**Dryrun Mode (`-n`):**
- Shows docker commands without executing them
- Useful for testing and debugging
- Used in t/03_dozo.t to avoid Docker dependency during installation

## Important Context

### Dependencies

**Runtime:**
- Perl 5.24+ (for the module wrapper)
- Bash 4.3+ (for the main script)
- Docker (runtime requirement, not checked by tests)
- Getopt::Long::Bash 0.6.0+ (provides `getoptlong.sh`)

**Development:**
- Minilla (build tool)
- Test::More (testing)
- Module::Build::Tiny (build backend)

### Documentation Synchronization

POD documentation exists in two places but is kept in sync by release hooks:
- **Source of truth:** `script/dozo` (embedded POD)
- **Copy:** `lib/App/dozo.pm` (auto-generated during release)

When modifying documentation, edit only `script/dozo`. The `minil release` command will sync it to `lib/App/dozo.pm`.

### Version Management

Version is stored in both:
- `lib/App/dozo.pm` - Perl module version (`our $VERSION = "X.Y"`)
- `script/dozo` - POD version section (`=head1 VERSION\n\nVersion X.Y`)

Release hooks keep these synchronized. When updating version, update `lib/App/dozo.pm` first.

### Relationship to App::Greple::xlate

While Dôzo was originally developed as part of App::Greple::xlate for Docker-based translation workflows, it's designed to work standalone. The `getoptlong.sh` script is provided by the `Getopt::Long::Bash` CPAN package, which is installed as a dependency.

This allows Dôzo to be used independently as a general-purpose Docker runner.
