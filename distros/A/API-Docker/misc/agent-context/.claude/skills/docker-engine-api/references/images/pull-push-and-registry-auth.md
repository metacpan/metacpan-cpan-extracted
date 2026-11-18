# Image operations and registry authentication headers

> Read when: pulling or pushing images through the Engine API.

The Engine's registry-auth header is not the Registry HTTP API's bearer-token exchange. A client supplies registry credentials to the daemon, and the daemon contacts the registry. The daemon still needs network reachability and TLS trust independently of the client.

Encode the JSON auth object using **padded URL-safe base64**, matching Moby's encoder. An explicit empty object encodes as `e30=`. Keep padding; do not substitute standard base64 or an unpadded variant merely because a particular value appears to work.

```python
import base64, json
header = base64.urlsafe_b64encode(
    json.dumps({"username": "user", "password": "secret", "serveraddress": "registry.example.com"},
               separators=(",", ":")).encode("utf-8")
).decode("ascii")
```

Do not put real credentials in source or logs. The example explains encoding only. Prefer credential-helper integration and short-lived scoped credentials. Treat `identitytoken` and `registrytoken` according to the selected endpoint/auth flow rather than assuming they are interchangeable.

## Correct the anonymous-push assumption

The pinned Moby decoder accepts an empty/missing auth value as an empty configuration. Consequently, “every anonymous push always requires this header” is not a universal daemon rule. Supply the documented format when credentials are needed or when a target requires an explicit header, and test the supported version/endpoint. Padding behavior and header presence are separate questions.

Pull/push progress still needs in-band error handling. An HTTP 200 does not prove the registry accepted all content. Verify the intended digest and platform set. A tag accepted by the daemon can refer to a different local image than the release you intended; record image identity before push.

For registry token challenges, repository scopes, cross-host redirects, and OCI distribution requests made **directly** to a registry, switch to the `docker-registry` skill.

## Primary sources

- [Pinned Moby registry auth encoder/decoder](https://raw.githubusercontent.com/moby/moby/v28.5.2/api/types/registry/authconfig.go)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
