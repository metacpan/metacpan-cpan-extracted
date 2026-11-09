# Reviewed companion skills and dependency policy

Reviewed on **2026-09-30**. The package is complete without external skills.
The optional composed profile delegates general PostgreSQL review and specialized
graph knowledge while this skill owns PostgreSQL 18 compatibility, cross-model
query boundaries, consistency, and end-to-end tests.

## Candidates with observable maintenance

| Candidate | Reviewed evidence | Use here | Boundary |
|---|---|---|---|
| Supabase `supabase-postgres-best-practices` | Repository commit `544bfc56c89afe2b87b20017a59b2c6e9502a1fb`, 2026-09-28; skill exists at `skills/supabase-postgres-best-practices/` | Optional general schema/query/index/connection review | Not proof of AGE support or a requirement to host on Supabase |
| Microsoft `pg-graph` | Skill-path commit `ffd266746bcea53b6d37a6c95efe1a722350261c`, 2026-09-16; `plugin/skills/pg-graph/` | Optional ontology, extraction, Cypher, graph-RAG and provenance companion | Azure-specific operations and plugin tools are not generic PostgreSQL requirements |
| Timescale / Tiger Data `pg-aiguide` | Repository commit `b236d3583fb51f5ef009d2c95d4fc361df748280`, 2026-09-25; upstream documents `postgres` and `schema-exploration` skills | Optional alternative general PostgreSQL skill or documentation supplement | Recent repo activity is not evidence that every skill file changed; remote MCP is optional |

These are maintenance signals, not a security audit or a guarantee of future
maintenance. Only Microsoft's evidence above is explicitly scoped to the skill
path; the other dates are repository activity. Do not substitute marketplace star
counts or an old frontmatter date for source review.

## Profiles

**Standalone (default):** no required companion. All references and worked examples
remain available. **Composed:** require the reviewed Supabase skill and Microsoft
`pg-graph` to be available before claiming that profile is active. If either is
missing, report the missing companion and fall back to standalone; never pretend
to have loaded it.

[dependencies.json](../../dependencies.json) is this package's own descriptive
manifest. It is **not** a portable Agent Skills dependency resolver. Do not invent
a universal `requires:` frontmatter feature or promise automatic installation.

## Review and install intentionally

Pin a reviewed commit, inspect the selected skill directory and its local
references, licenses, scripts, hooks, tool declarations, and network access.
Install the whole selected skill directory through the host's documented mechanism.
Do not flatten references or copy only SKILL.md. Recheck the commit/path if updating.
No third-party skill files are redistributed in this ZIP.

The complete Microsoft plugin can start `@microsoft/postgres-mcp` through `npx`.
Reading a companion skill is not authorization to install or start that process,
connect a database, or enable Azure tooling. Likewise, pg-aiguide's remote docs MCP
is not required; review data egress and tool permissions separately.

## Conflict resolution

Use actual deployed-version primary documentation and measured behavior over a
companion's generic defaults. Qualify application DDL and use trusted schemas;
never blindly copy a blanket search-path order. Use verified AGE parameter maps
instead of unsafe interpolation. Treat graph path confidence rules as heuristics
unless calibrated. Provider-only instructions apply only to that provider.

Do not import the entire companion on every task. Consult its relevant reference
when it fills a specific gap; avoid three overlapping PostgreSQL guides competing
for context on a simple query.

## Sources

- [Supabase Agent Skills](https://github.com/supabase/agent-skills)
- [Microsoft Postgres Skills](https://github.com/microsoft/postgres-skills)
- [Timescale / Tiger Data pg-aiguide](https://github.com/timescale/pg-aiguide)
- [Agent Skills specification](https://agentskills.io/specification)
