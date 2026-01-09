# sdseasydyn

`sdseasydyn` is a small, CLI-first Dynamic DNS updater for the
[EasyDNS](https://www.easydns.com/) service.

It is designed to be safe for cron usage, avoid unnecessary updates,
and behave predictably under transient network conditions.

The project is implemented in modern Perl and is distributed on CPAN
as `App::sdseasydyn`.

---

## Features

- Simple CLI interface (`sdseasydyn update`)
- Clear configuration precedence: CLI > environment > config file > defaults
- Secure handling of credentials (tokens are never logged)
- Public IPv4 discovery with configurable endpoint
- Local state file to avoid redundant updates
- Bounded retry logic using `Retry::Policy`
- Suitable for unattended / scheduled execution

---

## Quick start

sdseasydyn update --host example.easydns.net

Credentials are provided via environment variables:

export EASYDNS_USER=your_username
export EASYDNS_TOKEN=your_token

See `docs/EASYDNS.md` and `docs/HOWTO.md` for full configuration details.

---

## Relationship to EasyDNS

This project is an independent, community-maintained tool and is not
affiliated with, endorsed by, or officially supported by EasyDNS
Technologies.

It uses the publicly documented EasyDNS Dynamic DNS update endpoint and
is provided as-is under the terms of its open-source license.

---

## Documentation

- `docs/EASYDNS.md` — EasyDNS-specific behavior and notes
- `docs/HOWTO.md` — usage and configuration guide
- `SECURITY.md` — security considerations

---

## License

This project is licensed under the GNU Lesser General Public License
version 2.1 (LGPL-2.1). See the `LICENSE` file for details.

---

## Author

Sergio de Sousa  
<sergio@serso.com>
