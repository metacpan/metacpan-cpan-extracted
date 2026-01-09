# sdseasydyn HOWTO

This guide covers setup, safe testing, cron usage, and troubleshooting.

## Secrets (recommended)

Export these environment variables:

- `EASYDNS_USER`
- `EASYDNS_TOKEN`

Example:

```bash
export EASYDNS_USER="your_user"
export EASYDNS_TOKEN="your_token"
```

Why: keeps tokens out of files and logs; works well with cron/systemd.

## Configuration file

Common path:

* `~/.config/sdseasydyn/config.ini`

Example:

```ini
[easydns]
username = ${EASYDNS_USER}
token    = ${EASYDNS_TOKEN}

[update]
hosts   = ddns-test.example.com
ip_url  = https://api.ipify.org
timeout = 10

[state]
path = ~/.local/state/sdseasydyn/last_ip
```

### Precedence

Config is resolved in this order:

* CLI > ENV > config file > defaults

## Safe testing (no WAN/IP disruption)

You can test “IP changed vs unchanged” without needing your real public IP to change.

Use:

* `--ip` to supply a test IP
* `--state` pointing to a throwaway file

Example:

```bash
rm -f /tmp/sdseasydyn.last_ip.test

perl -Ilib bin/sdseasydyn update \
  --dry-run \
  --host ddns-test.example.com \
  --state /tmp/sdseasydyn.last_ip.test \
  --ip 203.0.113.10 \
  -v
```

Then simulate “unchanged”:

```bash
printf "203.0.113.10\n" > /tmp/sdseasydyn.last_ip.test

perl -Ilib bin/sdseasydyn update \
  --dry-run \
  --host ddns-test.example.com \
  --state /tmp/sdseasydyn.last_ip.test \
  --ip 203.0.113.10 \
  -v
```

## Real update

```bash
perl -Ilib bin/sdseasydyn update --host yourhost.example.com -v
```

## Cron example

Every 10 minutes:

```cron
*/10 * * * * EASYDNS_USER=your_user EASYDNS_TOKEN=your_token /usr/bin/perl -I/home/you/code/sdseasydyn/lib /home/you/code/sdseasydyn/bin/sdseasydyn update --host yourhost.example.com >> /home/you/.cache/sdseasydyn.log 2>&1
```

Tip: prefer a dedicated test hostname (e.g. `ddns-test.yourdomain.com`) while validating behavior.

## Exit codes

* `0` success (including “IP unchanged”)
* `2` usage/config error
* `3` auth/permission failure
* `4` transient failure (network/IP discovery)
* `5` provider/policy failure (`TOOSOON`, `NOSERVICE`, `ILLEGAL`, unknown)

## Troubleshooting

### “Missing EasyDNS token”

Set `EASYDNS_TOKEN` in your environment (or in cron), and ensure your config uses `${EASYDNS_TOKEN}`.

### “Could not determine public IPv4 address”

Try:

* `--ip` for testing
* or set `ip_url` to a reachable service and increase `timeout`.

### Too frequent updates / `TOOSOON`

This tool stores the last IP and avoids calling EasyDNS if unchanged.
If you delete the state file frequently, it will “forget” and call again.

