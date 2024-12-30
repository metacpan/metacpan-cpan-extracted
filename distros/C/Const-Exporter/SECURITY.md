This is the Security Policy for the Perl distribution Const-Exporter.

The latest version of this Security Policy can be found on
[MetaCPAN](https://metacpan.org/dist/Const-Exporter).

This text is based on the CPAN Security Group's
[Guidelines for Adding a Security Policy to Perl Distributions](https://security.metacpan.org/docs/guides/security-policy-for-authors.html)
(version 0.1.8).


# How to Report a Security Vulnerability

Security vulnerabilties can be reported by e-mail to the current
project maintainer(s) at <rrwo@cpan.org>.

Please include as many details as possible, including code samples
or test cases, so that we can reproduce the issue.

If you would like any help with triaging the issue, or if the issue
is being actively exploited, please copy the report to the CPAN
Security Group (CPANSec) at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue reporting system on RT or
GitHub issues for reporting security vulnerabilities.

Please do not disclose the security vulnerability in public forums
until past any proposed date for public disclosure, or it has been
made public by the maintainers or CPANSec.  That includes patches or
pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainer(s) aim to acknowledge your security report as soon as
possible.  However, this project is maintained by a single person in
their spare time, and they cannot guarantee a rapid response.  If you
have not received a response from the them within a week, then
please send a reminder to them and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information.  It
will not necessarily include any fixes for the issue.

The project maintainer(s) may forward this issue to the security
contacts for other projects where we believe it is relevant.  This
may include embedded libraries, system libraries, prerequisite
modules or downstream software that uses this software.

They may also forward this issue to CPANSec.

# What Software this Policy Applies to

Any security vulnerabilities in Const-Exporter are covered
by this policy.

Security vulnerabilities are considered anything that allows users
to execute unauthorised code, access unauthorised resources, or to
have an adverse impact on accessibility or performance of a system.

Security vulnerabilities in upstream software (embedded libraries,
prerequisite modules or system libraries, or in Perl), are not covered
by this policy unless they affect Const-Exporter, or
Const-Exporter can be used to exploit vulnerabilities in
them.

Security vulnerabilities in downstream software (any software that
uses Const-Exporter, or plugins to it that are not included
with the Const-Exporter distribution) are not covered by
this policy.

## Which Versions of this Software are Supported?

The maintainer(s) will only commit to releasing security fixes for the
latest version of Const-Exporter.

Note that the Const-Exporter project only supports major
versions of Perl released in the past ten (10) years, even though
Const-Exporter will run on older versions of Perl.  If a
security fix requires us to increase the minimum version of Perl that
is supported, then we may do that.

# Installation and Usage Issues

Please see the module documentation for more information.
