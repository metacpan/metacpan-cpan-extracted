# Dallycot

[![Build Status](https://travis-ci.org/jgsmith/perl-Dallycot.svg?branch=master)](https://travis-ci.org/jgsmith/perl-Dallycot)

A linked open code engine. See [the website](http://www.dallycot.net/) for more information.

## Installation

Installing Dallycot is straightforward.

### Installation with cpanm

If you have cpanm, you only need one line:

    % cpanm Dallycot

If you are installing into a system-wide directory, you may need to pass the
"-S" flag to cpanm, which uses sudo to install the module:

    % cpanm -S Dallycot

### Installing with the CPAN shell

Alternatively, if your CPAN shell is set up, you should just be able to do:

    % cpan Dallycot

### Manual installation

As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Build.PL
    % ./Build && ./Build test

Then install it:

    % ./Build install

If you are installing into a system-wide directory, you may need to run:

    % sudo ./Build install
