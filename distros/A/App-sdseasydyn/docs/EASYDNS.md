# Notes for EasyDNS users / EasyDNS team

This project provides a small command-line Dynamic DNS updater for EasyDNS.

## Endpoint used

This tool uses the classic EasyDNS Dynamic DNS update endpoint:

- `https://api.cp.easydns.com/dyn/generic.php?hostname=...&myip=...`

Authentication is performed via HTTP Basic Auth using your EasyDNS credentials/token.

## Behavior and safety

- The updater stores the last-known public IP in a state file and **skips** the EasyDNS update call when the IP is unchanged.
- Secrets are not printed in normal or verbose output.
- Retries transient network failures using `Retry::Policy` (exponential backoff + jitter).

## Quick start

- See `README.md` and `docs/HOWTO.md`
- Example config: `examples/config.ini`

