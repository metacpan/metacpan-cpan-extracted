# Amazon::Sites

A Perl class that contains information about the various international Amazon
sites.

## Badges

Hopefully, these are all green.

[![CI](https://github.com/davorg-cpan/amazon-sites/actions/workflows/perltest.yml/badge.svg)](https://github.com/davorg-cpan/amazon-sites/actions/workflows/perltest.yml)
[![Coverage Status](https://coveralls.io/repos/github/davorg-cpan/amazon-sites/badge.svg?branch=main)](https://coveralls.io/github/davorg-cpan/amazon-sites?branch=main)
[![Kwality](https://cpants.cpanauthors.org/release/DAVECROSS/Amazon-Sites.svg "Kwality")](https://cpants.cpanauthors.org/release/DAVECROSS/Amazon-Sites)

## Example

    use Amazon::Sites;

    my $az = Amazon::Sites->new;

    my $az_uk = $az->site('UK');

    say $az_uk->currency; # GBP
    say $az_uk->tldn;     # co.uk
    say $az_uk->domain;   # amazon.co.uk

For more documentation visit:

* https://metacpan.org/pod/Amazon::Sites

Or run `perldoc Amazon::Sites` once you have installed the module.

## Installation

The traditional way to install a Perl module is to download the latest zipped
tarball from CPAN (https://metacpan.org/dist/Amazon-Sites) and then run
through the following steps:

1. `unzip Amazon-Sites-X.X.X.tar.gz`
1. `tar xvf Amazon-Sites-X.X.X.tar`
1. `cd Amazon-Sites-X.X.X`
1. `perl Makefile.PL`
1. `make test`
1. `make install`

But there are programs that make this easier. For example, `cpan` comes as
part of the standard Perl installation:

* `cpan Amazon::Sites`

And many people use `cpanm` instead:

* `cpanm Amazon::Sites`

## Code

The code is maintained on GitHub.

* https://github.com/davorg-cpan/amazon-sites

## Questions, bugs and feature requests

All issues are tracked on GitHub:

* https://github.com/davorg-cpan/amazon-sites/issues

## Author

* Dave Cross <dave@perlhacks.com>

