# App::Prove::Plugin::PassEnv

[![Build Status](https://travis-ci.org/Camelcade/App-Prove-Plugin-PassEnv.svg?branch=master)](https://travis-ci.org/Camelcade/App-Prove-Plugin-PassEnv)

A `prove` plugin to pass environment variables to your tests behind `prove`

Usage:

```env PROVE_PASS_PERL5OPT="-d:Cover" prove -PPassEnv` t/test.t```

Runs perl test with coverage using `prove`. 

Created for using with [Perl5 plugin for IntelliJ products](https://github.com/Camelcade/Perl5-IDEA). 

- Published on [meta::cpan](https://metacpan.org/release/App-Prove-Plugin-PassEnv)
- Packaged with [Dist::Zilla](https://github.com/rjbs/Dist-Zilla)
- CI with [TravisCI](https://travis-ci.org/) and [perl-helpers](https://github.com/travis-perl/helpers)
- Smoked on [CPANTesters](http://www.cpantesters.org/distro/T/App-Prove-Plugin-PassEnv.html)
- [CPAN Testers Matrix](http://matrix.cpantesters.org/?dist=App-Prove-Plugin-PassEnv)

