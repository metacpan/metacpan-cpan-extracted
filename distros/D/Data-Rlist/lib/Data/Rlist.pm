#!/usr/bin/perl
# -*-cperl-*-

=head1 VENUE

Data::Rlist - A lightweight data language for Perl and C++

=cut

# $Writestamp: 2008-07-27 21:19:43 andreas$
# $Compile: perl -c Rlist.pm; pod2html --title="Random-Lists" Rlist.pm >../../Rlist.pm.html$
# $Comp1le: podchecker Rlist.pm$

=head1 SYNOPSIS

    use Data::Rlist;

File and string I/O for any Perl data F<$thing>:

    ### Compile data as text.

                  WriteData $thing, $filename;  # compile data into file
                  WriteData $thing, \$string;   # compile data into buffer
    $string_ref = WriteData $thing;             # dto.

    $string     = OutlineData $thing;           # compile printable text
    $string     = StringizeData $thing;         # compile text in a compact form (no newlines)
    $string     = SqueezeData $thing;           # compile text in a super-compact form (no whitespace)

    ### Parse data from text.

    $thing      = ReadData $filename;           # parse data from file
    $thing      = ReadData \$string;            # parse data from string buffer

F<L</ReadData>>,  F<L</WriteData>> etc.  are  L<auto-exported functions|/Exports>.   Alternately we
use:

    ### Qualified functions to parse text.

    $thing      = Data::Rlist::read($filename);
    $thing      = Data::Rlist::read($string_ref);
    $thing      = Data::Rlist::read_string($string_or_string_ref);

    ### Qualified functions to compile data into text.

                  Data::Rlist::write($thing, $filename);
    $string_ref = Data::Rlist::write_string($thing);
    $string     = Data::Rlist::write_string_value($thing);

    ### Print data to STDOUT.

    PrintData $thing;

The object-oriented interface:

    ### For objects the '-output' attribute refers to a string buffer or is a filename.
    ### The '-data' attribute defines the value or reference to be compiled into text.

    $object     = new Data::Rlist(-data => $thing, -output => \$target)

    $string_ref = $object->write;           # compile into $target, return \$target
    $string_ref = $object->write_string;    # compile into new string ($target not touched)
    $string     = $object->write_string_value; # dto. but return string value

    ### Print data to STDOUT.

    print $object->write_string_value;
    print ${$object->write};                # returns \$target

    ### Set output file and write $thing to disk.

    $object->set(-output => ".foorc");

    $object->write;                         # write "./.foorc", return 1
    $object->write(".barrc");               # write "./.barrc" (the filename overrides -output)

    ### The '-input' attribute defines the text to be compiled, either as
    ### string reference or filename.

    $object->set(-input => \$input_string); # assign some text

    $thing      = $object->read;            # parse $input_string into Perl data
    $thing      = $object->read($other_string); # parse $other_string (the argument overrides -input)

    $object->set(-input => ".foorc");       # assign some input file

    $foorc      = $object->read;            # parse ".foorc"
    $barrc      = $object->read(".barrc");  # parse some other file
    $thing      = $object->read(\$string);  # parse some string buffer
    $thing      = $object->read_string($string_or_ref); # dto.

Create deep-copies  of any Perl data.  The  metaphor "keelhaul" vividly connotes  that F<$thing> is
stringified, then compiled back:

    ### Compile a value or ref $thing into text, then parse back into data.

    $reloaded   = KeelhaulData $thing;
    $reloaded   = Data::Rlist::keelhaul($thing);

    $object     = new Data::Rlist(-data => $thing);
    $reloaded   = $object->keelhaul;

Do deep-comparisons of any Perl data:

    ### Deep-compare $a and $b and get a description of all type/value differences.

    @diffs      = CompareData($a, $b);

For more information see F<L</compile>>, F<L</keelhaul>>, and F<L</deep_compare>>.

=head1 DESCRIPTION

=head2 Venue

F<Random-Lists> (Rlist)  is a tag/value  text format, which  can "stringify" any data  structure in
7-bit ASCII text.  The basic types are lists  and scalars.  The syntax is similar, but not equal to
Perl's.  For example,

    ( "hello", "world" )
    { "hello" = "world"; }

designates two lists, the first of which is sequential, the second associative.  The format...

- allows the definition of hierachical and constant data,

- has no user-defined types, no keywords, no variables,

- has no arithmetic expressions,

- uses 7-bit-ASCII character encoding and escape sequences,

- uses C-style numbers and strings,

- has an extremely minimal syntax implementable in any programming language and system.

You can  write any  Perl data  structure into  files as legible  text.  Like  with CSV  the lexical
overhead of Rlist is minimal: files are merely data.

You can  read compiled texts back  in Perl and C++  programs.  No information will  be lost between
different program languages, and floating-point numbers keep their precision.

You can also compile structured CSV text  from Perl data, using special functions from this package
that will keep numbers precise and properly quote strings.

Since Rlist has no  user-defined types the data is structured out of  simple scalars and lists.  It
is conceivable, however, to develop a simple  type system and store type information along with the
actual data.  Otherwise the data structures are  tacit consents between the users of the data.  See
also the implemenation notes for L</Perl> and L</C++>.

=head2 Character Encoding

Rlist text uses the  7-bit-ASCII character set.  The 95 printable character  codes 32 to 126 occupy
one  character.  Codes  0 to  31 and  127  to 255  require four  characters each:  the F<\>  escape
character followed by  the octal code number.  For example, the  German Umlaut character F<E<uuml>>
(252) is translated into F<\374>.  An exception are the following codes:

    ASCII               ESCAPED AS
    -----               ----------
      9 tab               \t
     10 linefeed          \n
     13 return            \r
     34 quote     "       \"
     39 quote     '       \'
     92 backslash \       \\

=head2 Values and Default Values

F<Values> are either scalars,  array elements or the value of a pair.   Each value is constant.

The default scalar value is the empty string C<"">.  So in Perl F<undef> is compiled into C<"">.

=head2 Numbers, Strings and Here-Documents

Numbers constants adhere to the IEEE 754  syntax for integer- and floating-point numbers (i.e., the
same lexical conventions as in C and C++ apply).

Strings constants consisting only of  C<[a-zA-Z_0-9-/~:.@]> characters "look like identifiers" (aka
symbols) need  not to be  quoted.  Otherwise string  constants follow the C  language lexicography.
They strings must  be placed in double-quotes (single-quotes are not  allowed).  Quoted strings are
also escaped (i.e., characters are converted to the input character set of 7-bit ASCII).

You  can  define  a  string  using  a  line-oriented  form of  quoting  based  on  the  UNIX  shell
F<here-document> syntax and RFC 111.  Multiline quoted strings can be expressed with

    <<DELIMITER

Following the sigil F< << > an identifier  specifies how to terminate the string scalar.  The value
of the  scalar will be  all lines  following the current  line down to  the line starting  with the
delimiter (i.e., the delimiter must be at column  1).  There must be no space between the sigil and
the identifier.

B<EXAMPLES>

Quoted strings:

    "Hello, World!"

Unquoted strings (symbols, identifiers):

    foobar   cogito.ergo.sum   Memento::mori

Here-document strings:

    <<hamlet
    "This above all: to thine own self be true". - (Act I, Scene III).
    hamlet

Integegers and floats:

    38   10e-6   -.7   3.141592653589793

For more information see F<L</is_symbol>>, F<L</is_number>> and F<L</escape7>>.

=head2 List Values

We have two types of lists: sequential (aka array) and associative (aka map, hash, dictionary).

B<EXAMPLES>

Arrays:

    ( 1, 2, ( 3, "Audiatur et altera pars!" ) )

Maps:

    {
        key = value;
        standalone-key;
        Pi = 3.14159;

        "meta-syntactic names" = (foo, bar, "lorem ipsum", Acme, ___);

        var = {
            log = {
                messages = <<LOG;
    Nov 27 21:55:04 localhost kernel: TSC appears to be running slowly. Marking it as unstable
    Nov 27 22:34:27 localhost kernel: Uniform CD-ROM driver Revision: 3.20
    Nov 27 22:34:27 localhost kernel: Loading iSCSI transport class v2.0-724.<6>PNP: No PS/2 controller found. Probing ports directly.
    Nov 27 22:34:27 localhost kernel: wifi0: Atheros 5212: mem=0x26000000, irq=11
    LOG
            };
        };
    }

=head2 Binary Data

Binary data can  be represented as base64-encoded string,  or L<here-document|/Numbers, Strings and
Here-Documents> string.  For example,

    use MIME::Base64;

    $str = encode_base64($binary_buf);

The result F<$str> will be a string broken into  lines of no more than 76 characters each; the 76th
character  will be  a  newline C<"\n">.   Here  is a  complete  Perl program  that  creates a  file
F<random.rls>:

    use MIME::Base64;
    use Data::Rlist;

    our $binary_data = join('', map { chr(int rand 256) } 1..300);
    our $sample = { random_string => encode_base64($binary_data) };

    WriteData $sample, 'random.rls';

These few lines create a file F<random.rls> containing text like the following:

    {
        random_string = <<___
    w5BFJIB3UxX/NVQkpKkCxEulDJ0ZR3ku1dBw9iPu2UVNIr71Y0qsL4WxvR/rN8VgswNDygI0xelb
    aK3FytOrFg6c1EgaOtEudmUdCfGamjsRNHE2s5RiY0ZiaC5E5XCm9H087dAjUHPtOiZEpZVt3wAc
    KfoV97kETH3BU8/bFGOqscCIVLUwD9NIIBWtAw6m4evm42kNhDdQKA3dNXvhbI260pUzwXiLYg8q
    MDO8rSdcpL4Lm+tYikKrgCih9UxpWbfus+yHWIoKo/6tW4KFoufGFf3zcgnurYSSG2KRLKkmyEa+
    s19vvUNmjOH0j1Ph0ZTi2pFucIhok4krJi0B5yNbQStQaq23v7sTqNom/xdRgAITROUIoel5sQIn
    CqxenNM/M4uiUBV9OhyP
    ___
    ;
    }

Note that F<L</WriteData>>  uses the predefined C<"default"> configuration,  which enables here-doc
strings.  See also L<MIME::Base64>.

=head2 Embedded Perl Code (Nanoscripts)

Rlist text  can define embedded Perl  programs, called F<nanonscripts>.  The  embedded program text
has the form of a L<here-document|/Numbers,  Strings and Here-Documents> with the special delimiter
C<"perl">.  After  the Rlist text has  been parsed you call  F<L</evaluate_nanoscripts>> to F<eval>
all embedded Perl in the order of definiton.  The function arranges it that within the F<eval>...

=over

=item *

the F<$root> variable refers to the root of the input, as unblessed array- or hash-reference;

=item *

the F<$this> variable refers to the array or hash that stores the currently F<eval>'d nanoscript;

=item *

the F<$where> variable stores the name of the key, or the index, within F<$this>.

=back

The nanoscript  can use  this information to  oriented itself  within the parsed  data, or  even to
modify the  data in-place.  The result  of F<eval>'ing will  replace the nanoscript text.   You can
also  F<eval>  the   embedded  Perl  codes  programmatically,  using   the  F<L</nanoscripts>>  and
F<L</result>> functions.

B<EXAMPLES>

Simple example of an Rlist text that hosts Perl code:

    (<<perl)
    print "Hello, World!";
    perl

Here is a more complex example that defines a list of nanoscripts, and evaluates them:

    use Data::Rlist;

    $data = join('', <DATA>);
    $data = EvaluateData \$data;

    __END__
    ( <<perl, <<perl, <<perl, <<perl )
    print "Hello World!\n"          # english
    perl
    print "Hallo Welt!\n"           # german
    perl
    print "Bonjour le monde!\n"     # french
    perl
    print "Olá mundo!\n"            # spanish
    perl

When we execute the above script the following output is printed before the script exits:

    Hello World!
    Hallo Welt!
    Bonjour le monde!
    Olá mundo!

Note  that  when  the  Rlist  text  after  F<__END__>  is  placed  in  F<some_file>,  we  can  call
F<L</EvaluateData(C<"some_file">)>> for the same effect.  The next example modifies the parsed data
in place.  Imagine a file F<this_file_modifies_itself> with the following content:

    ( <<perl )
    ReadData(\\'{ foo = bar; }');
    perl

When we parse this file using

    $data = ReadData("this_file_modifies_itself");

to F<$data> will be assigned the following Perl value

    [ "ReadData(\\'{ foo = bar; }');\n" ]

Next we call F<Data::Rlist::L</evaluate_nanoscripts>()> to "morph" this value into

    [ { 'foo' => 'bar' } ]

The same effect can be achieved in just one call

    $data = EvaluateData("this_file_modifies_itself");

=head2 Comments

Rlist  supports multiple  forms  of comments:  F<//>  or F<#>  single-line-comments,  and F</*  */>
multi-line-comments. You may use all three forms at will.

=cut

package Data::Rlist;

use strict;
use warnings;
use Exporter;
use Carp;
use Scalar::Util qw/reftype/;
use integer;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS

            $DEBUG
            %PredefinedOptions
            $RoundScientific $SafeCppMode $EchoStderr
            $R $Fh $Locked $DefaultMaxDepth $MaxDepth $Depth
            $Errors $Warnings $Broken $MissingInput @Messages
            $DefaultCsvDelimiter $DefaultConfDelimiter $DefaultConfSeparator
            $DefaultNanoscriptToken

            $REPunctuationCharacter $REIntegerHere $REFloatHere
            $RESymbolCharacter $RESymbolHere $REStringHere
            $REInteger $REFloat
            $RESymbol $REString $REValue
            @REIsPunct @REIsDigit
           /;

# Parser/lexer variables.  Used by open_input, parse and lex. Declaring them as lexicals is
# slightly faster than to 'use vars'.

my($Readstruct, $ReadFh, $Ln, $LnArray);
my(%Rules, @VStk, @NStk);

use constant DEFAULT_VALUE => qq'""'; # default Rlist, the empty string

BEGIN {
    $VERSION = '1.44';
    $DEBUG = 0;
    @ISA = qw/Exporter/;

    # Always exported (:DEFAULT) when the package is fetched with "use", not "required".

    @EXPORT = qw/ReadCSV WriteCSV
                 ReadConf WriteConf
                 ReadData EvaluateData WriteData
                 PrintData OutlineData StringizeData SqueezeData
                 KeelhaulData CompareData/;

    # Symbols exported on request.

    @EXPORT_OK = qw/:DEFAULT

                    predefined_options complete_options

                    maybe_quote7 quote7 escape7 unquote7 unescape7 unhere
                    is_value is_random_text is_symbol is_integer is_number
                    split_quoted parse_quoted

                    equal round

                    keelhaul deep_compare fork_and_wait synthesize_pathname

                    $REInteger $REFloat $RESymbol/;

    %EXPORT_TAGS = (# Handle IEEE numbers
                    floats => [@EXPORT, qw/equal round is_number is_integer
                                          /],
                    # Handle (quoted) strings
                    strings => [@EXPORT, qw/maybe_quote7 quote7 escape7
                                            unquote7 unescape7 
                                            unhere split_quoted parse_quoted
                                            is_value is_random_text is_number is_integer is_symbol
                                           /],
                    # Compile options
                    options => [@EXPORT, qw/predefined_options complete_options
                                           /],
                    # Auxiliary functions
                    aux => [@EXPORT, qw/keelhaul deep_compare fork_and_wait synthesize_pathname
                                       /]);

    $MaxDepth = 0; $DefaultMaxDepth = 100; $Broken = 0;
    $SafeCppMode = 0;
    $EchoStderr = 0;
    $RoundScientific = 0;
    $DefaultConfSeparator = ' = ';
    $DefaultConfDelimiter = '\s*=\s*';
    $DefaultCsvDelimiter = '\s*,\s*';
    $DefaultNanoscriptToken = 'perl';

    %PredefinedOptions =
    (
     default =>
     {# Warning: "code_refs" are disabled by default because compile_fast() (the default compile
      # function) never calls subs.  Likewise the default "precision" must be undef!
      eol_space => "\n",
      bol_tabs => 1,
      outline_hashes => 0,
      outline_data => 6,
      paren_space => '',
      comma_punct => ', ',
      semicolon_punct => ';',
      assign_punct => ' = ',
      here_docs => 1,
      auto_quote => undef,      # let write() and write_csv() choose their defaults
      code_refs => 0,
      scientific => 0,
      separator => ',',
      delimiter => undef,
      precision => undef
     },

     string =>
     {
      eol_space => '',
      bol_tabs => 0,
      outline_data => 0,
      here_docs => 0
     },

     outlined =>
     {
      eol_space => "\n",
      bol_tabs => 1,
      outline_hashes => 1,
      outline_data => 1,
      paren_space => ' ',
      comma_punct => ', ',
     },

     squeezed =>
     {
      bol_tabs => 0,
      eol_space => '',
      outline_hashes => 0,
      outline_data => 0,
      here_docs => 0,
      code_refs => 0,
      paren_space => '',
      comma_punct => ',',
      assign_punct => '=',
      precision => 6,
     }
    );

    ########
    # Regular expressions for scalars
    #
    # $RESymbolHere shall be defined equal to the 'identifier' regex in 'rlist.l', to keep the
    # C/C++ and Perl implementations compatible.  See also the C++ function quote() and the
    # {identifier} rule in <rlist.l>
    #
    # In Perl regexes, by default the "^" character matches only the beginning of the string, the
    # "$" character only the end (or before the newline at the end). The "/s" modifier will force
    # "^" to match only at the beginning of the string and "$" to match only at the end (or just
    # before a newline at the end) of the string.  "$" hence ignores an optional trailing newline.
    #
    # When "/m" is used this means for "foo\nbar" the "$" matches the end of the string (after "r")
    # and also before every line break (between "o" and "\n").  Therefore we've to use "\z" which
    # matches only at the end of the string.

    $REIntegerHere = '[+-]?\d+';
    $REFloatHere = '(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?';
    $REPunctuationCharacter = '\=\,;\{\}\(\)';
    $RESymbolCharacter = 'a-zA-Z_0-9\-/\~:\.@';
    $RESymbolHere = '[a-zA-Z_\-/\~:@]'.qq'[$RESymbolCharacter]*';
    $REStringHere = '"[^"\\\r\n]*(?:\\.[^"\\\r\n]*)*"'; # " allowed inside the quotes, but only as \"

    $REInteger = qr/^$REIntegerHere\z/;
    $REFloat = qr/^$REFloatHere\z/;
    $RESymbol = qr/^$RESymbolHere\z/;
    $REString = qr/^$REStringHere\z/;

    $REValue = qr/$REString|
                  $REInteger|
                  $REFloat|
                  $RESymbol/x;

    $REValue = qr/^$REStringHere\z|
                  ^$REIntegerHere\z|
                  ^$REFloatHere\z|
                  ^$RESymbolHere\z/x if 0; # disabled because it is slightly slower

    ########
    # Rlist parser map:
    #
    #   token => [ rule, deduce-function ]
    #   rule  => [ rule, deduce-function ]
    #
    # See `lex()' for token meanings.

    sub syntax_error($;$) {
        my($msg, $tr) = (shift, shift||'??');
        $msg =~ s/\s/ /go; pr1nt('ERROR', $msg);
        $Errors++; $tr
    }
    sub warning($;$) {
        my($msg, $tr) = (shift, shift||'');
        $msg =~ s/\s/ /go; pr1nt('WARNING', $msg);
        $Warnings++; $tr
    }

    %Rules =
    (#
     # Key/value pairs.
     #
     # For nanoscripts (n) push hash-ref, key and the script to @NStk.
     #

     '{}'   => sub { push @VStk, { }; 'v' },
     '{h}'  => sub { 'v' },
     # first pairs (open the hash)
     'v;'   => sub { push @VStk, { pop(@VStk) => '' }; 'h' },
     'v=v;' => sub { push @VStk, { splice @VStk, -2 }; 'h' },
     'v=n;' => sub { my($k, $v) = splice @VStk, -2;
                     my $h = { $k => $v };
                     push @VStk, $h; push @NStk, [ $h, $k ]; 'h' },
     # subsequent pairs (complete the hash)
     'hv;'  => sub { my $k      = pop @VStk;        $VStk[$#VStk]->{$k} = ''; 'h' },
     'hv=v' => sub { my($k, $v) = splice @VStk, -2; $VStk[$#VStk]->{$k} = $v; 'h' },
     'hv=n' => sub { my($k, $v) = splice @VStk, -2; $VStk[$#VStk]->{$k} = $v; push @NStk, [ $VStk[$#VStk], $k ]; 'h' },
     'h;'   => sub { 'h' },

     #
     # Single values/scripts.
     #

     '()'   => sub { push @VStk, [ ]; 'v' },
     '(l)'  => sub { 'v' },
     '(v)'  => sub {                    push @VStk, [pop(@VStk)]; 'v' },
     '(n)'  => sub { my $v = pop @VStk; push @VStk, [ $v ]; push @NStk, [ $VStk[$#VStk], 0 ]; 'v' },
     'v,'   => sub {                    push @VStk, [pop(@VStk)]; 'l,' },
     'n,'   => sub { my $v = pop @VStk; push @VStk, [ $v ]; push @NStk, [ $VStk[$#VStk], 0 ]; 'l,' },
     'l,v'  => sub { my $v = pop @VStk; push @{$VStk[$#VStk]}, $v; 'l' }, # push to existing list
     'l,n'  => sub { my $v = pop @VStk; push @{$VStk[$#VStk]}, $v; push @NStk, [ $VStk[$#VStk], $#{$VStk[$#VStk]} ]; 'l' },

     #
     # Rules for syntax errors.  All rules containing '??' are error-recovery-rules.
     #

     '=??'  => sub { syntax_error("invalid value after '='", ';') },
     '??;'  => sub { syntax_error("invalid key/value before ';'", ';') },
     ',??'  => sub { push @VStk, ''; syntax_error("invalid value after ','", ',v') },
     '??'   => sub { '' },

     'vv'   => sub { my($k, $v) = splice @VStk, -2; syntax_error("missing ',' or ';'") },
     'v=v}' => sub { my($k, $v) = splice @VStk, -2; push @VStk, { $k => $v }; warning("unterminated pair: expected ';'", 'h}') },
     'v=v,' => sub { my($k, $v) = splice @VStk, -2; warning("pair terminated with ',': expected ';'", '??') },
     'v=;'  => sub { warning("missing value, or superfluous '='", 'v;') },
     'v=}'  => sub { warning("missing value: expected ';', not '}'", 'v;') },
     '(v}'  => sub { my $v = pop @VStk; syntax_error("expected ')' after value, not '}'") },
     '{v)'  => sub { my $v = pop @VStk; syntax_error("expected '(' before value, not '{'") },
     '{v}'  => sub { my $k = pop @VStk; push @VStk, { $k => '' }; warning("unterminated pair: expected ';'", 'h') },

     '(v,)' => sub { warning("superfluous ',' at end of list", '(v)') },
     '(l,)' => sub { warning("superfluous ',' at end of list",  'v') },

     '{{'   => sub { warning("non-scalar hash-key", '??') },
     '{('   => sub { warning("non-scalar hash-key", '??') },

     'n;'   => sub { warning("nanoscript ignored: shall be def'd as value, not key", 'v;') },
     'n=v;' => sub { warning("nanoscript ignored: shall be def'd as value, not key", 'v=v;') },
    );

    # True syntax errors, which cannot be converted into valid rules.  The error will be printed
    # and recorded in @Messages when '??' is actually reduced.

    foreach my $errrule ((',,', ',;', ';,', ';;',
                          '{=', '{,', '{;',
                          '(=', '(,', '(;',
                          '==',
                          '(v;', '(n;',
                          'v=,', 'v=)')) {
        die if exists $Rules{$errrule};
        $Rules{$errrule} = eval(<<___);
    sub { my \@r = map { s/\\s+/ /g; \$_ } map { if (/[vnhl]/) { pop(\@VStk) }; s/v/value/; s/n/nanoscript/; s/h/hash/; s/l/list/; \$_ }
                   split / */, '$errrule';
          return syntax_error("'".join(' ', \@r)."'"); }
___
    }

    my($rule_max, $rule_min) = (0, 9);
    foreach (keys %Rules) {
        $rule_min = length($_) if length($_) < $rule_min;
        $rule_max = length($_) if length($_) > $rule_max;
    }
    die $rule_min if $rule_min != 2;
    die $rule_max if $rule_max != 4;
}

sub pr1nt(@)
{
    # This function is used to write a new comment line (usually some sort of error message) into
    # the currently compiled file, and to STDERR (if $Data::Rlist::DEBUG).

    my $label = shift;
    my $msg = join(': ', grep { length }
                   ($label,
                    ((defined($Readstruct) &&
                      exists $Readstruct->{filename}) ? $Readstruct->{filename}."($.)" : ""),
                    grep { defined } @_))."\n";
    foreach my $fh (grep { defined } ($Fh, $EchoStderr ? *STDERR{IO} : undef)) {
        next unless defined $fh;
        print $fh map { $fh == defined($Fh) ? "# $_" : $_ } $msg;
    }
    push @Messages, $msg;
}

=head1 PACKAGE INTERFACE

The  core  functions to  cultivate  package objects  are  F<L</new>>,  F<L</dock>>, F<L</set>>  and
F<L</get>>.  When a regular package function is called in object context some omitted arguments are
read from object attributes.  This is  true for the following functions: F<L</read>>, F<L</write>>,
F<L</read_string>>,   F<L</write_string>>,  F<L</read_csv>>,   F<L</write_csv>>,  F<L</read_conf>>,
F<L</write_conf>> and F<L</keelhaul>>.

Unless called  in object  context the first  argument has  an indifferent meaning  (i.e., it  is no
F<Data::Rlist> reference).  Then F<L</read>> expects an  input file or string, F<L</write>> the data
to compile etc.

=head2 Construction

=over

=item F<new([ATTRIBUTES])>

Create a F<Data::Rlist> object from the hash ATTRIBUTES. For example,

    $self = Data::Rlist->new(-input => 'this.dat',
                             -data => $thing,
                             -output => 'that.dat');

For   this   object   the   call   F<L<$self-E<gt>read()|/read>>  reads   from   F<this.dat>,   and
F<L<$self-E<gt>write()|/write>> writes any Perl data F<$thing> to F<that.dat>.

B<REGULAR OBJECT ATTRIBUTES>

=over 8

=item C<-input =E<gt> INPUT>

=item C<-filter =E<gt> FILTER>

=item C<-filter_args =E<gt> FILTER-ARGS>

Defines what  Rlist text to  parse and  how to preprocess  an input file.   INPUT is a  filename or
string reference.  FILTER can be 1 to  select the standard C preprocessor F<cpp>.  These attributes
are applied by F<L</read>>, F<L</read_string>>, F<L</read_conf>> and F<L</read_csv>>.

=item C<-data =E<gt> DATA>

=item C<-options =E<gt> OPTIONS>

=item C<-output =E<gt> OUTPUT>

Defines  the Perl  data to  be L<compiled|/compile>  into  text (DATA),  how it  shall be  compiled
(OPTIONS) and  where to  store the  compiled text (OUTPUT).   When OUTPUT  is string  reference the
compiled text  will be stored  in that string.   When OUTPUT is F<undef>  a new string  is created.
When OUTPUT  is a string  value it is  a filename.  These  attributes are applied  by F<L</write>>,
F<L</write_string>>, F<L</write_conf>>, F<L</write_csv>> and F<L</keelhaul>>.

=item C<-header =E<gt> HEADER>

Defines an array  of text lines, each of which will  by prefixed by a F<#> and  then written at the
top of the output file.

=item C<-delimiter =E<gt> DELIMITER>

Defines the field delimiter for F<.csv>-files. Applied by F<L</read_csv>> and F<L</read_conf>>.

=item C<-columns =E<gt> STRINGS>

Defines the column names for F<.csv>-files to be written into the first line.

=back

B<ATTRIBUTES THAT MASQUERADE PACKAGE GLOBALS>

The attributes  listed below raise  new values for  package globals for  the time an  object method
runs.

=over

=item C<-InputRecordSeparator =E<gt> FLAG>

Masquerades F<$/>, which affects  how lines are read and written to  and from Rlist- and CSV-files.
You may also set F<$/> by yourself.  See L<perlport> and L<perlvar>.

=item C<-MaxDepth =E<gt> INTEGER>

=item C<-SafeCppMode =E<gt> FLAG>

=item C<-RoundScientific =E<gt> FLAG>

Masquerade  F<L<$Data::Rlist::MaxDepth|Debugging Data>>, F<L<$Data::Rlist::SafeCppMode|open_input>>
and F<L<$Data::Rlist::RoundScientific|round>>.

=item C<-EchoStderr =E<gt> FLAG>

Print read errors and warnings message on STDERR (default: off).

=item C<-DefaultCsvDelimiter =E<gt> REGEX>

=item C<-DefaultConfDelimiter =E<gt> REGEX>

Masquerades F<$Data::Rlist::DefaultCsvDelimiter>  and F<$Data::Rlist::DefaultConfDelimiter>.  These
globals define  the default regexes  to use  when the F<-options>  attribute does not  specifiy the
L<C<"delimiter">|/Compile Options> regex.  Applied by F<L</read_csv>> and F<L</read_conf>>.

=item C<-DefaultConfSeparator =E<gt> STRING>

Masquerades F<$Data::Rlist::DefaultConfSeparator>,  the default string to use  when the F<-options>
attribute   does  not  specifiy   the  L<C<"separator">|/Compile   Options>  string.    Applied  by
F<L</write_conf>>.

=back

=item F<dock(SELF, SUB)>

Localize object  SELF within the  package and run  SUB.  This means  that some of  SELF's attribute
masqquerade  few  package globals  for  the  time  SUB runs.   SELF  then  locks the  package,  and
F<$Data::Rlist::Locked> is greater than 0.

=back

=head2 Attribute Access

=over

=item F<set(SELF[, ATTRIBUTE]...)>

Reset or initialize object attributes, then return SELF.  Each ATTRIBUTE is a name/value-pair.  See
F<L</new>> for a list of valid names.  For example,

    $obj->set(-input => \$str, -output => 'temp.rls', -options => 'squeezed');

=item F<get(SELF, NAME[, DEFAULT])>

=item F<require(SELF[, NAME])>

=item F<has(SELF[, NAME])>

Get some  attribute NAME from object SELF.   Unless NAME exists returns  DEFAULT.  The F<require>
method has  no default value,  hence it dies  unless NAME exists.  F<has> returns true  when NAME
exists, false otherwise.  For NAME the leading hyphen is optional.  For example,

    $self->get('foo');          # returns $self->{-foo} or undef
    $self->get(-foo=>);         # dto.
    $self->get('foo', 42);      # returns $self->{-foo} or 42

=back

=cut

sub new {
    my($prototype, $k) = shift;
    carp <<___ if @_ & 1;
$prototype->Data::Rlist::new(${\(join(', ', @_))})
    odd number of arguments supplied, expecting key/value pairs
___
    my %args = @_;
    bless { map { $k = $_;
                  s/^_+//o;         # remove leading underscores
                  s/^([^\-])/-$1/o; # prepend missing '-'
                  $_ => $args{$k}
              } keys %args }, ref($prototype) || $prototype;
}

sub set {
    my($self) = shift;
    my %attr = @_;
    while(my($k, $v) = each %attr) {
        $self->{$k} = $v
    } $self
}

sub require($$) {               # get attribute or confess
    my($self, $attr) = @_;
    my $v = $self->get($attr);
    confess "$self->require(): missing '$attr' attribute:\n\t\t".join("\n\t\t", map { "$_ = $self->{$_}" } keys %$self) unless defined $v;
    return $v;
}

sub get($$;$) {                 # get attribute or return default value/undef
    my($self, $attr, $default) = @_;
    $attr = '-'.$attr unless $attr =~ /^-/;
    return $self->{$attr} if exists $self->{$attr};
    return $default;
}

sub has($$) {
    my($self, $attr) = @_;
    $attr = '-'.$attr unless $attr =~ /^-/;
    exists $self->{$attr};
}

sub dock($\&) {
    carp "package Data::Rlist locked" if $Locked++; # TODO: use critical sections and atomic increment
    my ($self, $block) = @_;
    local $MaxDepth = $self->get(-MaxDepth=>) if $self->has(-MaxDepth=>);
    local $SafeCppMode = $self->get(-SafeCppMode=>) if $self->has(-SafeCppMode=>);
    local $EchoStderr = $self->get(-EchoStderr=>) if $self->has(-EchoStderr=>);
    local $RoundScientific = $self->get(-RoundScientific=>) if $self->has(-RoundScientific=>);
    local $DefaultCsvDelimiter = $self->get(-DefaultCsvDelimiter=>) if $self->has(-DefaultCsvDelimiter=>);
    local $DefaultConfDelimiter = $self->get(-DefaultConfDelimiter=>) if $self->has(-DefaultConfDelimiter=>);
    local $DefaultConfSeparator = $self->get(-DefaultConfSeparator=>) if $self->has(-DefaultConfSeparator=>);
    local $DefaultNanoscriptToken = $self->get(-DefaultNanoscriptToken=>) if $self->has(-DefaultNanoscriptToken=>);
    local $DEBUG = $self->get(-DEBUG=>) if $self->has(-DEBUG=>);
    local $/ = $self->get(-InputRecordSeparator=>) if $self->has(-InputRecordSeparator=>);
    local $R;
    unless (defined wantarray) { # void context
        $block->(); --$Locked;
    } elsif (wantarray) {
        my @r = $block->(); --$Locked; return @r;
    } else {
        my $r = $block->(); --$Locked; return $r;
    }
}

=head2 Public Functions

=over

=item F<read(INPUT[, FILTER, FILTER-ARGS])>

Parse data from INPUT, which specifies some Rlist-text.  See also F<L</errors>>, F<L</write>>.

B<PARAMETERS>

INPUT shall be either

- some Rlist object created by F<L</new>>,

- a string reference, in which case F<read> and F<L</read_string>> parse Rlist text from it,

- a string scalar, in which case F<read> assumes a file to parse.

See F<L</open_input>>  for the FILTER and FILTER-ARGS  parameters, which are used  to preprocess an
input file.  When an input file cannot  be F<open>'d and F<flock>'d this function dies.  When INPUT
is  an  object,  arguments for  FILTER  and  FILTER-ARGS  eventually  override the  F<-filter>  and
F<-filter_args> attributes.

B<RESULT>

The parsed data as array- or hash-reference, or  F<undef> if there was no data. The latter may also
be the case when file consist only of comments/whitespace.

B<NOTES>

This function  may die.  Dying  is Perl's  mechanism to raise  exceptions, which eventually  can be
catched with F<eval>.  For example,

    my $host = eval { use Sys::Hostname; hostname; } || 'some unknown machine';

This code fragment  traps the F<die> exception, so  that F<eval> returns F<undef> or  the result of
calling F<hostname>. The following example uses F<eval> to trap exceptions thrown by F<read>:

    $object = new Data::Rlist(-input => $thingfile);
    $thing = eval { $object->read };

    unless (defined $thing) {
        if ($object->errors) {
            print STDERR "$thingfile has syntax errors"
        } else {
            print STDERR "$thingfile not found, is locked or empty"
        }
    } else {
        # Can use $thing
            .
            .
    }

=item F<read_csv(INPUT[, OPTIONS, FILTER, FILTER-ARGS])>

=item F<read_conf(INPUT[, OPTIONS, FILTER, FILTER-ARGS])>

Parse data from INPUT, which specifies some comma-separated-values (CSV) text.  Both functions

- read data from strings or files,

- use an optional delimiter,

- ignore delimiters in quoted strings,

- ignore empty lines,

- ignore lines begun with F<#>.

F<read_conf> is a variant of F<read_csv> dedicated to configuration files. Such files consist
of lines of the form

    key = value

B<PARAMETERS>

For INPUT see F<L</read>>.  For FILTER,  FILTER-ARGS see F<L</open_input>>.

OPTIONS  can be  used to  override the  L<C<"delimiter">|/Compile Options>  regex.  For  example, a
delimiter of C<'\s+'>  splits the line at horizontal whitespace into  multiple values (with respect
of quoted strings).   For F<read_csv> the delimiter defaults to  C<'\s*,\s*'>, and for F<read_conf>
to C<'\s*=\s*'>.  See also F<L</write_csv>> and F<L</write_conf>>.

B<RESULT>

Both functions return a list of lists.  Each embedded array defines the fields in a line.

B<EXAMPLES>

Un/quoting of values happens implicitly.  Given a file F<db.conf>

    # Comment
    SERVER      = hostname
    DATABASE    = database_name
    LOGIN       = "user,password"

the call F<$opts=ReadConf(C<"db.conf">)> assigns

    [ [ 'SERVER', 'hostname' ],
      [ 'DATABASE', 'database_name' ],
      [ 'LOGIN', 'user,password' ]
    ]

The F<L</WriteConf>> function can be used to create or update the configuration:

    push @$opts, [ 'MAGIC VALUE' => 3.14_15 ];

    WriteConf('db.conf', { precision => 2 });

This writes to F<db.conf>:

    SERVER = hostname
    DATABASE = database_name
    LOGIN = "user,password"
    "MAGIC VALUE" = 3.14

=item F<read_string(INPUT)>

Calls F<L</read>>  to parse Rlist language  productions from the string  or string-reference INPUT.
When INPUT is an object do this for its F<-input> attribute.

=item F<result([SELF])>

Return  the last  result  of  calling F<L</read>>,  which  is either  F<undef>  or  some array-  or
hash-reference.  When SELF is passed as object  reference, returns the result that occured the last
time SELF had called F<L</read>>.

=item F<nanoscripts([SELF])>

In list context return an array of nanoscripts  defined by the last call to F<L</read>>.  When SELF
is passed return this information for the last time SELF had called F<L</read>>. The result has the
form:

    ( [ $hash_or_array_ref, $key_or_index ], # 1st nanoscript
      [ $hash_or_array_ref, $key_or_index ], # 2nd nanoscript
        .
        .
        .
    )

In scalar context  return a reference to the  above.  This information defines the  location of all
embedded Perl  scripts within the result,  and can be  used to F<eval> them  programmatically.  See
also F<L</result>>, F<L</evaluate_nanoscripts>>.

=item F<evaluate_nanoscripts([SELF])>

Evaluates all nanoscripts defined by the last call to F<L</read>>.  When called as method evaluates
the  nanoscripts defined  by the  last time  SELF had  called F<L</read>>.   Returns the  number of
scripts or  0 if none  were available.  Each  script is replaced by  the result of  F<eval>'ing it.
(For details and examples see L</Embedded Perl Code (Nanoscripts)>.)

=item F<messages([SELF])>

In  list context  returns  a list  of  compile-time messages  that  occurred in  the  last call  to
F<L</read>>.  In scalar context returns an array  reference.  When an package object SELF is passed
returns the information for the last time SELF had called F<L</read>>.

=item F<errors([SELF])>

=item F<warnings([SELF])>

Returns the  number of syntax errors  and warnings that occurred  in the last  call to F<L</read>>.
When called as method returns the number that occured the last time SELF had called F<L</read>>.

Example:

    use Data::Rlist;

    our $data = ReadData 'things.rls';

    if (Data::Rlist::errors() || Data::Rlist::warnings()) {
        print join("\n", Data::Rlist::messages())
    } else {
        # Ok, $data is an array- or hash-reference.
        die unless $data;

    }

=item F<broken([SELF])>

Returns the  number of times the last  F<L</compile>> violated F<L<$Data::Rlist::MaxDepth|Debugging
Data>>.  When  called  as method  returns  the  information  for  the  last time  SELF  had  called
F<L</compile>>.

=item F<missing_input([SELF])>

Returns true  when the last  call to  F<L</parse>> yielded F<undef>,  because there was  nothing to
parse.   When  called  as method  returns  the  information  for  the  last time  SELF  had  called
F<L</parse>>.

=item F<write(DATA[, OUTPUT, OPTIONS, HEADER])>

Transliterates Perl data into  Rlist text and write the text to a  file or string buffer.  F<write>
is auto-exported as F<L</WriteData>>.

B<PARAMETERS>

DATA is either an object generated by F<L</new>>,  or any Perl data including F<undef>.  In case of
an object  the actual DATA  value is defined  by its F<-data>  attribute. (When F<-data>  refers to
another Rlist object, this other object is invoked.)

OUTPUT defines the  output location, as filename, string-reference or  F<undef>.  When F<undef> the
function allocates  a string  and returns  a reference to  it.  OUTPUT  defaults to  the F<-output>
attribute when DATA defines an object.

OPTIONS  define how  to compile  DATA: when  F<undef> or  C<"fast"> uses  F<L</compile_fast>>, when
C<"perl">  uses  F<L</compile_Perl>>,  otherwise   F<L</compile>>.   Defaults  to  the  F<-options>
attribute when DATA is an object.

HEADER is  a reference to  an array of  strings that shall  be printed literally  at the top  of an
output file. Defaults to the F<-header> attribute when DATA is an object.

B<RESULT>

When F<write> creates a  file it returns 0 for failure or 1 for  success.  Otherwise it returns a
string reference.

B<EXAMPLES>

    $self = new Data::Rlist(-data => $thing, -output => $output);

    $self->write;   # Compile $thing into a file ($output is a filename)
                    # or string ($output is a string reference).

    Data::Rlist::write($thing, $output);    # dto., but using the functional interface.

=item F<write_csv(DATA[, OUTPUT, OPTIONS, COLUMNS])>

=item F<write_conf(DATA[, OUTPUT, OPTIONS, HEADER])>

Write  DATA as  comma-separated-values  (CSV) to  file  or string  OUTPUT.  F<write_conf>  writes
configuration  files where  each  line contains  a  tagname, a  separator and  a  value.

B<PARAMETERS>

DATA is either  an object, or defines the data  to be compiled as reference to  an array of arrays.
F<write_conf> uses only the first and second fields. For example,

    [ [ a, b, c ],      # fields of line 1
      [ d, e, f, g ],   # fields line 2
        .
        .
    ]



OPTIONS  specifies  the  comma-separator  (C<"separator">),  how to  quote  (C<"auto_quote">),  the
linefeed (C<"eol_space">) and the numeric precision (C<"precision">).  COLUMNS specifies the column
names to be written to the first line.  Likewise  the text from the HEADER array is written in form
of F<#>-comments at the top of an output file.

B<RESULT>

When a  file was  created both function  return 0 for  failure, or  1 for success.   Otherwise they
return a reference to the compiled text.

B<EXAMPLES>

Functional interface:

    use Data::Rlist;            # imports WriteCSV

    WriteCSV($thing, "foo.dat");

    WriteCSV($thing, "foo.dat", { separator => '; ' }, [qw/GBKNR VBKNR EL LaD/]);

    WriteCSV($thing, \$target_string);

    $string_ref = WriteCSV($thing);

Object-oriented interface:

    $object = new Data::Rlist(-data => $thing, -output => "foo.dat",
                              -options => { separator => '; ' },
                              -columns => [qw/GBKNR VBKNR EL LaD LaD_V/]);

    $object->write_csv;         # write $thing as CSV to foo.dat
    $object->write;             # write $thing as Rlist to foo.dat

    $object->set(-output => \$target_string);

    $object->write_csv;         # write $thing as CSV to $target_string

See also F<L</write>> and F<L</read_csv>>.

=item F<write_string(DATA[, OPTIONS])>

Stringify any Perl data  and return a reference to the string.   Works like F<L</write>> but always
compiles  to a  new string  to which  it  returns a  reference.  The  default for  OPTIONS will  be
L<C<"string">|/Predefined Options>.

=item F<write_string_value(DATA[, OPTIONS])>

Stringify  any  Perl  dats  and  return  the  compiled  text  string  value.   OPTIONS  default  to
L<C<"default">|/Predefined Options>.  For example,

    print "\n\$thing dumped: ", Data::Rlist::write_string_value($thing);

    $self = new Data::Rlist(-data => $thing);

    print "\nsame \$thing dumped: ", $self->write_string_value;

=item F<keelhaul(DATA[, OPTIONS])>

Do a deep copy of DATA according  to L<OPTIONS|/Compile Options>.  First the function compiles DATA
to Rlist text, then restores the data  from exactly this text.  This process is called "keelhauling
data", and allows us to

- adjust the accuracy of numbers, 

- break circular-references,

- drop F<\*foo{THING}>s,

- bring multiple data sets to the same, common basis.

It is useful (e.g.)  when  DATA had been hatched by some other code, and  you don't know whether it
is hierachical, or if typeglob-refs nist inside.  Then  keelhaul it to clean it from its past.  For
example, to bring all numbers in

    $thing = { foo => [ [ .00057260 ], -1.6804e-4 ] };

to a certain accuracy, use

    $deep_copy_of_thing = Data::Rlist::keelhaul($thing, { precision => 4 });

All number scalars in  F<$thing> are rounded to 4 decimal places,  so they're finally comparable as
floating-point numbers.  To F<$deep_copy_of_thing> is assigned the hash-reference

    { foo => [ [ 0.0006 ], -0.0002 ] }

Likewise one can convert all floats to integers:

    $make_integers = new Data::Rlist(-data => $thing, -options => { precision => 0 });

    $thing_without_floats = $make_integers->keelhaul;

When F<L</keelhaul>> is called in an array context it also returns the text from which the copy had
been built.  For example,

    $deep_copy = Data::Rlist::keelhaul($thing);

    ($deep_copy, $rlist_text) = Data::Rlist::keelhaul($thing);

    $deep_copy = new Data::Rlist(-data => $thing)->keelhaul;

B<DETAILS>

F<L</keelhaul>> won't throw F<die> nor return an error, but be prepared for the following effects:

=over

=item *

F<ARRAY>, F<HASH>, F<SCALAR> and F<REF> references were compiled, whether blessed or not.  (Since
compiling does not store type information, F<keelhaul> will turn blessed references into barbars
again.)

=item *

F<IO>, F<GLOB> and F<FORMAT> references have been converted into strings.

=item *

Depending on the compile options, F<CODE> references are invoked, deparsed back into their function
bodies, or dropped.

=item *

Depending on the compile options floats are rounded, or are converted to integers.

=item *

F<undef>'d array elements are converted into the default scalar value C<"">.

=item *

Unless F<$Data::Rlist::MaxDepth> is 0, anything deeper than F<$Data::Rlist::MaxDepth> will be
thrown away.

=item *

When the data contains objects, no special methods are triggered to "freeze" and "thaw" the
objects.

=back

See also F<L</compile>> and F<L</deep_compare>>

=back

=head2 Static Functions

=over

=item F<predefined_options([PREDEF-NAME])>

Return   are   predefined   hash-reference    of   compile   otppns.    PREDEF-NAME   defaults   to
L<C<"default">|/Predefined Options>.

=item F<complete_options([OPTIONS[, BASICS]])>

Completes OPTIONS  with BASICS, so that  all pairs not already  in OPTIONS are  copied from BASICS.
Always returns a new hash-reference, i.e., neither OPTIONS nor BASICS are modified.  Both arguments
define  hashes  or  some  L<predefined  options  name|/Predefined  Options>.   BASICS  defaults  to
L<C<"default">|/Predefined Options>.  For example,

    $options = complete_options({ precision => 0 }, 'squeezed')

merges  the  predefined  options  for  L<C<"squeezed"> text|/Predefined  Options>  with  a  numeric
precision of 0  (converts all floats to  integers).

=back

=cut

sub is_integer(\$);
sub is_number(\$);
sub is_symbol(\$);
sub is_random_text(\$);

sub read($;$$);
sub read($;$$) {
    my($input, $fcmd, $fcmdargs) = @_;

    if (ref($input) eq __PACKAGE__) {
        $input->dock(sub {
                         unless ($fcmd) {
                             $fcmd = $input->get('-filter');
                             $fcmdargs = $input->get('-filter_args');
                         }
                         $R = Data::Rlist::read($input->require(-input=>), $fcmd, $fcmdargs); # returns a reference
                         $input->set(-read_result => [$Warnings, $Errors, $Broken, $MissingInput, \@Messages]);
                         $input->set(-nanoscripts => (@NStk ? [@NStk] : undef));
                         $input->set(-result => $R);
                         $R
                     }
                    )
    } else {
        # $input is either a string (filename) or reference.
        local $| = 1 if $DEBUG;
        if ($DEBUG) {
            print STDERR "Data::Rlist::open_input($input, $fcmd, $fcmdargs)\n" if $fcmd && $fcmdargs;
            print STDERR "Data::Rlist::open_input($input, $fcmd)\n" if $fcmd && !$fcmdargs;
            print STDERR "Data::Rlist::open_input($input)\n" unless $fcmd;
        }
        return undef unless open_input($input, $fcmd, $fcmdargs);
        confess unless defined $Readstruct;
        my $data = parse();
        print STDERR "Data::Rlist::close_input() parser result = ", (defined $data) ? $data : 'undef', "\n" if $DEBUG;
        close_input();
        return $data;
    }
}

sub read_csv($;$$$);
sub read_csv($;$$$) {
    my($input, $options, $fcmd, $fcmdargs) = @_;

    if (ref($input) eq __PACKAGE__) {
        $input->dock
        (sub {
             $options ||= $input->get('options');
             $fcmd ||= $input->get('filter');
             $fcmdargs ||= $input->get('filter_args');
             $input = $input->get('input');
             Data::Rlist::read_csv($input, $options, $fcmd, $fcmdargs);
         });
    } else {
		# Call open_input, let lexln read all lines, call close_input.  $input names a file or a
		# string-ref (buffer); from both we're reading linewise.  For strings open_input does not
		# call read_csv, but splits at LF or CR+LF.  Since lexln only chomps $/ we explicitly check
		# for a trailing \r here.

        return undef unless open_input($input, $fcmd, $fcmdargs);
        confess unless defined $Readstruct;
        my $delim = complete_options($options)->{delimiter} || $DefaultCsvDelimiter;
        my @L; push @L, $Ln while lexln();
        my @R; push @R, map { [ map { maybe_unquote7($_) } split_quoted($_, $delim) ] }
        grep { not /^\s*#|^\s*$/o } # throw away comment lines and blank lines
        #map { s/\r+$//o; $_ }		# strip trailing \r
		@L;
        close_input();
        return \@R;
    }
}

sub read_conf(@) { 
    my($input, $options, $fcmd, $fcmdargs) = @_;
    $options ||= $input->get('options') if ref($input) eq __PACKAGE__;
    $options = complete_options($options) unless ref $options; # expand using predef'd set "default"
    $options->{delimiter} ||= $DefaultConfDelimiter;           # ...where "delimiter" is undef
    return read_csv($input, $options, $fcmd, $fcmdargs);
}

sub read_string($);
sub read_string($) {
    my $r = shift;
    if (defined($r) and not defined reftype($r)) {
        return read_string(\$r);
    } elsif (reftype($r) ne 'SCALAR') {
        carp 'string or string-reference required';
    } Data::Rlist::read($r);
}

sub result(;$) {
    my $self = shift;
    return $self->get(-result=>) if $self;
    return $R;
}

sub nanoscripts(;$) {
    return unless defined wantarray;
    my $self = shift;
    my $ls = $self ? $self->get(-nanoscripts=>) : \@NStk;
    return wantarray ? @$ls : $ls;
}

sub evaluate_nanoscripts(;$)
{
    my($self) = @_;
    my @ns = nanoscripts($self);
    my $root = result($self);   # this is $Data::Rlist::R or $self->{'-result'}
    my($this, $where);

    foreach my $ns (@ns) {
        $this = $ns->[0];       # list in which the nanoscript occurs
        $where = $ns->[1];      # key or index into the list
        if (ref($this) =~ 'ARRAY') {
            my $i = int($where);
            my $code = $this->[$i];
            print "$root: evaluating nanoscript $this\->[$i]:\n\t${\(escape7($code))}\n" if $DEBUG;
            $this->[$i] = eval $code;
            print "\n\tresult: $this->[$i]\n" if $DEBUG;
        } else {
            die unless ref($this) =~ 'HASH';
            my $code = $this->{$where};
            print "$root: evaluating nanoscript $this\->{$where}:\n\t${\(escape7($code))}\n" if $DEBUG;
            $this->{$where} = eval $code;
            print "\n\tresult: $this->{$where}\n" if $DEBUG;
        }
    }
    return $#ns + 1;
}

sub warnings(;$) {
    my $self = shift;
    if ($self) {
        my $a = $self->get(-read_result=>);
        return $a->[0] if ref $a;
        return 0;
    } $Warnings
}

sub errors(;$) {
    my $self = shift;
    if ($self) {
        my $a = $self->get(-read_result=>);
        return $a->[1] if ref $a;
        return 0;
    } $Errors
}

sub broken(;$) {
    my $self = shift;
    if ($self) {
        my $a = $self->get(-read_result=>);
        return $a->[2] if ref $a;
        return 0;
    } $Broken
}

sub missing_input(;$) {
    my $self = shift;
    if ($self) {
        my $a = $self->get(-read_result=>);
        return $a->[3] if ref $a;
        return 0;
    } $MissingInput
}

sub messages(;$) {
    return unless defined wantarray; # void context
    my $self = shift;
    if ($self) {
        my $a = $self->get(-read_result=>);
        return @{$a->[4]} if ref $a;
    } return wantarray ? @Messages : \@Messages
}

sub predefined_options($) {
    my $name = shift || 'default';
    carp "\nunknown compile-options '$name'" unless exists $PredefinedOptions{$name};
    $PredefinedOptions{$name};
}

sub complete_options(;$$);
sub complete_options(;$$)
{
    my($opts, $base) = (shift||'default', shift||'default');
    my $using_default = ($base eq 'default');
    $opts = predefined_options($opts) unless ref $opts;
    $base = predefined_options($base) unless ref $base;

    # Make a new hash, copy all keys not already in $opts from $base.
    $opts = { %$opts };
    $opts->{_base} = ref($base) ? 'some hash' : $base;
    while (my($k, $v) = each %$base) {
        $opts->{$k} = $v unless exists $opts->{$k}
    }

    # Finally complete $opts with "default" and return the new hash.
    $opts = complete_options($opts) unless $using_default;
    $opts
}

sub write($;$$$);
sub write($;$$$)
{
    my($data, $output) = (shift, shift);
    my($options, $header) = @_;
    local $| = 1 if $DEBUG;

    if (ref($data) eq __PACKAGE__) {
        $data->dock(sub {
						$output ||= $data->get('-output');
						$options ||= $data->get('-options');
						$header ||= $data->get('-header');
						Data::Rlist::write($data->get('-data'), $output, $options, $header) });
    } else {
        # $data is any Perl data or undef.  Reset package globals, validate $options, then compile
        # $data.

        my $to_string = ref $output || not defined $output;
        my($result, $optname, $fast, $perl);
        $options ||= ($to_string ? 'string' : 'fast');
        unless (ref $options) {
            $fast = 1 if $options eq 'fast';
            $perl = 1 if $options eq 'perl';
            $optname = "'$options'";
            $options = predefined_options($options) unless $fast || $perl;
        } else {
            $optname = "custom, based on '${\($options->{_base} || 'default')}'";
        }
        unless ($fast || $perl) {
            $options->{auto_quote} = 1 unless defined $options->{auto_quote};
        }

        unless ($to_string) {
            # Compile $data into a file named $output.  Create a new file, exclusively lock it. It
            # is guaranteed that no other process will be able to run flock(FH,2) on the same file
            # while we hold the lock. (Because the OS suspends and blocks other processes.)

            confess $output if not defined $output or ref $output; # or not_valid_pathname($output)
            my($to_stdout, $fh) = $output eq '-';
            if ($to_stdout) {
                open($fh, ">$output") or confess("\nERROR: $!");
            } else {
                (open($fh, ">$output") and flock($fh, 2)) or
                confess("\nERROR: $output: can't create and lock Rlist-file: $!");
            }

            # Build file header.  Compile $data to file $fh, return undef.  

            my $host = eval { use Sys::Hostname; hostname; } || 'some unknown machine';
            my $uid = getlogin || getpwuid($<);
            my $tm = localtime;
            my $prec; $prec = $options->{precision} if ref $options and defined $options->{precision};
            my $eol = $/; $eol = $options->{eol_space} if ref $options and defined $options->{eol_space};
            my @header = 
            map { (length) ? "# $_\n" : "#\n" }
            (($to_stdout ? () : 
              ("-*-rlist-generic-*-", "", $output, "",
               "Created $tm on <$host> by user <$uid>.",
               "Random Lists (Rlist) file (see Data::Rlist on CPAN and <http://www.visualco.de>).")),
             ((defined $prec) ? 
              sprintf('Numerical precision: fixed-point, rounded to %d decimal places.', $prec) :
              sprintf('Numerical precision: floating-point.')),
             "Compile options: $optname.", 
             ($header ? ("", @$header) : ("")));
            print $fh @header, $eol;

            unless ($fast || $perl) {
                $result = 1 if compile($data, $options, $fh);
            } else {
                # Note that we return $Data::Rlist::R here.
                $result = 1;
                print $fh ${compile_fast($data)}.$eol if $fast;
                print $fh ${compile_Perl($data)}.$eol if $perl;
            } close $fh;
        } else {
            # Compile $data into string and return a reference.  Here $output has to be undef or a
            # string-ref (buffer).
            confess $output unless not defined $output or ref $output eq 'SCALAR';
            unless ($fast || $perl) {
                $result = compile($data, $options);
                $output = $result if ref $output;
            } else {
                $result = compile_fast($data) if $fast;
                $result = compile_Perl($data) if $perl;
                $$output = $$result if ref $output; # copy it -> $result is $Data::Rlist::R
            }
        } return $result;
    }
}

sub write_csv($;$$$$);
sub write_csv($;$$$$)
{
    my($data, $output) = (shift, shift);
    my($options, $columns, $header) = @_;
    return 0 unless defined $data;

    if (ref($data) eq __PACKAGE__) {
        $data->dock(sub {
						$output ||= $data->get('-output');
						$options ||= $data->get('-options');
						$columns ||= $data->get('-columns');
						$header ||= $data->get('-header');
						Data::Rlist::write_csv($data->get('-data'), $output, $options, $columns, $header) });
    } else {
        # $data is anything.  In case of undef returns 0.  When the file could not be created,
        # dies. Otherwise returns 1.
        #
        # Unless a value looks like a number the value is quoted (strings may have commas).
        # read_csv uses split_quoted which keeps quotes and backslashes, then maybe_unquote7()s
        # each value.

        $options = complete_options($options, 'default');
        my $to_string = ref $output || not defined $output;
        my($separator, $prec, $auto_quote) = map { $options->{$_} } qw/separator precision auto_quote/;
        my $eol = $/; $eol = $options->{eol_space} if ref $options and defined $options->{eol_space}; $eol ||= "\n";
        my $result = '';
        $auto_quote = 0 unless defined $auto_quote;
        $result.= join($separator, @$columns).$eol if $columns;
        $result.= join($eol, map {
            join($separator, map { is_number($_)
                                   ? (defined($prec) ? round($_, $prec) : $_)
                                   : ($auto_quote ? maybe_quote7($_) : $_)
                               } @$_) } @$data).$eol if @$data;

        if ($to_string) {
            if (ref $output) {
                $$output = $result; return $output
            } else {
                return \$result;
            }
        } else {
            my($to_stdout, $fh) = ($output eq '-');
            local $| = 1 if $DEBUG;
            if ($to_stdout) {
                open($fh, ">$output") or confess("\nERROR: $!");
            } else {
                (open($fh, ">$output") and flock($fh, 2)) or
                confess("\nERROR: $output: can't create and lock CSV-file: $!");
            }
            print $fh $result;
            close $fh; 1
        }
    }
}

sub write_conf($;$$$$)
{
    my($data, $output, $options, $header) = @_;
    $options ||= $data->get('options') if ref($data) eq __PACKAGE__;
    my $have_sep = ref($options) && defined $options->{separator};
    $options = complete_options($options) unless ref $options;
    $options->{separator} = $DefaultConfSeparator unless $have_sep;
    return write_csv($data, $output, $options, $header);
}

sub write_string($;$) {
    my($data, $options) = (shift, shift||'string');
    my $strref;
    if (ref($data) eq __PACKAGE__) {
        my $out = $data->get('output');
        $data->set(-output => undef);
        $strref = Data::Rlist::write($data, undef, $options);
        $data->set(-output => $out);
    } else {
        $strref = Data::Rlist::write($data, undef, $options);
    } return $strref;
}

sub write_string_value($;$) {
    my($data, $options) = (shift, shift||'default');
    local $MaxDepth = $DefaultMaxDepth if $MaxDepth == 0;
    return ${Data::Rlist::write_string($data, $options)};
}

sub keelhaul($;$) {
    my($data, $options) = (shift, shift);
    carp 'Cannot keelhaul Perl data' if defined $options and $options eq 'perl'; # TODO: eval back
    $options ||= complete_options({ precision => undef }, 'squeezed');
    my $strref = Data::Rlist::write_string($data, $options);
    local $MaxDepth = $DefaultMaxDepth if $MaxDepth == 0;
    my $deep_copy = read_string($strref);
    return wantarray ? ($deep_copy, $strref) : $deep_copy;
}

=head2 Implementation Functions

=over

=item F<open_input(INPUT[, FILTER, FILTER-ARGS])>

=item F<close_input>

Open/close  Rlist text  file  or string  INPUT for  parsing.   Used internally  by F<L</read>>  and
F<L</read_csv>>.

B<PREPROCESSING>

The function  can preprocess the INPUT  file using FILTER.  Use  the special value 1  to select the
default  C preprocessor  (F<gcc  -E -Wp,-C>).   FILTER-ARGS  is an  optional  string of  additional
command-line arguments to be appended to FILTER.  For example,

    my $foo = Data::Rlist::read("foo", 1, "-DEXTRA")

eventually does not parse F<foo>, but the output of the command

    gcc -E -Wp,-C -DEXTRA foo

Hence within F<foo> now C-preprocessor-statements are allowed. For example,

    {
    #ifdef EXTRA
    #include "extra.rlist"
    #endif

        123 = (1, 2, 3);
        foobar = {
            .
            .

B<SAFE CPP MODE>

This mode uses F<sed> and a  temporary file.  It is enabled by setting F<$Data::Rlist::SafeCppMode>
to 1  (the default is  0).  It  protects single-line F<#>-comments  when FILTER begins  with either
F<gcc>, F<g++>  or F<cpp>.  F<L</open_input>>  then additionally runs  F<sed> to convert  all input
lines beginning  with whitespace plus the  F<#> character.  Only the  following F<cpp>-commands are
excluded, and only when they appear in column 1:

- F<#include> and F<#pragma>

- F<#define> and F<#undef>

- F<#if>, F<#ifdef>, F<#else> and F<#endif>.

For  all other  lines F<sed>  converts F<#>  into  F<##>.  This  prevents the  C preprocessor  from
evaluating them.   Because of Perl's  limited F<open> function,  which isn't able to  dissolve long
pipes, the invocation  of F<sed> requires a temporary  file.  The temporary file is  created in the
same directory  as the input file.   When you only use  F<//> and F</* */>  comments, however, this
read mode is not required.

=cut

sub open_input($;$$)
{
    my($input, $fcmd, $fcmdargs) = @_;
    my($rls, $filename);
    my $rtp = reftype $input;

    carp "\n${\((caller(0))[3])}: filename or scalar-ref required as INPUT" if defined $rtp && $rtp ne 'SCALAR';
    carp "\n${\((caller(0))[3])}: package locked" if $Readstruct;
    $Readstruct = $ReadFh = undef;
    local $| = 1 if $DEBUG;

    if (defined $input) {
        $Readstruct = { };
        unless (ref $input) {
            $Readstruct->{filename} = $input;
            unless ($fcmd) {	# the file is read unfiltered
                unless (open($Readstruct->{fh}, "<$input") && flock($Readstruct->{fh}, 1)) {
                    $Readstruct = undef;
                    pr1nt('ERROR', "input file '$input'", $!);
                }
            } else {			# pipe it through $fcmt
                $fcmd = "gcc -E -Wp,-C -x c++" if $fcmd == 1;
                $fcmd = "$fcmd $fcmdargs" if $fcmdargs;

                if ($SafeCppMode) {
                    if ($fcmd =~ /^(gcc|g\+\+|cpp)/i) {
                        # Filter input with sed:
                        #
                        # (1) Because known #-commands must start at column 1 we first escape all
                        #     indented '#'s into '##'s:
                        #           "(^ +)#" -> '$1\#'
                        # (2) Next we prefix the known commands with a blank, e.g.
                        #           "#if 0" -> " #if 0"
                        # (3) Finally we escape all unknown #-commands at column 1:
                        #           "^#" -> "\#"
                        #
                        # lexln will then reverse the escaping.  Since the builtin open does not
                        # support true pipes, a temporary file receives the output of sed, which is
                        # then preprocessed. The temporary file will be removed in close_input.

                        my($sedfh, $tmpfh);
                        open($sedfh,
							 "sed '".
							 join('; ', ("s/^\\([ \t][ \t]*\\)#/\\1\\\\#/", # many seds don't know \t -> insert literally
										 "s/^#\\(include\\|pragma\\|if\\|ifdef\\|else\\|endif\\|define\\|undef\\)/ #\\1/",
										 "s/^#/\\\\#/")).";' <$input 2>nul |") ||
										 die "\nERROR: input file '$fcmd': $!";
                        my($tmpinput, $i) = (undef, 0);
                        do { $tmpinput = $input.'.tmp'.$i++ } while -e $tmpinput;
                        $Readstruct->{tmpfile} = $input = $tmpinput;
                        open ($tmpfh, ">$input") || die "\nERROR: temporary file '$input': $!";
                        print $tmpfh readline($sedfh);
                        close $tmpfh;
                        close $sedfh;
                    }
                }

                # Open the file $input (or the temporary sed'd file) for preprocessing.

                unless (open($Readstruct->{fh}, "$fcmd $input 2>nul |")) {
                    $Readstruct = undef;
                    pr1nt('ERROR', "preprocessed input '$fcmd $input': $!");
                }
            }

            if (defined $Readstruct) {
                $ReadFh = $Readstruct->{fh};
                $LnArray = undef;
                $Ln = '';
            }
        } else {
            # Input is a string-ref.  It will be split into lines at LF or CR+LF.  But when it has
            # no newlines it is read as one big line.

            carp "cannot preprocess strings" if $fcmd;
            $LnArray = [ split /\r*\n/, $$input ];
            $Ln = '';
        }
    } $Readstruct
}

sub close_input()
{
	close($Readstruct->{fh}) if $Readstruct->{fh};
    if ($Readstruct->{tmpfile}) {
        unlink($Readstruct->{tmpfile}) ||
        croak "\nERROR: could not temporary file '$Readstruct->{tmpfile}': $!";
    }
    $LnArray = $Ln = $Readstruct = undef;
}

=item F<lex()>

Lexical scanner.  Called by F<L</parse>> to split  the current line into tokens.  F<lex> reads F<#>
or F<//> single-line-comment and F</* */> multi-line-comment as regular white-spaces.  Otherwise it
returns tokens according to the following table:

    RESULT      MEANING
    ------      -------
    '{' '}'     Punctuation
    '(' ')'     Punctuation
    ','         Operator
    ';'         Punctuation
    '='         Operator
    'v'         Constant value as number, string, list or hash
    '??'        Error
    undef       EOF

F<lex> appends all here-doc-lines with a newline character. For example,

        <<test1
        a
        b
        test1

is effectively read as C<"a\nb\n">, which is the same value as the equivalent here-doc in Perl has.
So, not all  strings can be encoded as a  here-doc.  For example, it might not  be quite obvious to
many programmers that C<"foo\nbar"> cannot be expressed as here-doc.

=item F<lexln()>

Read the next line of text from the current input.  Return 0 if F<L</at_eof>>, otherwise return 1.

=item F<at_eof()>

Return true if current input file/string is exhausted, false otherwise.

=item F<parse()>

Read Rlist language productions from current input.  This is a fast, non-recursive parser driven by
the  parser  map  F<%Data::Rlist::Rules>, and  fed  by  F<L</lex>>.   It  is called  internally  by
F<L</read>>.   F<parse>  returns an  array-  or  hash-reference, or  F<undef>  in  case of  parsing
F<L</errors>>.

=cut

# Local variables for lex(). Note that since lexical variables are init'd at compile-time, they're
# available in BEGIN blocks.

my $RELexNumber = qr/^($REFloatHere)/;  # number constant
my $RELexSymbol = qr/^($RESymbolHere)/; # symbolic name without quotes
my $RELexQuotedString = qr/^\"((?:\\[nrbftv\"\'\\]|\\[0-7]{3}|[^\"])*)\"/; # quoted string constant
my $RELexQuotedSymbol = qr/^"($RESymbolHere)"/; # symbolic name in quotes
my $RELexPunctuation = qr/^[$REPunctuationCharacter]/;
my $C1;

BEGIN {
    $REIsPunct[$_] = 0 foreach  0..255;
    $REIsPunct[ 61] = 1;            # =
    $REIsPunct[ 44] = 1;            # ,
    $REIsPunct[ 59] = 1;            # ;
    $REIsPunct[123] = 1;            # {
    $REIsPunct[125] = 1;            # }
    $REIsPunct[ 40] = 1;            # (
    $REIsPunct[ 41] = 1;            # )

    $REIsDigit[$_] = 0 foreach  0..255;
    $REIsDigit[$_] = 1 foreach 48.. 57;
    $REIsDigit[43] = $REIsDigit[45] = $REIsDigit[46] = 1;
}

sub lex()
{
    # First reduce leading whitespace and empty lines. Set $C1 to the ASCII code of the first
    # character in the current line $Ln.
    #
    # The Perl \s regex matches  [ \t\n\r\f], but
    #   ($C1 <= 32 && ($C1 == 32 || $C1 == 9 || $C1 == 10 || $C1 == 13 || $C1 == 12))
    # is still more efficient.  However, to make it even faster we use
    #   ($C1 <= 32)

    unless (defined $Ln) {
        return undef unless lexln(); # fetch next $Ln or stop
    }
    NEXTC1:
    unless ($C1 = ord($Ln)) { # ord returns 0 on empty strings
        return undef unless lexln();
        goto NEXTC1;
    }
    if ($C1 <= 32) {
        $Ln =~ s/^\s+//o;
        goto NEXTC1 unless $C1 = ord($Ln);
    }

    # Puncutators = , ; { } ( )

    #if ($Ln =~ $RELexPunctuation) {
    #if ($C1 == 61 || $C1 == 44 || $C1 == 59 || $C1 == 123 || $C1 == 125 || $C1 == 40 || $C1 == 41) {
    if ($REIsPunct[$C1]) {
        $Ln = substr($Ln, 1);
        return chr($C1);
    }

    # Number scalars. C language single/double-precision numbers.  Test if $C1 is a digit, '.', '-'
    # or '+'.

    #if (($C1 >= 48 && $C1 <= 57) || $C1 == 43 || $C1 == 45 || $C1 == 46) {
    if ($REIsDigit[$C1]) {
        if ($Ln =~ s/$RELexNumber//o) {
            push @VStk, $1;
            return 'v';
        } elsif (($C1 == 45 || $C1 == 46) && $Ln =~ s/$RELexSymbol//o) {
            # Symbolic name (unquoted string) beginning with '-' or '.'.
            push @VStk, $1;
            return 'v';
        } else {
            return syntax_error(qq'unrecognized number "$Ln"');
        }
    }

    # String scalars, un/quoted, here-docs.

    if ($C1 == 34) {            # "
        # String scalar, quoted. Removes the quotes and unesacpes the strings (compile adds
        # quotes).

        #if (0) {
            # BUG: the regex engine of perl 5.8.7 (Cygwin) unconditionally exits when it tried to
            # match a large quoted string, e.g. >8000 characters.  perldb provides no hint
            # why. This problem once occurred during intensive testing of this package.

            #if (length($Ln) > 1000) {
                #print STDERR "string len=".length($Ln)." val = \n\n$Ln\n\n" if $DEBUG;

                # TODO: take a precautionary approach because of bug/misbehaviors in Perl's regex
                # engine now (see above). 
            #}
        #}

#         if ($Ln =~ s/$RELexQuotedSymbol//o) { # no escape sequences
#             push @VStk, $1;
#             return 'v';
#         }

        if ($Ln =~ s/$RELexQuotedString//o) { # maybe has escape sequences
            push @VStk, unescape7($1);
            return 'v';
        } else {
            # There was no closing '"' found on this line. To recover from this error (which is
            # hard) we simply continue to fetch lines until EOF, or $RELexQuotedString happens to
            # match.  Then we return '??' instead of 'v'.

            my $Lnprev;
            syntax_error("unterminated quoted string '$Ln'");
            while (1) {
                $Lnprev = $Ln;
                unless (lexln()) {
                    syntax_error("EOF in quoted string"); last;
                }
                $Ln = $Lnprev.$Ln;
                last if $Ln =~ s/$RELexQuotedString//o;
            } return '??';
        }
    } elsif ($C1 == 60) {       # <<HERE
        if ($Ln =~ s/<<([_\w]+)//io) {
            # Fetch lines until $tok appears at top of a line.  Then continues at $rest of original
            # line. If not EOF the next call to lexln() will return the next line after the line
            # that had closed the here-doc.

            my($tok, $rest, @ln, $ok) = ($1, $Ln);
            my $nanoscript = ($tok eq $DefaultNanoscriptToken);
            while ($ok = lexln()) {
                if ($Ln =~ /^$tok\s*$/m) {
                    $Ln = $rest; last;
                } else {
                    push @ln, unescape7($Ln)
                }
            }
            unless ($ok) {
                confess unless at_eof();
                return syntax_error(qq(EOF while reading here-document '$tok'));
            } else {
                push @VStk, join("\n", @ln)."\n"; # add newline to all lines
                return $nanoscript ? 'n' : 'v';
            }
        }
    }

    # Jump over comments. '//' or '#' single-line-comment, '/*' multi-line-comment.

    if ($C1 == 35) {            # '#'
        $Ln = ''; goto NEXTC1;
    } elsif ($C1 == 47) {       # '/'
        if ($Ln =~ /^\/[\*\/]/o) {
            goto NEXTC1 if $Ln =~ s/^\/\*.*\*\/\s*//x;
            if ($Ln =~ /^\/\//o) {
                $Ln = ''; goto NEXTC1;
            }
            while (lexln()) {
                if ($Ln =~ /\*\/(.*)/) {
                    $Ln = $1; goto NEXTC1;
                }
            } return syntax_error(qq(unterminated comment));
        }
    }

    # Must be a symbolic name (unquoted string). Names are printable and hence have no \NNN
    # sequences.  (Finally applies a regex.)

    if ($Ln =~ s/$RELexSymbol//o) {
        push @VStk, $1;
        return 'v';
    }

    # Unrecognized character, e.g. '*', single '<', '\''.

    die "\n".syntax_error(qq(unrecognized character-code $C1).' '.chr($C1));
}

sub at_eof() {
    if ($ReadFh) {
        return eof($ReadFh);
    } elsif (defined $LnArray && $#$LnArray != -1) {
        return 0
    } else {
        return 1                # $LnArray undef'd or empty
    }
}

sub lexln() {
    # Called from lex to parse Rlist files, and from read_csv.

    if ($ReadFh && !eof($ReadFh)) { # eof(undef) and eof(0) are 1
        $Ln = readline($ReadFh); chomp $Ln; # strips $/
        $Ln =~ s/^([ \t]*)\\#/$1#/o if $SafeCppMode;
        #print "$Ln\n";
        return 1;
    } elsif (defined $LnArray && $#$LnArray != -1) {
        # Read from string.
        $Ln = shift @$LnArray;
        return 1;
    }
    $Ln = undef;
    return 0;
}

sub parse()
{
    my($q, $t, $m, $r, $l) = ('');
    $Warnings = $Errors = $MissingInput = $Broken = 0;
    @Messages = @VStk = @NStk = ();

    while (defined($t = lex())) {
        # Push new token, then reduce as many rules as possible from the tail of the queue before
        # fetching more tokens.  Longer rules are matched first.  The constants 2 and 4 are the
        # min./max. lengths of rules in %Rules. When $l (the current length of $m) is <2 no rule
        # can be matched.

        if (1) {
            $q .= $t;
            while (($l = length($q)) >= 2) {
                if ($r = $Rules{substr($q, -4)}) {
                    substr($q, -4) = $r->();
                } elsif ($r = $Rules{substr($q, -3)}) {
                    substr($q, -3) = $r->();
                } elsif ($r = $Rules{substr($q, -2)}) {
                    substr($q, -2) = $r->();
                } else { last }   # fetch another token
            }                     # match another rule
        } else {
            # The above loop is ca. 10% faster than the second, so this one is disabled (although
            # working).  We expect the if(1/0) blocks to be neutralized by the byte-compiler.

            $l = length($q .= $t);
            while ($l >= 2) {
                $l = 4 if $l > 4;
                $m = substr($q, -$l);

                while (1) {			  # TODO: last if $m begins with [=,;})]
                    if ($Rules{$m}) { # can reduce a rule $m
                        printf STDERR "%20s\treducing  $m\n", $q if $DEBUG;
                        substr($q, -$l) = $Rules{$m}->();
                        $l = length $q; last;
                    } else {
                        # $m is not a matching rule.  Cut the first character from $m and try
                        # matching it.
                        #
                        # Note that to uickly remove the first character from a string is
                        # surprisingly hard in Perl. All of the following work:
                        #
                        #   $m = unpack('x1A'.$l, $m)
                        #   $m = substr($m, 1)      # fastest
                        #   substr($m, 0, 1) = ''

                        printf STDERR "%20s\tno rule   $m\n", $q if $DEBUG && $l > 1;
                        last if --$l < 2;
                        $m = substr($m, 1);
                    }
                } last if $Errors;
            }
        }
    }

    # Parser has finished, EOF has been reached (lex had returned undef). The token queue has now
	# been reduced to one token and @VStk only contains its value. The token 'h' (hash) or 'l'
	# (list). Because of the parser map nature it could also be 'v' (value), in which case it shall
	# decay into a hash or list.

    return undef if $Errors;

	print STDERR qq'Data::Rlist::parse() reached EOF with "$q"\n' if $DEBUG;
	if (@VStk == 0) {
		croak STDERR "unexpected, supernumeray tokens after parsing:\n\t$q\n" if $DEBUG && $q;
		$MissingInput = 1;		# empty input or non-existing file
		return undef;
	} else {
		if (@VStk > 1) {
			pr1nt('ERROR', qq'broken input', qq'expected "l" (list) or "h" (hash), not "$q"');
			my @overproduced = map { ref($_) ? $_ : Data::Rlist::quote7($_) } @VStk;
			for (my $i = 0; $i <= $#overproduced; ++$i) {
				warning(sprintf("cancelling overbilled value [%u] %s", $i, $overproduced[$i]));
			}
			print STDERR qq'Data::Rlist::parse() returns undef\n' if $DEBUG;
			return undef;
		} elsif (not defined $VStk[0]) {
			confess				# dto.
		} elsif ($q eq 'v') {
			my $rtp = reftype $VStk[0]; # result type
			unless (defined $rtp) {
				$VStk[0] = { $VStk[0] => undef } # not a reference -> the input is just one scalar
			} elsif ($rtp !~ /(?:HASH|ARRAY)/) {
				confess quote7($VStk[0]) # shall be an array/hash-reference
			}
		}
	}

	print STDERR "Data::Rlist::parse() returns $VStk[0]\n" if $DEBUG;
	return pop @VStk;
}

=item F<compile(DATA[, OPTIONS, FH])>

Build  Rlist text  from DATA:

=over

=item *

Reference-types F<SCALAR>, F<HASH>, F<ARRAY> and F<REF> are compiled into text, whether blessed or
not.

=item *

Reference-types F<CODE> are compiled depending on the L<C<"code_refs">|/Compile Options> setting in
OPTIONS.

=item *

Reference-types F<GLOB> (L<typeglob-refs|/A Short Story  of Typeglobs>), F<IO> and F<FORMAT> (file-
and  directory  handles) cannot  be  dissolved,  and are  compiled  into  the strings  C<"?GLOB?">,
C<"?IO?"> and C<"?FORMAT?">.

=item *

F<undef>'d values in arrays are compiled into the default Rlist C<"">.

=back

When FH is defined compile directly to this file and return 1.  Otherwise build a string and return
a reference  to it.  This is  the compilation function called  when the OPTIONS  argument passed to
F<L</write>> is not omitted, and is not C<"fast"> or C<"perl">.

=item F<compile_fast(DATA)>

Build Rlist  text from  DATA, as  fast as actually possible  with pure Perl:

=over

=item *

Reference-types F<SCALAR>, F<HASH>, F<ARRAY> and F<REF> are compiled into text, whether blessed or
not.

=item *

F<CODE>, F<GLOB>, F<IO> and F<FORMAT> are compiled into the strings C<"?CODE?">, C<"?IO?">,
C<"?GLOB?"> and C<"?FORMAT?">.  

=item *

F<undef>'d values in arrays are compiled into the default Rlist C<"">.

=back

F<L</compile_fast>> is  the default compilation  function. It is  called when you pass  F<undef> or
C<"fast">  in  place of  the  OPTIONS  parameter  (see F<L</write>>,  F<L</write_string>>).   Since
F<L</compile_fast>>  considers no  compile options  it will  not call  code, round  numbers, detect
self-referential data etc.  Also F<L</compile_fast>> always compiles into a unique package variable
to which it returns a reference.

=item F<compile_Perl(DATA)>

Like F<L</compile_fast>>,  but do not compile  Rlist text - compile  DATA into Perl  syntax. It can
then  be F<eval>'d.   This renders  more compact,  and more  exact output  as  L<Data::Dumper>. For
example, only  strings are quoted.  To  enable this compilation  function pass C<"perl"> to  as the
OPTIONS argument, or set the F<-options> attribute of package objects to this string.

=back

=cut

our($Datatype, $K, $V);
our($Outline_data, $Outline_hashes, $Code_refs, $Here_docs, $Auto_quote, $Precision);
our($Eol_space, $Paren_space, $Bol_tabs, $Comma_punct, $Semicolon_punct, $Assign_punct);

sub compile($;$$)
{
    my($data, $result) = shift;
    my $options = complete_options(shift);

    local($Fh, $Depth, $Broken) = (shift, -1, 0);
    local $RoundScientific = 1 if $options->{scientific};
    local($Eol_space, $Paren_space, $Bol_tabs, 
          $Comma_punct, $Semicolon_punct, $Assign_punct) = map { $options->{$_} }
          qw/eol_space paren_space bol_tabs 
             comma_punct semicolon_punct assign_punct/;

    local($Outline_data, $Outline_hashes,
          $Code_refs, $Here_docs, $Auto_quote, $Precision) = map { $options->{$_} }
          qw/outline_data outline_hashes
             code_refs here_docs auto_quote precision/;

    $Eol_space = $/ unless defined $Eol_space;

    return compile1($data) unless $Fh; # return string-reference
    return compile2($data);     # return 1
}

sub comptab($) {
    return '' if $Bol_tabs == 0; # no indentation
    return chr(9) x ($Bol_tabs * ($Depth + $_[0])); # use physical TABs
}

sub compval($) {
    # Compile a scalar value (number or string, but not a reference).
    #
    # TODO: to gain more speed, in compile create a specialized sub depending on globals
    # $Precision, $Here_docs.

    my $v = shift;
    if (defined $v) {
        if ($v !~ $REValue) {
            # Not an identifier, number or quoted string.  Hence $v will be quoted, and maybe as
            # here-doc.
            if ($Here_docs) {
                if ($v =~ /\n.*\n\z/os) {
                    # Here-docs enabled and $v qualifies.  We can write only strings with at least
                    # two LFs as here-docs (although a final LF would be sufficient).  Now find a
                    # token that doesn't interfere with the text: "___", "HERE", "HERE0", "HERE1"
                    # etc.

                    my @ln = split /\n/, $v;
                    my $tok = '___';
                    while (1) {
                        last unless grep { /^$tok/ } @ln;
                        if ($tok =~ /\d\z/) {
                            $tok++
                        } else {
                            $tok = $tok !~ 'HERE' ? 'HERE' : 'HERE0'
                        }
                    } $v = join('', map { "$_\n" } ("<<$tok", (map { escape7($_) } @ln), $tok));
                } else {
                    $v = quote7($v)
                }
            } else {
                $v = quote7($v)
            }
        } elsif (ord($v) != 34) {
            # Not already quoted.  Either $v is a number or a symbolic name.
            if ($Auto_quote) {
                if ($v =~ $REFloat) {
                    $v = round($v, $Precision) if defined $Precision;
                } else {
                    die $v unless $v =~ $RESymbol;
                    $v = qq("$v");
                }
            } elsif (defined $Precision) {
                $v = round($v, $Precision) if $v =~ $REFloat;
            }
        }
    } $v
}

sub compile1($);
sub compile1($)
{
    # Compile Perl data structure $data into some Rlist and return a string reference.

    my $data = shift;
    my($r, $inl, $k, $v);

    if (ref $data) {
        $Datatype = ord reftype $data;
        $Depth++;
        if ($MaxDepth >= 1 && $MaxDepth < $Depth) {
            pr1nt('ERROR', "compile1() broken in deep $data (max-depth = $MaxDepth)") unless $Broken++;
            $r = DEFAULT_VALUE
        } elsif ($Datatype == 65) { # 65 => 'A' => 'ARRAY'
            my $cnt = @$data;
            unless ($cnt) {
                $r = '('.$Paren_space.')';
            } elsif ($Outline_data > 0 && $Outline_data <= $cnt) {
                # List has more than $Outline_data number of configured elements; print each
                # element on a separate line.

                my($pref0, $pref) = (comptab(0), comptab(1));
                $r.= $Eol_space.$pref0.'('.$Eol_space.$pref;

                # BUG: for some strange reason it destroys $data if assigning the result of the
                # recursive compile1() call to $v again.  Perl 5.8.6,
                # cygwin-thread-multi-64int. Solution: assign temporarily to $w.

                my $w;
                foreach $v (@$data) {
                    $w = ${compile1($v)};
                    $r.= $Comma_punct.$Eol_space.$pref if $inl; $inl = 1;
                    $r.= $w;
                }
                $r.= $Eol_space.$pref0.')';
            } else {
                # Print all entries to one line.

                my $w;
                $r.= '('.$Paren_space;
                foreach $v (@$data) {
                    $w = ${compile1($v)};
                    $r.= $Comma_punct if $inl; $inl = 1;
                    $r.= $w;
                }
                $r.= $Paren_space if $inl;
                $r.= ')';
            }
        } elsif ($Datatype == 72) { # 72 => 'H' => 'HASH'
            my @keys = sort keys %$data;
            unless (@keys) {
                $r = '{'.$Paren_space.'}';
            } else {
                my $manykeys = $Outline_data && @keys;
                my($pref0, $pref) = (comptab(0), comptab(1));
                foreach $k (@keys) {
                    $v = $data->{$k};
                    unless ($inl) { # prepare first pair
                        $r.= $Eol_space.$pref0 if $Outline_hashes && $manykeys;
                        $r.= '{'.$Paren_space;
                        $r.= $Eol_space if $manykeys; $inl = 1;
                    }
                    $k = $pref.(($k !~ $REValue) ? quote7($k) : $k);
                    unless (defined($v)) {
                        $r.= $k.$Semicolon_punct.$Eol_space; # value is undef
                    } else {
                        $v = ${compile1($v)};
                        $r.= $k.$Assign_punct.$v.$Semicolon_punct.$Eol_space;
                    }
                }
                $r.= $pref0 if $manykeys;
                $r.= '}';
                $r.= $Eol_space unless $Depth;
            }
        } elsif ($Datatype == 82) { # 82 => 'R' => 'REF'
            $r.= ${compile1($$data)}
        } elsif ($Datatype == 83) { # 83 => 'S' => 'SCALAR'
            $r.= compval($$data);
        } elsif ($Datatype == 67) { # 67 => 'C' => 'CODE'
            $r.= $Code_refs ? ${compile1($data->())} :  '"?CODE?"'
        } else {                # other reference: 'IO', 'GLOB' or 'FORMAT'
            $r.= compval('?'.reftype($data).'?')
        }
        $Depth--;
    } elsif (defined $data) {   # $data is some scalar (not a ref)
        $r = compval($data);
    } else {                    # $data is undefined
        $r = DEFAULT_VALUE
    } \$r;
}

sub compile2($);
sub compile2($)
{
    # Compile Perl data structure $data into some Rlist and directly print into file handle $Fh (do
    # not compile a big string such as compile1() does).
    #
    # WARNING: this must be merely a copy of the compile1() code.

    my $data = shift;
    my($inl, $k, $v);

    if (ref $data) {
        $Datatype = ord reftype $data;
        $Depth++;
        if ($MaxDepth >= 1 && $MaxDepth < $Depth) {
            pr1nt('ERROR', "compile2() broken in deep $data (depth = $Depth, max-depth = $MaxDepth)") unless $Broken++;
            print $Fh "\n", DEFAULT_VALUE;
        } elsif ($Datatype == 65) { # 65 => 'A' => 'ARRAY'
            my $cnt = 1 + $#$data;
            unless ($cnt) {
                print $Fh '('.$Paren_space.')';
            } elsif ($Outline_data > 0 && $Outline_data <= $cnt) {
                # List has more than the number of configured elements; print each element on a
                # separate line.

                my($pref0, $pref) = (comptab(0), comptab(1));
                print $Fh $Eol_space.$pref0.'('.$Eol_space.$pref;
                foreach $v (@$data) {
                    print $Fh $Comma_punct.$Eol_space.$pref if $inl; $inl = 1;
                    compile2($v);
                }
                print $Fh $Eol_space.$pref0.')';
                print $Fh $Eol_space unless $Depth;
            } else {			# print all entries to one line
                print $Fh '('.$Paren_space;
                foreach $v (@$data) {
                    print $Fh $Comma_punct if $inl; $inl = 1;
                    compile2($v);
                }
                print $Fh $Paren_space if $inl;
                print $Fh ')';
            }
        } elsif ($Datatype == 72) { # 72 => 'H' => 'HASH'
            my @keys = sort keys %$data;
            unless( @keys ) {
                print $Fh '{'.$Paren_space.'}';
            } else {
                my $manykeys = $Outline_data && @keys;
                my($pref0, $pref) = (comptab(0), comptab(1));
                foreach $k (@keys) {
                    $v = $data->{$k};
                    unless ($inl) {
                        print $Fh $Eol_space.$pref0 if $Outline_hashes && $manykeys;
                        print $Fh '{'.$Paren_space;
                        print $Fh $Eol_space if $manykeys; $inl = 1;
                    }
                    $k = $pref.(($k !~ $REValue) ? quote7($k) : $k);
                    unless (defined($v)) {
                        print $Fh $k.$Semicolon_punct.$Eol_space; # value is undef
                    } else {
                        print $Fh $k.$Assign_punct;
                        compile2($v);
                        print $Fh $Semicolon_punct.$Eol_space;
                    }
                }
                print $Fh $pref0 if $manykeys;
                print $Fh '}';
                print $Fh $Eol_space unless $Depth;
            }
        } elsif ($Datatype == 82) { # 82 => 'R' => 'REF'
            compile2($$data)
        } elsif ($Datatype == 83) { # 83 => 'S' => 'SCALAR'
            print $Fh compval($$data);
        } elsif ($Datatype == 67) { # 67 => 'C' => 'CODE'
            if ($Code_refs) {
                compile2($data->())
            } else {
                print $Fh '"?CODE?"'
            }
        } else {                # other reference: 'IO', 'GLOB' or 'FORMAT'
            print $Fh compval('?'.reftype($data).'?')
        }
        $Depth--;
    } elsif (defined $data) {   # $data is some scalar (not a ref)
        print $Fh compval($data);
    } else {                    # $data is undefined
        print $Fh DEFAULT_VALUE;
    } 1
}

sub compile_fast($)
{
    my $data = shift;
    $R = ''; $Depth = -1;       # reset result string
    compile_fast1($data); # return a string reference
    return \$R; # reference to the package-variable $Data::Rlist::R
}

sub compile_fast1($);
sub compile_fast1($)
{
    # Undefined values always are compiled into the default Rlist, the empty string.
    #
    # ord() returns 0 when reftype is undef, which it is for scalars.  For any reference, blessed
    # or not, reftype returns "HASH", "ARRAY", "CODE" or "SCALAR".  The $Datatype approach is
    # significantly faster than testing whether ref($data)=~'ARRAY' etc.

    my $data = $_[0];

    if (ref $data) {
        $Datatype = ord reftype $data;
        $Depth++;
        if ($Datatype == 65) {  # 65 => 'A' => 'ARRAY'
            # Open arrays in lines of their own, like we do also with hashes. The approach is fast
            # and compiles legible text.  Lists of lists (matrices) then look nice.

            if (@$data) {
                $R.= chr(10).(chr(9) x $Depth).'(';
                my $in = 0;
                foreach (@$data) {
                    unless ($in) { $in = 1 } else { $R.= ', ' }
                    if (defined) {
                        if (ref) {
                            compile_fast1($_)
                        } else {
                            $R.= $_ !~ $REValue ? quote7($_): $_
                        }
                    } else { $R.= DEFAULT_VALUE }
                } $R.= ')';
            } else { $R .= '()' }
        } elsif ($Datatype == 72) {   # 72 => 'H' => 'HASH'
            if (%$data) {
                my $pref = chr(9) x $Depth;

                # Sorting is slightly slower than
                #       while (($K, $V) = each %$data)
                # but produces nicer results.  Note also that calling is_random_text is generally
                # faster than to always quote.

                $R.= "{\n";
                foreach $K (sort keys %$data) {
                    $V = $data->{$K};
                    $K = quote7($K) if $K !~ $REValue;
                    $R.= $pref.chr(9).$K;
                    if (defined $V) {
                        $R.= ' = ';
                        if (ref $V) {
                            compile_fast1($V);
                        } else {
                            $V = quote7($V) if $V !~ $REValue;
                            $R.= $V;
                        }
                    } $R.= ";\n";
                } $R.= $pref.'}';
            } else {
                $R.= '{}'
            }
        } elsif ($Datatype == 82) { # 82 => 'R' => 'REF'
            compile_fast1($$data)
        } elsif ($Datatype == 83) { # 83 => 'S' => 'SCALAR'
            $R.= ($$data !~ $REValue) ? quote7($$data) : $$data;
        } else {                # other reference: 'CODE', 'IO', 'GLOB' or 'FORMAT'
            $R.= '"?'.reftype($data).'?"'
        }
        $Depth--;
    } elsif (defined $data) {   # number or string
        $R.= ($data !~ $REValue) ? quote7($data) : $data;
    } else {                    # undef
        $R.= DEFAULT_VALUE;
    }
}

sub compile_Perl($)
{
    my $data = shift;
    $R = ''; $Depth = -1;       # reset result string
    compile_Perl1($data);
    return \$R;
}

sub compile_Perl1($);
sub compile_Perl1($)
{
    my $data = $_[0];
    sub __quote7($) {
        my $s = shift;
        return $s if $s =~ /^["']/;
        return quote7($s);
    }

    if (ref $data) {
        $Datatype = ord reftype $data;
        $Depth++;
        if ($Datatype == 65) {
            if (@$data) {
                $R.= chr(10).(chr(9) x $Depth).'[';
                my $in = 0;
                foreach (@$data) {
                    unless ($in) { $in = 1 } else { $R.= ', ' }
                    if (defined) {
                        if (ref) {
                            compile_Perl1($_)
                        } else {
                            $R.= is_number($_) ? $_ : __quote7($_)
                        }
                    } else { $R.= DEFAULT_VALUE }
                } $R.= ']';
            } else { $R .= '[]' }
        } elsif ($Datatype == 72) {
            if (%$data) {
                my $pref = chr(9) x $Depth;
                $R.= "{\n";
                foreach $K (sort keys %$data) {
                    $V = $data->{$K};
                    $K = __quote7($K) unless is_number($K);
                    $R.= $pref.chr(9).$K;
                    if (defined $V) {
                        $R.= ' => ';
                        if (ref $V) {
                            compile_Perl1($V);
                        } else {
                            $V = __quote7($V) unless is_number($V);
                            $R.= $V;
                        }
                    } $R.= ",\n";
                } $R.= $pref.'}';
            } else {
                $R.= '{}'
            }
        } elsif ($Datatype == 82) {
            compile_Perl1($$data)
        } elsif ($Datatype == 83) {
            $R.= is_number($data) ? $$data : __quote7($$data);
        } else {
            $R.= '"?'.reftype($data).'?"'
        }
        $Depth--;
    } elsif (defined $data) {   # number or string
        $R.= is_number($data) ? $data : __quote7($data);
    } else {                    # undef
        $R.= DEFAULT_VALUE;
    }
}

=head2 Auxiliary Functions

The  utility  functions in  this  section  are generally  useful  when  handling stringified  data.
Internally  F<L</quote7>>, F<L</escape7>>,  F<L</is_integer>>  etc. apply  precompiled regexes  and
precomputed    ASCII     tables.     F<L</split_quoted>>    and     F<L</parse_quoted>>    simplify
L</Text::ParseWords>.   F<L</round>>  and F<L</equal>>  are  working  solutions for  floating-point
numbers.   F<L</deep_compare>>  is a  smart  function  to "diff"  two  Perl  variables.  All  these
functions are very fast and mature.

=over

=item F<is_integer(SCALAR-REF)>

Returns  true when  a scalar  looks like  a positive  or negative  integer constant.   The function
applies the compiled regex F<$Data::Rlist::REInteger>.

=item F<is_number(SCALAR-REF)>

Test for strings  that look like numbers. F<is_number>  can be used to test whether  a scalar looks
like  a  integer/float  constant  (numeric  literal).   The function  applies  the  compiled  regex
F<$Data::Rlist::REFloat>.  Note that it doesn't match

- leading or trailing whitespace,

- lexical conventions such as the C<"0b"> (binary), C<"0"> (octal), C<"0x"> (hex) prefix to denote
  a number-base other than decimal, and

- Perls' legible numbers, e.g. F<3.14_15_92>,

- the IEEE 754 notations of Infinite and NaN.

See also

    $ perldoc -q "whether a scalar is a number"

=item F<is_symbol(SCALAR-REF)>

Test for symbolic names.   F<is_symbol> can be used to test whether a  scalar looks like a symbolic
name.   Such strings  need not  to be  quoted.  Rlist  defines symbolic  names as  a superset  of C
identifier names:

    [a-zA-Z_0-9]                    # C/C++ character set for identifiers
    [a-zA-Z_0-9\-/\~:\.@]           # Rlist character set for symbolic names

    [a-zA-Z_][a-zA-Z_0-9]*                  # match C/C++ identifier
    [a-zA-Z_\-/\~:@][a-zA-Z_0-9\-/\~:\.@]*  # match Rlist symbolic name

For example, names such as F<std::foo>, F<msg.warnings>, F<--verbose>, F<calculation-info> need not
be quoted.

=item F<is_value(SCALAR-REF)>

Returns true when a scalar is an integer, a number, a symbolic name or some quoted string.

=item F<is_random_text(SCALAR-REF)>

The opposite of F<L</is_value>>.  Such scalars will be turned into quoted strings by F<L</compile>>
and F<L</compile_fast>>.

=cut

sub is_integer(\$) { ${$_[0]} =~ $REInteger ? 1 : 0 }
sub is_number(\$) { ${$_[0]} =~ $REFloat ? 1 : 0 }
sub is_symbol(\$) { ${$_[0]} =~ $RESymbol ? 1 : 0 }
sub is_value(\$) { ${$_[0]} =~ $REValue ? 1 : 0 }
sub is_random_text(\$) { ${$_[0]} =~ $REValue ? 0 : 1 }

=item F<quote7(TEXT)>

=item F<escape7(TEXT)>

Converts TEXT into 7-bit-ASCII.  All characters not in the set of the 95 printable ASCII characters
are escaped.  The following  ASCII codes will be converted to escaped  octal numbers, i.e. 3 digits
prefixed by a slash:

    0x00 to 0x1F
    0x80 to 0xFF
    " ' \

The  difference  between  the  two  functions  is that  F<quote7>  additionally  places  TEXT  into
double-quotes.    For  example,   F<quote7(qq'"FrE<uuml>her  Mittag\n"')>   returns  C<"\"Fr\374her
Mittag\n\"">, while F<escape7> returns C<\"Fr\374her Mittag\n\">

=item F<maybe_quote7(TEXT)>

Return F<quote7(TEXT)> if  F<L</is_random_text>(TEXT)>; otherwise (TEXT defines a  symbolic name or
number) return TEXT.

=item F<maybe_unquote7(TEXT)>

Return F<unquote7(TEXT)> when TEXT is enclosed by double-quotes; otherwise returns TEXT.

=item F<unquote7(TEXT)>

=item F<unescape7(TEXT)>

Reverses what F<L</quote7>> and F<L</escape7>> did with TEXT.

=item F<unhere(HERE-DOC-STRING[, COLUMNS, FIRSTTAB, DEFAULTTAB])>

Combines  recipes   1.11  and   1.12  from   the  Perl  Cookbook.    HERE-DOC-STRING  shall   be  a
L<here-document|/Numbers,  Strings and  Here-Documents>.   The function  checks  whether each  line
begins with  a common prefix,  and if so,  strips that off.   If no prefix  it takes the  amount of
leading whitespace found the first line and removes that much off each subsequent line.

Unless  COLUMNS  is defined  returns  the  new here-doc-string.  Otherwise,  takes  the string  and
reformats it into  a paragraph having no line  more than COLUMNS characters long.  FIRSTTAB will be
the indent  for the first  line, DEFAULTTAB  the indent for  every subsequent line.  Unless passed,
FIRSTTAB and DEFAULTTAB default to the empty string C<"">.

=cut

our(%g_nonprintables_escaped,   # keys are non-printable ASCII chars, values are escape sequences
    %g_escaped_nonprintables,   # keys are escaped sequences, values are the non-printables
    $REnonprintable,
    $REescape_seq);

BEGIN {
    # Perl should not use/require the same module twice. However, the die below may throw when
    # Rlist.pm is symlinked. (This is a mature package, and we experienced many scenarios with it
    # so far.)  For example, when Rlist.pm is installed locally to ~/bin and ~/bin is in @INC, one
    # can say
    #       use Rlist;
    # to read the package Data::Rlist.  But in order to
    #       use Data::Rlist;
    # as with the regularily installed version (from CPAN), one must create ~/bin/Data/Rlist.pm.
    # If this is a symlink to ~/bin/Rlist.pm the same file might be used twice by perl.

    croak "${\(__FILE__)} used/required twice" if %g_escaped_nonprintables;

    # Tabulate octalization. In previous versions escape7() was implemented so
    #
    #   sub _octl {
    #       $n = ord($1);
    #       '\\'.($n >> 6).(($n >> 3) & 7).($n & 7);
    #   }
    #   s/([\x00-\x1F\x80-\xFF])/_octl()/ge # non-printables => \NNN
    #
    # which has now been optimized into
    #
    #   s/$REnonprintable/$g_nonprintables_escaped{$1}/go

    sub escape_char($) {
        my $c = ord($_[0]);						 # get number code, eg. 'ü' => 252
        '\\'.($c >> 6).(($c >> 3) & 7).($c & 7); # eg. 252 => \374
    }

    sub unescape_char($) {      # w/o leading backslash
        pack('C', oct($_[0]));  # deoctalize eg. 11 => 9 => \t
    }

    $REescape_seq = qr/\\([0-7]{1,3}|[nrt"'\\])/;
    $REnonprintable = qr/([\x00-\x1F\x80-\xFF"'])/;

    # Build tables for non-printable ASCII chararacters.

    %g_nonprintables_escaped = map { chr($_) => escape_char(chr($_)) } (0x00..0x1F, 0x80..0xFF);
    my @v = values %g_nonprintables_escaped;
    foreach (@v) {
        s/^\\// or die;
        croak $_ if exists $g_escaped_nonprintables{$_};
        $g_escaped_nonprintables{$_} = unescape_char($_)
    }

    croak unless keys(%g_nonprintables_escaped) == (255 - 95);
    croak join("  ", keys %g_escaped_nonprintables) unless keys(%g_escaped_nonprintables) == (255 - 95);
    #croak sort keys %g_escaped_nonprintables;

    # Add \ " ' into the tables, which spares another s// call in escape and unescape for them. The
    # leading \ is alredy matched by $REescape_seq.

    $g_nonprintables_escaped{chr(34)} = qq(\\"); # " => \"
    $g_nonprintables_escaped{chr(39)} = qq(\\'); # ' => \'

    $g_escaped_nonprintables{chr(34)} = chr(34);
    $g_escaped_nonprintables{chr(39)} = chr(39);
    $g_escaped_nonprintables{chr(92)} = chr(92);

    # Add \r, \n and \t.

    if (1) {
        $g_nonprintables_escaped{chr( 9)} = qq(\\t); # \t => \\t
        $g_nonprintables_escaped{chr(10)} = qq(\\n); # \n => \\n
        $g_nonprintables_escaped{chr(13)} = qq(\\r); # \r => \\r

        $g_escaped_nonprintables{'t'} = chr( 9);
        $g_escaped_nonprintables{'n'} = chr(10);
        $g_escaped_nonprintables{'r'} = chr(13);
    }
}

sub maybe_quote7($) { is_random_text($_[0]) ? quote7($_[0]) : $_[0] }
sub maybe_unquote7($) { ord($_[0]) == 34 ? unquote7($_[0]) : $_[0] }
sub quote7($) {
    # Escape, then add quotes. Note that the below expression is faster than qq.
    '"'.escape7($_[0]).'"'
}

sub unquote7($) {
    # First remove quotes, then unescape. The below expression might look complicated; but it is
    # faster than to shift the string and apply s/^\"// and s/\"$// on it.
    unescape7(ord($_[0]) == 34 ? substr($_[0], 1, length($_[0]) - 2) : $_[0])
}

sub escape7($) {
    my $s = shift; return '' unless defined $s;
    $s =~ s/\\/\\\\/g;                                        # has to happen first, because...
    $s =~ s/$REnonprintable/$g_nonprintables_escaped{$1}/gos; # ...this will intersperse more backslashes
    $s
}

sub unescape7($) {
    my $s = shift;
    $s =~ s/$REescape_seq/$g_escaped_nonprintables{$1}/gos;
    $s
}

sub unhere($;$$$) {
    # Combines recipes 1.11 and 1.12.
    local $_ = shift;
    my($white, $leader);        # common whitespace and common leading string
    if (/^\s*(?:([^\w\s]+)(\s*).*\n)(?:\s*\1\2?.*\n)+$/) {
        ($white, $leader) = ($2, quotemeta($1));
    } else {
        ($white, $leader) = (/^(\s+)/, '');
    }
    s/^\s*?$leader(?:$white)?//gm;

    # This is recipe 1.12
    my($columns, $firsttab, $deftab) = (shift, shift||'', shift||'');
    if ($columns) {
        use Text::Wrap;
        $Text::Wrap::columns = $columns;
        return wrap($firsttab, $deftab, $_);
    } else {
        return $_;
    }
}

=item F<split_quoted(INPUT[, DELIMITER])>

=item F<parse_quoted(INPUT[, DELIMITER])>

Divide the string INPUT into a list of strings.  DELIMITER is a regular expression specifying where
to split (default: C<'\s+'>).  The functions won't  split at DELIMITERs inside quotes, or which are
backslashed.

F<parse_quoted> works like F<split_quoted> but  additionally removes all quotes and backslashes
from   the   splitted   fields.    Both   functions   effectively   simplify   the   interface   of
F<Text::ParseWords>.  In an array context they return  a list of substrings, otherwise the count of
substrings.    An  empty   array   is  returned   in   case  of   unbalanced  double-quotes,   e.g.
F<split_quoted(C<'foo,"bar'>)>.

B<EXAMPLES>

    sub split_and_list($) {
        print ($i++, " '$_'\n") foreach split_quoted(shift)
    }

    split_and_list(q("fee foo" bar))

        0 '"fee foo"'
        1 'bar'

    split_and_list(q("fee foo"\ bar))

        0 '"fee foo"\ bar'

The  default   DELIMITER  C<'\s+'>  handles   newlines.   F<split_quoted(C<"foo\nbar\n">)>  returns
S<F<('foo', 'bar',  '')>> and hence can  be used to to  split a large string  of unF<chomp>'d input
lines into words:

    split_and_list("foo  \r\n bar\n")

        0 'foo'
        1 'bar'
        2 ''

The DELIMITER matches everywhere outside of quoted constructs, so in case of the default C<'\s+'>
you may want to remove heading/trailing whitespace. Consider

    split_and_list("\nfoo")
    split_and_list("\tfoo")

        0 ''
        1 'foo'

and

    split_and_list(" foo ")

        0 ''
        1 'foo'
        2 ''

F<parse_quoted> additionally removes all quotes and backslashes from the splitted fields:

    sub parse_and_list($) {
        print ($i++, " '$_'\n") foreach parse_quoted(shift)
    }

    parse_and_list(q("fee foo" bar))

        0 'fee foo'
        1 'bar'

    parse_and_list(q("fee foo"\ bar))

        0 'fee foo bar'

B<MORE EXAMPLES>

String C<'field\ one  "field\ two"'>:

    ('field\ one', '"field\ two"')  # split_quoted
    ('field one', 'field two')      # parse_quoted

String C<'field\,one, field", two"'> with a DELIMITER of C<'\s*,\s*'>:

    ('field\,one', 'field", two"')  # split_quoted
    ('field,one', 'field, two')     # parse_quoted

Split a large string F<$soup> (mnemonic: slurped from a file) into lines, at LF or CR+LF:

    @lines = split_quoted($soup, '\r*\n');

Then transform all F<@lines> by correctly splitting each line into "naked" values:

    @table = map { [ parse_quoted($_, '\s*,\s') ] } @lines

Here is some more complete code to parse a F<.csv>-file with quoted fields, escaped commas:

    open my $fh, "foo.csv" or die $!;
    local $/;                   # enable localized slurp mode
    my $content = <$fh>;        # slurp whole file at once
    close $fh;
    my @lines = split_quoted($content, '\r*\n');
    die q(unbalanced " in input) unless @lines;
    my @table = map { [ map { parse_quoted($_, '\s*,\s') } ] } @lines

In  core  this  is  what  F<L</read_csv>>  does.   F<L</deep_compare>>  allows  you  to  test  what
F<L</split_quoted>> and  F<L</parse_quoted>> return.  For  example, the following code  shall never
die:

    croak if deep_compare([split_quoted("fee fie foo")], ['fee', 'fie', 'foo']);
    croak if deep_compare( parse_quoted('"fee fie foo"'), 1);

=cut

sub split_quoted($;$) {
    # Split [0] at delimiter [1], returning a list of words/tokens.  Delimiter defaults to '\s+'.
    #
    # We've to map the result of parse_line again to build the result. For "foo\nbar\n" parse_line
    # returns ('foo','bar',undef), not ('foo','bar',''). This may cause hard to track "Use of
    # uninitialized value..."  warnings.

    use Text::ParseWords;
    return map { (defined) ? $_ : '' } parse_line($_[1]||'[\s]+', 1, $_[0])
}

sub parse_quoted($;$) {
    use Text::ParseWords;
    return map { (defined) ? $_ : '' } parse_line($_[1]||'[\s]+', 0, $_[0])
}

=item F<equal(NUM1, NUM2[, PRECISION])>

F<L</equal>>  returns true  if  NUM1 and  NUM2  are equal  to PRECISION  number  of decimal  places
(default: 6).  For details see F<L</round>>.

=item F<round(NUM1[, PRECISION])>

Compare and round floating-point numbers NUM1 and NUM2 (as string- or number scalars).

When the C<"precision"> compile option is defined, F<L</round>> is called during compilation on all
numbers.

Normally  F<round>  will  return  a  number  in  fixed-point  notation.   When  the  package-global
F<$Data::Rlist::RoundScientific> is true, however, F<round>  formats the number in either normal or
exponential (scientific) notation,  whichever is more appropriate for  its magnitude.  This differs
slightly from fixed-point notation  in that insignificant zeroes to the right  of the decimal point
are  not included.  Also,  the  decimal point  is  not included  on  whole  numbers.  For  example,
F<L</round>(42)> does not return 42.000000, and F<round(0.12)> returns 0.12, not 0.120000.

B<MACHINE ACCURACY>

One needs a function like F<equal> to compare floats, because IEEE 754 single- and double precision
implementations are  not absolute -  in contrast  to the numbers  they actually represent.   In all
machines  non-integer numbers are  only an  approximation to  the numeric  truth.  In  other words,
they're not commutative.  For  example, given two floats F<a> and F<b>,  the result of F<a+b> might
be different than that of F<b+a>.  For another example, it is a mathematical truth that F<a * b = b
* a>, but not necessarily in a computer.

Each machine has its own accuracy, called the F<machine epsilon>, which is the difference between 1
and the smallest exactly representable number greater than one. Most of the time only floats can be
compared that have been carried out to a  certain number of decimal places.  In general this is the
case when  two floats that result  from a numeric operation  are compared - but  not two constants.
(Constants are accurate through to lexical conventions of the language. The Perl and C syntaxes for
numbers simply won't allow you to write down inaccurate numbers.)

See also recipes 2.2 and 2.3 in the Perl Cookbook.

B<EXAMPLES>

    CALL                    RETURNS NUMBER
    ----                    --------------
    round('0.9957', 3)       0.996
    round(42, 2)             42
    round(0.12)              0.120000
    round(0.99, 2)           0.99
    round(0.991, 2)          0.99
    round(0.99, 1)           1.0
    round(1.096, 2)          1.10
    round(+.99950678)        0.999510
    round(-.00057260)       -0.000573
    round(-1.6804e-6)       -0.000002

=cut

sub equal($$;$) {
    my($a, $b, $prec) = @_;
    $prec = 6 unless defined $prec;
    sprintf("%.${prec}g", $a) eq sprintf("%.${prec}g", $b)
}

sub round($;$) {
    # Note that sprintf("%.6g\n", 2006073104) yields 2.00607e+09, which looses digits.
    my $a = shift; return $a if is_integer($a);
    my $prec = shift; $prec = 6 unless defined $prec;
    return sprintf("%.${prec}g", $a) if $RoundScientific;
    return sprintf("%.${prec}f", $a);
}

=item F<deep_compare(A, B[, PRECISION, TRACE_FLAG])>

Compare and  analyze two numbers, strings or  references.  Generates a list  of messages describing
exactly all unequal data.  Hence, for any Perl data F<$a> and F<$b> one can assert:

    croak "$a differs from $b" if deep_compare($a, $b);

When PRECISION is defined all numbers in A and B are F<L</round>>'d before actually comparing them.
When TRACE_FLAG is true traces progress.

B<RESULT>

Returns an array of messages, each describing unequal data, or data that cannot be compared because
of type- or value-mismatching.  The array is empty when deep comparison of A and B found no unequal
numbers or strings, and only indifferent types.

B<EXAMPLES>

The  result is line-oriented,  and for  each mismatch  it returns  a single  message. For  a simple
example,

    Data::Rlist::deep_compare(undef, 1)

yields

    <<undef>> cmp <<1>>   stop! 1st undefined, 2nd defined (1)

=cut

sub deep_compare($$;$$$);
sub deep_compare($$;$$$)
{
    use Scalar::Util qw/reftype blessed looks_like_number/;

    sub prind($@) { my $ind = shift||0; print STDERR chr(9) x $ind, join(' ', grep { defined } @_), chr(10) }
    #sub quot($) { my $s = shift; $s =~ s/([\n\r\t])/\\&ord($1)/ge; "'$s'" }
    sub quot($) { my $s = shift; defined($s) ? "'$s'" : 'undef' }

    my(@R);
    my($a, $b, $prec, $dump, $ind) = @_;
    my($atp, $btp) = (reftype($a), reftype($b)); # undef, SCALAR, ARRAY or HASH
    my($anm, $bnm, $refs) = (0, 0, defined($atp));
    my $prefix = sub { quot($a).($anm ? ' == ' : ' cmp ').quot($b) };
    my($mismatch, $match) = sub { # use "lazy instantiation", so that this sub isn't compiled for
                                  # the majority of cases (when two values are equal)
        my $s = shift; eval 'push @R, $prefix->()."\tStop! ".$s; prind($ind, $R[$#R]) if $dump;'
    };
    $match = sub { my $s = shift; eval 'prind($ind, $prefix->(), $s)' } if $dump;
    $ind ||= 0;

    unless ($refs) {            # unless $a is a reference
        unless (defined $a) {
            $atp = 'undef';
            if (defined $b) {
                $mismatch->('only 2nd defined');
            } else {
                $match->() if $dump; # both undef'd
            } return @R;
        } else {
            unless (defined $b) {
                $mismatch->('only 1st defined');
                return @R;
            }
            $atp = ($anm = is_number($a)) ? 'number' : 'string';
            $a = round($a, $prec) if $anm and defined $prec;
        }
    }
    unless (defined $btp) {
        unless (defined $b) {
            $btp = 'undef';
            if (defined $a) {
                $mismatch->('only 1st defined');
            } else {
                $match->() if $dump; # both undef'd
            } return @R;
        } else {
            unless (defined $a) {
                $mismatch->('only 2nd defined');
                return @R;
            }
            $btp = ($bnm = is_number($b)) ? 'number' : 'string';
            $b = round($b, $prec) if $bnm and defined $prec;
        }
    }
    #die unless defined $a && defined $b;
    if ($atp ne $btp) {
        $mismatch->("type-mismatch, $atp vs. $btp");
        return @R;
    }

    # At this point $a and $b have equal types.
    unless ($refs) {			# compare numbers/strings
        if ($anm) {
            $prec = (defined $prec) ? " precision=$prec" : '';
            unless (equal($a, $b)) {
                $mismatch->($prec)
            } elsif ($dump) {
                $match->($prec)
            }
        } elsif ($a ne $b) {
            $mismatch->('unequal strings')
        } elsif ($dump) {
            $match->()
        } return @R
    } else {					# deep-compare two references
        my $recurse = sub($$) { deep_compare($_[0], $_[1], $prec, $dump, $ind + 1) };
        prind($ind, $prefix->()) if $dump;
        if ($atp eq 'SCALAR') {	# two scalars refs
            push @R, $recurse->($$a, $$b);
            return @R
        } elsif ($atp eq 'HASH') { # two hashes
            my $acnt = keys %$a;
            my $bcnt = keys %$b;
            unless ($acnt == $bcnt) {
                $mismatch->("different number of keys ($acnt, $bcnt)");
                return @R;
            } return @R if $acnt == 0; # no keys

            # Although both hashes have an equal number of keys, make sure that the keys themselves
            # are equal, and only then compare values.
            my @a_keys_missing = grep { not exists $b->{$_} } keys %$a;
            my @b_keys_missing = grep { not exists $a->{$_} } keys %$b;

            if (@a_keys_missing || @b_keys_missing) {
                $mismatch->('1st hash misses keys ('.join(', ', map { quote7($_) } @a_keys_missing).")") if @a_keys_missing;
                $mismatch->('2nd hash misses keys ('.join(', ', map { quote7($_) } @b_keys_missing).")") if @b_keys_missing;
                return @R;
            }

            foreach (keys %$a) {
                prind($ind, "key '$_'") if $dump;
                push @R, $recurse->($a->{$_}, $b->{$_});
            }
        } elsif ($atp eq 'ARRAY') {	# two arrays
            if ($#$a != $#$b) {
                $mismatch->("different array sizes: ${\(1+$#$a)} vs. ${\(1+$#$b)}")
            } else {
                for (0 .. $#$a) {
                    prind($ind, "index [$_]") if $dump;
                    push (@R, $recurse->($a->[$_], $b->[$_]))
                }
            }
        } elsif ($atp eq 'REF') {
            # Reference to reference.
            $recurse->($$a, $$b)
        } else {
            $mismatch->("cannot compare types $atp");
        }
    } return @R;
}

=item F<fork_and_wait(PROGRAM[, ARGS...])>

Forks a process  and waits for completion.   The function will extract the  exit-code, test whether
the  process died  and prints  status messages  on F<STDERR>.   F<fork_and_wait> hence  is  a handy
wrapper around the built-in F<system> and F<exec> functions.  Returns an array of three values:

    ($exit_code, $failed, $coredump)

F<$exit_code> is -1  when the program failed to  execute (e.g. it wasn't found or  the current user
has insufficient rights).  Otherwise F<$exit_code> is between  0 and 255.  When the program died on
receipt of a signal (like F<SIGINT> or  F<SIGQUIT>) then F<$signal> stores it. When F<$coredump> is
true the program died and a F<core>-file was written.

=item F<synthesize_pathname(TEXT...)>

Concatenates and  forms all  TEXT strings  into a  symbolic name that  can be  used as  a pathname.
F<synthesize_pathname>  is a  useful  function to  concatenate  strings and  nearby converting  all
characters that do  not qualify as filename-characters, into C<"_"> and  C<"-">.  The result cannot
only be used as file- or URL name, but also (coinstantaneously) as hash key, database name etc.

=back

=cut

sub fork_and_wait(@)
{
    my $prog = shift;
    my($exit_code, $signal, $coredump);
    local $| = 1;
    system($prog, @_);          # == 0 or die "\n\tfailed: $?";
    if ($? == -1) {             # not found
        $exit_code = -1;
        print STDERR "\n\tfailed to execute program: $!\n";
    } elsif ($? & 127) {        # died
        $exit_code = -1;
        $signal = ($? & 127);
        $coredump = ($? & 128);
        print STDERR "\n\tchild died with signal %d, %s core-dump\n", $signal, $coredump ? 'with' : 'without';
    } else {                    # ok
        $exit_code = $? >> 8;
        printf STDERR "\n\tchild exited with value %d\n", $exit_code, "\n" if $DEBUG;
    }
    return ($exit_code, $signal, $coredump)
}

sub synthesize_pathname(@)
{
    my @s = @_;
    my($dch1, $dch2) = ('-', '_');
    join('_',
         map {
             # Unquote.
             s/^"(.+)"\z/$1/;
             # Escape all non-printables.
             $_ = escape7($_);
             # Undo \" \'
             s/\\(["'])/$1/go;
             s/[']/_/g;
             s/"(.+)"/$dch2$dch2$1$dch2$dch2/o; # "xxx" within string => __xxx__
             # Handle \NNN
             s/[\\]/0/g; # eg. \347 => 0347
             # Filename
             s/[\(\|\)\/:;]/$dch1/go;            # ( | ) / : ; ==> -
             s/[\^<>:,;\"\$\s\?!\&\%\*]/$dch2/go; # ^ < > " $ ? ! & % * , ; : wsp => _
             s/^[\-\s]+|[\-\s]+\z//o;
             $_
         } @s
        )
}


=head2 Compile Options

The format of the compiled text and the behavior of F<L</compile>> can be controlled by the OPTIONS
parameter of F<L</write>>, F<L</write_string>> etc.  The  argument is a hash defining how the Rlist
text shall be formatted. The following pairs are recognized:

=over

=item 'precision' =E<gt> PLACES

Make F<L</compile>>  round all numbers  to PLACES decimal  places, by calling F<L</round>>  on each
scalar that L<looks  like a number|/is_number>.  By default PLACES is  F<undef>, which means floats
are not rounded.

=item 'scientific' =E<gt> FLAG

Causes F<L</compile>>  to masquerade  F<$Data::Rlist::RoundScientific>.  See F<L</round>>.

=item 'code_refs' =E<gt> TOKEN

Defines  how F<L</compile>>  shall treat  F<CODE> reference.   Legal values  for TOKEN  are  0 (the
default), C<"call"> and C<"deparse">.

- 0 compiles subroutine references into the string C<"?CODE?">.

- C<"call"> calls the code, then compiles the return value.

- C<"deparse"> serializes the code using F<B::Deparse> (reproducing the Perl source).

=item 'threads' =E<gt> COUNT

If enabled F<L</compile>> internally use multiple  threads.  Note that can speedup compilation only
on machines with at least COUNT CPUs.

=item 'here_docs' =E<gt> FLAG

If enabled strings with at least two newlines in them are written as
L<here-document|/Here-Documents>, when possible.  To qualify as here-document a string has to have
at least two LFs (C<"\n">), one of which must terminate it.

=item 'auto_quote' =E<gt> FLAG

When true (default)  do not quote strings that look like  identifiers (see F<L</is_symbol>>).  When
false quote F<all> strings.  Hash keys are not affected.

F<L</write_csv>> and F<L</write_conf>> interpret this flag differently: false means not to quote at
all; true quotes only strings that don't look like numbers and that aren't yet quoted.

=item 'outline_data' =E<gt> NUMBER

When NUMBER is  greater than 0 use C<"eol_space">  (linefeed) to split data to many  lines. It will
insert a linefeed after every NUMBERth array value.

=item 'outline_hashes' =E<gt> FLAG

If enabled, and C<"outline_data"> is also enabled, prints F<{> and F<}> on distinct lines when
compiling Perl hashes with at least one pair.

=item 'separator' =E<gt> STRING

The comma-separator string to be used by F<L</write_csv>>.  The default is C<','>.

=item 'delimiter' =E<gt> REGEX

Field-delimiter for F<L</read_csv>>.  There is no  default value.  To read configuration files, for
example, you may use C<'\s*=\s*'> or C<'\s+'>. To read CSV-files use e.g. C<'\s*[,;]\s*'>.

=back

The following options format the generated Rlist; normally you don't want to modify them:

=over

=item 'bol_tabs' =E<gt> COUNT

Count of physical, horizontal TAB characters to use at the begin-of-line per indentation
level. Defaults to 1. Note that we don't use blanks, because they blow up the size of generated
text without measure.

=item 'eol_space' =E<gt> STRING

End-of-line string to  use (the linefeed).  For  example, legal values are C<"">,  C<" ">, C<"\n">,
C<"\r\n"> etc. The default  is F<undef>, which means to use the current  value of F<$/>.  Note that
this  is  a compile-option  that  only  affects F<L</compile>>.   When  parsing  files the  builtin
F<readline> function is called, which uses F<$/>.

=item 'paren_space' =E<gt> STRING

String to write after F<(> and F<{>, and before F<}> and F<)> when compiling arrays and hashes.

=item 'comma_punct' =E<gt> STRING

=item 'semicolon_punct' =E<gt> STRING

Comma and semicolon strings, which shall be at least C<","> and C<";">.  No matter what,
F<L</compile>> will always print the C<"eol_space"> string after the C<"semicolon_punct"> string.

=item 'assign_punct' =E<gt> STRING

String to make up key/value-pairs. Defaults to C<" = ">.

=back

=head2 Predefined Options

The L<OPTIONS|/Compile Options> parameter accepted by some package functions is either a hash-ref
or the name of a predefined set:

=over

=item 'default'

Default if writing to a file.

=item 'string'

Compact, no newlines/here-docs. Renders a "string of data".

=item 'outlined'

Optimize the compiled Rlist for maximum readability.

=item 'squeezed'

Very compact, no whitespace at all. For very large Rlists.

=item 'perl'

Compile data in Perl syntax, using F<L</compile_Perl>>, not F<L</compile>>.  The output then
can be F<eval>'d, but it cannot be F<L</read>> back.

=item 'fast' or F<undef>

Compile data as fast as possible, using F<L</compile_fast>>, not F<L</compile>>.

=back

All  functions   that  define   an  L<OPTIONS|/Compile  Options>   parameter  do   implicitly  call
F<L</complete_options>> to complete the argument from  one of the predefined sets, and additionally
from C<"default">.   Therefore you can always  define nothing, or  a "lazy subset of  options". For
example,

    my $obj = new Data::Rlist(-data => $thing);

    $obj->write('thing.rls', { scientific => 1, precision => 8 });

=head2 Exports

Example:

    use Data::Rlist qw/:floats :strings/;

=head3 Exporter Tags

=over

=item F<:floats>

Imports F<L</equal>>, F<L</round>> and F<L</is_number>>.

=item F<:strings>

Imports  F<L</maybe_quote7>>,  F<L</quote7>>,  F<L</escape7>>,  F<L</unquote7>>,  F<L</unescape7>>,
F<L</unhere>>, F<L</is_random_text>>,  F<L</is_number>>, F<L</is_symbol>>, F<L</split_quoted>>, and
F<L</parse_quoted>>.

=item F<:options>

Imports F<L</predefined_options>> and F<L</complete_options>>.

=item F<:aux>

Imports F<L</deep_compare>>, F<L</fork_and_wait>> and F<L</synthesize_pathname>>.

=back

=head3 Auto-Exported Functions

The following functions are implicitly imported into the callers symbol table.  (But you may say
F<require Data::Rlist> instead of F<use Data::Rlist> to prohibit auto-import.  See also
L<perlmod>.)

=over

=item F<ReadData(INPUT[, FILTER, FILTER-ARGS])>

=item F<ReadCSV(INPUT[, OPTIONS, FILTER, FILTER-ARGS])>

=item F<ReadConf(INPUT[, OPTIONS, FILTER, FILTER-ARGS])>

These    are   aliases    for   F<Data::Rlist::L</read>>,    F<Data::Rlist::L</read_csv>>   and
F<Data::Rlist::L</read_conf>>.

=item F<EvaluateData(INPUT[, FILTER, FILTER-ARGS])>

Like F<L</ReadData>>  but implicitly call F<Data::Rlist::L</evaluate_nanoscripts>>  in case parsing
was successful.

=item F<WriteData(DATA[, OUTPUT, OPTIONS, HEADER])>

=item F<WriteCSV(DATA[, OUTPUT, OPTIONS, COLUMNS, HEADER])>

=item F<WriteConf(DATA[, OUTPUT, OPTIONS, HEADER])>

These     are    aliases     for     F<Data::Rlist::L</write>>,    F<Data::Rlist::L</write_string>>
F<Data::Rlist::L</write_csv>> and F<Data::Rlist::L</write_conf>>.  OPTIONS default to C<"default">.

=item F<OutlineData(DATA[, OPTIONS])>

=item F<StringizeData(DATA[, OPTIONS])>

=item F<SqueezeData(DATA[, OPTIONS])>

These   are  aliases  for   F<Data::Rlist::L</write_string_value>>.   F<OutlineData>   applies  the
predefined   L<C<"outlined">|/Predefined   Options>   options,   while   F<StringizeData>   applies
L<C<"string">|/Predefined Options> and F<SqueezeData>() L<C<"squeezed">|/Predefined Options>.  When
specified, OPTIONS are merged into the.  For example,

    print "\n\$thing: ", OutlineData($thing, { precision => 12 });

F<L<rounds|/round>> all numbers in F<$thing> to 12 digits.

=item F<PrintData(DATA[, OPTIONS])>

An alias for

    print OutlineData(DATA, OPTIONS);

=item F<KeelhaulData(DATA[, OPTIONS])>

=item F<CompareData(A, B[, PRECISION, TRACE_FLAG])>

These are  aliases for F<L</keelhaul>> and F<L</deep_compare>>. For example,

    use Data::Rlist;
        .
        .
    my($copy, $as_text) = KeelhaulData($thing);

=back

=cut

sub ReadCSV($;$$$) {
    my($input, $options, $fcmd, $fcmdargs) = @_;
    return Data::Rlist::read_csv($input, $options, $fcmd, $fcmdargs);
}

sub ReadConf($;$$$) {
    my($input, $options, $fcmd, $fcmdargs) = @_;
    return Data::Rlist::read_conf($input, $options, $fcmd, $fcmdargs);
}

sub ReadData($;$$) {
    my($input, $fcmd, $fcmdargs) = @_;
    return Data::Rlist::read($input, $fcmd, $fcmdargs);
}

sub EvaluateData($;$$) {
    my($input, $fcmd, $fcmdargs) = @_;
    my $result = ReadData($input, $fcmd, $fcmdargs);
    my $count = Data::Rlist::evaluate_nanoscripts();
    return $result;
}


sub WriteCSV($;$$$$) {
    my($data, $output, $options, $columns, $header) = @_;
    $options ||= 'default';
    Data::Rlist::write_csv($data, $output, $options, $columns, $header);
}

sub WriteConf($;$$$) {
    my($data, $output, $options, $header) = @_;
    $options ||= 'default';
    Data::Rlist::write_conf($data, $output, $options, $header);
}

sub WriteData($;$$$) {
    my($data, $output, $options, $header) = @_;
    $options ||= 'default';     # when undef uses 'default'
    Data::Rlist::write($data, $output, $options, $header);
}

sub PrintData($;$) {            # return outlined data as string-value
    my($data, $options) = @_;
    print OutlineData($data, $options);
}

sub OutlineData($;$) {          # return outlined data as string-ref
    my($data, $options) = @_;
    return Data::Rlist::write_string_value($data, complete_options($options, 'outlined'));
}

sub StringizeData($;$) {        # return data as compact string-ref (no newlines)
    my($data, $options) = @_;
    return Data::Rlist::write_string_value($data, complete_options($options, 'string'));
}

sub SqueezeData($;$) {          # return data as super-compact string-ref (no whitespace at all)
    my($data, $options) = @_;
    return Data::Rlist::write_string_value($data, complete_options($options, 'squeezed'));
}

sub KeelhaulData($;$) {         # recursively copy data
    my($data, $options) = @_;
    return Data::Rlist::keelhaul($data, $options);
}

sub CompareData($$;$$) {        # recursively compare data
    my($a, $b, $prec, $dump) = @_;
    return Data::Rlist::deep_compare($a, $b, $prec, $dump);
}

=head1 EXAMPLES

String- and number values:

    "Hello, World!"
    foo                         # compiles to { 'foo' => undef }
    3.1415                      # compiles to { 3.1415 => undef }

Array values:

    (1, a, 4, "b u z")          # list of numbers/strings

    ((1, 2),
     (3, 4))                    # list of list (4x4 matrix)

    ((1, a, 3, "foo bar"),
     (7, c, 0, ""))             # another list of lists

Here-document strings:

        $hello = ReadData(\<<HELLO)
        ( <<DEUTSCH, <<ENGLISH, <<FRANCAIS, <<CASTELLANO, <<KLINGON, <<BRAINF_CK )
    Hallo Welt!
    DEUTSCH
    Hello World!
    ENGLISH
    Bonjour le monde!
    FRANCAIS
    Ola mundo!
    CASTELLANO
    ~ nuqneH { ~ 'u' ~ nuqneH disp disp } name
    nuqneH
    KLINGON
    ++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++
    ..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.
    BRAINF_CK
    HELLO

Compiles F<$hello> as 

    [ "Hallo Welt!\n", "Hello World!\n", "Bonjour le monde!\n", "Ola mundo!\n",
      "~ nuqneH { ~ 'u' ~ nuqneH disp disp } name\n",
      "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++\n..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.\n" ]

Configuration object as hash:

    {
        contribution_quantile = 0.99;
        default_only_mode = Y;
        number_of_runs = 10000;
        number_of_threads = 10;
        # etc.
    }

Altogether:

    Metaphysic-terms =
    {
        Numbers =
        {
            3.141592653589793 = "The ratio of a circle's circumference to its diameter.";
            2.718281828459045 = <<___;
The mathematical constant "e" is the unique real number such that the value of
the derivative (slope of the tangent line) of f(x) = e^x at the point x = 0 is
exactly 1.
___
            42 = "The Answer to Life, the Universe, and Everything.";
        };

        Words =
        {
            ACME = <<Value;
A fancy-free Company [that] Makes Everything: Wile E. Coyote's supplier of equipment and gadgets.
Value
            <<Key = <<Value;
foo bar foobar
Key
[JARGON] A widely used meta-syntactic variable; see foo for etymology.  Probably
originally propagated through DECsystem manuals [...] in 1960s and early 1970s;
confirmed sightings go back to 1972. [...]
Value
        };
    };

=head1 NOTES

The  F<Random Lists> (Rlist)  syntax is  inspired by  NeXTSTEP's F<Property  Lists>.  But  Rlist is
simpler, more readable  and more portable.  The  Perl and C++ implementations are  fast, stable and
free.  Markus Felten,  with whom I worked a few  month in a project at  Deutsche Bank, Frankfurt in
summer 1998,  arrested my attention  on Property lists.   He had implemented  a Perl variant  of it
(F<L<http://search.cpan.org/search?dist=Data-PropertyList>>).

The term "Random" underlines the fact that the language

=over

=item *

has four primitive/anonymuous types;

=item *

the basic building block is a list, which is combined at random with other lists.

=back

Hence the term F<Random> does not mean F<aimless> or F<accidental>.  F<Random Lists> are
F<arbitrary> lists.

=head1 F<Data::Dumper>

The main  difference between F<Data::Dumper>  and F<Data::Rlist> is  that scalars will  be properly
encoded as number or string.  F<Data::Dumper> writes numbers always as quoted strings, for example

    $VAR1 = {
                'configuration' => {
                                    'verbose' => 'Y',
                                    'importance_sampling_loss_quantile' => '0.04',
                                    'distribution_loss_unit' => '100',
                                    'default_only' => 'Y',
                                    'num_threads' => '5',
                                            .
                                            .
                                   }
            };

where F<Data::Rlist> writes

    {
        configuration = {
            verbose = Y;
            importance_sampling_loss_quantile = 0.04;
            distribution_loss_unit = 100;
            default_only = Y;
            num_threads = 5;
                .
                .
        };
    }

As one can  see F<Data::Dumper> writes the data  right in Perl syntax, which means  the dumped text
can be simply F<eval>'d, and the data can  be restored very fast. Rlists are not quite Perl-syntax:
a dedicated parser  is required.  But therefore Rlist  text is portable and can be  read from other
programming languages such as L</C++>.

With  F<$Data::Dumper::Useqq>   enabled  it  was  observed  that   F<Data::Dumper>  renders  output
significantly slower  than F<L</compile>>. This  is actually suprising, since  F<Data::Rlist> tests
for each scalar  whether it is numeric, and truely  quotes/escapes strings.  F<Data::Dumper> quotes
all scalars (including numbers), and it does not  escape strings.  This may also result in some odd
behaviors.  For example,

    use Data::Dumper;
    print Dumper "foo\n";

yields

    $VAR1 = 'foo
    ';

while

    use Data::Rlist;
    PrintData "foo\n"

yields

    { "foo\n"; }

Finally, F<Data::Rlist>  generates smaller files.   With the default F<$Data::Dumper::Indent>  of 2
F<Data::Dumper>'s output  is 4-5  times that of  F<Data::Rlist>'s. This is  because F<Data::Dumper>
recklessly  uses blanks,  instead  of horizontal  tabulators,  which blows  up  file sizes  without
measure.

=head2 Rlist vs. Perl Syntax

Rlists are not Perl syntax:

    RLIST    PERL
    -----    ----
     5;       { 5 => undef }
     "5";     { "5" => undef }
     5=1;     { 5 => 1 }
     {5=1;}   { 5 => 1 }
     (5)      [ 5 ]
     {}       { }
     ;        { }
     ()       [ ]

=head2 Debugging Data

To  reduce recursive data  structures (into  true hierachies)  set F<$Data::Rlist::MaxDepth>  to an
integer above 0.  It then defines the  depth under which F<L</compile>> shall not venture deeper.
The compilation of Perl data (into Rlist text)  then continues, but on F<STDERR> a message like the
following is printed:

    ERROR: compile2() broken in deep ARRAY(0x101aaeec) (depth = 101, max-depth = 100)

This  message will  also be  repeated as  comment when  the compiled  Rlist is  written to  a file.
Furthermore  F<$Data::Rlist::Broken>  is  incremented  by  one. While  the  compilation  continues,
effectively  any  attempt to  venture  deeper as  suggested  by  F<$Data::Rlist::MaxDepth> will  be
blocked.

See F<L</broken>>.

=head2 Speeding up Compilation (Explicit Quoting)

Much work  has been spent to  optimize F<Data::Rlist> for speed.   Still it is  implemented in pure
Perl (no XS).  A rough estimation for Perl 5.8 is "each MB takes one second per GHz".  For example,
when the resulting  Rlist file has a size of 13  MB, compiling it from a Perl  script on a 3-GHz-PC
requires  about 5-7  seconds.   Compiling  the same  data  under Solaris,  on  a sparcv9  processor
operating at 750 MHz, takes about 18-22 seconds.

The process of compiling can be speed up by calling F<L</quote7>> explicitly on scalars. That is,
before calling F<L</write>> or F<L</write_string>>.  Big data sets may compile faster when for
scalars, that certainly not qualify as symbolic name, F<L</quote7>> is called in advance:

    use Data::Rlist qw/:strings/;

    $data{quote7($key)} = $value;
        .
        .
    Data::Rlist::write("data.rlist", \%data);

instead of

    $data{$key} = $value;
        .
        .
    Data::Rlist::write("data.rlist", \%data);

It depends on the case whether  the first variant is faster: F<L</compile>> and F<L</compile_fast>>
both have to call  F<L</is_random_text>> on each scalar.  When the scalar  is already quoted, i.e.,
its first character is C<">, this test ought to run faster.

Internally F<L</is_random_text>> applies the precompiled regex F<$Data::Rlist::REValue>.  Note that
the  expression S<F<($s!~$Data::Rlist::REValue)>>  can  be up  to  20% faster  than the  equivalent
F<is_random_text($s)>.

=head2 Quoting strings that look like numbers

Normally  you  don't  have to  care  about  strings,  since  un/quoting  happens as  required  when
reading/compiling Rlist or CSV  text.  A common problem, however, occurs when  some string uses the
same lexicography than numbers do.

Perl defines  the string as the  basic building block for  all program data, then  lets the program
decide F<what strings mean>.   Analogical, in a printed book the reader  has to decipher the glyphs
and  decide  what evidence  they  hide.   Printed text  uses  well-defined  glyphs and  typographic
conventions, and finally the competence of the reader, to recognize numbers.  But computers need to
know the exact number type and  format.  Integer?  Float?  Hexadecimal?  Scientific?  Klingon?  The
Perl Cookbook recommends the use of a  regular expression to distinguish number from string scalars
(recipe 2.1).

In Rlist,  string scalars  that look  like numbers need  to be  quoted explicitly.   Otherwise, for
example, the  string scalar C<"-3.14"> appears as  F<-3.14> in the output,  C<"007324"> is compiled
into 7324 etc. Such text is lost and read back  as a number.  Of course, in most cases this is just
what you want. For hash keys, however, it might be a problem.  One solution is to prefix the string
with C<"_">:

    my $s = '-9'; $s = "_$s";

Such strings do not qualify as a number anymore.  In the C++ implementation it will then become
some F<std::string>, not a F<double>.  But the leading C<"_"> has to be removed by the reading
program.  Perhaps a better solution is to explicitly call F<L</quote7>>:

    use Data::Rlist qw/:strings/;

    $k = -9;
    $k = quote7($k);            # returns qq'"-9"'

    $k = 3.14_15_92;
    $k = quote7($k);            # returns qq'"3.141592"'

Again, the  need to quote  strings that  look like numbers  is a problem  evident only in  the Perl
implementation of Rlist, since Perl is a  language with weak types.  With the C++ implementation of
Rlist  there's  no  need  to  quote  strings  that  look  like  numbers.

See    also   F<L</write>>,    F<L</is_number>>,   F<L</is_symbol>>,    F<L</is_random_text>>   and
F<L<http://en.wikipedia.org/wiki/American_Standard_Code_for_Information_Interchange>>.

=head2 Installing F<Rlist.pm> locally

Installing CPAN  packages usually requires  administrator privileges.  Another  way is to  copy the
F<Rlist.pm> file  into a directory  of your choice.   Instead of F<use Data::Rlist;>,  however, you
then use the following code.  It will find  F<Rlist.pm> also in F<.> and F<~/bin>, and it calls the
F<Exporter> explicitly:

    BEGIN {
        $0 =~ /[^\/]+$/;
        push @INC, $`||'.', "$ENV{HOME}/bin";
        require Rlist;
        Data::Rlist->import();
        Data::Rlist->import(qw/:floats :strings/);
    }

=head2 An Rlist-Mode for Emacs

    (define-generic-mode 'rlist-generic-mode
       (list "//" ?#)
       nil
       '(;; Punctuators
         ("\\([(){},;?=]\\)" 1 'cperl-array-face)
         ;; Numbers
         ("\\([-+]?[0-9]+\\(\\.[0-9]+\\)?[dDlL]?\\)" 1 'font-lock-constant-face)
         ;; Identifier names
         ("\\([-~A-Za-z_][-~A-Za-z0-9_]+\\)" 1 'font-lock-variable-name-face))
       (list "\\.[rR][lL][iI]?[sS]$")
       ;; Extra functions to setup mode.
       (list 'generic-bracket-support
             '(lambda()
               (require 'cperl-mode)
               ;;(hl-line-mode t)                      ; highlight cursor-line
               (local-set-key [?\t] (lambda()(interactive)(cperl-indent-command)))
               (local-set-key [?\M-q] 'fill-paragraph)
               (set-fill-column 100)))
       "Generic mode for Random Lists (Rlist) files.")

=head2 Implementation Details

=head3 Perl

=head4 Package Dependencies

F<Data::Rlist> depends only on few other packages:

    Exporter
    Carp
    strict
    integer
    Sys::Hostname
    Scalar::Util        # deep_compare() only
    Text::Wrap          # unhere() only
    Text::ParseWords    # split_quoted(), parse_quoted() only

F<Data::Rlist> is free of F<$&>, F<$`> or F<$'>.  Reason: once Perl sees that you need one of these
meta-variables anywhere in the  program, it has to provide them for  every pattern match.  This may
substantially slow your program (see also L<perlre>).

=head4 A Short Story of Typeglobs

This is supplement  information for F<L</compile>>, the function  internally called by F<L</write>>
and   F<L</write_string>>.    We  will   discuss   why   F<L</compile>>,  F<L</compile_fast>>   and
F<L</compile_Perl>>  transliterate  typeglobs  and  typeglob-refs  into C<"?GLOB?">.   This  is  an
attempted explanation.

B<TYPEGLOBS ARE A PERL IDIOSYNCRACY>

Perl uses a symbol table per package to map symbolic names like F<x> to Perl values.  Typeglob (aka
glob) objects are complete symbol table entries,  as hash values.  The symbol table hash (F<stash>)
is an  ordinary hash, named like  the package with two  colons appended.  In the  package stash the
symbol name is mapped to a memory address which  holds the actual data of your program.  In Perl we
do not  have real  global values, only  package globals.  Any  Perl code  is always running  in one
package or another.

The  main symbol  table's name  is F<%main::>,  or F<%::>.   In the  C implementation  of  the Perl
interpreter, the main  symbol is simply a global variable, called  the F<defstash> (default stash).
The  symbol F<Data::>  in stash  F<%::> addresses  the  stash of  package F<Data>,  and the  symbol
F<Rlist::> in the stash F<%::Data::> addresses the stash of package F<Data::Rlist>.

Typeglobs are  an idiosyncracy  of Perl: different  types need  only one stash  entry, so  that one
symbol can name all  types of Perl data (scalars, arrays, hashes)  and nondata (functions, formats,
I/O handles).  The symbol F<x> is mapped to the typeglob F<*x>.  In the typeglob coexist the scalar
F<$x>, the list F<@x>, the hash F<%x>, the code F<&x> and the I/O-handle or format specifieer F<x>.

Most  of the  time only  one glob  slot is  used.  Do  typeglobs waste  space then?   Probably not.
(Although some  authors believe that.)  Other script  languages like (e.g.)  Python  is not forcing
decoration characters  -- the  interpreter already  knows the type.   In terms  of C,  symbol table
entries are then  struct/union-combinations with a type field, a F<double>  field, a F<char*> field
and so forth.   Perl symbols follow a contrary  design: globs are really pointer  sets to low-level
structs that hold numbers, strings etc.  Naturally pointers to non-existing values are NULL, and so
no type  field is required.   Perl interpreters can  now implement fine-grained  smart-pointers for
reference-counting and copy-on-write, and must  not necessarily handle abstract unions.  In theory,
the garbage-collector  should have "increased recycling  opportunities."  We do  know, for example,
that F<perl> is very greedy with RAM: it almost never returns any memory to the operating system.

Modifying F<$x>  in a Perl  program won't  change F<%x>, because  the typeglob F<*x>  is interposed
between the stash and  the program's actual values for F<$x>, F<@x> etc.   The sigil F<*> serves as
wildcard for the other sigils F<%>, F<@>, F<$> and F<&>. (Hint: a F<sigil> is a symbol "created for
a specific magical purpose"; the name derives  from the latin F<sigilum> = seal.)

Typeglobs cannot be dissolved  by F<L</compile>>, because when (e.g.)  F<$x> and  F<%x> are in use,
the glob F<*x> does not return some useful value like

    (SCALAR => \$x, HASH => \@x)

Typeglobs  are  also  not  interpolated  in  strings.   F<perl> always  plays  the  ball  back.   A
typeglob-value is simply a string:

    $ perl -e '$x=1; @x=(1); print *x'
    *main::x

    $ perl -e 'print "*x is not interpolated"'
    *x is not interpolated

    $ perl -e '$x = "this"; print "although ".*x." could be a string"'
    although *main::x could be a string

As one  can see, even when only  F<$x> is defined the  F<*x> does not return  its value.  Typeglobs
(stash entries) are arranged by F<perl> on the fly, even with the F<use strict> pragma in effect:

    $ perl -e 'package nirvana; use strict; print *x'
    *nirvana::x

Each  typeglob is  a full  path into  the F<perl>  stashes, down  from the  F<defstash>:

    $ perl -e 'print "*x is \"*main::x\"" if *x eq "*main::x"'
    *x is "*main::x"

    $ perl -e 'package nirvana; sub f { local *g=shift; print *g."=$g" }; package main; $x=42; nirvana::f(*x)'
    *main::x=42

B<GLOB-REFS>

In the C implementation of Perl, typeglobs have the struct-type F<GV> for "Glob value".  Each F<GV>
is merely a  set of pointers to sub-objects  for scalars, arrays, hashes etc.  In  Perl the special
syntax F<*x{ARRAY}>  accesses the  array-sub-object, and is  another way  to say F<\@x>.   But when
applied to  a typeglob as F<\*foo>  it returns a typeglob-ref,  or globref.  So  the Perl backslash
operator C<\> works like the address-of operator C<&> in C.

    $ perl -e 'print *::'
    *main::main::               # ???

    $ perl -e '$x = 42; print $::{x}'
    *main::x                    # typeglob-value 'x' in the stash

    $ perl -e 'print \*::'
    GLOB(0x10010f08)            # some globref

Little do we know what happens inside F<perl>, when we assign REFs to typeglobs:

    $ perl -e '$x = 42; *x = \$x; print $x'
    42
    $ perl -e '$y = 42; *x = \$y; print $x'
    42

In Perl4 you had to pass typeglob-refs  to call functions by references (the backslash-operator was
not  yet "invented").   Since  Perl5 saw  the  light of  day, typeglob-refs  can  be considered  as
artefacts.  Note, however, that these veterans  are still faster than true references, because true
references  are themselves stored  in a  typeglob (as  REF type)  and so  need to  be dereferenced.
Globrefs can be used directly (as F<GV*>'s) by F<perl>.  For example,

    void f1 { my $bar = shift; ++$$bar }
    void f2 { local *bar = shift; ++$bar }

    f1(\$x);                  # increments $x
    f1(*x);                   # dto., but faster

B<GLOB-ALIASES>

Typeglob-aliases offer  another interesting application for typeglobs.   For example, S<F<*bar=*x>>
aliases the symbol F<bar> in the current stash, so that F<x> and F<bar> point to the same typeglob.
This means  that when  you declare S<F<sub  x {}>> after  casting the  alias, F<bar> is  F<x>.

This smells like  a free lunch.  The penalty,  however, is that the F<bar> symbol  cannot be easily
removed from the stash.   One way is to say F<local *bar>, wich  temporarily assigns a new typeglob
to F<bar> with all pointers zeroized:

    package nirvana;

    sub f { print $bar; }
    sub g { local *bar; $bar = 42; f(); }

    package main;

    nirvana::g();

Running this code as  Perl script prints the number assigned in F<g>.  F<f>  acts as a closure. The
F<local>-statement will  put the  F<bar> symbol temporarily  into the package  stash F<%::nirvana>,
i.e., the same stash in which F<f> and F<g> exist.  It will remove F<bar> when F<g> returns.

B<*foo{THINGS}s>

The F<*x{NAME}> expression family is fondly called "the F<*foo{THING}> syntax":

    $scalarref = *x{SCALAR};
    $arrayref  = *ARGV{ARRAY};
    $hashref   = *ENV{HASH};
    $coderef   = *handlers{CODE};

    $ioref     = *STDIN{IO};
    $ioref     = *STDIN{FILEHANDLE};    # same as *STDIN{IO}

    $globref   = *x{GLOB};
    $globref   = \*x;                   # same as *x{GLOB}
    $undef     = *x{THIS_NAME_IS_NOT_SUPPORTED} # yields undef

    die unless defined *x{SCALAR};      # ok -> will not die
    die unless defined *x{GLOB};        # ok
    die unless defined *x{HASH};        # error -> will die

When THINGs are accessed this way few rules apply.  Firstofall, F<*foo{THING}s> are not hashes. The
syntax is a stopgap:

    $ perl -e 'print \*x, *x{GLOB}, \*x{GLOB}'
    GLOB(0x100110b8)GLOB(0x100110b8)REF(0x1002e944)

    $ perl -e '$x=1; exists *x{GLOB}'
    exists argument is not a HASH or ARRAY element at -e line 1.

Some F<*foo{THING}> is F<undef> if the  requested THING hasn't been used yet.  Only F<*foo{SCALAR}>
returns an anonymous scalar-reference:

    $ perl -e 'print "nope" unless defined *foo{HASH}'
    nope
    $ perl -e 'print *foo{SCALAR}'
    SCALAR(0x1002e94c)

In Perl5 it is still not possible to  get a reference to an I/O-handle (file-, directory- or socket
handle) using  the backslash operator.  When a  function requires an I/O-handle  you must therefore
pass a globref.  More precisely, it is possible to pass an F<IO::Handle>-reference, a typeglob or a
typeglob-ref as the filehandle.  This is obscure bot only for new Perl programmers.

    sub logprint($@) {
        my $fh = shift;
        print $fh map { "$_\n" } @_;
    }

    logprint(*STDOUT{IO}, 'foo');   # pass IO-handle -> IO::Handle=IO(0x10011b44)
    logprint(*STDOUT, 'bar');       # ok, pass typeglob-value -> '*main::STDOUT'
    logprint(\*STDOUT, 'bar');      # ok, pass typeglob-ref -> 'GLOB(0x10011b2c)'
    logprint(\*STDOUT{IO}, 'nope'); # ERROR -> won't accept 'REF(0x10010fe0)'

It is very amusing that Perl, although refactoring  UNIX in form of a language, does not make clear
what a file-  or socket-handle is.  The  global symbol STDOUT is actually  an F<IO::Handle> object,
which F<perl>  had silently  instantiated.  To functions  like F<print>,  however, you may  pass an
F<IO::Handle>, globname or globref.

B<VIOLATING STASHES>

As we saw we can access the Perl guts without using a scalpel.  Suprisingly, it is also possible to
touch the stashes themselves:

    $ perl -e '$x = 42; *x = $x; print *x'
    *main::42

    $ perl -e '$x = 42; *x = $x; print *42'
    *main::42

By assigning the scalar value F<$x> to F<*x> we have demolished the stash (at least, logically):
neither F<$42> nor F<$main::42> are accessible.  Symbols like F<42> are invalid, because 42 is a
numeric literal, not a string literal.

    $ perl -e '$x = 42; *x = $x; print $main::42'

Nevertheless it is easy to confuse F<perl> this way:

    $ perl -e 'print *main::42'
    *main::42

    $ perl -e 'print 1*9'
    9

    $ perl -e 'print *9'
    *main::9

    $ perl -e 'print *42{GLOB}'
    GLOB(0x100110b8)

    $ perl -e '*x = 42; print $::{42}, *x'
    *main::42*main::42

    $ perl -v
    This is perl, v5.8.8 built for cygwin-thread-multi-64int
    (with 8 registered patches, see perl -V for more detail)

Of course these  behaviors are not reliable, and  may disappear in future versions  of F<perl>.  In
German  you  say   "Schmutzeffekt"  (dirt  effect)  for  certain   mechanical  effects  that  occur
non-intendedly,  because machines  and electrical  circuits are  not perfect,  and so  is software.
However, "Schmutzeffekts" are neither bugs nor features; these are phenomenons.

B<LEXICAL VARIABLES>

Lexical variables (F<my> variables) are not stored in stashes, and do not require typeglobs.  These
variables are stored in a special array, the F<scratchpad>, assigned to each block, subroutine, and
thread. These are really private variables, and they cannot be F<local>ized.  Each lexical variable
occupies a  slot in the scratchpad;  hence is addressed by  an integer index, not  a symbol.  F<my>
variables are like F<auto> variables in C.  They're also faster than F<local>s, because they can be
allocated at compile time, not runtime. Therefore you cannot declare F<*x> lexically:

    $ perl -e 'my(*x)'
    Can't declare ref-to-glob cast in "my" at -e line 1, near ");"

Seel also the Perl man-pages L<perlguts>, L<perlref>, L<perldsc> and L<perllol>.

=head3 C++

In C++  we use a  F<flex>/F<bison> scanner/parser combination  to read Rlist  language productions.
The  C++  parser  generates  an   F<Abstract  Syntax  Tree>  (AST)  of  F<double>,  F<std::string>,
F<std::vector> and F<std::map> values.   Since each value is put into the  AST, as separate object,
we use a free store management that allows the allocation of huge amounts of tiny objects.

We also use reference-counted smart-pointers, which allocate themselves on our fast free store.  So
RAM will not be fragmented, and the allocation of RAM is significantly faster than with the default
process heap.   Like with Perl,  Rlist files can  have hundreds of megabytes  of data (!),  and are
processable in constant time, with constant  memory requirements.  For example, a 300 MB Rlist-file
can be read from a C++ process which will not peak over 400-500 MB of process RAM.

=head1 BUGS

There are no known bugs, this package is stable.  Deficiencies and TODOs:

=over

=item *

The C<"deparse"> functionality for the C<"code_refs"> L<compile option|/Compile Options> has not
yet been implemented.

=item *

The C<"threads"> L<compile option|/Compile Options> has not yet been implemented.

=item *

IEEE 754 notations of Infinite and NaN not yet implemented.

=item *

F<L</compile_Perl>> is experimental.

=back

=head1 COPYRIGHT/LICENSE

Copyright 1998-2008 Andreas Spindler

Maintained   at  CPAN   (F<L<http://search.cpan.org/dist/Data-Rlist/>>)  and   the   author's  site
(F<L<http://www.visualco.de>>). Please send mail to F<rlist@visualco.de>.

This library  is free software; you  can redistribute it and/or  modify it under the  same terms as
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

Contact the author for the C++ library at F<rlist@visualco.de>.

Thank you for your attention.

=cut

1;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### fill-column: 99
### End:
