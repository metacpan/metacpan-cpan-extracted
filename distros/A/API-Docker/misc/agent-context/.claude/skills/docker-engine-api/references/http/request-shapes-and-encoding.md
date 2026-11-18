# Request shapes, filters, identifiers, and URL encoding

> Read when: building API requests without an official SDK.

Use the selected schema for each query/body/header location. JSON body booleans are actual booleans. Query values are encoded strings. Numeric units vary by field: bytes, nanoseconds, CPU quota/period, and counts are not interchangeable. Preserve absent versus explicit zero/null where the schema distinguishes them.

## Filters

The documented array form is a JSON object such as `{"label":["owner=example"],"status":["running"]}`, then URL-encoded as **one** query parameter. Pinned Moby source also supports its map-of-boolean-sets representation. This does not mean arbitrary shapes are accepted.

Malformed filters can produce errors. Never promise they always yield an empty or unfiltered result. Validate inputs locally, check endpoint-specific allowed keys, and test negative cases. Filter semantics are endpoint-specific; do not generalize event-filter OR/AND rules to every prune/list endpoint.

```python
from urllib.parse import urlencode
import json
query = urlencode({"filters": json.dumps({"label": ["owner=example"]}), "all": "true"})
```

## Paths and references

Container names and unambiguous ID prefixes may be accepted, but store full IDs for ownership and subsequent mutations. Leading `/` in list-result names is a presentation/API convention, not something to copy blindly into a name-creation field.

Registry image references can contain host ports, repository slashes, tags, and digests. Use an endpoint-specific reference encoder and preserve the route's expected structure. Do not claim percent-encoding always breaks image paths; client, router, and endpoint handling matters. Test nested repositories, ports, digest references, and reserved characters through the chosen HTTP library. Prefer query parameters where the endpoint defines them.

## Input safety

Do not concatenate untrusted strings into paths, query strings, shell commands, or JSON text. Validate resource ownership separately from identifier syntax. Reject control characters and unexpected reference forms before request construction. Log sanitized logical parameters, not raw auth-bearing requests.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Pinned Moby filter parser](https://raw.githubusercontent.com/moby/moby/v28.5.2/api/types/filters/parse.go)
- [Engine events behavior](https://docs.docker.com/reference/cli/docker/system/events/)
