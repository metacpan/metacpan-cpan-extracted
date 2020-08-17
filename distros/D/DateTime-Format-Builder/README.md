# NAME

DateTime::Format::Builder - Create DateTime parser classes and objects.

# VERSION

version 0.83

# SYNOPSIS

    package DateTime::Format::Brief;

    use DateTime::Format::Builder (
        parsers => {
            parse_datetime => [
                {
                    regex  => qr/^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
                    params => [qw( year month day hour minute second )],
                },
                {
                    regex  => qr/^(\d{4})(\d\d)(\d\d)$/,
                    params => [qw( year month day )],
                },
            ],
        }
    );

# DESCRIPTION

DateTime::Format::Builder creates DateTime parsers. Many string formats of
dates and times are simple and just require a basic regular expression to
extract the relevant information. Builder provides a simple way to do this
without writing reams of structural code.

Builder provides a number of methods, most of which you'll never need, or at
least rarely need. They're provided more for exposing of the module's innards
to any subclasses, or for when you need to do something slightly beyond what I
expected.

# TUTORIAL

See [DateTime::Format::Builder::Tutorial](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3ATutorial).

# ERROR HANDLING AND BAD PARSES

Often, I will speak of `undef` being returned, however that's not strictly
true.

When a simple single specification is given for a method, the method isn't
given a single parser directly. It's given a wrapper that will call `on_fail`
if the single parser returns `undef`. The single parser must return `undef`
so that a multiple parser can work nicely and actual errors can be thrown from
any of the callbacks.

Similarly, any multiple parsers will only call `on_fail` right at the end
when it's tried all it could.

`on_fail` (see [later](#on_fail)) is defined, by default, to throw an error.

Multiple parser specifications can also specify `on_fail` with a coderef as
an argument in the options block. This will take precedence over the
inheritable and overrideable method.

That said, don't throw real errors from callbacks in multiple parser
specifications unless you really want parsing to stop right there and not try
any other parsers.

In summary: calling a **method** will result in either a `DateTime` object
being returned or an error being thrown (unless you've overridden `on_fail`
or `create_method`, or you've specified a `on_fail` key to a multiple
parser specification).

Individual **parsers** (be they multiple parsers or single parsers) will return
either the `DateTime` object or `undef`.

# SINGLE SPECIFICATIONS

A single specification is a hash ref of instructions on how to create a
parser.

The precise set of keys and values varies according to parser type. There are
some common ones though:

- length

    **length** is an optional parameter that can be used to specify that this
    particular _regex_ is only applicable to strings of a certain fixed
    length. This can be used to make parsers more efficient. It's strongly
    recommended that any parser that can use this parameter does.

    You may happily specify the same length twice. The parsers will be tried in
    order of specification.

    You can also specify multiple lengths by giving it an arrayref of numbers
    rather than just a single scalar. If doing so, please keep the number of
    lengths to a minimum.

    If any specifications without _length_s are given and the particular
    _length_ parser fails, then the non-_length_ parsers are tried.

    This parameter is ignored unless the specification is part of a multiple
    parser specification.

- label

    **label** provides a name for the specification and is passed to some of the
    callbacks about to mentioned.

- on\_match and on\_fail

    **on\_match** and **on\_fail** are callbacks. Both routines will be called with
    parameters of:

    - input

        **input** is the input to the parser (after any preprocessing callbacks).

    - label

        **label** is the label of the parser if there is one.

    - self

        **self** is the object on which the method has been invoked (which may just be
        a class name). Naturally, you can then invoke your own methods on it do get
        information you want.

    - **args** is an arrayref of any passed arguments, if any. If there were no
    arguments, then this parameter is not given.

    These routines will be called depending on whether the **regex** match
    succeeded or failed.

- preprocess

    **preprocess** is a callback provided for cleaning up input prior to
    parsing. It's given a hash as arguments with the following keys:

    - input

        **input** is the datetime string the parser was given (if using multiple
        specifications and an overall _preprocess_ then this is the date after it's
        been through that preprocessor).

    - parsed

        **parsed** is the state of parsing so far. Usually empty at this point unless
        an overall _preprocess_ was given.  Items may be placed in it and will be
        given to any **postprocess**or and `DateTime->new` (unless the
        postprocessor deletes it).

    - self, args, label

        **self**, **args**, **label** as per _on\_match_ and _on\_fail_.

    The return value from the routine is what is given to the _regex_. Note that
    this is last code stop before the match.

    **Note**: mixing _length_ and a _preprocess_ that modifies the length of the
    input string is probably not what you meant to do. You probably meant to use
    the _multiple parser_ variant of _preprocess_ which is done **before** any
    length calculations. This `single parser` variant of _preprocess_ is
    performed **after** any length calculations.

- postprocess

    **postprocess** is the last code stop before `DateTime->new` is
    called. It's given the same arguments as _preprocess_. This allows it to
    modify the parsed parameters after the parse and before the creation of the
    object. For example, you might use:

        {
            regex       => qr/^(\d\d) (\d\d) (\d\d)$/,
            params      => [qw( year  month  day   )],
            postprocess => \&_fix_year,
        }

    where `_fix_year` is defined as:

        sub _fix_year {
            my %args = @_;
            my ( $date, $p ) = @args{qw( input parsed )};
            $p->{year} += $p->{year} > 69 ? 1900 : 2000;
            return 1;
        }

    This will cause the two digit years to be corrected according to the cut
    off. If the year was '69' or lower, then it is made into 2069 (or 2045, or
    whatever the year was parsed as). Otherwise it is assumed to be 19xx. The
    [DateTime::Format::Mail](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AMail) module uses code similar to this (only it allows the
    cut off to be configured and it doesn't use Builder).

    **Note**: It is **very important** to return an explicit value from the
    _postprocess_ callback. If the return value is false then the parse is taken
    to have failed. If the return value is true, then the parse is taken to have
    succeeded and `DateTime->new` is called.

See the documentation for the individual parsers for their valid keys.

Parsers at the time of writing are:

- [DateTime::Format::Builder::Parser::Regex](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3AParser%3A%3ARegex) - provides regular expression
based parsing.
- [DateTime::Format::Builder::Parser::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3AParser%3A%3AStrptime) - provides strptime based
parsing.

## Subroutines / coderefs as specifications.

A single parser specification can be a coderef. This was added mostly because
it could be and because I knew someone, somewhere, would want to use it.

If the specification is a reference to a piece of code, be it a subroutine,
anonymous, or whatever, then it's passed more or less straight through. The
code should return `undef` in event of failure (or any false value, but
`undef` is strongly preferred), or a true value in the event of success
(ideally a `DateTime` object or some object that has the same interface).

This all said, I generally wouldn't recommend using this feature unless you
have to.

## Callbacks

I mention a number of callbacks in this document.

Any time you see a callback being mentioned, you can, if you like, substitute
an arrayref of coderefs rather than having the straight coderef.

# MULTIPLE SPECIFICATIONS

These are very easily described as an array of single specifications.

Note that if the first element of the array is an arrayref, then you're
specifying options.

- preprocess

    **preprocess** lets you specify a preprocessor that is called before any of the
    parsers are tried. This lets you do things like strip off timezones or any
    unnecessary data. The most common use people have for it at present is to get
    the input date to a particular length so that the _length_ is usable
    ([DateTime::Format::ICal](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AICal) would use it to strip off the variable length
    timezone).

    Arguments are as for the _single parser_ _preprocess_ variant with the
    exception that _label_ is never given.

- on\_fail

    **on\_fail** should be a reference to a subroutine that is called if the parser
    fails. If this is not provided, the default action is to call
    `DateTime::Format::Builder::on_fail`, or the `on_fail` method of the
    subclass of DTFB that was used to create the parser.

# EXECUTION FLOW

Builder allows you to plug in a fair few callbacks, which can make following
how a parse failed (or succeeded unexpectedly) somewhat tricky.

## For Single Specifications

A single specification will do the following:

User calls parser:

    my $dt = $class->parse_datetime($string);

1. _preprocess_ is called. It's given `$string` and a reference to the parsing
workspace hash, which we'll call `$p`. At this point, `$p` is empty. The
return value is used as `$date` for the rest of this single parser.  Anything
put in `$p` is also used for the rest of this single parser.
2. _regex_ is applied.
3. If _regex_ **did not** match, then _on\_fail_ is called (and is given `$date`
and also _label_ if it was defined). Any return value is ignored and the next
thing is for the single parser to return `undef`.

    If _regex_ **did** match, then _on\_match_ is called with the same arguments
    as would be given to _on\_fail_. The return value is similarly ignored, but we
    then move to step 4 rather than exiting the parser.

4. _postprocess_ is called with `$date` and a filled out `$p`. The return
value is taken as a indication of whether the parse was a success or not. If
it wasn't a success then the single parser will exit at this point, returning
undef.
5. `DateTime->new` is called and the user is given the resultant `DateTime`
object.

See the section on [error handling](#error-handling-and-bad-parses)
regarding the `undef`s mentioned above.

## For Multiple Specifications

With multiple specifications:

User calls parser:

    my $dt = $class->complex_parse($string);

1. The overall _preprocess_or is called and is given `$string` and the hashref
`$p` (identically to the per parser _preprocess_ mentioned in the previous
flow).

    If the callback modifies `$p` then a **copy** of `$p` is given to each of the
    individual parsers. This is so parsers won't accidentally pollute each other's
    workspace.

2. If an appropriate length specific parser is found, then it is called and the
single parser flow (see the previous section) is followed, and the parser is
given a copy of `$p` and the return value of the overall _preprocess_or as
`$date`.

    If a `DateTime` object was returned so we go straight back to the user.

    If no appropriate parser was found, or the parser returned `undef`, then we
    progress to step 3!

3. Any non-_length_ based parsers are tried in the order they were specified.

    For each of those the single specification flow above is performed, and is
    given a copy of the output from the overall preprocessor.

    If a real `DateTime` object is returned then we exit back to the user.

    If no parser could parse, then an error is thrown.

See the section on [error handling](#error-handling-and-bad-parses) regarding
the `undef`s mentioned above.

# METHODS

In the general course of things you won't need any of the methods. Life often
throws unexpected things at us so the methods are all available for use.

## import

`import` is a wrapper for `create_class`. If you specify the _class_ option
(see documentation for `create_class`) it will be ignored.

## create\_class

This method can be used as the runtime equivalent of `import`. That is, it
takes the exact same parameters as when one does:

    use DateTime::Format::Builder ( ... )

That can be (almost) equivalently written as:

    use DateTime::Format::Builder;
    DateTime::Format::Builder->create_class( ... );

The difference being that the first is done at compile time while the second
is done at run time.

In the tutorial I said there were only two parameters at present. I
lied. There are actually three of them.

- parsers

    **parsers** takes a hashref of methods and their parser specifications. See the
    [DateTime::Format::Builder::Tutorial](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3ATutorial) for details.

    Note that if you define a subroutine of the same name as one of the methods
    you define here, an error will be thrown.

- constructor

    **constructor** determines whether and how to create a `new` function in the
    new class. If given a true value, a constructor is created. If given a false
    value, one isn't.

    If given an anonymous sub or a reference to a sub then that is used as
    `new`.

    The default is `1` (that is, create a constructor using our default code
    which simply creates a hashref and blesses it).

    If your class defines its own `new` method it will not be overwritten. If you
    define your own `new` and **also** tell Builder to define one an error will be
    thrown.

- verbose

    **verbose** takes a value. If the value is `undef`, then logging is
    disabled. If the value is a filehandle then that's where logging will go. If
    it's a true value, then output will go to `STDERR`.

    Alternatively, call `$DateTime::Format::Builder::verbose` with the relevant
    value. Whichever value is given more recently is adhered to.

    Be aware that verbosity is a global setting.

- class

    **class** is optional and specifies the name of the class in which to create
    the specified methods.

    If using this method in the guise of `import` then this field will cause an
    error so it is only of use when calling as `create_class`.

- version

    **version** is also optional and specifies the value to give `$VERSION` in the
    class. It's generally not recommended unless you're combining with the
    _class_ option. A `ExtUtils::MakeMaker` / `CPAN` compliant version
    specification is much better.

In addition to creating any of the methods it also creates a `new` method
that can instantiate (or clone) objects.

# SUBCLASSING

In the rest of the documentation I've often lied in order to get some of the
ideas across more easily. The thing is, this module's very flexible. You can
get markedly different behaviour from simply subclassing it and overriding
some methods.

## create\_method

Given a parser coderef, returns a coderef that is suitable to be a method.

The default action is to call `on_fail` in the event of a non-parse, but you
can make it do whatever you want.

## on\_fail

This is called in the event of a non-parse (unless you've overridden
`create_method` to do something else.

The single argument is the input string. The default action is to call
`croak`. Above, where I've said parsers or methods throw errors, this is
the method that is doing the error throwing.

You could conceivably override this method to, say, return `undef`.

# USING BUILDER OBJECTS aka USERS USING BUILDER

The methods listed in the [METHODS](https://metacpan.org/pod/METHODS) section are all you generally need when
creating your own class. Sometimes you may not want a full blown class to
parse something just for this one program. Some methods are provided to make
that task easier.

## new

The basic constructor. It takes no arguments, merely returns a new
`DateTime::Format::Builder` object.

    my $parser = DateTime::Format::Builder->new;

If called as a method on an object (rather than as a class method), then it
clones the object.

    my $clone = $parser->new;

## clone

Provided for those who prefer an explicit `clone` method rather than using
`new` as an object method.

    my $clone_of_clone = $clone->clone;

## parser

Given either a single or multiple parser specification, sets the object to
have a parser based on that specification.

    $parser->parser(
        regex  => qr/^ (\d{4}) (\d\d) (\d\d) $/x;
        params => [qw( year    month  day    )],
    );

The arguments given to `parser` are handed directly to `create_parser`. The
resultant parser is passed to `set_parser`.

If called as an object method, it returns the object.

If called as a class method, it creates a new object, sets its parser and
returns that object.

## set\_parser

Sets the parser of the object to the given parser.

    $parser->set_parser($coderef);

Note: this method does not take specifications. It also does not take anything
except coderefs. Luckily, coderefs are what most of the other methods produce.

The method return value is the object itself.

## get\_parser

Returns the parser the object is using.

    my $code = $parser->get_parser;

## parse\_datetime

Given a string, it calls the parser and returns the `DateTime` object that
results.

    my $dt = $parser->parse_datetime('1979 07 16');

The return value, if not a `DateTime` object, is whatever the parser wants to
return. Generally this means that if the parse failed an error will be thrown.

## format\_datetime

If you call this function, it will throw an error.

# LONGER EXAMPLES

Some longer examples are provided in the distribution. These implement some of
the common parsing DateTime modules using Builder. Each of them are, or were,
drop in replacements for the modules at the time of writing them.

# THANKS

Dave Rolsky (DROLSKY) for kickstarting the DateTime project, writing
[DateTime::Format::ICal](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AICal) and [DateTime::Format::MySQL](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AMySQL), and some much needed
review.

Joshua Hoblitt (JHOBLITT) for the concept, some of the API, impetus for
writing the multi-length code (both one length with multiple parsers and
single parser with multiple lengths), blame for the Regex custom constructor
code, spotting a bug in Dispatch, and more much needed review.

Kellan Elliott-McCrea (KELLAN) for even more review, suggestions,
[DateTime::Format::W3CDTF](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AW3CDTF) and the encouragement to rewrite these docs almost
100%!

Claus Färber (CFAERBER) for having me get around to fixing the
auto-constructor writing, providing the 'args'/'self' patch, and suggesting
the multi-callbacks.

Rick Measham (RICKM) for [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime) which Builder now
supports.

Matthew McGillis for pointing out that `on_fail` overriding should be
simpler.

Simon Cozens (SIMON) for saying it was cool.

# SEE ALSO

`datetime@perl.org` mailing list.

http://datetime.perl.org/

[perl](https://metacpan.org/pod/perl), [DateTime](https://metacpan.org/pod/DateTime), [DateTime::Format::Builder::Tutorial](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3ATutorial),
[DateTime::Format::Builder::Parser](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder%3A%3AParser)

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/DateTime-Format-Builder/issues](https://github.com/houseabsolute/DateTime-Format-Builder/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for DateTime-Format-Builder can be found at [https://github.com/houseabsolute/DateTime-Format-Builder](https://github.com/houseabsolute/DateTime-Format-Builder).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://www.urth.org/fs-donation.html](https://www.urth.org/fs-donation.html).

# AUTHORS

- Dave Rolsky <autarch@urth.org>
- Iain Truskett <spoon@cpan.org>

# CONTRIBUTORS

- Daisuke Maki <daisuke@endeworks.jp>
- James Raspass <jraspass@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
