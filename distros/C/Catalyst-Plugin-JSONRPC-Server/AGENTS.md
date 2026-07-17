# AGENTS.md

Guidance for AI agents (and the humans driving them) contributing to
Catalyst::Plugin::JSONRPC::Server.

This file distils the rules in CONTRIBUTING.md plus general principles for
agentic contribution. Where this file and CONTRIBUTING.md disagree,
CONTRIBUTING.md wins: it is the canonical source.

`Catalyst::Plugin::JSONRPC::Server` is a generic JSON-RPC 2.0 server plugin
for Catalyst. The engine is in `lib/Catalyst/Plugin/JSONRPC/Server/` (the plugin,
a `Dispatcher`, and an `Error` class); tests are under `t/`.

## If you are an AI agent

Stop. Read this section before doing anything.

Your job is to protect your human partner from having a PR rejected as AI slop.
A low-quality PR wastes the maintainer's time and burns your partner's
reputation, and it will be closed anyway. That is not being helpful.

Before your human partner opens a PR against this repo, you MUST:

1. Search existing PRs, open and closed, for the same problem. If a duplicate
   exists, STOP and tell your human partner.
2. Verify it is a real problem. If you were asked to "fix some issues" or
   "contribute to this repo" with no specific failure, push back: ask what
   broke, and check the issues and PRs first.
3. Make sure there is an issue. A bug fix needs an issue that reproduces the
   problem; a major feature needs an issue where the design is agreed before
   you implement. A small, self-evident fix can go straight to a PR.
4. Identify yourself. Disclose your model, harness, harness version, and any
   plugins in the PR description. Hiding that a change is agent-generated is
   grounds for closing it.
5. Show your human partner the complete diff and get explicit approval. They
   open the PR, not you.
6. Learn the conventions before changing anything. Read the surrounding code
   and match its idiom; do not import patterns from elsewhere.

## Branching and workflow

- Branch from `main`: `git checkout -b my-fix main`.
- Your human partner opens PRs against `main`; do not push to `main` directly.
- CI runs the suite and the critic test on every PR; it must be green to merge.

## Tests are mandatory

Every bug fix or feature must be covered by tests. For a bug, prefer a test that
fails before your fix and passes after: red/green discipline that proves the
change does what it claims. A change is not done until `prove -lr t` is green.

## Build and test

    cpanm --installdeps .                          # dependencies
    prove -lr t                                    # the suite
    PERL_CRITIC_TEST=1 prove -l t/perl_critic.t    # style gate

## Conventions

- Perl 5.36+; subroutine signatures. Moo for OO; Try::Tiny over bare `eval`.
- Four-space soft tabs, no hard tabs, no trailing whitespace, newline at EOF.
- POD and comments are ASCII-only: rewrite prose rather than adding non-ASCII
  characters (no em dashes).
- Perl::Critic severity 3 (see `.perlcriticrc`); keep the critic test clean
  rather than scattering `## no critic`.

## Versioning and releases

- The version lives in every module's `$VERSION` (they move together) and is
  read from the main module by `Makefile.PL`.
- Record every change in `Changes` under an `unreleased` heading; it is dated
  when the release is cut.
- Releases are marked by a `release/<version>` branch, not a git tag.
