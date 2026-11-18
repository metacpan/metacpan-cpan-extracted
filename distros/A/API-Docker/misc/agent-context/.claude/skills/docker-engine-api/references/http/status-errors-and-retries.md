# Status codes, stream errors, retries, and ambiguous outcomes

> Read when: mapping HTTP responses to operation results.

Build an endpoint-specific status contract. Many state mutations return 204 with no body. Some start/stop operations use 304 for an already-achieved state. Create operations can return identifiers; delete/list endpoints have other documented shapes. Do not JSON-decode every 2xx or treat all 3xx as redirect instructions.

Finite HTTP errors commonly contain `{"message":"..."}`; preserve a bounded sanitized message for diagnostics but do not parse its English wording for control flow. Unexpected HTML may come from a proxy, not Docker. Keep HTTP failure, malformed response, transport loss, timeout, and application-level operation failure as separate error classes.

Progress-stream operations can fail after an initial successful HTTP status. Consume build/pull/push messages to their intended completion and check in-band error fields. Early authentication/validation errors can still be ordinary non-2xx responses; “all failed builds return 200” is also too strong.

## Retry classes

Retry safe reads with bounded exponential backoff and jitter where appropriate. Reconcile state after an ambiguous mutation. If a create request timed out, the daemon may have created the container. Find the intended object using a unique name/ownership label and inspect its configuration before retrying. Do not blindly issue a second create or delete an unrelated naming conflict.

Starting an already running owned container may be an acceptable idempotent outcome. Exec creation/start is not a business-operation idempotency mechanism: retrying a payment, migration, or job command can duplicate effects. The application needs its own operation identity and reconciliation.

## Result contract

Return operation ID, daemon identity, selected API version, affected full resource ID, final observed state, and uncertainty where completion is unknown. A client-side timeout is not proof that the server rolled back or stopped working. Avoid “success” when the only observed fact is that HTTP headers arrived.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
