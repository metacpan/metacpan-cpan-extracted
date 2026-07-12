This is the Security Policy for the Perl DBIO-DB2 distribution.

Report security issues via email to <getty@conflict.industries>.

This policy was updated on 2026-06-23.

If this policy or the release is more than two years old, then you
should check for a more recent version of
[DBIO-DB2 on CPAN](https://metacpan.org/dist/DBIO-DB2) or the main branch of the
[DBIO-DB2 git repository](https://codeberg.org/dbio/dbio-db2).

This text is based on the CPAN Security Group's Guidelines for Adding
a Security Policy to Perl Distributions (version 1.5.0)
https://security.metacpan.org/docs/guides/security-policy-for-authors.html

# How to Report a Security Vulnerability

Security vulnerabilities can be reported by e-mail to the current
project maintainer at <getty@conflict.industries>.

Please include as many details as possible, including code samples
or test cases, so that we can reproduce the issue. Check that your
report does not expose any sensitive data, such as passwords, tokens,
or personal information.

The maintainer will normally credit the reporter when a vulnerability
is disclosed or fixed. If you do not want to be credited publicly,
please indicate that in your report.

If you would like any help with triaging the issue, or if the issue is
being actively exploited, please copy the report to the CPAN Security
Group (CPANSec) at <cpan-security@security.metacpan.org>.

DBIO-DB2 is hosted on Codeberg, which does not support confidential issue
reporting. Please *do not* use the public Codeberg issue tracker, or
any other public forum, mailing list or RT queue, for reporting
security vulnerabilities.

Please do not disclose the security vulnerability in public until past
any proposed date for public disclosure, or it has been made public by
the maintainer or CPANSec. That includes patches or pull requests or
mitigation advice.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainer aims to acknowledge your security report as soon as
possible. However, this project is maintained by a single volunteer in
their spare time, and they cannot guarantee a rapid response. If you
have not received a response within a week, then please send a reminder
and copy the report to CPANSec at <cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information. It will
not necessarily include any fixes for the issue.

The maintainer may forward this issue to the security contacts for
other projects where it is believed to be relevant. This may include
embedded libraries, system libraries, prerequisite modules or
downstream software that uses this software.

They may also forward this issue to CPANSec.

# Which Software This Policy Applies To

Any security vulnerabilities in DBIO-DB2 are covered by this policy.

Security vulnerabilities are considered anything that allows users to
execute unauthorised code, access unauthorised resources, or to have an
adverse impact on accessibility, integrity or performance of a system.

Security vulnerabilities in upstream software (prerequisite modules or
system libraries, or in Perl), are not covered by this policy unless
they affect DBIO-DB2, or DBIO-DB2 can be used to exploit vulnerabilities in
them.

Security vulnerabilities in downstream software (any software that uses
DBIO-DB2, or plugins to it that are not included with the DBIO-DB2
distribution) are not covered by this policy.

## Supported Versions of DBIO-DB2

Only the latest release of DBIO-DB2 will be supported for security fixes.

Only major versions of Perl released in the past ten (10) years will be
supported, even when DBIO-DB2 will run on older versions of Perl. If a
security fix requires the maintainer to increase the minimum version of
Perl that is supported, then they may do so.

# Installation and Usage Issues

The distribution metadata specifies minimum versions of prerequisites
that are required for DBIO-DB2 to work. However, some of these
prerequisites may have security vulnerabilities, and you should ensure
that you are using up-to-date versions of these prerequisites.

Where security vulnerabilities are known, the metadata may indicate
newer versions as recommended.

## Usage

Please see the software documentation for further information.
