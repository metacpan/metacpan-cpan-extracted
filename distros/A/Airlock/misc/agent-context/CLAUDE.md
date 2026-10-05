# CLAUDE.md

Airlock — embeddable core for approving a waiting request from an already trusted session: the server side of the OAuth 2.0 Device Authorization Grant (RFC 8628) with optional step-up second factors, QR codes, two JSON endpoints as PSGI, and a device-flow client. Moo-based; released to CPAN via Dist::Zilla `[@Author::GETTY]`.

The design is `docs/superpowers/specs/2026-10-02-airlock-design.md`. It is the source of truth for scope and module layout; code that contradicts it is a finding, not a decision.

Two upstream mappings are built, each with a live test behind an environment variable and
its fixtures in a directory of its own: `Airlock::Upstream::Keycloak` (`t/90`,
`t/keycloak/`) and `Airlock::Upstream::Authentik` (`t/91`, `t/authentik/`). What a
provider puts into `acr`, `amr` and `auth_time` is recorded there from a real token.
Airlock depends on neither provider client at runtime.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/airlock-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `airlock-worker` (default) |
| Write/extend tests | `airlock-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `airlock-release-manager` |
| Write/maintain POD | `airlock-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Commands

```bash
prove -lr t          # full test suite (recursive; live tests skip by default)
dzil build           # build the distribution
dzil test            # test via Dist::Zilla
```

`LICENSE` is committed, not generated at build time; re-run `dzil genlicense` and
`git add LICENSE` after changing license, holder or year in `dist.ini`.
