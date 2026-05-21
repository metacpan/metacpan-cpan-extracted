# API-Docker

Perl client for the Docker Engine API.

## Docker Engine API

- **Unix Socket**: Default transport via `/var/run/docker.sock`
- **TCP**: Remote Docker daemons via `tcp://host:port`
- **TLS**: Optional TLS for secure remote connections
- **Auto-Negotiate**: Detects highest API version from daemon

## Build & Test

```bash
dzil build
dzil test
prove -lv t/
```

## Test Architecture

Unified mock/live tests controlled by environment variables:

```bash
# Mock mode (default):
prove -l t/

# Read tests against real Docker:
API_DOCKER_TEST_HOST=unix:///var/run/docker.sock prove -l t/

# Full live mode (read + write):
API_DOCKER_TEST_HOST=unix:///var/run/docker.sock API_DOCKER_TEST_WRITE=1 prove -l t/
```

| Env Var | Effect |
|---------|--------|
| (none) | All tests run with mocks |
| `API_DOCKER_TEST_HOST` | Read tests live, write tests skip |
| `API_DOCKER_TEST_HOST` + `API_DOCKER_TEST_WRITE=1` | All tests live |

Test helper: `t/lib/Test/API/Docker/Mock.pm` exports `test_docker`, `is_live`, `can_write`, `skip_unless_write`, `check_live_access`, `register_cleanup`, `load_fixture`.

## Structure

```
lib/API/
├── Docker.pm                  # Main entry point + auto-negotiate
└── Docker/
    ├── Role/
    │   └── HTTP.pm            # HTTP over Unix Socket / TCP
    ├── API/
    │   ├── Containers.pm      # Container management
    │   ├── Images.pm          # Image management
    │   ├── Networks.pm        # Network management
    │   ├── Volumes.pm         # Volume management
    │   ├── System.pm          # System info, version, ping
    │   └── Exec.pm            # Exec into containers
    ├── Container.pm           # Container entity
    ├── Image.pm               # Image entity
    ├── Network.pm             # Network entity
    └── Volume.pm              # Volume entity
```

## Tech

- **Moo** for OOP
- **IO::Socket::UNIX** for Unix socket transport (no LWP dependency)
- **JSON::MaybeXS** for JSON handling
- **Log::Any** for logging
- **Dist::Zilla** with `[@Author::GETTY]`
