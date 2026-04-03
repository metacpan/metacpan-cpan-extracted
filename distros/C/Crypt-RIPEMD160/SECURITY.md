# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Crypt-RIPEMD160, please report it
responsibly.

**Contact:** Todd Rinaldo (TODDR) <toddr@cpan.org>

You can also open a security advisory on GitHub:
https://github.com/cpan-authors/Crypt-RIPEMD160/security/advisories/new

Please do **not** open a public GitHub issue for security vulnerabilities.

## Supported Versions

Only the latest release on CPAN is supported with security fixes.

## Note on RIPEMD-160

RIPEMD-160 is a legacy hash function. While no practical collision attacks
are known, it provides only 80-bit collision resistance. For new applications,
consider using SHA-256 or SHA-3 instead. This module is maintained for
backward compatibility with existing systems.
