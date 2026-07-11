# DBIx-QuickDB

## Testing
ALWAYS run tests with: `timeout 600 env AUTHOR_TESTING=1 prove -Ilib -r t -j16`
(AUTHOR_TESTING enables ~/dbs scanning; -j16 keeps the suite ~5min; timeout catches hung servers).
See AGENTS.md for the ~/dbs per-install test machinery and its constraints.

## CPAN Testers
Dist name on https://mcp.cpantesters.org/: `DBIx-QuickDB`
See ~/CLAUDE.md for MCP query protocol.
