# Repository Guidelines

## Project Structure & Module Organization
- Core Perl modules live under `lib/App/Greple/wordle*.pm`; `wordle.pm` provides the CLI entry point, `game.pm` manages state, and `word_hidden.pm` / `word_all.pm` supply word lists.
- Tests reside in `t/`, numbered `NN_description.t`; the current `00_compile.t` sanity-checks module loading.
- Assets and long-form docs sit in `images/` and `README.md`; distribution metadata is maintained in `Build.PL`, `cpanfile`, and `minil.toml`.

## Build, Test, and Development Commands
- `cpanm --installdeps .` installs runtime and test dependencies listed in `cpanfile`.
- `perl Build.PL && ./Build` builds the distribution with Module::Build::Tiny.
- `./Build test` or `prove -l t` executes the full test suite.
- `minil test` mirrors the GitHub Actions workflow; run it before tagging or releasing.
- `greple -Ilib -Mwordle` launches the module against the in-tree code for manual playtesting.

## Coding Style & Naming Conventions
- Target Perl `v5.18.2` or newer; add `use v5.18.2; use warnings; use utf8;` to new modules.
- Prefer 4-space indentation and match the surrounding alignment; keep lines under 100 columns and avoid trailing whitespace.
- Follow the existing namespace pattern `App::Greple::wordle::*`, with filenames mirroring package names beneath `lib/`.
- Reuse helpers from `List::Util`, `List::MoreUtils`, and other declared dependencies instead of duplicating functionality.

## Testing Guidelines
- Use `Test::More` (as in `t/00_compile.t`) and require explicit versions when importing.
- Place new tests under `t/` using incremental numbers (`01_game.t`, `02_cli.t`) and add `use lib 'lib';` when accessing in-tree modules.
- Cover success and failure paths for each feature; ensure `prove -l t` passes before submitting changes.

## Commit & Pull Request Guidelines
- Write concise, present-tense commit messages (e.g., `Fix hint filter edge case`) and keep unrelated changes separate.
- Reference issues with `Fixes #123` when relevant; document compatibility or dependency shifts in the commit body or PR description.
- Pull requests should summarize changes, note test commands and outcomes, and include screenshots when altering assets in `images/` or terminal output.
- Confirm GitHub Actions (`.github/workflows/test.yml`) succeeds on your branch and rebase to resolve conflicts before requesting review.

## Release & Automation Notes
- CI currently exercises Perl 5.18–5.36; spot-check locally on at least one target version prior to release.
- Update `Changes` and bump `$VERSION` in `lib/App/Greple/wordle.pm` when preparing a release, then run `minil release` after all checks pass.
