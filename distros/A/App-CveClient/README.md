# CVE-Client: CLI-based client / toolbox for CVE.org

Because why would you ever rely on someone else's clobbered together JavaScript code to get important security information.

## Dependencies
- Perl 5
- Getopt::Std (should be included in your perl)
- JSON::MaybeXS (should be included in your perl)
- LWP::UserAgent (should be included in your perl)
- LWP::Protocol::https

## Example
```
% cve-client CVE-2021-35197
CVE ID: CVE-2021-35197

Description Language: eng
Description:
In MediaWiki before 1.31.15, 1.32.x through 1.35.x before 1.35.3, and 1.36.x before 1.36.1, bots have certain unintended API access. When a bot account has a "sitewide block" applied, it is able to still "purge" pages through the MediaWiki Action API (which a "sitewide block" should have prevented).

Reference Source: MISC
- Name: https://phabricator.wikimedia.org/T280226
- URL: https://phabricator.wikimedia.org/T280226

Reference Source: CONFIRM
- Name: https://lists.wikimedia.org/hyperkitty/list/mediawiki-announce@lists.wikimedia.org/thread/YR3X4L2CPSEJVSY543AWEO65TD6APXHP/
- URL: https://lists.wikimedia.org/hyperkitty/list/mediawiki-announce@lists.wikimedia.org/thread/YR3X4L2CPSEJVSY543AWEO65TD6APXHP/

Reference Source: GENTOO
- Name: GLSA-202107-40
- URL: https://security.gentoo.org/glsa/202107-40
```
