# Keycloak live test

`t/90-live-keycloak.t` runs only when `TEST_AIRLOCK_KEYCLOAK_URL` is set. It
needs a Keycloak with the realm `airlock-test` from `realm.json` in this
directory: a public client `airlock-test-cli` with the device authorization
grant and direct access grants enabled, a user `plain` with a password, and a
user `otp` with a password and a TOTP credential whose secret is the RFC 6238
test secret `12345678901234567890`.

## Start a throwaway Keycloak

On Kubernetes (`k8s.yaml` in this directory; no persistence, NodePort service):

```bash
kubectl create namespace airlock-test
kubectl -n airlock-test create configmap airlock-realm --from-file=realm.json=t/keycloak/realm.json
kubectl -n airlock-test apply -f t/keycloak/k8s.yaml
kubectl -n airlock-test rollout status deploy/keycloak
kubectl -n airlock-test get svc keycloak        # the NodePort is the port of the URL
kubectl delete namespace airlock-test           # when done
```

The Keycloak image needs a CPU with x86-64-v2. On a VM with a generic CPU model
the pod dies with `Fatal glibc error: CPU does not support x86-64-v2`; give the
VM the host's CPU model or schedule the pod on another node.

With Docker:

```bash
docker run --rm --name airlock-keycloak -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -v "$PWD/t/keycloak/realm.json:/opt/keycloak/data/import/realm.json:ro" \
  quay.io/keycloak/keycloak:26.8.0 start-dev --import-realm
```

Keycloak needs about 1 GB of memory. Do not start it on a machine that is
already short of it.

## Make the realm report how someone logged in

```bash
perl -I ~/dev/p5-www-keycloak/lib t/keycloak/setup.pl http://localhost:8080
```

The script uses `WWW::Keycloak` (repository `p5-www-keycloak`); point `-I` at
its `lib` until it is installed.

A default realm puts no `amr` into its tokens. Two things change that. The
client needs the AMR protocol mapper; that is part of `realm.json`. And each
step of the authentication flows needs a reference value, which `setup.pl` sets
through the Admin REST API: `pwd` on the password steps and `otp` on the OTP
steps of the `browser` and `direct grant` flows. The script can be run again at
any time; a restarted pod has lost the setting and needs it again.

## Run

```bash
TEST_AIRLOCK_KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t
```

The test starts a device flow with `Airlock::Client`, logs in the way a browser
would (login form, one-time code, consent), and reads the claims of the token
the client receives. It needs `HTTP::CookieJar`. Keycloak accepts a one-time
code once; when two runs fall into the same 30 seconds the test waits for the
next code, so a run can take half a minute.

## Findings

Keycloak 26.8.0, recorded 2026-10-02.

| Realm | Login | acr | amr | auth_time |
|---|---|---|---|---|
| as imported, before `setup.pl` and without the AMR mapper | direct grant, password | `1` | absent | absent |
| as imported, before `setup.pl` and without the AMR mapper | direct grant, password + TOTP | `1` | absent | absent |
| with mapper and reference values | device flow, browser login, password | `1` | `pwd` | time of login |
| with mapper and reference values | device flow, browser login, password + TOTP | `1` | `pwd`, `otp` | time of login |
| with mapper and reference values | direct grant, password + TOTP | `1` | `pwd`, `otp` | absent |

What the runs established:

- `realm.json` imports as written, including the OTP credential.
- `Airlock::Client` completes a device flow against Keycloak: discovery, start,
  `authorization_pending` while waiting, and the token after the approval. The
  device response carries `verification_uri_complete`.
- **A default realm does not say in the token whether a second factor was
  used.** With the AMR mapper and the reference values it does, and
  `Airlock::Factor::Upstream` with its default `accept_amr` then tells the two
  logins apart. `acr` stays `1` either way and is of no use here.
- `auth_time` is only present after a browser login, not after a direct grant.
- The reference values carry a maximum age (`default.reference.maxAge`, set to
  3600 seconds by `setup.pl`); a step older than that drops out of `amr`.
- Keycloak accepts a TOTP code once per time step, also across logins.
- The form the consent page posts to is a path without host, unlike the forms
  of the login pages.
