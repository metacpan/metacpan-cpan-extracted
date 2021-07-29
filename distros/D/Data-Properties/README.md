# Data::Properties -- Flexible properties handling

A flexible properties mechanism modelled after the Java implementation
of properties.

In general, a property is a string value that is associated with a
key. A key is a series of names (identifiers) separated with periods.
Names are treated case insensitive. Unlike in Java, the properties are
really hierarchically organized. This means that for a given property
you can fetch the list of its subkeys, and so on. Moreover, the list
of subkeys is returned in the order the properties were defined.

Data::Properties can also be used to define data structures, just like
JSON but with much less quotes. Note that only scalar values and
arrays are possible.

## Example of Usage

    use Data::Properties;

    my $cfg = new Data::Properties;

    # Preset a property.
    $cfg->set_property("config.version", "1.23");

    # Parse a properties file.
    $cfg->parse_file("config.prp");

    # Get a property value
    $version = $cfg->get_property("config.version");
    # Same, but with a default value.
    $version = $cfg->get_property("config.version", "1.23");

    # Get the list of subkeys for a property, and process them.
    my $aref = $cfg->get_property_keys("item.list");
    foreach my $item ( @$aref ) {
        if ( $cfg->get_property("item.list.$item") ) {
            ....
        }
    }

## Example of a Properties file

    config.version: 1.23
	title: "An example"
	database {
	  name: demo
	  host: dbserver.example.com
	  port: 1313
	  type: postgres
    }

The last couple of lines show a short form of writing `database.name`,
`database.host` and so on.

## Design goals

* properties must be hierarchical of unlimited depth;

* manual editing of the property files (hence unambiguous syntax and
  lay out);

* it must be possible to locate all subkeys of a property in the order
  they appear in the property file(s);

* lightweight so shell scripts can use it to query properties.

## Installation

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## Support and Documentation

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Data-Properties.

You can find documentation for this module with the perldoc command.

    perldoc Data::Properties

Please report any bugs or feature requests using the issue tracker on
GitHub.

## Acknowledgements

This module was initially developed in 1994 as part of the Multihouse
MH-Doc (later: MMDS) software suite. Multihouse kindly waived copyrights.

In 2002 it was revamped as part of the Compuware OptimalJ development
process. Compuware kindly waived copyrights.

In 2020 it was updated to support arrays and released to the general
public.

## Copyright and Licence

Copyright (C) 1994,2002,2020 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

