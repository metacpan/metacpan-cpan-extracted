# Changes file for Date-Holidays

## 1.35 2023-08-16 Maintenance release, update not required

- Merged PR [#113](https://github.com/jonasbn/perl-date-holidays/pull/113) by @haarg. Removing unused explicit imports, where error handling will change in the future, so this is a preemptive change

## 1.34 2022-10-10 Bug fix release, update not required

- Specified requirement for [Test::MockModule](https://metacpan.org/pod/Test::MockModule) as `0.13`, when migrating to use of a `cpanfile` for dependency specification, I forgot to specify the version even though it was specified in the Dist::Zilla configuration `dist.ini`, thanks to @eserte for spotting this. It is actually a regression in that sense that it was also fixed in [#47](https://github.com/jonasbn/Date-Holidays/issues/47). This addresses [#76](https://github.com/jonasbn/Date-Holidays/issues/76)

- Added missing adapter [Date::Holidays::Adapter::CA](https://metacpan.org/pod/Date::Holidays::Adapter::CA) for [Date::Holidays::CA](https://metacpan.org/pod/Date::Holidays::CA)

- Commented out some problematic and noisy tests, which require some additional work

## 1.33 2022-10-04 Feature release, update not required

- Further improvement to the handling of the parameters required by:

  - [Date::Holidays::NL](https://metacpan.org/pod/Date::Holidays::NL) via [Date::Holidays::Adapter::NL](https://metacpan.org/pod/Date::Holidays::Adapter::NL)
  - [Date::Holidays::AW](https://metacpan.org/pod/Date::Holidays::AW) via [Date::Holidays::Adapter::AW](https://metacpan.org/pod/Date::Holidays::Adapter::AW)
  - [Date::Holidays::BQ](https://metacpan.org/pod/Date::Holidays::BQ) via [Date::Holidays::Adapter::BQ](https://metacpan.org/pod/Date::Holidays::Adapter::BQ)

  The `gov` and `lang` parameters can now be used in conjunction with the country list parameter

- Exchanged [TryCatch](https://metacpan.org/pod/TryCatch) for [Try::Tiny](https://metacpan.org/pod/Try::Tiny)

## 1.32 2022-10-03 Feature release, update not required

- Introduction of [Date::Holidays::Adapter::BQ](https://metacpan.org/pod/Date::Holidays::Adapter::BQ) for adapting [Date::Holidays::BQ](https://metacpan.org/pod/Data::Holidays::BQ)

- Support for extra parameters for `is_holiday` and `is_holiday_dt`:

  - [Date::Holidays::NL](https://metacpan.org/pod/Date::Holidays::NL) via [Date::Holidays::Adapter::NL](https://metacpan.org/pod/Date::Holidays::Adapter::NL)
  - [Date::Holidays::AW](https://metacpan.org/pod/Date::Holidays::AW) via [Date::Holidays::Adapter::AW](https://metacpan.org/pod/Date::Holidays::Adapter::AW)
  - [Date::Holidays::BQ](https://metacpan.org/pod/Date::Holidays::BQ) via [Date::Holidays::Adapter::BQ](https://metacpan.org/pod/Date::Holidays::Adapter::BQ)

  All via PR [#70](https://github.com/jonasbn/perl-date-holidays/pull/70) by Wesley Schwengle (@waterkip) author of:

  - [Date::Holidays::AW](https://metacpan.org/pod/Date::Holidays::AW)
  - [Date::Holidays::BQ](https://metacpan.org/pod/Date::Holidays::BQ)
  - [Date::Holidays::NL](https://metacpan.org/pod/Date::Holidays::NL)

- Fixed and clean up to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) configuration by @jonasbn

## 1.31 2022-03-08 Feature release, update not required

- Improved support for [Date::Holidays::FR](https://metacpan.org/pod/Date::Holidays::FR)

## 1.30 2022-03-01 Bug fix release, update not required

- PR from @qorron [#53](https://github.com/jonasbn/Date-Holidays/pull/53) fixes issue with initialization of US calendar via the adapter. The official calendar module is called: [Date::Holidays::USFederal](https://metacpan.org/pod/Date::Holidays::USFederal).

## 1.29 2020-11-13 Maintenance release, update not required

- Added contribution guidelines for meta.cpan.org

## 1.28 2020-11-11 Maintenance release, update not required

- We need to specify the requirement of [Test::MockModule](https://metacpan.org/pod/Test::MockModule) to version 0.13, since redefined not introduced until this version

## 1.27 2020-11-09 Bug fix release, update recommended

- Fixed a bug in the mock introduced in release 1.27. Had added it to the `cpanfile`, but not the proper prerequisites and the mocking was not correct syntax

- Made adjustments to the tar-ball generation, way to much non-distribution related material included

## 1.26 2020-11-09 Bug fix release, update not required

- I am implementing an example application and I came across a minor bug in the adapter for [Date::Holidays::SK](https://metacpan.org/pod/Date::Holidays::SK). Reported as issue [#45](https://github.com/jonasbn/Date-Holidays/issue/45)

## 1.25 2020-09-27 Maintenance release, update recommended

- Introduced some issues with references and test suite for the new addition [Date::Holidays::AW](https://metacpan.org/pod/Date::Holidays::AW)

Thanks to Wesley Schwengle for the PR

## 1.24 2020-09-26 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::AW](https://metacpan.org/pod/Date::Holidays::AW) (Aruba)

- Added adapter for:
    [Date::Holidays::NL](https://metacpan.org/pod/Date::Holidays::NL) (Netherlands)

Thanks to Wesley Schwengle for mentioning his CPAN contributions to the Date::Holidays::* namespace

## 1.23 2020-07-02 Maintenance release, update not required

- Improvements to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) configuration, only [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) supported via [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) now. [Module::Build](https://metacpan.org/pod/Module::Build) support having been removed

- See [the article](https://neilb.org/2015-05-18/two-build-files-considered-harmful.html) by Neil Bowers (NEILB) on the topic

- Thanks to Karen Etheridge (ETHER) for information and link to the mentioned article

## 1.22 2020-06-13 Bug fix release, update recommended

- Addressed broken support for regions in ES (Spain), improving support for [Date::Holidays::CA_ES](https://metacpan.org/pod/Date::Holidays::CA_ES)
  Thanks to Miquel Ruiz

## 1.21 2020-04-22 Bug fix release, update not required

- Addressed a minor bug in the test suite addressed with release 1.19, [Date::Holidays::UA](https://metacpan.org/pod/Date::Holidays::UA) supports a holidays method

## 1.20 2020-04-21 Bug fix release, update recommended

- A bug was introduced with the release of 1.19, the bug had been lurking since just after the release of 1.18. The bug did not show itself unless adaptees where installed and I tested release 1.19 on a branch new Perlbrew installation, so the bug was not demonstrated.

## 1.19 2020-04-20 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::UA](https://metacpan.org/pod/Date::Holidays::UA) added to the distribution thanks to Denis Boyun

    Ref: PR [#38](https://github.com/jonasbn/perl-date-holidays/pull/38)

    Also fixed a minor bug the documentation, my bumping of the version numbers across the files in the distribution had altered a parameter description. Apparently this had not caught my eye until now.

## 1.18 2019-01-23 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::AT](https://metacpan.org/pod/Date::Holidays::AT)(Austria) we now support the state parameter for this distribution

    Ref: PR [#33](https://github.com/jonasbn/Date-Holidays/pull/33)

## 1.17 2019-01-22 Feature release, update recommended

- Improved adapter for:
    [Date::Holidays::DE](https://metacpan.org/pod/Date::Holidays::DE) we now support the state parameter for this distribution

    Ref: PR [#31](https://github.com/jonasbn/Date-Holidays/pull/31)

## 1.16 2018-06-17 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::CZ](https://metacpan.org/pod/Date::Holidays::CZ) the distribution had some issue with building
    these issue seems to have been fixed

    Ref: PR [#30](https://github.com/jonasbn/Date-Holidays/pull/30)

## 1.15 2018-06-16 Feature release, update recommended

- Added implementation of `is_holiday` method for [Date::Holidays::DE](https://metacpan.org/pod/Date::Holidays::DE)

  Ref: PR [#18](https://github.com/jonasbn/perl-date-holidays/pull/18)

- Changed the structure returned from [Date::Holidays::DE](https://metacpan.org/pod/Date::Holidays::DE) from a
  reference to an array to a reference to a hash, which is easier to work with and seems to be the de facto standard

  This is all done in the adapter.

  Ref: PR [#29](https://github.com/jonasbn/perl-date-holidays/pull/29)

## 1.14 2018-06-14 Feature release, update recommended

- [Date::Holidays::UK](https://metacpan.org/pod/Date::Holidays::UK) marked as unsupported

- [Date::Holidays::UK::EnglandAndWales](https://metacpan.org/pod/Date::Holidays::UK::EnglandAndWales) marked as unsupported

  Ref: PR [#11](https://github.com/jonasbn/perl-date-holidays/pull/11)

- Addressed issue with support for country code UK. This is done with the
  adapter [Date::Holidays::Adapter::UK](https://metacpan.org/pod/Date::Holidays::Adapter::UK), which uses [Date::Holidays::GB](https://metacpan.org/pod/Date::Holidays::GB) via
  [Date::Holidays::Adapter::GB](https://metacpan.org/pod/Date::Holidays::Adapter::GB).

  Ref: PR [#14](https://github.com/jonasbn/perl-date-holidays/pull/14)

## 1.13 2018-06-12 Feature release, update recommended

- This release integrates [Date::Holidays::CA_ES](https://metacpan.org/pod/Date::Holidays::CA_ES) is does so
  by supporting the region parameter with the value 'ca' via
  [Date::Holidays::ES](https://metacpan.org/pod/Date::Holidays::ES)

  Ref: PR [#28](https://github.com/jonasbn/Date-Holidays/pull/28)

## 1.12 2018-06-05 Feature release, update recommended

- Added adapter for US, an implementation adapting Date::Holidays::USFederal
  but for the official and standard country code

  Ref: PR [#27](https://github.com/jonasbn/Date-Holidays/pull/27)

## 1.11 2018-06-01 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::SK](https://metacpan.org/pod/Date::Holidays::SK) the integration had some flaws, which have now been
    addressed with the new adapter

    Ref: PR [#23](https://github.com/jonasbn/Date-Holidays/pull/23)

## 1.10 2018-05-31 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::NZ](https://metacpan.org/pod/Date::Holidays::NZ) the distribution has been supported for some time,
    but the latest changes revealed a sub-optimal integration. Support
    for regions was also added

    Ref: PR [#22](https://github.com/jonasbn/Date-Holidays/pull/22)

## 1.09 2018-05-30 Bug fix release, update not required

- Based on issue #21 several issues with the test suite was spotted
  and corrected, at the same time there was created issues for
  implementation of adapters for SK and NZ. An issue with ES was also
  created since this distribution seems to rely on Date::Holidays,
  which does not seem to make sense.

  Ref: PR [#21](https://github.com/jonasbn/Date-Holidays/pull/21)

## 1.08 2018-05-28 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::USFederal](https://metacpan.org/pod/Date::Holidays::USFederal) (US) in response to request from
    Scott Seller. This required a lot of changes to internal code and the test
    suite was restructured. I hope I did not break anything, all tests pass currently.

## 1.07 2017-12-10 Feature release, update recommended

- Added adapter for:
    [Date::Holidays::KZ](https://metacpan.org/pod/Date::Holidays::KZ) (Kazakhstan) via patch from Vladimir Varlamov

## 1.06 2017-05-31 Maintenance release, update not required

- Added use of [Test::Fatal](https://metacpan.org/pod/Test::Fatal)

- Added homepage metadata and changed GitHub URL

- Added [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugins requirements causing issues to `dist.ini`, so these
  are explicitly specified

- Exchanged CJM´s:
  [Dist::Zilla::Plugin::VersionFromModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromModule)

  For Dave Rolskys:
  [Dist::Zilla::Plugin::VersionFromMainModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromMainModule)

  There are some deprecation notices from [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) making tests fail
  see XDG's [PR](https://github.com/madsen/dist-zilla-plugins-cjm/pull/5)

## 1.05 2017-05-31 Bug fix release, update not required

- Addressed GitHub issue [#10](https://github.com/jonasbn/Date-Holidays/issues/10) reported by Alexandr Ciornii (CHORNY)
  `carton` generated directory `local/` was included in distribution by accident

## 1.04 2017-05-30 Feature release, update not required

- Added adapter for:
    [Date::Holidays::BY](https://metacpan.org/pod/Date::Holidays::BY) (Belarus) via patch from Vladimir Varlamov

## 1.03 2015-08-10 bug fix release, update not required

- Following up on some TODO points in the code, probably in relation to: [RT:101366](https://rt.cpan.org/Ticket/Display.html?id=101366)

## 1.02 2015-08-03 Maintenance release, update not required

- Aligned version numbers in Perl components in `lib/`

- Added missing version in [Date::Holidays::Adapter::LOCAL](https://metacpan.org/pod/Date::Holidays::Adapter::LOCAL)

- Added `MetaProvides` to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) build, this should assist in addressing
  the issue listed on CPANTS

  Ref: [Date-Holidays-1.01](http://cpants.cpanauthors.org/dist/Date-Holidays-1.01)

## 1.01 2015-01-31 Feature release, update not required

- Added adapter for:
    [Date::Holidays::RU](https://metacpan.org/pod/Date::Holidays::RU) via patch from Alexander Nalobin

## 1.00 2014-09-18 Major release, update recommended

- License upgraded from Artistic License 1.0 to Artistic License 2.0

- You can now overwrite calendars with a local file, see issue [#6](https://github.com/jonasbn/Date-Holidays/issues/6)

- Use of [Error](https://metacpan.org/pod/Error) has been removed

- Use of `can` from [UNIVERSAL](https://metacpan.org/pod/UNIVERSAL) had been changed to more contemporary
  pattern

- Adapter strategy has also been changed so adapters have precedence
  over adapted implementations

## 0.22 2014-09-15 bug fix release, update not required

- Addressing issue [#7](https://github.com/jonasbn/Date-Holidays/issues/7)

  This is bug in the tests suite generating reports on failures from CPAN testers.

## 0.21 2014-08-30 bug fix/feature release, update recommended

- Added adapter for:
    [Date::Holidays::GB](https://metacpan.org/pod/Date::Holidays::GB) addressing GitHub issue [#4](https://github.com/jonasbn/Date-Holidays/issues/4)

    [Date::Holidays::GB](https://metacpan.org/pod/Date::Holidays::GB) exposes new parameter: regions, for local countries under GB.

- Fixed bug in countries parameter handling

## 0.20 2014-08-30 bug fix/feature release, update recommended

- Fixed bug in [Date::Holidays::Adapter::FR](https://metacpan.org/pod/Date::Holidays::Adapter::FR), which wrongfully reported
  lack of implementation of is_holidays method when it was the holidays method - error being thrown upon call to holidays methods

- Added adapters for:
    [Date::Holidays::CN](https://metacpan.org/pod/Date::Holidays::CN)
    [Date::Holidays::KR](https://metacpan.org/pod/Date::Holidays::KR)
    [Date::Holidays::PL](https://metacpan.org/pod/Date::Holidays::PL)

  Addressing GitHub issue [#5](https://github.com/jonasbn/Date-Holidays/issues/5)

- First shot at improvement of [Date::Holidays::Adapter](https://metacpan.org/pod/Date::Holidays::Adapter) code, this needs more work

- Improvements to the test suite, this also needs additional work

- Introducing use of [Scalar::Util](https://metacpan.org/pod/Scalar::Util)

## 0.19 2014-08-27 bug fix release, update not required

- This release addressed reports on failing tests for perl 5.21
  The use in this distribution of [UNIVERSAL](https://metacpan.org/pod/UNIVERSEL) is now deprecated,
  see: GitHub issue [#3](https://github.com/jonasbn/Date-Holidays/issues/3) and RT:98337

## 0.18 2014-08-24 feature release, update not required

- Added adapter class for [Date::Holidays::BR](https://metacpan.org/pod/Date::Holidays::BR) (RT:63437)

## 0.17 2014-08-22 maintenance release, update not required

- Migrated from [Module::Build](https://metacpan.org/pod/Module::Build) to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

- Fixed issue in some test, which would break if [Date::Holidays::DK](https://metacpan.org/pod/Date::Holidays::DK)
  was not installed

## 0.16 2014-08-18 maintenance release, update not required

- Fixed POD error

- Aligned all version numbers

- Added `t/kwalitee.t` [Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee) test

- Added `t/changes.t` [Test::CPAN::Changes](https://metacpan.org/pod/Test::CPAN::Changes) test

## 0.15 2007-03-13 maintenance release, update not required

- Added `t/perlcriticrc`

- Updated `t/critic.t` to more contemporary version

## 0.14 2007-03-12 maintenance release, update not required

- Added the following (again) to `MANIFEST` as a result of the [Kwalitee](https://metacpan.org/pod/Test::Kwalitee) test:

  - `t/pod.t`
  - `t/pod-coverage.t`

  These had been removed from the distribution, but the [Kwalitee](https://metacpan.org/pod/Test::Kwalitee)
  metrics likes them so, they are however not run as part of the
  normal test suite unless `$TEST_POD` is set in your environment.

## 0.13 2007-03-07 maintenance release, update not required

- Fixed broken tests
  
  - `t/new.t` did not have a `SKIP` section
  - `t/datetime.t` did not have a `SKIP` section

## 0.12 2007-03-05 maintenance release, update not required

- Fixed a problem with `pod.t`

- Increased the [Perl::Critic](https://metacpan.org/pod/Perl::Critic) severity to `5`

- Exchanged [Readonly](https://metacpan.org/pod/Readonly) for good old constants, one less dependency, should make the failing tests go away

## 0.11 2007-02-25 maintenance release, update not required

- Added missing requirement to `Build.PL` [Readonly](https://metacpan.org/pod/Readonly)
  Based on tests reports from CPAN testers

  Thanks david at cantrell.org.uk

  I thought [Readonly](https://metacpan.org/pod/Readonly) was core, but according to [Module::CoreList](https://metacpan.org/pod/Module::CoreList) this
  is not the case, so this has been corrected now

- Updated to more contemporary versions of:
  
  - `t/pod-coverage.t`
  - `t/pod.t`

  These should be there for the quality, but will not be run as a part
  of the normal test run, unless the `$TEST_POD` environment variable is
  set.

  This seem to be the de facto way of doing things. So they have been removed from `MANIFEST.SKIP` so they are now a part of the distribution.

## 0.10 2007-02-22 feature release, update not required

- Updated and corrected POD in [Date::Holidays](https://metacpan.org/pod/Date::Holidays)

- Updated and corrected POD in [Date::Holidays::Adapter](https://metacpan.org/pod/Date::Holidays::Adapter)

- Added `$VERSION` to all exception classes
  (Date::Holidays::Exception::*), I and who just file an RT ticket on
  the same issue for another distribution

  oh the sweet nemesis :)

- Updated POD in all exception classes (Date::Holidays::Exception::*)

- Updated POD in [Date::Holidays::Adapter::AU](https://metacpan.org/pod/Date::Holidays::Adapter::AU)

- Updated POD in [Date::Holidays::Adapter::GB](https://metacpan.org/pod/Date::Holidays::Adapter::GB)

- Updated POD in [Date::Holidays::Adapter::PT](https://metacpan.org/pod/Date::Holidays::Adapter::PT)

- Updated POD in [Date::Holidays::Adapter::NO](https://metacpan.org/pod/Date::Holidays::Adapter::NO)

- Updated POD in [Date::Holidays::Adapter::DK](https://metacpan.org/pod/Date::Holidays::Adapter::DK)

- Updated POD in [Date::Holidays::Adapter::FR](https://metacpan.org/pod/Date::Holidays::Adapter::FR)

- Updated POD in [Date::Holidays::Adapter::DE](https://metacpan.org/pod/Date::Holidays::Adapter::DE)

- Updated POD in [Date::Holidays::Adapter::JP](https://metacpan.org/pod/Date::Holidays::Adapter::JP)

- Added new adapter for [Date::Holidays::Adapter::ES](https://metacpan.org/pod/Date::Holidays::Adapter::ES)
  `lib/Date/Holidays/Adapter/ES.pm`

- Added use of exceptions instead of carp in Date::Holidays::Adapter,
  this however produces issues with adhering to Perl::Critics
  recommendation on explicit returns. Be aware that return with in
  Error's try-catch block returns from a sub, so you have to have a
  return outside the block.

 [Perl::Critic](https://metacpan.org/pod/Perl::Critic) is happy and I am happy

  Updated version to 0.02 for [Date::Holidays::Adapter](https://metacpan.org/pod/Date::Holidays::Adapter)

## 0.09 2007-02-21 feature release update recommended

- Added no_indexing of `t/` directory to Build.PL

- Updated README with pod2text appending of [Date::Holidays](https://metacpan.org/pod/Date::Holidays) POD

- Code cleaned a bit, much work still to be done

- Wrote some better DIAGNOSTICS and added 3 more Exceptions

  - `lib/Date/Holidays/Exception/InvalidCountryCode.pm`
  - `lib/Date/Holidays/Exception/NoCountrySpecified.pm`
  - `lib/Date/Holidays/Exception/UnsupportedMethod.pm`

- Added a few tests adapters for some of the tests dating before the refactoring (all tests now pass):
  
  - `t/lib/Date/Holidays/Adapter/NOPOLY.t`
  - `t/lib/Date/Holidays/Adapter/OOP.t`

- Renamed `_loader` in [Date::Holidays](https://metacpan.org/pod/Date::Holidays) to `_fetch` and `_load`, see also the
  similar methods in [Date::Holidays::Adapter](https://metacpan.org/pod/Date::Holidays::Adapter)

    `_loader.t` obsolete and removed

- Introduced use of Error (Exceptions) for better diagnostics:
  
  - `Date/Holidays/Exception/AdapterInitialization.pm`
  - `Date/Holidays/Exception/AdapterLoad.pm`
  - `Date/Holidays/Exception/SuperAdapterLoad.pm`

- Refactored the whole thing to a variation of an object adapter
  pattern, introduced:

    lib/Date/Holidays/Adapter.pm
    lib/Date/Holidays/Adapter/
    lib/Date/Holidays/Adapter/AU.pm
    lib/Date/Holidays/Adapter/DE.pm
    lib/Date/Holidays/Adapter/DK.pm
    lib/Date/Holidays/Adapter/FR.pm
    lib/Date/Holidays/Adapter/GB.pm
    lib/Date/Holidays/Adapter/JP.pm
    lib/Date/Holidays/Adapter/NO.pm
    lib/Date/Holidays/Adapter/PT.pm

  tests are located in t/Adapter:
    _fetch.t
    _load.t
    new.t

- Set severity to 3 for [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) test
  ran code through `perltidy` to remove hard tabs

- Set severity to 4 for [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) test
  added use warnings statement

- Changed the constructor to no longer be able to initialize a shallow
  object. If you want to make use of [Date::Holidays](https://metacpan.org/pod/Date::Holidays) ability to check
  all countries for a given holiday please, use it using full namespace.
  POD updated correspondingly.

- Addressed issue with method calling problems, OOP vs. Procedural vs.
  the weird mix I personally had boiled up, thanks to Florian Merges
  for reporting this.

  This has resulted in a minor cleanup and again I can see that the
  current architecture is not optimal, I am planning a major rewrite,
  to eliminate the problems of handling new classes introduced in the
  Date::Holidays::* namespace.

  I am not an authority of any kind, I just attempt to get things to
  play along nicely.

  New files introduced:
    `t/NOPOLY.t`
    `t/OOP.t`
    `t/SUPERED.t`
    `t/ABSTRACTED.t`
    `t/PRODUCERAL.t`
    `t/new.t`

  and the test classes (in t/lib/Date/Holidays):
    `ABSTRACTED.pm`
    `NOPOLY.pm`
    `OOP.pm`
    `PROCUDERAL.pm`
    `SUPERED.pm`

- Updated `MANIFEST.SKIP` with more contemporary version

- Added `t/critic.t`, [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) test, currently at severity `5`.
  In addition to this I changed the return of `undef` scattered all over
  the code to simple return statements.

- Added `t/kwalitee.t`, [Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee) test, disabled check for symlinks
  since it reacted on symlinked `.releaserc` in directory, which however
  is NOT in the distribution even though it thinks so

  Added the following as a result of the [Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee) test:
  - `t/pod.t`
  - `t/pod-coverage.t`

- Added use of [Module::Load](https://metacpan.org/pod/Module::Load) to `Build.PL` and to own `_loader` routine in
  Date::Holidays. I also added:
    `t/_loader.t` to isolate the actual test

## 0.08 2006-09-06 Bug fix release, update recommended

- Added RT request #21089, helper scripts not part of distribution, but
  mentioned in the auto-generated `Makefile.PL`

  Renamed `bin/` directory to `scripts/`

## 0.07 2006-08-02 bug fix release, update recommended

- Removed `bin/` directory from distribution (it is development purpose
  only anyway)

- Removed `t/pod.t` (and prerequisites in `Build.PL`) this test can be
  performed by Module::Build

- Removed `t/pod-coverage.t` (and prerequisites in `Build.PL`) this test
  can be performed by Module::Build

- Updated TODO with new point

- Changed way `Makefile.PL` is generated from 'passthrough' to 'traditional', I kind of like the way it is done in Workflow, so I adapted this

- Fixed a bug in program flow concerning [Date::Holidays::DE](https://metacpan.org/pod/Date::Holidays::DE)

- Fixed a test holding a wrong number of tests to be skipped

- Updated POD, added [Date::Holidays::CN](https://metacpan.org/pod/Date::Holidays::CN) to SEE ALSO section (no work
  done to implement this at this time

- Updated POD with TEST COVERAGE section, planning next release to be a maintenance release focused on test coverage

  Also in an attempt to address [report](http://www.nntp.perl.org/group/perl.cpan.testers/276637) on failing tests

## 0.06 2005-12-17 Feature release, update recommended

- Moved build requirements to special section in `Build.PL`

- Added AU and NZ to `bin/test_date-holidays.t`

- Updated `MANIFEST.SKIP` with:
  - Komodo project file
  - [Module::Build](https://metacpan.org/pod/Module::Build) parameters mentioned in [Module::Signature](https://metacpan.org/pod/Module::Signature)

- Signed module using [Module::Signature](https://metacpan.org/pod/Module::Signature), added:
  - `t/0-signature.t`
  - `SIGNATURE`

- Parameter 'state' also added for holidays method, have sent patch to
  David Dick author of [Date::Holidays::AU](https://metacpan.org/pod/Date::Holidays::AU) offering a more flexible API.

- Added some more POD on developing in the Date::Holidays::* namespace

- [Date::Holidays::AU](https://metacpan.org/pod/Date::Holidays::AU) have been updated to 0.03, meaning that the exception
  implemented in 0.05 could be removed, it was however changed to accommodate
  the state parameter implemented in [Date::Holidays::AU](https://metacpan.org/pod/Date::Holidays::AU).

- Exchanged manually built `Makefile.PL` for a `Makefile.PL` maintained by
  [Module::Build](https://metacpan.org/pod/Module::Build)

## 0.05 2005-12-09 bug fix release, update recommended

- Addressing [failing test](http://www.nntp.perl.org/group/perl.cpan.testers/262252)
  
  So we have added yet another exception, this time for [Date::Holidays::AU](https://metacpan.org/pod/Date::Holidays::AU).

  The problem is that its method is_holiday, needs an additional parameter
  indicating the state, the holidays method in the same module defaults
  to VIC, so for know we are using this as our default state, this will need
  readdressing.

## 0.04 2005-10-22 maintenance release, update not required

- Changes to unit-tests, it was assumed that some of the [Date::Holidays](https://metacpan.org/pod/Date::Holidays)
  modules where installed, this is not always the case

  This was pointed out to me by shild on [use.perl.org](http://use.perl.org/comments.pl?sid=28993&cid=43889)

## 0.03 2006-10-13 feature release, update recommended

- Small refactoring added new sub `_check_countries`

- Moved portuguese exception, [Date::Holiday::PT](https://metacpan.org/pod/Date::Holiday::PT) has changed name to
  [Date::Holidays::PT](https://metacpan.org/pod/Date::Holidays::PT), but it has turned OOP.

- Implemented new parameter in `is_holiday` (countries). This method
  returns a list of country codes having the holiday specified as a
  holiday for the respective country (suggested by cog).

  So it has to be used in conjunction with the data parameters: year, month and day

  if given a subset of countries only these countries are tested and a
  hashref is returned pointing where the countries codes are the keys
  and the values indicate true or false for the date specified.

  The values are:

  - `undef` if the country has no module or the data could not be obtained
  - a name of the holiday if a holiday is present
  - an empty string if the a module was located but the day is not a
  holiday

- Updated `INSTALL`

- Removed [Exporter](https://metacpan.org/pod/Exporter) from prerequisites

- Replaced use of [ExtUtils::Makemake](https://metacpan.org/pod/ExtUtils::Makemake) with [Module::Build](https://metacpan.org/pod/Module::Build)

- Added real names to Changes file (this file)

- Added suggestion on improvements from cog (Jose Castro) to TODO

## 0.02 2004-05-31 feature release, update not required

- Indented code in POD after tip from RJBS (Ricardo Signes)

- 'jp' left out of the test suite for now

- [Date::Holidays::NO](https://metacpan.org/pod/Date::Holidays::NO) added to test suite, courtesy of MRAMBERG (Marcus
  Ramberg)

- Added experimental subs using [DateTime](https://metacpan.org/pod/DateTime) objects as suggested by BORUP
  (Christian Borup) (SEE: TODO)

## 0.01 2004-05-22

- Initial release
