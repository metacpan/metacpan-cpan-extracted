# Contributing to Catalyst::Plugin::OAuth2::ResourceServer

Bug reports, patches, and questions are all welcome.

## Reporting bugs

Open an issue at
<https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-ResourceServer/issues>.
A failing test case is the most useful bug report of all.

## Development setup

    cpanm --installdeps .
    prove -lr t

This distribution targets Perl 5.36 or newer and uses subroutine signatures.

## Code style

- Four-space soft tabs (no hard tabs); no trailing whitespace; newline at EOF.
- `use v5.36` and subroutine signatures in new code; Moo for OO.
- Keep POD and comments ASCII-only.

There is a Perl::Critic test (severity 3; see `.perlcriticrc`), skipped by
default and run with:

    PERL_CRITIC_TEST=1 prove -l t/perl_critic.t

## Submitting changes

- Work on a branch and open a pull request against `main`.
- Keep commits atomic, in imperative mood; commit tidy-ups (whitespace,
  reformatting) separately from behavioural changes.
- Rebase onto `main` before your PR is merged, so the history stays linear.
- CI (GitHub Actions) runs the suite and the critic test; please keep it green.

## Licence

This distribution is free software under the same terms as Perl itself.
