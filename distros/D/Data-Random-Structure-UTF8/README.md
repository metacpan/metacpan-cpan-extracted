# NAME

Data::Random::Structure::UTF8 - Produce nested data structures with unicode keys, values, elements.

# VERSION

Version 0.06

# SYNOPSIS

This module produces random, arbitrarily deep and long,
nested Perl data structures  with unicode content for the
keys, values and/or array elements. Content can be forced
to be exclusively strings and exclusively unicode. Or
the strings can be unicode. Or anything goes, mixed
unicode and non-unicode strings as well as integers, floats, etc.

This is an object-oriented module
which inherits from
[Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) and extends its functionality by
providing for unicode keys and values for hashtables and
unicode content for array elements or scalars, randomly mixed with the
usual repertoire of [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure), which is
non-unicode strings,
numerical, boolean values and the assorted entourage to the court
of Emperor Computer, post-Turing.

For example, it produces these:

- unicode scalars: e.g. `"αβγ"`,
- mixed arrays: e.g. `["αβγ", "123", "xyz"]`
- hashtables with some/all keys and/or values as unicode: e.g.
`{"αβγ" =` "123", "xyz" => "αβγ"}>
- exclusive unicode arrays or hashtables: e.g. `["αβγ", "χψζ"]`

This is accomplised by adding an extra
type `string-UTF8` (invisible to the user) and the
respective generator method. All these are invisible to the user
which will get the old functionality plus some (or maybe none
because this is a random process which does not eliminate non-unicode
strings, at the moment) unicode strings.

      use Data::Random::Structure::UTF8;

      my $randomiser = Data::Random::Structure::UTF8->new(
          'max_depth' => 5,
          'max_elements' => 20,
          # all the strings produced (keys, values, elements)
          # will be unicode strings
          'only-unicode' => 1,
          # all the strings produced (keys, values, elements)
          # will be a mixture of unicode and non-unicode
          # this is the default behaviour
          #'only-unicode' => 0,
          # only unicode strings will be produced for (keys, values, elements),
          # there will be no numbers, no bool, only unicode strings
          #'only-unicode' => 2,
      );
      my $perl_var = $randomiser->generate() or die;
      print pp($perl_var);

      # which prints the usual escape mess of Dump and Dumper
  [
    "\x{7D5A}\x{4EC1}",
    "\x{E6E2}\x{75A4}",
    329076,
    0.255759160148987,
    [
      "TEb97qJt",
      1,
      "_ow|J\@~=6%*N;52?W3Y\$S1",
      {
        "x{75A4}x{75A4}" => 123,
        "123" => "\x{7D5A}\x{4EC1}",
        "xyz" => [1, 2, "\x{7D5A}\x{4EC1}"],
      },
    ],

      # can control the scalar type (for keys, values, items) on the fly
      # this produces unicode strings in addition to
      # Data::Random::Structure's usual repertoire:
      # non-unicode-string, numbers, bool, integer, float, etc.
      # (see there for the list)
      $randomiser->only_unicode(0); # the default: anything plus unicode strings
      print $randomiser->only_unicode();

      # this produces unicode strings in addition to
      # Data::Random::Structure's usual repertoire:
      # numbers, bool, integer, float, etc.
      # (see there for the list)
      # EXCEPT non-unicode-strings, (all strings will be unicode)
      $randomiser->only_unicode(1);
      print $randomiser->only_unicode();

      # this produces unicode strings ONLY
      # Data::Random::Structure's usual repertoire does not apply
      # there will be no numbers, no bool, no integer, no float, no nothing
      $randomiser->only_unicode(2);
      print $randomiser->only_unicode();

# METHODS

This is an object oriented module which has exactly the same API as
[Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure).

## `new`

Constructor. In addition to [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) `<new()`>
API, it takes parameter `'only-unicode'` with
a valid value of 0, 1 or 2. Default is 0.

- 0 : keys, values, elements of the produced data structure will be
a mixture of unicode strings, plus [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure)'s full
repertoire which includes non-unicode strings, integers, floats etc.
- 1 : keys, values, elements of the produced data structure will be
a mixture of unicode strings, plus [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure)'s full
repertoire except non-unicode strings. That is, all strings will be
unicode. But there will possibly be integers etc.
- 2 : keys, values, elements of the produced data structure will be
only unicode strings. Nothing of [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure)'s
repertoire applies. Only unicode strings, no integers, no nothing.

Controlling the scalar data types can also be done on the fly, after
the object has been created using
[Data::Random::Structure::UTF8](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3AUTF8) `<only_unicode()`>
method.

Additionally, [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) `<new()`>'s API reports that
the constructor takes 2 optional arguments, `max_depth` and `max_elements`.
See [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) `<new()`> for up-to-date, official information.

## `only_unicode`

Controls what scalar types to be included in the nested
data structures generated. With no parameters it returns back
the current setting. Otherwise, valid input parameters and their
meanings are listed in [Data::Random::Structure::UTF8](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3AUTF8) `<new()`>

## `generate`

Generate a nested data structure according to the specification
set in the constructor. See [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) `<generate()`> for
all options. This method is not overriden by this module.

It returns the Perl data structure as a reference.

## `generate_scalar`

Generate a scalar which may contain unicode content.
See [Data::Random::Structure::generate\_scalar](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3Agenerate_scalar) for
all options. This method is overriden by this module but
calls the parent's too.

It returns a Perl string.

## `generate_array`

Generate an array with random, possibly unicode, content.
See [Data::Random::Structure::generate\_array](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3Agenerate_array) for
all options. This method is not overriden by this module.

It returns the Perl array as a reference.

## `generate_hash`

Generate an array with random, possibly unicode, content.
See [Data::Random::Structure::generate\_array](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3Agenerate_array) for
all options. This method is not overriden by this module.

It returns the Perl array as a reference.

## `random_char_UTF8`

Return a random unicode character, guaranteed to be valid.
This is a very simple method which selects characters
from some pre-set code pages (Greek, Cyrillic, Cherokee,
Ethiopic, Javanese) with equal probability.
These pages and ranges were selected so that there are
no "holes" between them which would produce an invalid
character. Therefore, not all characters from the
particular code page will be produced.

Returns a random unicode character guaranteed to be valid.

## `random_chars_UTF8`

    my $ret = random_chars_UTF8($optional_paramshash)

Arguments:

- `$optional_paramshash` : can contain
    - `'min'` sets the minimum length of the random sequence to be returned, default is 6
    - `'max'` sets the maximum length of the random sequence to be returned, default is 32

Return a random unicode-only string optionally specifying
minimum and maximum length. See
[Data::Random::Structure::UTF8](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3AUTF8) `<random_chars_UTF8()`>
for the range of characters it returns. The returned string
is unicode and is guaranteed all its characters are valid.

# SUBROUTINES

## `check_content_recursively`

    my $ret = check_content_recursively($perl_var, $paramshashref)

Arguments:

- `$perl_var` : a Perl variable containing an arbitrarily nested data structure
- `$paramshashref` : can contain one or more of the following keys:
    - `'numbers'` set it to 1 to look for numbers (possibly among other things).
    If set to 1 and a number `123` or `"123"` is found, this sub returns 1.
    Set it to 0 to not look for numbers at all (and not report if
    there are no numbers) - _don't bother checking for numbers_, that's what
    setting this to zero means.
    - `'strings-unicode'` set it to 1 to look for unicode strings (possibly among other things).
    The definition of "unicode string" is that at least one its characters is unicode.
    If set to 1 and a "unicode string" is found, this sub returns 1.
    - `'strings-plain'` set it to 1 to look for plain strings (possibly among other things).
    The definition of "plain string" is that none of its characters is unicode.
    If set to 1 and a "plain string" is found, this sub returns 1.
    - `'strings'` set it to 1 to look for plain or unicode strings (possibly among other things).
    If set to 1 and a "plain string" or "unicode string" is found, this sub returns 1. Basically,
    it returns 1 when a string is found (as opposed to a "number").

In general, by setting `<'strings-unicode'=`1>> you are checking whether
the input Perl variable contains a unicode string in a key, a value,
an array element, or a scalar reference.

But, setting `<'strings-unicode'=`0>>, it simply means do not look for
this. It does not mean _report if they are NO unicode strings_.

Return value: 1 or 0 depending whether what
was looking for, was found.

This is not an object-oriented method. It is called thously:

    # check if ANY scalar (hash key, value, array element or scalar ref)
    # contains ONLY single number (integer, float)
    # the decicion is made by Scalar::Util:looks_like_number()
    if( Data::Random::Structure::UTF8::check_content_recursively(
        {'abc'=>123, 'xyz'=>[1,2,3]},
        {
                # look for numbers, are there any?
                'numbers' => 1,
        }
    ) ){ print "data structure contains numbers\n" }

    # check if it contains no numbers but it does unicode strings
    if( Data::Random::Structure::UTF8::check_content_recursively(
        {'abc'=>123, 'xyz'=>[1,2,3]},
        {
                # don't look for numbers
                'numbers' => 0,
                # look for unicode strings, are there any?
                'strings-unicode' => 1,
        }
    ) ){ print "data structure contains numbers\n" }

CAVEAT: as its name suggests, this is a recursive function. Beware
of extremely deep data structures. Deep, not long. If you do get
`<"Deep recursion..." warnings`>, and you do insist to go ahead,
this will remove the warnings (but are you sure?):

    {
        no warnings 'recursion';
        if( Data::Random::Structure::UTF8::check_content_recursively(
            {'abc'=>123, 'xyz'=>[1,2,3]},
            {
                'numbers' => 1,
            }
        ) ){ print "data structure contains numbers\n" }
    }

# SEE ALSO

- The parent class [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure).
- [Data::Roundtrip](https://metacpan.org/pod/Data%3A%3ARoundtrip) for stringifying possibly-unicode Perl data structures.

# AUTHOR

Andreas Hadjiprocopis, `<bliako ta cpan.org / andreashad2 ta gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-data-random-structure-utf8 at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Random-Structure-UTF8](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Random-Structure-UTF8).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# CAVEATS

There are two issues users should know about.

The first issue is that the unicode produced can make
[Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) to complain with

    Operation "lc" returns its argument for UTF-16 surrogate U+DA4B at /usr/local/share/perl5/Data/Dump.pm line 302.

This, I have found, can be fixed with the following workaround (from [github user iafan](https://github.com/evernote/serge/commit/865402bbde42101345a5bee4cd0a855b9b76bdd7), thank you):

    # Suppress `Operation "lc" returns its argument for UTF-16 surrogate 0xNNNN` warning
    # for the `lc()` call below; use 'utf8' instead of a more appropriate 'surrogate' pragma
    # since the latter is not available in until Perl 5.14
    no warnings 'utf8';

The second issue is that this class inherits from [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure)
and relies on it complaining about not being able to handle certain types
which are our own extensions (the `string-UTF8` extension). We have
no way to know that except from catching its `croak`'ing and parsing it
with the following code

    my $rc = eval { $self->SUPER::generate_scalar(@_) };
    if( $@ || ! defined($rc) ){
      # parent doesn't know what to do, can we handle this?
      if( $@ !~ /how to generate (.+?)\R/ ){ ...  ... }
      else { print "type is $1" }
      ...

in order to extract the `type` which can not be handled
and handle it ourselves. So whenever the parent class ([Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure))
changes its `croak` song, we will have to adopt this code
accordingly (in [Data::Random::Structure::UTF8](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure%3A%3AUTF8) `<generate_scalar()`>).
For the moment, I have placed a catch-all, fall-back condition
to handle this but it will be called for all kind of types
and not only the types we have added.

So, this issue is not going to make the module die but may make it
to skew the random results in favour of unicode strings (which
is the fallback, default action when can't parse the type).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Random::Structure::UTF8

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Random-Structure-UTF8](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Random-Structure-UTF8)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Data-Random-Structure-UTF8](http://annocpan.org/dist/Data-Random-Structure-UTF8)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Data-Random-Structure-UTF8](https://cpanratings.perl.org/d/Data-Random-Structure-UTF8)

- Search CPAN

    [https://metacpan.org/release/Data-Random-Structure-UTF8](https://metacpan.org/release/Data-Random-Structure-UTF8)

# SEE ALSO

- [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) 

# ACKNOWLEDGEMENTS

Mark Allen who created [Data::Random::Structure](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AStructure) which is our parent class.

# DEDICATIONS AND HUGS

!Almaz!

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
