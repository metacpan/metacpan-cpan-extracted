Crop - Creazilla on Perl (cd abbreviated as Crop) is a Perl framework with the main goal to make writing web scripts much easy

## DESCRIPTION

Creazilla on Perl (cd abbreviated as Crop) is a Perl framework with the main goal to make writing web scripts much easy. No wide experience is required to programming a top-level script. The SQL-layer is hidden from a programmer.

Crop implements:
1. class attributes inheritance
2. automatic object synchronization with warehouse
3. http request routing, parameter parsing
4. multiple warehouses of different type at the same time
5. role-based access system

The Crop has lightweight, simple and clear architecture, that makes changes to Crop itself simple. Crop uses common Perl syntax. Getters/setters are the only code Crop generates implicitly, so debugging is easy.

## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## DEPENDENCIES

The following Perl modules are required to use Crop:

- XML::LibXML
- Time::Stamp
- Clone
- XML::LibXSLT
- JSON
- CGI::Cookie
- CGI::Fast

Install these modules using CPAN or your package manager before proceeding.

## CONTRIBUTING

To contribute to Crop, follow these steps:

1. Fork the repository on GitHub.
2. Clone your fork locally.
3. Install dependencies using `cpan` or `cpanm`.
4. Run tests using `make test`.
5. Submit a pull request with your changes.

## CHANGELOG

### Version 0.1.25 (30 April 2025)

- Initial release of Crop framework.
- Added support for class attributes inheritance.
- Implemented role-based access system.
- Added multiple warehouse support.

## Sponsors

Creazilla on Perl has been sponsored by [Creazilla.com](https://creazilla.com/). 

## Core Developers

Euvgenio

## Contributors

Alex

## Copyright and License:

Apache 2.0

## See also

https://creazilla.com/pages/creazilla-on-perl

