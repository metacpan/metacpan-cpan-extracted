# Repository Guidelines

## Project Structure & Module Organization
- Source modules live in `lib/App/Greple/` (e.g., `lib/App/Greple/xlate.pm` and `lib/App/Greple/xlate/`).
- Executables are in `script/` (primary CLI: `script/xlate`).
- Tests are in `t/` (helpers under `t/runner`), examples in `examples/`, and docs in `docs/`.
- Shared assets/resources are under `share/`; containerization files under `docker/`.

## Build, Test, and Development Commands
- Install deps: `cpanm --installdeps .` (uses `cpanfile`; Perl 5.26+).
- Run tests: `prove -lr t` or `minil test` (verbose: `prove -lrv t`).
- Build distribution: `minil build` (Module::Build::Tiny), or `perl Build.PL && ./Build`.
- Lint/format (optional): `perltidy -b lib/**/*.pm` if available.
- CLI help: `script/xlate --help`. Docker build/run: `make -C docker build` / `make -C docker run`.

## Coding Style & Naming Conventions
- Perl: 4 spaces, no tabs; keep lines under ~100 cols. Use `strict`/`warnings` and lexical `my`.
- Module names follow `App::Greple::...`; files mirror package paths under `lib/`.
- CLI options use long, kebab-case flags (e.g., `--xlate-context`). Keep POD up to date.

## Testing Guidelines
- Framework: `Test::More`. Place unit tests as `t/NN_name.t` (two-digit prefix for order).
- Add focused tests for new behavior and edge cases; prefer pure tests over integration where possible.
- Run full suite before PRs: `prove -lr t`. Optional coverage if installed: `cover -test`.

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject (≤72 chars). Group related changes; include rationale in body.
- Reference issues like `Fixes #123` when applicable. Release bumps are handled by Minilla.
- PRs: clear description, scope of change, test coverage notes, and usage examples (CLI invocations/output). Add screenshots for user-facing changes.

## Security & Configuration Tips
- Do not commit secrets. For translators/APIs, pass keys via env (e.g., `DEEPL_AUTH_KEY`).
- Prefer local testing; use Docker (`docker/Makefile`) for reproducible environments.

