# Security policy for Crypt-TimestampedData

This document is the security policy for the CPAN distribution **Crypt-TimestampedData**
(`Crypt::TimestampedData` on [CPAN](https://metacpan.org/dist/Crypt-TimestampedData)).
Report security issues privately to the contact below; do not use public bug trackers for
initial disclosure of vulnerabilities.

## How to report a security vulnerability

Send reports **only** to the current maintainer at:

**[gdo@leader.it](mailto:gdo@leader.it)**

Include as much detail as needed to reproduce the issue (proof-of-concept code or steps,
affected version, and any relevant logs or excerpts). Do **not** include secrets, passwords,
tokens, or personal data in your report.

**Do not** disclose the vulnerability in public channels (issue trackers, pull requests,
mailing lists, forums, or social media) until coordinated disclosure has been agreed.

If you would like help with triaging, CVE coordination, or if the maintainer appears
unreachable, you may **copy** the [CPAN Security Group (CPANSec)](https://security.metacpan.org/)
at **[cpan-security@security.metacpan.org](mailto:cpan-security@security.metacpan.org)**.
See also [How to Report a Security Issue](https://security.metacpan.org/docs/report.html).

Maintainers will normally credit reporters when a vulnerability is fixed or disclosed.
If you do not want public credit, say so in your report.

## What to expect

The first reply will typically be an **acknowledgement** and may ask for more information.
It does **not** mean a fix is already available.

The maintainer aims to acknowledge valid reports **within 72 hours**. This project is
maintained voluntarily; if you have not received a response within **one week**, please
send a reminder to the maintainer and consider copying
**[cpan-security@security.metacpan.org](mailto:cpan-security@security.metacpan.org)** so
CPANSec can help coordinate.

The maintainer may forward relevant information to security contacts of dependent
projects, upstream libraries, or CPANSec when appropriate.

## What this policy applies to

**In scope:** security vulnerabilities in this distribution’s code and bundled documentation
that affect confidentiality, integrity, or availability when using **Crypt-TimestampedData** as
documented (e.g. unexpected code execution, path or parsing issues with security impact,
or incorrect handling of untrusted input that leads to a vulnerability in this library).

**Out of scope (unless they directly affect this distribution):** vulnerabilities only in
the Perl interpreter, in **Convert::ASN1**, or in other prerequisites; misuse of the API;
and issues in downstream or third-party software that uses this module. Reports about
upstream components may be forwarded or referred to the appropriate project.

### Supported versions for security fixes

Security fixes are provided for the **latest stable release** of **Crypt-TimestampedData**
published on CPAN. Older releases may not receive backports. Use the current release when
possible.

## Basis for this policy

This text follows the structure recommended in the
[Guidelines for Adding a Security Policy to Perl Distributions](https://security.metacpan.org/docs/guides/security-policy-for-authors.html)
by the [CPAN Security Group](https://security.metacpan.org/).
