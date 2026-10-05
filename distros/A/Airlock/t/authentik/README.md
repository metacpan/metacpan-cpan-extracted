# authentik live test

`t/91-live-authentik.t` runs only when `TEST_AIRLOCK_AUTHENTIK_URL` and
`TEST_AIRLOCK_AUTHENTIK_TOKEN` are set and `setup.pl` in this directory has run
against that instance.

## Start a throwaway authentik

The compose file lives with `WWW::Authentik`, not here: it pins the image, binds
its ports to `127.0.0.1` and keeps its secrets in a `.env` beside itself, and
duplicating it would mean two files to keep in step for one instance.

```bash
cd ~/dev/p5-www-authentik/t/authentik
cp env.example .env          # then fill in the four secrets
docker compose up -d
curl -s http://127.0.0.1:9000/-/health/ready/    # 200 once ready, about two minutes
```

`AUTHENTIK_BOOTSTRAP_TOKEN` from that `.env` is the API token below.

## Build the fixtures

```bash
perl -I ~/dev/p5-www-authentik/lib t/authentik/setup.pl http://127.0.0.1:9000 "$AUTHENTIK_BOOTSTRAP_TOKEN"
```

It makes an application `airlock-test` with a public OAuth2 provider that can do
the device flow, two users (`airlock-plain` and `airlock-otp`, password
`<username>-password`), and an empty flow that the brand needs as its
`flow_device_code` before anyone can approve a device code at `/device`. Every
step is an `ensure_*`, so it can be run again at any time. `--remove` as a third
argument takes it all away again.

Unlike Keycloak, authentik needs **nothing** configured to report a second
factor, so the script does not touch any mapper or flow step. Enrolling the TOTP
device is the test's own job: it goes through the setup flow the way a person
would, and deletes the device again at the end.

## Run

```bash
TEST_AIRLOCK_AUTHENTIK_URL=http://127.0.0.1:9000 \
TEST_AIRLOCK_AUTHENTIK_TOKEN="$AUTHENTIK_BOOTSTRAP_TOKEN" \
  prove -lv t/91-live-authentik.t
```

The test needs the `p5-www-authentik` checkout next door, for two things it does
not carry itself: `WWW::Authentik` to make and remove the fixtures, and
`t/lib/AuthentikExecutor.pm` to log in and enrol TOTP through authentik's flow
executor. Without it the test skips. Three variables point at it:

| Variable | Default |
|---|---|
| `AIRLOCK_WWW_AUTHENTIK` | `~/dev/p5-www-authentik` |
| `AIRLOCK_WWW_AUTHENTIK_LIB` | `$AIRLOCK_WWW_AUTHENTIK/lib` |
| `AIRLOCK_AUTHENTIK_LIB` | `$AIRLOCK_WWW_AUTHENTIK/t/lib` |

Setting the first is enough unless the two directories live apart.

One run spends four requests on the device authorization endpoint, and authentik
throttles that endpoint to **20 an hour per client IP** — see the finding below.
The compose file next door sets `AUTHENTIK_THROTTLE__PROVIDERS__OAUTH2__DEVICE`
high enough; against an instance that does not, the fifth run within the hour
bails out and says so.

**Airlock does not depend on either at runtime.** Neither is in `cpanfile`, and
nothing under `lib/` mentions them. The executor is deliberately not copied in
here: the shape of a flow challenge belongs to authentik and changes with its
versions, a copy would drift unnoticed, and a distribution that ships no
provider code should not carry two hundred lines of one.

## Findings

authentik 2026.8.3, recorded 2026-10-04, through the whole chain.

| Login | acr | amr | auth_time |
|---|---|---|---|
| device flow, browser login, password | `goauthentik.io/providers/oauth2/default` | `pwd` | time of login |
| device flow, browser login, password + TOTP | the same | `pwd`, `mfa` | time of login |
| a second token from the same session | the same | unchanged | **the first login**, not the new token |
| a refreshed token | the same | unchanged | unchanged |

What the runs established:

- **authentik reports the second factor out of the box.** No mapper, no scope,
  no flow setting: a password login carries `amr=pwd`, a login with TOTP
  `amr=pwd,mfa`, and `Airlock::Factor::Upstream` tells them apart with its
  defaults. This is the difference to Keycloak, which says nothing until
  `t/keycloak/setup.pl` has run.
- **`acr` is one constant string** whatever happened, so `mfa_acr` stays empty
  in `Airlock::Upstream::Authentik`. Sending `acr_values` changes nothing.
- **`auth_time` is when the session began** for the grants Airlock meets — the
  authorization code and the device code both take it from the session's login
  event — and it survives a refresh and further authorization requests.
  `max_age` on the factor therefore measures the age of the authentication,
  which is what a caller wants: a token minted now from a ten-minute-old
  session is refused by `max_age => 300`. Two things it is not: for a
  client-credentials or token-exchange grant `auth_time` is the minting time
  (those carry no `amr`, so the factor refuses them anyway), and when authentik
  finds no login event for a session it falls back to the current time, which
  makes an old authentication look new. That last one fails open; it was read
  in authentik's source, not provoked here.
- **`max_age=0` is the one value authentik throws away**, because its check is
  on the truth of the number and zero is not true. Every other value works, and
  so does `prompt=login`. Measured against a session six seconds old:

  | sent | result |
  |---|---|
  | nothing | a code, no new login |
  | `max_age=0` | a code, no new login — what `Airlock::Factor::Upstream->reauth_params` sends |
  | `max_age=1`, `max_age=2` | sent back to log in |
  | `max_age=3600` | a code, the session is younger than that |
  | `prompt=login` | sent back to log in |

  `Airlock::Upstream::Authentik->reauth_params` gives what works.
- `Airlock::Client` completes a device flow against authentik: discovery, start,
  `authorization_pending` while waiting, and the token after the approval. The
  device response carries `verification_uri_complete`.
- A device code is approved by opening `/device?code=…` with a session, which
  redirects into the authorization flow; one run of that flow through the
  executor ends at `ak-provider-oauth2-device-code-finish` and the poll
  succeeds.
- **The device authorization endpoint is throttled, and says `slow_down`.**
  RFC 8628 gives `slow_down` to the token endpoint, for a client polling too
  fast. authentik also puts a rate limit on the authorization request that
  starts the flow: `throttle.providers.oauth2.device`, 20 an hour per client IP
  by default, answered as HTTP 429 with that same error code. A client cannot
  tell it from a polling complaint except by which request it answered. Raise
  `AUTHENTIK_THROTTLE__PROVIDERS__OAUTH2__DEVICE` on a test instance; in
  production note that every device behind one NAT address shares the bucket.
- **authentik refuses a TOTP code twice.** The executor waits for the next
  thirty-second window and submits again, so a run can take a minute.
- The brand needs a `flow_device_code`; without it `/device` has nothing to
  show.
