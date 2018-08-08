# Dancer2::Plugin::SPID
Dancer2 plugin for for SPID authentication

[![Join the #spid-perl channel](https://img.shields.io/badge/Slack%20channel-%23spid--perl-blue.svg?logo=slack)](https://developersitalia.slack.com/messages/C7ESTMQDQ)
[![Get invited](https://slack.developers.italia.it/badge.svg)](https://slack.developers.italia.it/)
[![SPID on forum.italia.it](https://img.shields.io/badge/Forum-SPID-blue.svg)](https://forum.italia.it/c/spid) [![Build Status](https://travis-ci.org/italia/spid-perl-dancer2.svg?branch=master)](https://travis-ci.org/italia/spid-perl-dancer2) [![MetaCPAN Release](https://badge.fury.io/pl/Dancer2-Plugin-SPID.svg)](https://metacpan.org/pod/Dancer2::Plugin::SPID)

This Perl module is a plugin for the well-known Dancer2 web framework. It allows developers of SPID Service Providers to easily add SPID authentication to their Dancer2 applications. [SPID](https://www.spid.gov.it/) is the Italian digital identity system, which enables citizens to access all public services with single set of credentials.

This module provides the highest level of abstraction and ease of use for integration of SPID in a Dancer2 web application. Just set a few configuration options and you'll be able to generate the HTML markup for the SPID button on the fly (to be completed) in order to place it wherever you want in your templates. This plugin will automatically generate all the routes for SAML bindings, so you don't need to perform any plumbing manually. Hooks are provided for customizing behavior.

See the [example/](example/) directory for a demo application.

This is module is based on [Net::SPID](https://github.com/italia/spid-perl) which provides the lower-level framework-independent implementation of SPID for Perl.

## Repository layout

* [example/](example/) contains a demo application based on Dancer2
* [lib](lib) contains the source code of the Dancer2::Plugin::SPID module
* [t/](t/) contains the test suite

## Prerequisites & installation

This module is compatible with Perl 5.10+.
Just install it with cpanm and all dependencies will be retrieved automatically:

```
cpanm Dancer2::Plugin::SPID
```

Or, if you want the latest version from git, use:

```
cpanm https://github.com/italia/spid-perl-dancer2/archive/master.tar.gz
```

## Documentation

See the POD documentation in [Dancer2::Plugin::SPID](lib/Dancer2/Plugin/SPID.pm) or see it on [MetaCPAN](https://metacpan.org/release/Dancer2-Plugin-SPID).

## See also

* [SPID page](https://developers.italia.it/it/spid) on Developers Italia

## Authors

* [Alessandro Ranellucci](https://github.com/alexrj) (maintainer) - [Team per la Trasformazione Digitale](https://teamdigitale.governo.it/) - Presidenza del Consiglio dei Ministri
    * [alranel@teamdigitale.governo.it](alranel@teamdigitale.governo.it)
