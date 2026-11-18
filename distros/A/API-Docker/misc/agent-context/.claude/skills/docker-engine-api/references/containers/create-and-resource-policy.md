# Create configuration and effective-policy verification

> Read when: setting mounts, ports, capabilities, limits, or user identity through HTTP.

Container create requests separate application configuration, host settings, and network endpoint configuration. Use the target API schema rather than translating CLI flag names mechanically. `Env` is an array of `KEY=value` strings; commands are argument arrays; exposed ports and host port bindings are different fields. Host mounts refer to the daemon's filesystem.

## Safe construction strategy

Start from a narrow typed model with allowed fields, explicit defaults, and unit-aware constructors. Add approved user, labels, command, resource limits, read-only rootfs, capability policy, mounts, and network attachment. Do not merge arbitrary user JSON into `HostConfig` when the API is meant to enforce restrictions.

```json
{
  "Image": "example/app:reviewed",
  "Cmd": ["/app/server"],
  "User": "10001:10001",
  "Labels": {"example.owner": "job-controller"},
  "HostConfig": {
    "ReadonlyRootfs": true,
    "CapDrop": ["ALL"],
    "SecurityOpt": ["no-new-privileges:true"],
    "Memory": 536870912,
    "NanoCpus": 1000000000,
    "PidsLimit": 128
  }
}
```

This is a policy illustration, not a runnable image or universal resource budget. A read-only filesystem needs explicit writable mounts for applications that write. Windows/rootless implementations can differ in field support.

## Verify after creation

Inspect the created container and compare effective user, image identity, mounts, privileges, network mode, port addresses, and resource constraints. Fail closed if a required restriction is missing or unsupported. Do not assume accepted JSON proves enforcement.

For agent-facing services, authorize resource identity and dangerous body fields before forwarding. Host PID/network namespaces, raw devices, privileged mode, arbitrary bind paths, added capabilities, and Docker socket mounts need separate policy. An allowlist that permits `POST /containers/create` without inspecting these fields is effectively an escalation interface.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/)
- [Rootless Docker](https://docs.docker.com/engine/security/rootless/)
