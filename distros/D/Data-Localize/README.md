# NAME

Data::Localize - Alternate Data Localization API

# SYNOPSIS

    use Data::Localize;

    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class      => "Namespace", # Locale::Maketext-style .pm files
        namespaces => [ "MyApp::I18N" ]
    );

    $loc->add_localizer( 
        class => "Gettext",
        path  => "/path/to/localization/data/*.po"
    );

    $loc->set_languages();
    # or explicitly set one
    # $loc->set_languages('en', 'ja' );

    # looks under $self->languages, and checks if there are any
    # localizers that can handle the job
    $loc->localize( 'Hellow, [_1]!', 'John Doe' );

    # You can enable "auto", which will be your last resort fallback.
    # The key you give to the localize method will be used as the lexicon
    $self->auto(1);

# DESCRIPTION

Data::Localize is an object oriented approach to localization, aimed to
be an alternate choice for Locale::Maketext, Locale::Maketext::Lexicon, and
Locale::Maketext::Simple.

# RATIONALE

Functionality-wise, Locale::Maketext does what it advertises to do.
Here's a few reasons why you might or might not choose Data::Localize
over Locale::Maketext-based localizers:

## Object-Oriented

Data::Localize is completely object-oriented. YMMV.

## Faster

On some my benchmarks, Data::Localize is faster than Locale::Maketext
by 50~80%. (But see PERFORMANCE)

## Scalable For Large Amount Of Lexicons

Whereas Locale::Maketext generally stores the lexicons in memory,
Data::Localize allows you to store this data in alternate storage.
By default Data::Localize comes with a BerkeleyDB backend.

# BASIC WORKING 

## STRUCTURE

Data::Localize is a wrapper around various Data::Localize::Localizer 
implementers (localizers). So if you don't specify any localizers, 
Data::Localize will do... nothing (unless you specify `auto`).

Localizers are the objects that do the actual localization. Localizers must
register themselves to the Data::Localize parent, noting which languages it
can handle (which usually is determined by the presence of data files like
en.po, ja.po, etc). A special language ID of '\*' is used to accept fallback
cases. Localizers registered to handle '\*' will be tried _after_ all other
language possibilities have been exhausted.

If the particular localizer cannot deal with the requested string, then
it simply returns nothing.

## AUTO-GENERATING LEXICONS

Locale::Maketext allows you to supply an "\_AUTO" key in the lexicon hash,
which allows you to pass a non-existing key to the localize() method, and
use it as the actual lexicon, if no other applicable lexicons exists.

Locale::Maketext attaches this to the lexicon hash itself, but Data::Localizer
differs in that it attaches to the Data::Localizer object itself, so you
don't have to place \_AUTO everywhere.

    # here, we're deliberately not setting any localizers
    my $loc = Data::Localize->new(auto => 1);

    # previous auto => 1 will force Data::Localize to fallback to
    # using the key ('Hello, [_1]') as the localization token.
    print $loc->localize('Hello, [_1]', 'John Doe'), "\n";

# UTF8

All data is expected to be in decoded utf8. You must "use utf8" or 
decode them to Perl's internal representation for all values
passed to Data::Localizer. We won't try to be smart for you. USE UTF8!

- Using Explicit decode()

        use Encode q(decode decode_utf8);
        use Data::Localizer;

        my $loc = Data::Localize->new(...);

        $loc->localize( $key, decode( 'iso-2022-jp', $value ) );

        # if $value is encoded utf8...
        # $loc->localize( $key, decode_utf8( $value ) );

- Using utf8

    "use utf8" is simpler, but do note that it will affect ALL your literal strings
    in the current scope

        use utf8;

        $loc->localize( $key, "some-utf8-key-here" );

# USING ALTERNATE STORAGE

By default all lexicons are stored on memory, but if you're building an app
with thousands and thousands of long messages, this might not be the ideal
solution. In such cases, you can change where the lexicons get stored

    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class         => 'Gettext',
        path          => '/path/to/data/*.po'
        storage_class => 'BerkeleyDB',
        storage_args  => {
            dir => '/path/to/really/fast/device'
        }
    );

This would cause Data::Localize to put all the lexicon data in several BerkeleyDB files under /path/to/really/fast/device

Note that this approach would buy you no gain if you use Data::Localize::Namespace, as that approach by default expects everything to be in memory.

# DEBUGGING

## DEBUG

To enable debug tracing, either set DATA\_LOCALIZE\_DEBUG environment variable,

    DATA_LOCALIZE_DEBUG=1 ./yourscript.pl

or explicitly define a function before loading Data::Localize:

    BEGIN {
        *Data::Localize::DEBUG = sub () { 1 };
    }
    use Data::Localize;

# METHODS

## add\_localizer

Adds a new localizer. You may either pass a localizer object, or arguments
to your localizer's constructor:

    $loc->add_localizer( YourLocalizer->new );

    $loc->add_localizer(
        class => "Namespace",
        namespaces => [ 'Blah' ]
    );

## localize

Localize the given string ID, using provided variables.

    $localized_string = $loc->localize( $id, @args );

## detect\_languages

Detects the current set of languages to use. If used in an CGI environment,
will attempt to detect the language of choice from headers. See
I18N::LanguageTags::Detect for details.

## detect\_languages\_from\_header 

Detects the language from the given header value, or from HTTP\_ACCEPT\_LANGUAGES environment variable

## localizers

Return a arrayref of localizers

## add\_localizer\_map

Used internally.

## set\_localizer\_map

Used internally.

## find\_localizers 

Finds a localizer by its attribute. Currently only supports isa

    my @locs = $loc->find_localizers(isa => 'Data::Localize::Gettext');

## set\_languages

If used without any arguments, calls detect\_languages() and sets the
current language set to the result of detect\_languages().

## languages

Gets the current list of languages

## add\_fallback\_languages

## fallback\_languages

## count\_localizers()

Return the number of localizers available

## get\_localizer\_from\_lang($lang)

Get appropriate localizer for language $lang

## grep\_localizers(\\&sub)

Filter localizers

# PERFORMANCE 

tl;dr: Use one that fits your needs

## Using explicit get\_handle for every request

This benchmark assumes that you're fetching the lexicon anew for
every request. This allows you to switch languages for every request

Benchmark run with Mac OS X (10.8.2) perl 5.16.1

    Running benchmarks with
      Locale::Maketext: 1.23
      Data::Localize:   0.00023
                         Rate D::L(Namespace)   L::M D::L(Gettext) D::L(Gettext+BDB)
    D::L(Namespace)    5051/s              --   -65%          -73%              -73%
    L::M              14423/s            186%     --          -24%              -24%
    D::L(Gettext)     18868/s            274%    31%            --               -1%
    D::L(Gettext+BDB) 18987/s            276%    32%            1%                --

## Using cached lexicon objects for all

This benchmark assumes that you're fetching the lexicon once for
a particular language, and you keep it in memory for reuse.
This does NOT allow you to switch languages for every request.

Benchmark run with Mac OS X (10.8.2) perl 5.16.1

    Running benchmarks with
      Locale::Maketext: 1.23
      Data::Localize:   0.00023
                          Rate D::L(Namespace) D::L(Gettext+BDB) D::L(Gettext)  L::M
    D::L(Namespace)     6023/s              --              -65%          -69%  -96%
    D::L(Gettext+BDB)  17202/s            186%                --          -12%  -87%
    D::L(Gettext)      19548/s            225%               14%            --  -86%
    L::M              135993/s           2158%              691%          596%    --

# TODO

Gettext style localization files -- Make it possible to decode them

# CONTRIBUTORS

Dave Rolsky

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# COPYRIGHT

- The "MIT" License

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
