# Changelog

All notable changes to Acme-PrettyCure are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions up to 0.1.3 were released from `Changes`, before this file existed.

## [Unreleased]

## [1.0.0] - 2026-11-28

- Document that only the latest stable Perl is supported, and why (#6)
- Build the distribution with Module::Build::Tiny instead of Module::Build (#6)
- Pass the tests when installed from CPAN: they no longer need `.` in `@INC`, which Perl has not had since 5.26 (#7)
- `birthday` returns the birthday as a Time::Piece; it died for CureBlack, CureBloom, CureEgret and ShinyLuminous, and gave the current time for CureWhite (#7)
- `girls` with an unknown team dies with the name of the team, not `$team` (#7)
- The `AllStar` team has the members of "DokiDoki! Precure", whom the `allstar` method already transforms (#7)
- A girl of "DokiDoki! Precure" who transforms alone no longer warns "Redundant argument in sprintf" (#7)
- Fix the heading of `girls` and the addresses of the authors in the documentation (#7)

## [0.1.3] - 2014-01-03

- Add the members of "DokiDoki! Precure"

## [0.1] - 2013-02-03

- Add the title "DokiDoki! Precure"
- Change Any::Moose to Moo

## [0.08] - 2012-11-04

- Support the image method

## [0.072] - 2012-10-21

- Fix a bug when Moose is used

## [0.07] - 2012-10-06

- Fix the transform message of Suite
- Support colorized transform messages

## [0.06] - 2012-10-02

- Add `challenge_with_jankenpon` to CurePeace (thanks @maka2_donzoko)

## [0.05] - 2012-06-10

- Add the title "Smile Precure"
- Add the girl "CureEcho"
- Add the group "AllStarNewStage"

## [0.04] - 2011-10-25

- Add the title "Suite Precure"
- Add the girl "CureFlower"
- Add the group "AllStarDX3"
- Fix the challenge at transform

## [0.03] - 2010-12-08

- Add the TV series info (thanks yappo)
- CureBlack and CureWhite are 15 years old in MaxHeart

## [0.02] - 2010-12-06

- Fix bugs
- Add the teams "AllStarDX1" and "AllStarDX2"

## [0.01] - 2010-11-30

- Original version

[1.0.0]: https://github.com/kan/p5-acme-prettycure/releases/tag/v1.0.0
[0.1.3]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.1.3
[0.1]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.1
[0.08]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.08
[0.072]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.072
[0.07]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.07
[0.06]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.06
[0.05]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.05
[0.04]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.04
[0.03]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.03
[0.02]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.02
[0.01]: https://metacpan.org/release/MIKIHOSHI/Acme-PrettyCure-0.01
