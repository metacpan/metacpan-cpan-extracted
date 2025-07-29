# NAME

Data::Roundtrip - convert between Perl data structures, YAML and JSON with unicode support (I believe ...)

# VERSION

Version 0.30

# SYNOPSIS

This module contains a collection of utilities for converting between
JSON, YAML, Perl variable and a Perl variable's string representation (aka dump).
Hopefully, all unicode content will be handled correctly between
the conversions and optionally escaped or un-escaped. Also JSON can
be presented in a pretty format or in a condensed, machine-readable
format (not spaces, indendation or line breaks).

    use Data::Roundtrip qw/:all/;
    #use Data::Roundtrip qw/json2yaml/;
    #use Data::Roundtrip qw/:json/; # see EXPORT

    $jsonstr = '{"Songname": "Απόκληρος της κοινωνίας",'
               .'"Artist": "Καζαντζίδης Στέλιος/Βίρβος Κώστας"}'
    ;
    $yamlstr = json2yaml($jsonstr);
    print $yamlstr;
    # NOTE: long strings have been broken into multilines
    # and/or truncated (replaced with ...)
    #---
    #Artist: Καζαντζίδης Στέλιος/Βίρβος Κώστας
    #Songname: Απόκληρος της κοινωνίας

    $yamlstr = json2yaml($jsonstr, {'escape-unicode'=>1});
    print $yamlstr;
    #---
    #Artist: \u039a\u03b1\u03b6\u03b1 ...
    #Songname: \u0391\u03c0\u03cc\u03ba ...

    $backtojson = yaml2json($yamlstr);
    # $backtojson is a string representation
    # of following JSON structure:
    # {"Artist":"Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #  "Songname":"Απόκληρος της κοινωνίας"}

    # This is useful when sending JSON via
    # a POST request and it needs unicode escaped:
    $backtojson = yaml2json($yamlstr, {'escape-unicode'=>1});
    # $backtojson is a string representation
    # of following JSON structure:
    # but this time with unicode escaped
    # (pod content truncated for readbility)
    # {"Artist":"\u039a\u03b1\u03b6 ...",
    #  "Songname":"\u0391\u03c0\u03cc ..."}
    # this is the usual Data::Dumper dump:
    print json2dump($jsonstr);
    #$VAR1 = {
    #  'Songname' => "\x{391}\x{3c0}\x{3cc} ...",
    #  'Artist' => "\x{39a}\x{3b1}\x{3b6} ...",
    #};

    # and this is a more human-readable version:
    print json2dump($jsonstr, {'dont-bloody-escape-unicode'=>1});
    # $VAR1 = {
    #   "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #   "Songname" => "Απόκληρος της κοινωνίας"
    # };

    # pass some parameters to Data::Dumper
    # like: be terse (no $VAR1):
    print json2dump($jsonstr,
      {'dont-bloody-escape-unicode'=>0, 'terse'=>1}
     #{'dont-bloody-escape-unicode'=>0, 'terse'=>1, 'indent'=>0}
    );
    # {
    #  "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #  "Songname" => "Απόκληρος της κοινωνίας"
    # }

    # this is how to reformat a JSON string to
    # have its unicode content escaped:
    my $json_with_unicode_escaped =
          json2json($jsonstr, {'escape-unicode'=>1});

    # With version 0.18 and up two more exported-on-demand
    # subs were added to read JSON or YAML directly from a file:
    # jsonfile2perl() and yamlfile2perl()
    my $perldata = jsonfile2perl("file.json");
    my $perldata = yamlfile2perl("file.yaml");
    die "failed" unless defined $perldata;

    # For some of the above functions there exist command-line scripts:
    perl2json.pl -i "perl-data-structure.pl" -o "output.json" --pretty
    json2json.pl -i "with-unicode.json" -o "unicode-escaped.json" --escape-unicode
    # etc.

    # only for *2dump: perl2dump, json2dump, yaml2dump
    # and if no escape-unicode is required (i.e.
    # setting 'dont-bloody-escape-unicode' => 1 permanently)
    # and if efficiency is important,
    # meaning that perl2dump is run in a loop thousand of times,
    # then import the module like this:
    use Data::Roundtrip qw/:all no-unicode-escape-permanently/;
    # or like this
    use Data::Roundtrip qw/:all unicode-escape-permanently/;

    # then perl2dump() is more efficient but unicode characters
    # will be permanently not-escaped (1st case) or escaped (2nd case).

# EXPORT

By default no symbols are exported. However, the following export tags are available (:all will export all of them):

- `:json` :
`perl2json()`,
`json2perl()`,
`json2dump()`,
`json2yaml()`,
`json2json()`,
`jsonfile2perl()`
- `:yaml` :
`perl2yaml()`,
`yaml2perl()`,
`yaml2dump()`,
`yaml2yaml()`,
`yaml2json()`,
`yamlfile2perl()`
- `:dump` :
`perl2dump()`,
`perl2dump_filtered()`,
`perl2dump_homebrew()`
- `:io` :
`read_from_file()`, `write_to_file()`,
`read_from_filehandle()`, `write_to_filehandle()`,
- `:all` : everything above.
- Additionally, these four subs: `dump2perl()`, `dump2json()`, `dump2yaml()`, `dump2dump()`
do not belong to any export tag. However they can be imported explicitly by the caller
in the usual way (e.g. `use Data::Roundtrip qw/dump2perl perl2json .../`).
Section CAVEATS, under ["dump2perl"](#dump2perl), describes how these
subs `eval()` a string possibly coming from user,
possibly being unchecked.
- `no-unicode-escape-permanently` : this is not an
export keyword/parameter but a parameter which affects
all the `*2dump*` subs by setting unicode escaping
permanently to false. See ["EFFICIENCY"](#efficiency).
- `unicode-escape-permanently` : this is not an
export keyword/parameter but a parameter which affects
all the `*2dump*` subs by setting unicode escaping
permanently to true. See ["EFFICIENCY"](#efficiency).

# EFFICIENCY

The export keyword/parameter `no-unicode-escape-permanently`
affects
all the `*2dump*` subs by setting unicode escaping
permanently to false. This improves efficiency, although
one will ever need to
use this in extreme situations where a `*2dump*`
sub is called repeatedly in a loop of
a few hundreds or thousands of iterations or more.

Each time a `*2dump*` is called, the
`dont-bloody-escape-unicode` flag is checked
and if it is set, then  [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)'s `qquote()`
is overriden with `_qquote_redefinition_by_Corion()`
just for that instance and will be restored as soon as
the dump is finished. Similarly, a filter for
not escaping unicode is added to [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump)
just for that particular call and is removed immediately
after. This has some computational cost and can be
avoided completely by overriding the sub
and adding the filter once, at loading (in `import()`).

The price to pay for this added efficiency is that
unicode in any dump will never be escaped (e.g. `\x{3b1})`,
but will be rendered (e.g. `α`, a greek alpha). Always.
The option
`dont-bloody-escape-unicode` will permanently be set to true.

Similarly, the export keyword/parameter
`unicode-escape-permanently`
affects
all the `*2dump*` subs by setting unicode escaping
permanently to true. This improves efficiency as well.

See ["BENCHMARKS"](#benchmarks) on how to find the fastest `*2dump*`
sub.

# BENCHMARKS

The special Makefile target `benchmarks` will time
calls to each of the `*2dump*` subs under

    use Data::Roundtrip;

    use Data::Roundtrip qw/no-unicode-escape-permanently/;

    use Data::Roundtrip qw/unicode-escape-permanently/;

and for `'dont-bloody-escape-unicode' => 0` and
`'dont-bloody-escape-unicode' => 1`.

In general, ["perl2dump"](#perl2dump) is faster by 25% when one of the
permanent import parameters is used
(either of the last two cases above).

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
and/or prettify the returned result with `'pretty' => 1`
and/or allow conversion of blessed objects with `'convert_blessed' => 1`.

The latter is useful when the input (Perl) data structure
contains Perl objects (blessed refs!). But in addition to
setting it, each of the Perl objects (their class) must
implement a `TO_JSON()` method which will simply convert
the object into a Perl data structure. For example, if
your object stores the important data in `$self->data`
as a hash, then use this to return it

    sub TO_JSON { shift->data }

the converter will replace what is returned with the blessed
object which does not know what to do with it.
See [https://perldoc.perl.org/JSON::PP#2.-convert\_blessed-is-enabled-and-the-object-has-a-TO\_JSON-method.](https://perldoc.perl.org/JSON::PP#2.-convert_blessed-is-enabled-and-the-object-has-a-TO_JSON-method.)
for more information.

The output can be fed back to ["json2perl"](#json2perl)
for getting the Perl variable back.

It returns the JSON string on success or `undef` on failure.

## `json2perl`

Arguments:

- `$jsonstring`

Return value:

- `$ret`

Given an input `$jsonstring` as a string, it will return
the equivalent Perl data structure using
`JSON::decode_json(Encode::encode_utf8($jsonstring))`.

It returns the Perl data structure on success or `undef` on failure.

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
The output can be fed to ["yaml2perl"](#yaml2perl)
for getting the Perl variable back.

It returns the YAML string on success or `undef` on failure.

## `yaml2perl`

    my $ret = yaml2perl($yamlstring);

Arguments:

- `$yamlstring`

Return value:

- `$ret`

Given an input `$yamlstring` as a string, it will return
the equivalent Perl data structure using
`YAML::PP::Load($yamlstring)`

It returns the Perl data structure on success or `undef` on failure.

## `yamlfile2perl`

    my $ret = yamlfile2perl($filename)

Arguments:

- `$filename`

Return value:

- `$ret`

Given an input `$filename` which points to a file containing YAML content,
it will return the equivalent Perl data structure.

It returns the Perl data structure on success or `undef` on failure.

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
one can specify whether to escape unicode with
`'dont-bloody-escape-unicode' => 0`,
(or `'escape-unicode' => 1`). The DEFAULT
behaviour is to NOT ESCAPE unicode.

Additionally, use terse output with `'terse' => 1` and remove
all the incessant indentation with `'indent' => 1`
which unfortunately goes to the other extreme of
producing a space-less output, not fit for human consumption.
The output can be fed to ["dump2perl"](#dump2perl)
for getting the Perl variable back.

It returns the string representation of the input perl variable
on success or `undef` on failure.

The output can be fed back to ["dump2perl"](#dump2perl).

CAVEAT: when not escaping unicode (which is the default
behaviour), each call to this sub will override [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)'s
`qquote()` sub then
call [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)'s `Dumper()` and save its output to
a temporary variable, restore `qquote()` sub to its original
code ref and return the
contents. This exercise is done every time this `perl2dump()`
is called. It may be expensive. The alternative is
to redefine `qquote()` once, when the module is loaded, with
all the side-effects this may cause.

Note that there are two other alternative subs which offer more-or-less
the same functionality and their output can be fed back to all the `dump2*()`
subs. These are
["perl2dump\_filtered"](#perl2dump_filtered) which uses [Data::Dump::Filtered](https://metacpan.org/pod/Data%3A%3ADump%3A%3AFiltered)
to add a filter to control unicode escaping but
lacks in aesthetics and functionality and handling all the
cases Dump and Dumper do quite well.

There is also `perl2dump_homebrew()` which
uses the same dump-recursively engine as
["perl2dump\_filtered"](#perl2dump_filtered)
but does not involve Data::Dump at all.

## `perl2dump_filtered`

    my $ret = perl2dump_filtered($perlvar, $optional_paramshashref)

Arguments:

- `$perlvar`
- `$optional_paramshashref`

Return value:

- `$ret`

It does the same job as ["perl2dump"](#perl2dump) which is
to stringify a perl variable. And takes the same options.

It returns the string representation of the input perl variable
on success or `undef` on failure.

It uses [Data::Dump::Filtered](https://metacpan.org/pod/Data%3A%3ADump%3A%3AFiltered) to add a filter to
[Data::Dump](https://metacpan.org/pod/Data%3A%3ADump).

## `perl2dump_homebrew`

    my $ret = perl2dump_homebrew($perlvar, $optional_paramshashref)

Arguments:

- `$perlvar`
- `$optional_paramshashref`

Return value:

- `$ret`

It does the same job as ["perl2dump"](#perl2dump) which is
to stringify a perl variable. And takes the same options.

It returns the string representation of the input perl variable
on success or `undef` on failure.

The output can be fed back to ["dump2perl"](#dump2perl).

It uses its own basic dumper. Which is recursive.
So, beware of extremely deep nested data structures.
Deep not long! But it probably is as efficient as
it can be but definetely lacks in aesthetics
and functionality compared to Dump and Dumper.

## `dump_perl_var_recursively`

    my $ret = dump_perl_var_recursively($perl_var)

Arguments:

- `$perl_var`, a Perl variable like
a scalar or an arbitrarily nested data structure.
For the latter, it requires references, e.g.
hash-ref or arrayref.

Return value:

- `$ret`, the stringified version of the input Perl variable.

This sub will take a Perl var (as a scalar or an arbitrarily nested data structure)
and emulate a very very basic
Dump/Dumper but with enforced rendering unicode (for keys or values or array items),
and not escaping unicode - this is not an option,
it returns a string representation of the input perl var

There are 2 obvious limitations:

- 1. indentation is very basic,
- 2. it supports only scalars, hashes and arrays,
(which will dive into them no problem)
This sub can be used in conjuction with DataDumpFilterino()
to create a Data::Dump filter like,

         Data::Dump::Filtered::add_dump_filter( \& DataDumpFilterino );
    or
         dumpf($perl_var, \& DataDumpFilterino);

    the input is a Perl variable as a reference, so no `%inp` but `$inp={}` 
    and `$inp=[]`. 

    This function is recursive.
    Beware of extremely deep nested data structures.
    Deep not long! But it probably is as efficient as
    it can be but definetely lacks in aesthetics
    and functionality compared to Dump and Dumper.

    The output is a, possibly multiline, string. Which it can
    then be fed back to ["dump2perl"](#dump2perl).

## `dump2perl`

    # CAVEAT: it will eval($dumpstring) internally, so
    #         check $dumpstring for malicious code beforehand
    #         it is a security risk if you don't.
    #         Don't use it if $dumpstring comes from
    #         untrusted sources (user input for example).
    my $ret = dump2perl($dumpstring)

Arguments:

- `$dumpstring`, this comes from the output of [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump),
[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) or our own ["perl2dump"](#perl2dump),
["perl2dump\_filtered"](#perl2dump_filtered),
["perl2dump\_homebrew"](#perl2dump_homebrew).
Escaped, or unescaped.

Return value:

- `$ret`, the Perl data structure on success or `undef` on failure.

CAVEAT: it **eval()**'s the input `$dumpstring` in order to create the Perl data structure.
**eval()**'ing unknown or unchecked input is a security risk. Always check input to **eval()**
which comes from untrusted sources, like user input, scraped documents, email content.
Anything really.

## `json2perl`

    my $ret = json2perl($jsonstring)

Arguments:

- `$jsonstring`

Return value:

- `$ret`

Given an input `$jsonstring` as a string, it will return
the equivalent Perl data structure using
`JSON::decode_json(Encode::encode_utf8($jsonstring))`.

It returns the Perl data structure on success or `undef` on failure.

## `jsonfile2perl`

    my $ret = jsonfile2perl($filename)

Arguments:

- `$filename`

Return value:

- `$ret`

Given an input `$filename` which points to a file containing JSON content,
it will return the equivalent Perl data structure.

It returns the Perl data structure on success or `undef` on failure.

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
converting that variable to YAML using ["perl2yaml"](#perl2yaml).
All the parameters supported by ["perl2yaml"](#perl2yaml)
are accepted.

It returns the YAML string on success or `undef` on failure.

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
converting that variable to JSON using ["perl2json"](#perl2json).
All the parameters supported by ["perl2json"](#perl2json)
are accepted.

It returns the JSON string on success or `undef` on failure.

## `json2json` `yaml2yaml`

Transform a json or yaml string via pretty printing or via
escaping unicode or via un-escaping unicode. Parameters
like above will be accepted.

## `json2dump` `dump2json` `yaml2dump` `dump2yaml`

These subs offer similar functionality as their counterparts
described above.

Section CAVEATS, under ["dump2perl"](#dump2perl), describes how
`dump2*()` subs `eval()` a string possibly coming from user,
possibly being unchecked.

## `dump2dump`

    my $ret = dump2dump($dumpstring, $optional_paramshashref)

Arguments:

- `$dumpstring`
- `$optional_paramshashref`

Return value:

- `$ret`

For example:

    my $dumpstr = '...';
    my $newdumpstr = dump2dump(
      $dumpstr,
      {
        'dont-bloody-escape-unicode' => 1,
        'terse' => 0,
      }
    );

It returns the a dump string similar to 

## `read_from_file`

    my $contents = read_from_file($filename)

Arguments:

- `$filename` : the input filename.

Return value:

- `$contents`

Given a filename, it opens it using `:encoding(UTF-8)`, slurps its
contents and closes it. It's a convenience sub which could have also
been private. If you want to retain the filehandle, use
["read\_from\_filehandle"](#read_from_filehandle).

It returns the file contents on success or `undef` on failure.

## `read_from_filehandle`

    my $contents = read_from_filehandle($filehandle)

Arguments:

- `$filehandle` : the handle to an already opened file.

Return value:

- `$contents` : the file contents slurped.

It slurps all content from the specified input file handle. Upon return
the file handle is still open.
It returns the file contents on success or `undef` on failure.

## `write_to_file`

    write_to_file($filename, $contents) or die

Arguments:

- `$filename` : the output filename.
- `$contents` : any string to write it to file.

Return value:

- 1 on success, 0 on failure

Given a filename, it opens it using `:encoding(UTF-8)`,
writes all specified content and closes the file.
It's a convenience sub which could have also
been private. If you want to retain the filehandle, use
["write\_to\_filehandle"](#write_to_filehandle).

It returns 1 on success or 0 on failure.

## `write_to_filehandle`

    write_to_filehandle($filehandle, $contents) or die

Arguments:

- `$filehandle` : the handle to an already opened file (for writing).

Return value:

- 1 on success or 0 on failure.

It writes content to the specified file handle. Upon return
the file handle is still open.

It returns 1 on success or 0 on failure.

# SCRIPTS

A few scripts have been put together and offer the functionality of this
module to the command line. They are part of this distribution and can
be found in the `script` directory.

These are: `json2json.pl`,  `json2yaml.pl`,  `yaml2json.pl`,
`json2perl.pl`, `perl2json.pl`, `yaml2perl.pl`

# CAVEATS

I have to apologise here to the authors of [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP)
for defaming them because I clumsily wrote [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP)
when I wanted to write [YAML](https://metacpan.org/pod/YAML).

So, the reality is that [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP) does not have any
problem in handling the edge-case below.

A valid Perl variable may kill [YAML](https://metacpan.org/pod/YAML)'s `Load()` because
of escapes and quotes. For example this:

    my $yamlstr = <<'EOS';
    ---
    - 682224
    - "\"w": 1
    EOS
    my $pv = eval { YAML::Load($yamlstr) };
    if( $@ ){ die "failed(1): ". $@ }
    # it's dead

Strangely, there is no problem for this:

    my $yamlstr = <<'EOS';
    ---
    - 682224
    - "\"w"
    EOS
    # this is OK also:
    # - \"w: 1
    my $pv = eval { YAML::Load($yamlstr) };
    if( $@ ){ die "failed(1): ". $@ }
    # it's OK! still alive.

I have provided an author-only test (`make deficiencies`) which
tests all three of them on the edge cases. Both [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP)
and [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) pass the tests.

This [YAML issue](https://github.com/ingydotnet/yaml-pm/issues/224) is
relevant. Many thanks to CPAN authors [TINITA](https://metacpan.org/author/TINITA)
and [INGY](https://metacpan.org/author/INGY) for their work on this, and
on `YAML*` too.

For now, the plan is to still use [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP) and avoid explicitly requiring
[YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) until [YAML::Any](https://metacpan.org/pod/YAML%3A%3AAny) is ready.

Be warned that sub `dump2perl()` `eval()`'s
its input. If this comes from the user and
it is not checked then it is considered a security
problem. Subs `dump2json()`, `dump2yaml()`, `dump2dump()`
use `dump2perl()`. The four subs will issue a warning whenever
you call them. Additionally, as from version 0.28, they need
to be explicitly imported like:

    use Data::Roundtrip qw/... dump2perl .../

They are no longer part of export tag `:dump` nor `:all`.
If their input comes from the user please check the input
not to contain malicious code which when `eval()`'ed
can create security concerns.

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org> / <andreashad2 at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-data-roundtrip at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Roundtrip](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Roundtrip).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

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

- Review this module at PerlMonks

    [https://www.perlmonks.org/?node\_id=21144](https://www.perlmonks.org/?node_id=21144)

- Search CPAN

    [https://metacpan.org/release/Data-Roundtrip](https://metacpan.org/release/Data-Roundtrip)

# ACKNOWLEDGEMENTS

Several Monks at [PerlMonks.org ](https://metacpan.org/pod/%20https%3A#PerlMonks.org) (in no particular order):

- [haukex](https://perlmonks.org/?node_id=830549)
- [Corion](https://perlmonks.org/?node_id=5348) (the
`_qquote_redefinition_by_Corion()` which harnesses
[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)'s incessant unicode escaping)
- [kcott](https://perlmonks.org/?node_id=861371)
(The EXPORT section among other suggestions)
- [jwkrahn](https://perlmonks.org/?node_id=540414)
- [leszekdubiel](https://perlmonks.org/?node_id=1164259)
- [marto](https://perlmonks.org/?node_id=324763)
- [Haarg](https://perlmonks.org/?node_id=306692)
- and an anonymous monk
- CPAN author Slaven Rezić
([SREZIC](https://metacpan.org/author/SREZIC)) for testing
the code and reporting numerous problems.
- CPAN authors [TINITA](https://metacpan.org/author/TINITA)
and [INGY](https://metacpan.org/author/INGY)
for working on an issue related to [YAML](https://metacpan.org/pod/YAML).

# DEDICATIONS

Almaz!

# LICENSE AND COPYRIGHT

This software, EXCEPT the portions created by \[Corion\] @ Perlmonks
and \[kcott\] @ Perlmonks,
is Copyright (c) 2020 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 1403:

    &#x3d;back doesn't take any parameters, but you said =back  Given an input string C&lt;$dumpstring>, which can have been produced by e.g. C&lt;perl2dump()> and is identical to L<Data::Dumper>'s C<Dumper()> output, it will roundtrip back to the same string, possibly with altered format via the parameters in C&lt;$optional\_paramshashref>.
