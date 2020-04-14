# NAME

Data::Roundtrip - convert between Perl data structures, YAML and JSON with unicode support (I believe ...)

# VERSION

Version 0.03

# SYNOPSIS

This module contains a collection of utilities for converting between
JSON, YAML, Perl variable and a Perl variable's string representation (aka dump).
Hopefully, all unicode content will be handled correctly between
the conversions and optionally escaped or un-escaped. Also JSON can
be presented in a pretty format or in a condensed, machine-readable
format (not spaces, indendation or line breaks).

    use Data::Roundtrip qw/:all/;

    $jsonstr = '{"Songname": "Απόκληρος της κοινωνίας", "Artist": "Καζαντζίδης Στέλιος/Βίρβος Κώστας"}';
    $yamlstr = json2yaml($jsonstr);
    print $yamlstr;
    #---
    #Artist: Καζαντζίδης Στέλιος/Βίρβος Κώστας
    #Songname: Απόκληρος της κοινωνίας

    $yamlstr = json2yaml($jsonstr, {'escape-unicode'=>1});
    print $yamlstr;
    #---
    #Artist: \u039a\u03b1\u03b6\u03b1\u03bd\u03c4\u03b6\u03af\u03b4\u03b7\u03c2 \u03a3\u03c4\u03ad\u03bb\u03b9\u03bf\u03c2/\u0392\u03af\u03c1\u03b2\u03bf\u03c2 \u039a\u03ce\u03c3\u03c4\u03b1\u03c2
    #Songname: \u0391\u03c0\u03cc\u03ba\u03bb\u03b7\u03c1\u03bf\u03c2 \u03c4\u03b7\u03c2 \u03ba\u03bf\u03b9\u03bd\u03c9\u03bd\u03af\u03b1\u03c2

    $backtojson = yaml2json($yamlstr);
    # $backtojson is a string representation of this JSON structure:
    # {"Artist":"Καζαντζίδης Στέλιος/Βίρβος Κώστας","Songname":"Απόκληρος της κοινωνίας"}

    # This is useful when sending JSON via a POST request and it needs unicode escaped:
    $backtojson = yaml2json($yamlstr, {'escape-unicode'=>1});
    # $backtojson is a string representation of this JSON structure:
    # but this time with unicode escaped
    # {"Artist":"\u039a\u03b1\u03b6\u03b1\u03bd\u03c4\u03b6\u03af\u03b4\u03b7\u03c2 \u03a3\u03c4\u03ad\u03bb\u03b9\u03bf\u03c2/\u0392\u03af\u03c1\u03b2\u03bf\u03c2 \u039a\u03ce\u03c3\u03c4\u03b1\u03c2","Songname":"\u0391\u03c0\u03cc\u03ba\u03bb\u03b7\u03c1\u03bf\u03c2 \u03c4\u03b7\u03c2 \u03ba\u03bf\u03b9\u03bd\u03c9\u03bd\u03af\u03b1\u03c2"}

    # this is the usual Data::Dumper dump:
    print json2dump($jsonstr);
    #$VAR1 = {
    #  'Songname' => "\x{391}\x{3c0}\x{3cc}\x{3ba}\x{3bb}\x{3b7}\x{3c1}\x{3bf}\x{3c2} \x{3c4}\x{3b7}\x{3c2} \x{3ba}\x{3bf}\x{3b9}\x{3bd}\x{3c9}\x{3bd}\x{3af}\x{3b1}\x{3c2}",
    #  'Artist' => "\x{39a}\x{3b1}\x{3b6}\x{3b1}\x{3bd}\x{3c4}\x{3b6}\x{3af}\x{3b4}\x{3b7}\x{3c2} \x{3a3}\x{3c4}\x{3ad}\x{3bb}\x{3b9}\x{3bf}\x{3c2}/\x{392}\x{3af}\x{3c1}\x{3b2}\x{3bf}\x{3c2} \x{39a}\x{3ce}\x{3c3}\x{3c4}\x{3b1}\x{3c2}"
    #};

    # and this is a more human-readable version:
    print json2dump($jsonstr, {'dont-bloody-escape-unicode'=>1});
    # $VAR1 = {
    #   "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #   "Songname" => "Απόκληρος της κοινωνίας"
    # };

    # pass some parameters to Data::Dumper like to be terse (no $VAR1) and no indentation:
    print json2dump($jsonstr,
      {'dont-bloody-escape-unicode'=>0, 'terse'=>1}
    );
    # {
    #  "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #  "Songname" => "Απόκληρος της κοινωνίας"
    # }

    # this is how to reformat a JSON string to have its unicode content escaped:
    my $json_with_unicode_escaped = json2json($jsonstr, {'escape-unicode'=>1});

    # For some of the above functions there exist command-line scripts:
    perl2json.pl -i "perl-data-structure.pl" -o "output.json" --escape-unicode --pretty
    # etc.

# EXPORT

By default no symbols are exported. However, the following export tags are available (:all will export all of them):

- `:json` :
`perl2json()`,
`json2perl()`,
`json2dump()`,
`json2yaml()`,
`json2json()`
- `:yaml` :
`perl2yaml()`,
`yaml2perl()`,
`yaml2dump()`,
`yaml2yaml()`,
`yaml2json()`
- `:dump` :
`perl2dump()`,
`dump2perl()`,
`dump2json()`,
`dump2yaml()`
- `:io` :
`read_from_file()`, `write_to_file()`,
`read_from_filehandle()`, `write_to_filehandle()`,
- `:all` : everything above

# SUBROUTINES

## `perl2json`

    my $ret = perl2json($perlvar, $optional_paramshashref)

Arguments:

- `$perlvar`
- `$optional_paramshashref`

Return value:

- `$ret`

Given an input `$perlvar` (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent JSON string. In `$optional_paramshashref`
one can specify whether to escape unicode with
`'escape-unicode' => 1`
and/or prettify the returned result with `'pretty' => 1`.
The output can fed to [Data::Roundtrip::json2perl](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Ajson2perl)
for getting the Perl variable back.

Returns the JSON string on success or `undef` on failure.

## `json2perl`

Arguments:

- `$jsonstring`

Return value:

- `$ret`

Given an input `$jsonstring` as a string, it will return
the equivalent Perl data structure using
`JSON::decode_json(Encode::encode_utf8($jsonstring))`.

Returns the Perl data structure on success or `undef` on failure.

## `perl2yaml`

    my $ret = perl2yaml($perlvar, $optional_paramshashref)

Arguments:

- `$perlvar`
- `$optional_paramshashref`

Return value:

- `$ret`

Given an input `$perlvar` (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent YAML string. In `$optional_paramshashref`
one can specify whether to escape unicode with
`'escape-unicode' => 1`. Prettify is not supported yet.
The output can fed to [Data::Roundtrip::yaml2perl](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Ayaml2perl)
for getting the Perl variable back.

Returns the YAML string on success or `undef` on failure.

## `yaml2perl`

    my $ret = yaml2perl($yamlstring);

Arguments:

- `$yamlstring`

Return value:

- `$ret`

Given an input `$yamlstring` as a string, it will return
the equivalent Perl data structure using
`YAML::Load($yamlstring)`

Returns the Perl data structure on success or `undef` on failure.

## `perl2dump`

    my $ret = perl2dump($perlvar, $optional_paramshashref)

Arguments:

- `$perlvar`
- `$optional_paramshashref`

Return value:

- `$ret`

Given an input `$perlvar` (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent string (via [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)).
In `$optional_paramshashref`
one can specify whether to NOT escape unicode with
`'dont-bloody-escape-unicode' => 1`,
and/or use terse output with `'terse' => 1` and remove
all the incessant indentation `'indent' => 1`
which unfortunately goes to the other extreme of
producing a space-less output, not fit for human consumption.
The output can fed to [Data::Roundtrip::dump2perl](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Adump2perl)
for getting the Perl variable back.

Returns the string representation of the input perl variable
on success or `undef` on failure.

## `json2perl`

    my $ret = json2perl($jsonstring)

Arguments:

- `$jsonstring`

Return value:

- `$ret`

Given an input `$jsonstring` as a string, it will return
the equivalent Perl data structure using
`JSON::decode_json(Encode::encode_utf8($jsonstring))`.

Returns the Perl data structure on success or `undef` on failure.

In `$optional_paramshashref`
one can specify whether to escape unicode with
`'escape-unicode' => 1`
and/or prettify the returned result with `'pretty' => 1`.

Returns the yaml string on success or `undef` on failure.

## `json2yaml`

    my $ret = json2yaml($jsonstring, $optional_paramshashref)

Arguments:

- `$jsonstring`
- `$optional_paramshashref`

Return value:

- `$ret`

Given an input JSON string `$jsonstring`, it will return
the equivalent YAML string [YAML](https://metacpan.org/pod/YAML)
by first converting JSON to a Perl variable and then
converting that variable to YAML using [Data::Roundtrip::perl2yaml()](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Aperl2yaml%28%29).
All the parameters supported by [Data::Roundtrip::perl2yaml()](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Aperl2yaml%28%29)
are accepted.

Returns the YAML string on success or `undef` on failure.

## `yaml2json`

    my $ret = yaml2json($yamlstring, $optional_paramshashref)

Arguments:

- `$yamlstring`
- `$optional_paramshashref`

Return value:

- `$ret`

Given an input YAML string `$yamlstring`, it will return
the equivalent YAML string [YAML](https://metacpan.org/pod/YAML)
by first converting YAML to a Perl variable and then
converting that variable to JSON using [Data::Roundtrip::perl2json()](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Aperl2json%28%29).
All the parameters supported by [Data::Roundtrip::perl2json()](https://metacpan.org/pod/Data%3A%3ARoundtrip%3A%3Aperl2json%28%29)
are accepted.

Returns the JSON string on success or `undef` on failure.

## `json2json` `yaml2yaml`

Transform a json or yaml string via pretty printing or via
escaping unicode or via un-escaping unicode. Parameters
like above will be accepted.

## `json2dump` `dump2json` `yaml2dump` `dump2yaml`

similar functionality as their counterparts described above.

# SCRIPTS

A few scripts have been put together and offer the functionality of this
module to the command line. They are part of this distribution and can
be found in the `script` directory.

These files are: `json2json.pl`,  `json2yaml.pl`,  `yaml2json.pl`
`json2perl.pl`, `perl2json.pl`, `yaml2perl.pl`

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org> / <andreashad2 at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-data-roundtrip at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Roundtrip](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Roundtrip).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# FUTURE WORK

Replace [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) with [Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode)

# SEE ALSO

- [Convert JSON to Perl and back with unicode](https://perlmonks.org/?node_id=11115241)
- [RFC: Perl<->JSON<->YAML<->Dumper : roundtripping and possibly with unicode](https://perlmonks.org/?node_id=11115280)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Roundtrip

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Roundtrip](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Roundtrip)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Data-Roundtrip](http://annocpan.org/dist/Data-Roundtrip)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Data-Roundtrip](https://cpanratings.perl.org/d/Data-Roundtrip)

- Search CPAN

    [https://metacpan.org/release/Data-Roundtrip](https://metacpan.org/release/Data-Roundtrip)

# ACKNOWLEDGEMENTS

Several Monks at [PerlMonks.org ](https://metacpan.org/pod/%20https%3A#PerlMonks.org) (in no particular order):

- [haukex](https://perlmonks.org/?node_id=830549)
- [Corion](https://perlmonks.org/?node_id=5348) (the
` _qquote_redefinition_by_Corion() ` which harnesses
[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)'s incessant unicode escaping)
- [kcott](https://perlmonks.org/?node_id=861371)
(The EXPORT section among other suggestions)
- [jwkrahn](https://perlmonks.org/?node_id=540414)
- [leszekdubiel](https://perlmonks.org/?node_id=1164259)
- [marto](https://perlmonks.org/?node_id=https://perlmonks.org/?node_id=324763)
- and an anonymous monk

# DEDICATIONS

Almaz!

# LICENSE AND COPYRIGHT

This software, EXCEPT the portions created by \[Corion\] @ Perlmonks
and \[kcott\] @ Perlmonks,
is Copyright (c) 2020 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
