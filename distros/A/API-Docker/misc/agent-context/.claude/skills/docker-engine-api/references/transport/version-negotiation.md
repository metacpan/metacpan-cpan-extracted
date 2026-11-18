# Correct version negotiation and feature gating

> Read when: choosing request prefixes or handling new/old daemon combinations.

Discover server `ApiVersion` and `MinAPIVersion` using the supported unversioned discovery endpoint. Treat versions as integer pairs, never floats or lexical strings: `1.9` must compare lower than `1.10`.

Let the client understand `[client_min, client_max]` and the daemon accept `[server_min, server_max]`. Then:

```text
lower = max(client_min, server_min)
upper = min(client_max, server_max)
if lower > upper: fail with an explicit compatibility error
selected = upper
```

Do **not** simply adopt the server maximum: the client may not understand it. Prefix subsequent versioned operations with the selected version. Feature requirements must fit that version, and platform/implementation support must still be verified.

## Overrides and missing discovery fields

An explicit API version setting is a pin, not negotiation. Check that the chosen version lies within both supported ranges. Official CLI/SDK `DOCKER_API_VERSION` behavior can disable negotiation; make that visible in diagnostics.

For old or compatible implementations that omit a minimum version, choose and document a legacy compatibility policy. The included helper fails closed unless a caller supplies a deliberate fallback. Do not invent a server minimum silently. An unavailable discovery endpoint is a transport/compatibility event, not permission to send the latest schema blindly.

## Upgrade test cases

Test older server, newer server, disjoint ranges, explicit pin outside range, missing/malformed fields, and numeric ordering. Test a supported field and a field introduced later than the selected version. A server that ignores unknown fields can otherwise make a supposedly hardened container run without the requested restriction.

The included Python helper implements range intersection and pin validation with unit tests. Its configured client range belongs to the caller; its existence does not prove that the caller actually implements every endpoint in that range.

## Primary sources

- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
- [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
