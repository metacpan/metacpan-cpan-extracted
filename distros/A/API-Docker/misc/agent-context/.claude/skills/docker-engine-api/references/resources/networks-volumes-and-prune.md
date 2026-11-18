# Networks, volumes, and destructive endpoint policy

> Read when: automating resource creation or cleanup.

Use typed requests and full identifiers for network/volume operations. Distinguish the logical resource from a container attachment. A disconnected volume can still hold valuable data; an unused network can still be reserved for a deployment. Absence of current consumers is not proof of disposability.

## Ownership model

Create resources with an application-specific owner label and operation identity. Maintain an inventory of expected names/IDs, configurations, consumers, and retention state. Before reuse, inspect existing resources and check compatibility rather than treating an “already exists” response as success. Labels are helpful evidence, not cryptographic authorization.

## Deletion protocol

Require a concrete target set, ownership verification, reason, expected effect, backup/recovery status for stateful data, and approval. Prefer deleting explicit owned IDs to a broad prune request. If prune is used, validate its filter syntax and endpoint-specific semantics, inventory matching resources first, and report that concurrent state changes can alter the eventual selection.

Do not promise every prune endpoint offers a dry run. A preceding list is an approximation that can race, not an atomic transaction. Keep a conservative allowlist and refuse deletion when ownership or state is uncertain. Avoid `force` as the default.

## Recovery and error handling

When a container references a resource being removed, distinguish a conflict from permission or backend failure. A network disconnection can interrupt active requests. Volume deletion is not reversible by recreating a volume with the same name. If deletion's response is lost, reconcile existence; do not repeat unrelated cleanup just to obtain a clean status.

For Kubernetes-owned runtime storage or networks, do not bypass the owning control plane casually. Engine API is not a general containerd administration surface, even if Docker internally uses containerd.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Pinned Moby filter parser](https://raw.githubusercontent.com/moby/moby/v28.5.2/api/types/filters/parse.go)
- [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/)
