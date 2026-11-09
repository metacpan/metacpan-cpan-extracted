# Relational authorization and RLS

## Separate the trusted API from arbitrary SQL access

An application setting such as `app.tenant_id` is a context carrier, not an
authentication mechanism. A caller that can run arbitrary SQL under the same
role may set that value themselves. Establish tenant identity in a trusted
service, verified database identity mapping, or another reviewed boundary before
using a setting in policies. Never expose the lab context-setting pattern as a
public SQL endpoint.

## Policy checklist

Enable RLS on every tenant-bearing relation and define both visibility (`USING`)
and mutation (`WITH CHECK`) behavior. Table owners, superusers and roles with
`BYPASSRLS` require special attention; testing solely as an owner is not a valid
application isolation test. Use `FORCE ROW LEVEL SECURITY` where appropriate,
while remembering that it does not remove the superuser/BYPASSRLS bypass.

The lab role script uses a non-login, non-owner role and `SET LOCAL ROLE` to
exercise policies. The script changes cluster roles and requires separate,
explicit administrator approval.

## Every candidate channel needs authorization

Apply tenant and object permissions to lexical retrieval, vector candidates,
graph seeds, graph edges and destinations, fusion, reranking, and final hydration.
Do not rely on filtering the final text after prohibited IDs, relationships or
scores have already leaked into logs or prompts. Denormalized graph properties
are also sensitive data.

Partitioning can reduce interference between tenants' ANN workloads, but does
not itself grant or revoke access. Test role privileges and RLS independently
from recall and latency.

## Search path and function safety

Only trusted schemas belong on an operational search path. Qualify application
relations and extension-sensitive types/functions. Avoid copying `public` or
`"$user"` into a security-definer search path without auditing who can create
objects there. Do not create a superuser-owned generic query executor to make
AGE permission errors disappear.

Add tests for absent/malformed tenant context, tenant switching on a reused
connection, forged business keys, unauthorized IDs in candidate arrays, and
searches that intentionally match another tenant's exact text or embedding.

## Sources

- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [PostgreSQL 18 schemas and search_path](https://www.postgresql.org/docs/18/ddl-schemas.html)
- [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html)
