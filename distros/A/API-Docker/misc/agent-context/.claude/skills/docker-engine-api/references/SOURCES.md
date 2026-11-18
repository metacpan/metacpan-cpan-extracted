# Primary-source register

Documentation review: **2026-10-09**. The references in this skill link to the sources relevant to each topic. This register is for maintenance; agents should not fetch every source on every task.

Dynamic documentation and release branches can change. Revalidate exact release-dependent options before implementation. Pinned implementation sources describe that release, not all compatible products. No upstream manual or complete source repository is bundled. Operational checklists, examples, and decision guidance are authored additions.

| Source | Evidence scope |
|---|---|
| [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/) | Maintained primary documentation/source |
| [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/) | Maintained primary documentation/source |
| [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml) | Pinned implementation/specification |
| [Engine SDK guidance](https://docs.docker.com/reference/api/engine/sdk/) | Maintained primary documentation/source |
| [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/) | Maintained primary documentation/source |
| [Docker SDK for Python client](https://docker-py.readthedocs.io/en/stable/client.html) | Maintained primary documentation/source |
| [Docker Python SDK multiplexed streams](https://docker-py.readthedocs.io/en/stable/user_guides/multiplex.html) | Maintained primary documentation/source |
| [Pinned Moby stdcopy framing implementation](https://raw.githubusercontent.com/moby/moby/v28.5.2/pkg/stdcopy/stdcopy.go) | Pinned implementation/specification |
| [Pinned Moby registry auth encoder/decoder](https://raw.githubusercontent.com/moby/moby/v28.5.2/api/types/registry/authconfig.go) | Pinned implementation/specification |
| [Pinned Moby filter parser](https://raw.githubusercontent.com/moby/moby/v28.5.2/api/types/filters/parse.go) | Pinned implementation/specification |
| [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/) | Maintained primary documentation/source |
| [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/) | Maintained primary documentation/source |
| [Rootless Docker](https://docs.docker.com/engine/security/rootless/) | Maintained primary documentation/source |
| [Podman system service and Docker compatibility layer](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) | Maintained primary documentation/source |
| [Engine events behavior](https://docs.docker.com/reference/cli/docker/system/events/) | Maintained primary documentation/source |
| [Stats display versus API counters](https://docs.docker.com/reference/cli/docker/container/stats/) | Maintained primary documentation/source |
| [Container copy and archive semantics](https://docs.docker.com/reference/cli/docker/container/cp/) | Maintained primary documentation/source |
| [Container wait](https://docs.docker.com/reference/cli/docker/container/wait/) | Maintained primary documentation/source |
| [BuildKit build secrets](https://docs.docker.com/build/building/secrets/) | Maintained primary documentation/source |
| [Buildx multi-platform workflow](https://docs.docker.com/build/building/multi-platform/) | Maintained primary documentation/source |
| [Compose SDK and CLI history](https://docs.docker.com/compose/intro/history/) | Maintained primary documentation/source |
| [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/) | Maintained primary documentation/source |

## Maintenance procedure

When updating a claim, check the target product release and primary reference, update its feature gate and examples together, and add a regression test where practical. Record an integration result separately from a documentation review. If documentation and measured behavior disagree, preserve the discrepancy and scope the claim; do not silently choose the more convenient interpretation.
