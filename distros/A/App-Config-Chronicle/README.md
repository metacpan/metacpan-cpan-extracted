# NAME

App::Config::Chronicle - An OO configuration module which can be changed and stored into chronicle database.

[![Build Status](https://travis-ci.org/binary-com/perl-App-Config-Chronicle.svg?branch=master)](https://travis-ci.org/binary-com/perl-App-Config-Chronicle)
[![codecov](https://codecov.io/gh/binary-com/perl-App-Config-Chronicle/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-App-Config-Chronicle)

# VERSION

Version 0.01

# SYNOPSIS

    my $app_config = App::Config::Chronicle->new;

# DESCRIPTION

This module parses configuration files and provides interface to access
configuration information.

# FILE FORMAT

The configuration file is a YAML file. Here is an example:

    system:
      description: "Various parameters determining core application functionality"
      isa: section
      contains:
        email:
          description: "Dummy email address"
          isa: Str
          default: "dummy@mail.com"
          global: 1
        admins:
          description: "Are we on Production?"
          isa: ArrayRef
          default: []

Every attribute is very intuitive. If an item is global, you can change its value and the value will be stored into chronicle database by calling the method `save_dynamic`.

# SUBROUTINES/METHODS

## definition\_yml

The YAML file that store the configuration

## chronicle\_reader

The chronicle store that configurations can be fetch from it. It should be an instance of [Data::Chronicle::Reader](https://metacpan.org/pod/Data::Chronicle::Reader).
But user is free to implement any storage backend he wants if it is implemented with a 'get' method.

## chronicle\_writer

The chronicle store that updated configurations can be stored into it. It should be an instance of [Data::Chronicle::Writer](https://metacpan.org/pod/Data::Chronicle::Writer).
But user is free to implement any storage backend he wants if it is implemented with a 'set' method.

## check\_for\_update

check and load updated settings from chronicle db

## save\_dynamic

Save synamic settings into chronicle db

## current\_revision

loads setting from chronicle reader and returns the last revision and drops them

## BUILD

# AUTHOR

Binary.com, `<binary at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-app-config at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Config](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Config).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Config::Chronicle

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Config](http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Config)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/App-Config](http://annocpan.org/dist/App-Config)

- CPAN Ratings

    [http://cpanratings.perl.org/d/App-Config](http://cpanratings.perl.org/d/App-Config)

- Search CPAN

    [http://search.cpan.org/dist/App-Config/](http://search.cpan.org/dist/App-Config/)

# ACKNOWLEDGEMENTS
