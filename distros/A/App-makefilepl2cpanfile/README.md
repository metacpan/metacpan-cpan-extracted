# NAME

App::makefilepl2cpanfile - Convert Makefile.PL to a cpanfile automatically

# VERSION

# SYNOPSIS

        use App::makefilepl2cpanfile;

        my $cpanfile_text = App::makefilepl2cpanfile::generate(
                makefile     => 'Makefile.PL',
                existing     => '',   # optional: existing cpanfile text to merge
                with_develop => 1,    # include author/developer dependencies
        );

        path('cpanfile')->spew_utf8($cpanfile_text);

# DESCRIPTION

Parses a `Makefile.PL` file **without evaluating it** and produces a
`cpanfile` string containing:

- Runtime dependencies (`PREREQ_PM`)
- Build, test, and configure requirements (`BUILD_REQUIRES`,
`TEST_REQUIRES`, `CONFIGURE_REQUIRES`)
- Structured `prereqs => { phase => { rel => { ... } } }`
blocks (CPAN Meta Spec format), including `recommends` and `suggests`
relationships
- Inline comments attached to dependency entries
- Optional author/development dependencies in a `develop` block

# CONFIGURATION

An optional YAML file at `~/.config/makefilepl2cpanfile.yml` overrides
the default develop-phase tools:

        develop:
          Perl::Critic: 0
          Devel::Cover: 0
          My::Extra::Tool: '1.00'

# DATA STRUCTURE

`parse_prereqs()` and the internal pipeline use a three-level hashref:

        {
          phase_name => {
            relationship => {
              'Module::Name' => { version => '1.0', comment => 'why it is needed' },
            },
          },
        }

`phase_name` ∈ { runtime, configure, build, test, develop }.
`relationship` ∈ { requires, recommends, suggests }.
`version` is `0` when no minimum is declared.
`comment` is `undef` when no inline comment was present.

# METHODS

## generate(%args)

Parses a `Makefile.PL` and returns a complete `cpanfile` string.

### PSEUDOCODE

        1. Validate and normalise arguments; croak if makefile is unreadable.
        2. Slurp makefile content; extract MIN_PERL_VERSION.
        3. Call parse_prereqs() to build the phase/rel/module/entry structure.
        4. If an existing cpanfile string was supplied, merge its 'develop'
           block (all relationships) without overwriting freshly-parsed entries.
        5. If with_develop: load user config (or built-in defaults) and inject
           missing 'requires' develop tools — never overwrite explicit entries.
        6. Delegate to _emit() and return the formatted string.

### API SPECIFICATION

        Arguments (named hash or single hashref):
          makefile     Str   Path to Makefile.PL.  Default: 'Makefile.PL'
          existing     Str   Existing cpanfile text to merge.  Default: ''
          with_develop Bool  Inject default dev tools.  Default: 1 (true)

        Returns: Str — complete cpanfile text, terminated with a single newline.

### EXAMPLE

        # Minimal usage — generate from the project's own Makefile.PL
        my $out = App::makefilepl2cpanfile::generate();
        path('cpanfile')->spew_utf8($out);

        # Preserve hand-curated develop entries from an existing cpanfile
        my $out = App::makefilepl2cpanfile::generate(
                makefile => 'dist/Makefile.PL',
                existing => path('cpanfile')->slurp_utf8,
        );

### MESSAGES

        "Cannot read '$makefile'"
            The supplied path does not exist, is a directory, or is not readable.
            Resolution: verify the path and filesystem permissions.

        "Failed to parse $cfg_file: ..."
            The user config file exists but contains invalid YAML.
            Resolution: validate the YAML syntax; or delete the file to use defaults.

        "No 'develop' key found in $cfg_file; using defaults"
            The config file exists but lacks a 'develop' section.
            Resolution: add a develop: block, or delete the file to use defaults.

## parse\_prereqs($content)

Extracts all dependency declarations from a `Makefile.PL` string and
returns them structured by cpanfile phase and relationship type.  Exposed
as a public function so callers (e.g. `bin/makefilepl2cpanfile --check`)
can reuse the parsing logic without duplicating regexes.

Both the simple `PREREQ_PM => { ... }` form and the structured
`prereqs => { phase => { rel => { ... } } }` form (including
those nested under `META_MERGE`) are parsed.  Inline comments attached to
module entries are captured and preserved for round-trip fidelity.

### API SPECIFICATION

        Arguments:
          $content   Str   Raw text of a Makefile.PL

        Returns: HashRef (see L</DATA STRUCTURE>)
          {
            phase => {
              rel => {
                'Module::Name' => { version => version_str, comment => str_or_undef },
              },
            },
          }
          Absent phases/relationships are not present in the hashref.
          version is 0 when no minimum is declared.
          comment is undef when no inline comment was present.

### EXAMPLE

        my $deps = App::makefilepl2cpanfile::parse_prereqs(
            path('Makefile.PL')->slurp_utf8
        );

        # Iterate over all phases and relationships
        for my $phase (sort keys %{$deps}) {
            for my $rel (sort keys %{ $deps->{$phase} }) {
                for my $mod (sort keys %{ $deps->{$phase}{$rel} }) {
                    my $e = $deps->{$phase}{$rel}{$mod};
                    printf "%s %s %s => %s\n", $phase, $rel, $mod, $e->{version};
                }
            }
        }

### MESSAGES

        No errors or warnings — unrecognised content is silently ignored.

# LIMITATIONS

- Because parsing is regex-based and the `Makefile.PL` is never
`eval`'d, dynamically generated dependency lists (e.g. those produced by
`if`/`unless` branches or subroutine calls) cannot be detected.
- Encapsulation enforcement (`Sub::Private` in `enforce` mode) is not
applied; the `_` prefix convention is used instead.  A future release may
add `Sub::Private` once its `enforce`-mode API is verified.

# SUPPORT

This module is provided as-is without any warranty.

Bugs and feature requests:
[https://github.com/nigelhorne/App-makefilepl2cpanfile/issues](https://github.com/nigelhorne/App-makefilepl2cpanfile/issues)

# AUTHOR

Nigel Horne <njh@nigelhorne.com>

# FORMAL SPECIFICATION

## generate

        -- generate maps named arguments to a cpanfile string
        generate : Args → Str
        where
          Args ≙ [makefile : Path; existing : Str; with_develop : 𝔹]

        generate(a) ≙
          let content ≙ slurp(a.makefile)
              deps    ≙ parse_prereqs(content)
              merged  ≙ deps ⊕ {develop ↦
                           deps.develop ∪ extract_develop(a.existing)}
              final   ≙ if a.with_develop
                        then merged ⊕ {develop ↦
                               {requires ↦ load_config() ▷ merged.develop.requires}}
                        else merged
          in _emit(final, min_perl(content))
        -- (▷) right-biases toward the right operand: existing entries win.

## parse\_prereqs

        parse_prereqs : Str → DepMap
        where
          DepMap    ≙ Phase ↦ (Rel ↦ (ModName ↦ Entry))
          Entry     ≙ [version : VersionStr; comment : Str ∪ {⊥}]
          Phase     ∈ {runtime, configure, build, test, develop}
          Rel       ∈ {requires, recommends, suggests}

        parse_prereqs(s) ≙
          simple_deps(s) ⊕ structured_deps(s)
        where
          simple_deps(s)     ≙ ⋃ { extract_simple(k, s) | k ∈ dom(PHASE_MAP) }
          structured_deps(s) ≙ ⋃ { extract_prereqs_block(b) | b ∈ prereqs_blocks(s) }

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
