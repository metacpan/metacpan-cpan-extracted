-*- encoding: utf-8; indent-tabs-mode: nil -*-

Introduction
============

In 2023, I  heard about Perl 5.38 being published,  which a new object
model, Corinna.  Learning Corinna  cannot be done  by only  reading, I
have to read and  do. So I have to write  a sufficiently big programme
(typically a  module) which uses  Corinna. All the modules  I maintain
have some  back-compatibility requirements  down to version  5.8.8 (if
strings  and  UTF-8  are used)  or  even  below  if  we only  do  some
computations. So I  had no convenient subject to do  some "learning by
doing" on Corinna.

At the same time, from October 2023 until February 2024, I worked on a
Raku module,
[`Arithmetic::PaperAndPencil`](https://raku.land/zef:jforget/Arithmetic::PaperAndPencil).
After this  module was  published, I realised  that I  could perfectly
rewrite  in Perl  and that  I could  learn and  do some  Corinna while
writing this Perl module.

The document you  are reading will give you no  informations about the
features of the  module. If you want  to know how we  can compute with
only a pencil and some paper, please visit the
[Github repository](https://github.com/jforget/raku-Arithmetic-PaperAndPencil)
and the included
[documentation](https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-en.md).
The present document only deals  with Perl coding and differences with
Raku.

Module Development
==================

Hardware and Software
---------------------

My computer uses Devuan 4, with Perl 5.32.1? So I installed
[perlbrew 0.91](https://metacpan.org/dist/App-perlbrew/view/script/perlbrew)
with  the  package manager  and  then  I  installed Perl  5.38.2  with
Perlbrew.

Initialisation
--------------

I initialised the module repository using
[Module::Starter](https://metacpan.org/pod/Module::Starter)
version 1.77.

First surprise.  For a very long  time, I have heard  bad things about
`Module::Build`.     This    module     was    meant     to    replace
`ExtUtils::MakeMaker`.   There   are   defects  and   misfeatures   in
`Module::Build`, but when compared  to `ExtUtils::MakeMaker`, it still
has many advantages. Yet, the common  opinion in the Perl community is
that `Module::Build` should not be used  at all and that we should use
`ExtUtils::MakeMaker` instead. When using `Module::Starter`, I noticed
that  there was  still a  `Module::Build` option  in the  accompanying
programme `module-starter`. There is  also a `Module::Install` option,
but it is clearly flagged as "discouraged".

Anyway,   I   think  that,   irrespective   of   its  many   problems,
`ExtUtils::MakeMaker`  has  a bigger  audience  and  a more  promising
future when  compared to `Module::Build`,  so I adopted `EUMM`  for my
module.

When running  `module-starter`, I forgot to  generate the `.gitignore`
file. I generated a dummy repository with `module-starter`, I took its
`.gitignore` file  and I deleted  it. On the  other hand, I  did state
that the mininmum version was Perl 5.38.

Rewriting Schedule
------------------

When  writing the  original  Raku module,  I  implemented the  various
functions  in a  counter-intuitive order.  I began  with the  jalousie
multiplication, then a part of standard multiplication, then addition,
then  I finished  the standard  multiplication, then  I implemented  a
composite operation, the radix conversion with Horner's Scheme, then I
implemented subtraction and  so on. With the Perl  module, I implement
the operations in the usual order, that is addition, then subtraction,
then multiplication (all variants) and so on.

The secondary Raku  modules (number, action, etc)  have been developed
as the need  occurred during the writing of the  main Raku module. For
the  Perl module,  each  secondary module  will  be fully  implemented
before starting  the arithmetic operations  in the main module  and it
will  be  tested  with  the  test data  from  the  Raku  distribution,
converted to Perl.

Porting the Test Files
----------------------

For both the Raku module and  the Perl module, test files are numbered
in  chronological order  or nearly  so. That  means it  is not  always
obvious to  know from which  Raku file a  Perl test files  comes from.
Here is the way the files are linked with each other.

| Raku                        | Perl                       |
|:----------------------------|:---------------------------|
| 01-basic.rakutest           | 00-load.t                  |
| 02-test-meta.rakutest       | discarded                  |
| 03-number.rakutest          | 03-number.t                |
| 04-number-fatal.rakutest    | 04-number-fatal.t          |
| 05-action-csv.rakutest      | discarded                  |
| 06-html.rakutest            | 01-action.t                |
| 06-mult.rakutest            | 02-html.t                  |
| 07-mult.rakutest            | 07-mult.t                  |
| 08-mult.rakutest            | 08-mult.t                  |
| 09-mult-shortcut.rakutest   | 09-mult-shortcut.t         |
| 10-add.rakutest             | 05-add.t                   |
| 11-mult-prepared.rakutest   | 10-mult-prepared.t         |
| 12-mult-boat.rakutest       | 11-mult-boat.t             |
| 13-conversion.rakutest      | à faire                    |
| 14-subtraction.rakutest     | 06-subtraction.t           |
| 15-prep-division.rakutest   | à faire                    |
| 16-division.rakutest        | à faire                    |
| 17-square-root.rakutest     | à faire                    |
| 18-div-boat.rakutest        | à faire                    |
| 19-division.rakutest        | à faire                    |
| 20-conversion-div.rakutest  | à faire                    |
| 21-gcd.rakutest             | à faire                    |
| 22-russ-mult.rakutest       | 12-russ-mult.t             |

First Thoughts about Corinna
----------------------------

Although the new features of Perl 5.38 are selected with `use 5.38` at
the beginning  of many files,  I steel  need to add  `use experimental
qw/class/` to benefit of Corinna's syntax.

A bad surprise: I knew that version 5.38 contained only a
[MVP](https://github.com/Perl-Apollo/Corinna/blob/master/rfc/mvp.md)
(minimum viable product), but I thought  it would at least provide the
`:reader` attributes, which would alleviate me from writing accessors.
Too bad,  the `:reader` attributes are  not available in 5.38.2  and I
had  to  write  the  five  accessors for  `A::P&P::Char`  and  the  19
accessors of `A::P&P::Action`.  Maybe I should install  Perl 5.39 with
perlbrew?

Later, when I activated  standard test `pod-coverage.t`, this resulted
in many error messages, because  there is one explicit accessor method
for each attribute, therefore I would have to document all of them.

Another bad  surprise. When I  run a test file,  I get a  few messages
telling me  `class is  experimental` and may  messages with  `field is
experimental`.  Actually, I  got  rid of  these  messages. Instead  of
writing only:

```
use feature qw/class/;

```

I wrote instead:

```
use feature      qw/class/;
use experimental qw/class/;

```

At first, I used the style shown in the
[Corinna documentation](https://github.com/Perl-Apollo/Corinna/blob/master/pod/perlclasstut.pod),
that is, block syntax.

```
class Arithmetic::PaperAndPencil {
  blablabla
}
```

But each  time I  copied-pasted some methods  or subroutines  from the
Raku module  to the Perl module,  I had to fix  the indentation. Then,
rereading
[the Perl class documentation](https://perldoc.perl.org/perlclass)
and not only the examples, I discovered that statement style was allowed:

```
class Arithmetic::PaperAndPencil;

blablabla;
```

Therefore, if you  need to copy-paste from Raku (or  from some source)
to Perl, if the origin syntax is  the block syntax, you should use the
block syntax  in the destination Perl  source. And if the  origin file
has a  statement syntax, you  should use  the statement syntax  in the
destination file.

I did not see if Corinna allows for private methods. For the moment, I
use the usual  Perl naming convention: if the method  name begins with
an  underscore, this  is a  private method,  such as  `_native_int` in
`A::P&P::Number`; if  the method name  begins with  a letter, it  is a
public method.

Most often, in  methods, at the beginning I create  a `$radix` lexical
variable. With Raku, there is no ambiguity with the `radix` attribute,
with    is    typed     `$.radix`    within    `A::P&P::Number`    and
`$some_instance.radix` elsewhere. But in Perl, the attributes is typed
`$radix` within  `A::P&P::Number`. There is an  ambiguity with lexical
variable  `$radix`.  For the  moment,  each  time  I have  declared  a
`$radix` variable, this was within `Arithmetic::PaperAndPencil`, never
until now  within `A::P&P::Number`. So  there is no  ambiguity between
attributes and variables. Yet, the risk exists.

First Thoughts outside Corinna
------------------------------

I learnt Perl with version  5.5.2. Also, because of back-compatibility
for the  modules I  maintain, because  I have  published very  few big
programmes outside  my modules,  I have not  learnt many  new features
since version 5.12. The last new  features I frequently used come from
version 5.10 mainly:

* function `say`,

* control structure `given` / `when`,

* a small portion of smart match to use `given` / `when`,

* operator "defined-or" `//` (especially its combined form `//=`),

* lexical variable with extended lifespan declared with `state`,

* named captures in regexes.

There is also `use utf8;` which was released in a later Perl version.

Unfortunately, because of a seldom-used obscure corner case, the smart
match has  been obsoleted and `given`  / `when` has accompanied  it in
its downfall.

When I copied-pasted some methods or functions from Raku to Perl, I tried
to copy function signatures such as:

```
# Raku
sub filling-spaces(Int $l, Int $c) {
```

I replaced  the dash with an  underline without batting an  eyelid. As
for the signature,  I tried to use  it as is. Perl 5.38  does not like
type declarations  such as `Int`. On  the other hand, once  these type
declarations are removed, Perl  5.38 accepts the parameter declaration
and I was allowed to write:

```
# Perl
sub filling_spaces($l, $c) {
```

instead of

```
# Perl
sub filling_spaces {
  my ($l, $c) = @_;
```

which improves the readability and also the speed of code writing.

Another  new feature  I came  to appreciate  is the  fact that  we can
declare a function within another  function (or method). See functions
`check_l_min`,     `l2p_lin`,     `check_c_min`,     `l2p_col`     and
`filling_spaces` in method `html`.

On the  other hand, there is  a feature still missing  from Perl 5.38.
Now  it is  2024, all  programming tools  (source editors,  databases,
compilers) deal correctly with Unicode and UTF-8. Yet, by default, the
Perl 5.38 interpreter still considers  the default encoding for source
files and data  files is ISO-8859-1 or similar. This  can be explained
by back-compatibility with  programmes written in version  5.0 back in
the previous century. But as soon  as a programmer writes `use 5.38;`,
or even  `use 5.10;`,  we know that  the back-compatibility  no longer
extends into times before Unicode. So we could consider that with `use
5.38`, the Perl default would be  using Unicode and UTF-8. This is not
the case and I must still add:

```
use utf8;
use open ':encoding(UTF-8)';
```

Found Problems
--------------

### First problem with `A::P&P::Char`

The first problem appeared when coding the `A::P&P::Char` class and
the `html` method for `Arithmetic::PaperAndPencil`.

In  a few  instances, we  must insert  one or  several columns  at the
beginning of  each line in the  operation, and fill these  new columns
with  spaces (actually  instances  of the  `A::P&P::Char` class).  The
`html`  method   computes  the  number  of   inserted  columns,  named
`$delta_c` (or `$delta-c` in Raku) and then runs:

```
      # Raku
      for @sheet <-> $line {
        prepend $line, space-char() xx $delta-c;
      }
```

Function  `space-char`   is  the   function  giving  an   instance  of
`A::P&P::Char` filled with a space. My first attempt in Perl was:

```
      # Perl
      for my $line (@sheet) {
        unshift @$line, (Arithmetic::PaperAndPencil::Char->space_char) x $delta_c;
      }
```

It   did  not   work.  Test   programme  `01-action.t`   (Raku-to-Perl
translation  of  `06-html.rakutest`) would  write  `133`  where I  was
expecting  `123`. After  some debugging,  I understood  that one  each
line,  the `unshift`  statement would  insert the  same `A::P&P::Char`
instance twice.  On the other hand,  the problem was not  appearing in
Raku. Either  formula `space-char() xx $delta-c`  calls twice function
`space-char` and  gets two  different instances of  `A::P&P::Char`, or
the `prepend` statement deep-copies its argument into the list. Either
way, I had to fix the Perl version and write:

```
      # Perl
      for my $line (@sheet) {
        for (1 .. $delta_c) {
          unshift @$line, Arithmetic::PaperAndPencil::Char->space_char;
        }
      }
```

### Second problem with `A::P&P::Char`

The  `01-action.t` test  programme  generates two  HTML strings.  When
writing class `A::P&P::Char`  and method `html`, I  activated only the
first HTML string  generation until it was  completely implemented and
debugged. Then, when I activated the second HTML string generation, it
was  no  longer working.  With  the  help  of  a few  debugging  trace
messages,  I  pinpointed  an  error  in  at  least  `check_l_min`  and
`l2p_lin` inner functions.  Maybe the same error was  occurring in the
other inner functions:  `check_c_min`, `l2p_col` and `filling_spaces`,
I  did not  check. Here  is the  explanation with  only `l2p_lin`  for
brievety's sake. Here is the function:

```
  # Perl
  sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

This  function uses  a  formal  call parameter  `$logl`  and a  global
variable `$l_min` (actually a lexical  variable with a scope extending
beyond function `l2p_lin` to the  outer method). During the first HTML
string generation, variable `$l_min`  would have the successive values
0, -1,  -3 and -4  (skipping -2 because we  insert two columns  in one
go). Yet,  during the  second HTML  string generation,  `$l_min` would
have  a strange  behaviour. When  printed from  outside the  `l2p_lin`
function, I would have values 0, -1,  -3 and -4, but when printed from
within the `l2p_lin` function it would always give -4.

Here  is the  hypothetical explanation.  During the  first generation,
function `l2p_lin` would  use the proper value for  `$l_min`, that is,
0, then -1,  then -3 and lastly -4. When  method `html` ends, function
`l2p_lin` is still  alive thanks to the closure  mechanism. And thanks
to the  same closure  mechanism, variable  `$l_min` still  exists with
value  -4 because  it is  used by  `l2p_lin`. Then,  method `html`  is
called a second  time to check CSS usage. This  defines a new instance
of  variable `$l_min`,  initialised  to  0. On  the  other hand,  when
reading the definition

```
  # Perl
  sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

the function is not redefined, the  old definition is still in effect.
So the  next calls to  `l2p_lin` call  the closure function,  with the
closure variable `$l_min`, still equal to -4. The fix was very simple,
adding keyword `my`:

```
  # Perl
  my sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

I have written above  that I did not bother to  check whether the same
problem occurred  with `check_c_min`, `l2p_col`  and `filling_spaces`.
Actually, I involuntarily checked this in another function. The `html`
method  contains another  inner  function, `draw_h`  and  at first,  I
forgot  to add  a `my`  to  this function.  And running  `01-action.t`
resulted  in a  failure, because  some underlining  was not  done when
needed. After adding `my`, the test was successful.

### Problems with `A::P&P::Number`

In a  few places within this  class, I need to  convert a single-digit
`A::P&P::Number` instance into a native Perl or Raku integer. In Raku,
I declare a 36-element array:

```
# Raku
@digits = ( '0' .. '9', 'A' .. 'Z');
```

and I search  the processed digit `$.unit.value` within  this array to
obtain its index with:

```
  # Raku
  my Int $units = @digits.first: * eq $.unit.value, :k;
```

There is a Perl equivalent, provided module
[`List::MoreUtils`](https://metacpan.org/pod/List::MoreUtils)
is installed. Just use function
[`first_index`](https://metacpan.org/pod/List::MoreUtils#firstidx-BLOCK-LIST)
aka `firstidx`. I wrote:

```
  # Perl
  use List::MoreUtils qw/first_index/;
  ...
  my $units = first_index { * eq $.unit.value } @digits;

```

but it  failed, there  was a  syntax error. To  bypass the  problem, I
added  a hashtable  `%digit_value`  which gives  the  same result.  My
programme  runs,  but  I  would  be  interested  to  know  why  module
`List::MoreUtils` did not work.

Maybe  the explanation  is  the  same as  for  the  second problem  in
`A::P&P::Number`. Here it is. I needed to trigger some exceptions with
`croak` and I needed to compute  integer parts with `floor`. I invoked
the associated  core modules in  the first  lines of the  source files
with:

```
# Perl
use Carp;
use POSIX qw/floor/;
class Arithmetic::PaperAndPencil::Number 0.01;
```

The result was a few error messages such as:

```
Undefined subroutine &Arithmetic::PaperAndPencil::Number::floor called at lib/Arithmetic/PaperAndPencil/Number.pm line 179.
```

A solution was  using fully qualified names such  as `Carp::croak` and
`POSIX::floor`,  but it  does not  feel right.  Then I  swapped a  few
lines:

```
# Perl
class Arithmetic::PaperAndPencil::Number 0.01;
use Carp;
use POSIX qw/floor/;
```

and now,  it was  working, we  could use  `croak` and  `floor` without
adding the package name.

Back to  `List::MoreUtils`. The error message  was different, clearing
stating that  is was a  syntax error.  Maybe Perl was  displaying this
message because the highly unusual  syntax of the various functions in
`List::MoreUtils`. If  I had  written `use List::MoreUtils`  after the
source  line with  `class`, maybe  it would  have worked.  Anyhow, the
solution with hashtable `%digit_value` works  and it is readable, so I
keep it.

Another  problem  has been  there  for  a  long  time. We  cannot  use
variables in operator `tr`. This is why I use `eval`.

```
  # Perl
  my $before = substr($digits, 0, $radix);
  my $after  = reverse($before);
  $_ = '0' x ($len - length($s)) . $s;
  eval "tr/$before/$after/";
```

A  good new  is that  `overload` still  works, including  with Corinna
objects. I will be able to  compute additions with a plain `+` instead
of  `☈+`  and  substractions  with  plain `-`  instead  of  `☈-`.  For
multiplication, I  will have to  use this  stupid star instead  of the
multiplication sign `×`. Too bad.

By the way, several times I used a
[Perl secret operator](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod),
mainly the
[Venus operator](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod#Venus)
to test boolean results as `0` or `1` and the
[baby-cart operator](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod#Baby-cart)
to include method calls within char strings delimited with double quotes.

### Problems with method `addition`

I had no real problems, except it was boring to repeatedly convert `if
condition {` into `if (condition) {` and to repeatedly convert

```
# Raku
my Arithmetic::PaperAndPencil::Number $x .= new(radix => $radix, value => '10');
```

into

```
# Perl
my $x = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '10');
```

So  I introduced  a  few  changes into  Emacs'  configuration file  to
include  E-lisp  functions doing  these  changes.  This is  still  the
interactive variant  with `query-`, because some  changes are useless,
or even  plain wrong. For example,  when changing method calls  from a
Raku-like dot to a Perl-like arrow `->`, I must avoid modifying a file
name such as  `foo.csv` just because it looks like  a method call. Not
all changes were coded, because some  of them need some thinking, such
as replacing `%label<TIT01>` by `$label{TIT01}` or changing

```
  # Raku
  for @numbers.kv -> $i, $n {
```

into

```
  # Perl
  for my $i (0 .. $#numbers) {
    my $n = $numbers[$i];
```

A problem that is not important  now but which could be more important
for the next methods is keyword parameters.  I will have to go back to
the  old  way  of dealing  with  variable  `@_`  and  copy it  into  a
hashtable.

### Problems with method `subtraction`

No problems,  actually. I  discovered (or  rediscovered) that  you can
include a type in a `my` declaration,  provided it is a class name and
not a native type. Thus,

```
  my Arithmetic::PaperAndPencil::Action $action;
```

is valid, but

```
  my Int $i;
```

is not. About  an instance of `A::P&P::Action`, will this  allow me to
write shorter invocations  of method `new`? I do not  think so. I have
not tried.

### Problems with method `multiplication`

A problem  about development and organisation.  The multiplication has
several variants. I will not do  a single Git commit when all variants
are  implemented, I  will make  a Git  commit each  time a  variant is
implemented,  or maybe  two  variants.  Yet, the  test  files are  not
closely linked with such or such variant. Too bad. I will release test
file `07-mult.t`  (formely `07-mult.rakutest`) with the  first commit,
for the standard multiplication variant, even if this test file checks
the jalousie  multiplication. The  test file will  give a  failure. At
least we are  forewarned. I did not consider  worthwhile to deactivate
some  tests with  a  `TODO`  tag, because  the  situation producing  a
failure will not last a long time.

A problem about coding. In raku,  there are two syntaxes for key-value
pairs: the  syntax with the fat  arrow and the syntax  with the colon,
which has an auto-quoting variant.

```
key => value
:key(value)
:key<value>
```

Creating a number can be done with any of these lines:

```
  # Raku
  my Arithmetic::PaperAndPencil::Number $one .= new(radix => $radix, value => '1');
  my Arithmetic::PaperAndPencil::Number $one .= new(:radix($radix), :value('1'));
  my Arithmetic::PaperAndPencil::Number $one .= new(:radix($radix), :value<1>);
```

Until now,  I have  always been  confronted with  the syntax  with fat
arrows.  It is  easy  to  convert, especially  since  the Emacs  macro
`adapte` contains:

```
(save-excursion (query-replace-regexp " Arithmetic::PaperAndPencil::Number \\(.*\\)\.= new" " \\1 = Arithmetic::PaperAndPencil::Number->new" nil nil nil) )
```

This E-lisp statement produces:

```
  # Perl
  my $un = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');

```

which is valid for Perl and Corinna. But the second and third syntaxes
trigger  a compilation  error. Too  bad, I  will do  the changes  with
manual editing. I do  not want to search how to  write a E-lisp regexp
that  would be  used  by `query-replace-regexp`  and  would convert  a
colon-key-value pair into a fat-arrow-key-value pair.

And an already  mentioned coding problem. In Raku, we  have `given ...
when` control statements. In Perl,  it was allowed until recently, but
now  it  is  obsolete  or  even forbidden,  even  if  we  invoke  `use
experimental`. So  I replace this  control statement with a  series of
ugly `if ... elsif`. Maybe I could have used the
[`Switch` module](https://metacpan.org/pod/Switch),
but I will stick with `if ... elsif`.

### Problems with method `division`

As  mentioned already,  when  I  convert a  Raku  method with  keyword
parameters, the equivalent  Perl method use the idiom with  `@_` and a
hashtable `%param` to emulate keywords in Perl. For example:

```
# Perl
#### /!\    buggy code!!!    /!\
method _mult_and_sub(%param) {
  my $l_dd         = $param{l_dd};
  my $c_dd         = $param{c_dd};
  my $dividend     = $param{dividend};
  my $l_dr         = $param{l_dr};
  my $c_dr         = $param{c_dr};
  my $divisor      = $param{divisor};
  my $l_qu         = $param{l_qu};
  my $c_qu         = $param{c_qu};
  my $quotient     = $param{quotient};
  my $l_re         = $param{l_re};
  my $c_re         = $param{l_re};
  my $basic_level  = $param{basic_level};
  my $l_pr         = $param{l_pr};
  my $c_pr         = $param{c_pr};
  my $mult_and_sub = $param{mult_and_sub}  // 'combined';
#### /!\    buggy code!!!    /!\
```

Except that this example is buggy. Have you found where?

### Problems with method `square_root`

In the  Raku version,  this method  has a  positional parameter  and a
keyword parameter.

```
# Raku
method square-root(Arithmetic::PaperAndPencil::Number $number
                 , Str :$mult-and-sub is copy = 'combined'
                 --> Arithmetic::PaperAndPencil::Number
                   ) {
[...]
  $result = $operation.square-root($number, mult-and-sub => 'separate');
```

At  first,  I  converted  into  Perl as  a  method  with  two  keyword
parameters.  Then I  realised that  the  `%param` idiom  can mix  with
positional parameters within  the same method or  subroutine. You just
have to write:

```
# Perl
method square_root($number, %param) {
  my $mult_and_sub = $param{mult_and_sub} // 'combined';
[...]
  $result = $operation->square_root($number, mult_and_sub => 'separate');
```

### Problems with method `conversion`

For  the conversion  with  multiplications (or  Horner's scheme),  the
left-most digit is processed on its own, and then all remaining digits
are processed in turn, with a multiplication and an addition. In Raku,
this gives:

```
    # Raku
    for $number.value.substr(1).comb.kv -> $op1, $old-digit {
```

In other words, for the loop, we strip the leftmost digit
(`substr(1)`), we split the string into individual digits (`comb`) and
we run the loop with the digit in `$old-digit` and its zero-based rank
in `$op1`. As a consequence, we must check the last iteration of the
loop by comparing `$op1` with `$number.chars - 2`. When I translated
this loop directly into Perl, the result was rather complicated and
most usages of `$op1` would actually use `$op1 + 1`. To stremline
coding, I have changed the interpretation of `$op1`, which is not
longer the rank of the digit in the string without the first digit,
but the rank of the current digit in the full string. So `$op1` begins
with 1 and the Raku loop translates to:

```
    # Perl
    for my $op1 (1 .. $number->chars - 1) {
      my $old_digit = substr($number->value, $op1, 1);
```

### Problems when preparing the Module

During the  development, I  tested the  classes, methods  and routines
with commands such as:

```
perl -Ilib xt/99-my-test.t
prove -l t xt
```

To prepare  the module for  publication, I  ran the usual  Perl module
commands, with the addition of an environment variable to trigger some
tests proposed by `Module::Starter`:

```
export RELEASE_TESTING=1
perl Makefile.PL
make
make test
```

Also, I check for code coverage with `Devel::Cover` and:

```
cover -test html
```

The first  problem appeared when  running `Makefile.PL`. I  obtained a
message stating that it could not  find the version from the source of
`lib/Arithmetic/PaperAndPencil.pm`. Yet I had coded:

```
class Arithmetic::PaperAndPencil 0.01;
```

Actually, I had to add

```
our $VERSION = 0.01;
```

like before the use of Corinna.

Another  problem, which  I have  already mentionned,  is that  the POD
coverage test  lists several methods without  documentation. These are
the accessor methods I had  to explicitly write, instead of generating
them with the `:reader` attribute. A few methods are documented in the
POD source,  because I have  something interesting to say  about them.
But for  most fields,  I have  nothing worthwhile  to say  about their
accessors. Maybe the message from `Test::Pod::Coverage` will disappear
in the next Corinna version when I use `:reader`?

Yet another problem. I have used `overload` to link some routines with
the  standard  operators  `+`,  `-`  and so  on.  When  checking  code
coverage, these  routines appear in  red in the coverage  report, that
is, they are never checked.

Also, methods (the Corinna kind) are not processed. Someone else has
[already declared an issue](https://github.com/pjcj/Devel--Cover/issues/330).

The test file  `manifest.t` wrongly lists all files  within the `.git`
subdirectory as missing files. After reading
[MetaCPAN](https://metacpan.org/pod/Test::CheckManifest)
I found how to avoid these messages, problem solved.

Lastly, `Test::Pod` does not recognise the `=encoding utf8` statement.
So  sometimes it  gives an  error message  when encountering  char `→`
(U+2192 RIGHTWARDS ARROW). And sometimes, I have no error message.

### And the Last Problem

...actually more  of an annoyance  than a  problem. In Raku,  we write
things like:

```
  # Raku
  my Arithmetic::PaperAndPencil::Action $action;
  [...]
    $action .= new(level => 5, label => 'DRA02', w1l => 0, w1c => $len1 + 1
                                               , w2l => 0, w2c => $len1 + $len2);
```

The method name `new` is written in a column near the beginning of the
line. In the example above, this is in columns 15 to 17 (counting from
zero).  We have  room to  type the  parameters and  set them  up in  a
fashion that pleases the eyes  and improves readability, all this with
a moderate  line length, 80 chars  in the example above.  On the other
hand, in Perl, when calling the  `new` method, we must write the class
name, which  adds 34 chars  to the line length  (and a 35th  one, when
replacing the dot  `.` with the arrow `->`). So  the line length gives
an unwieldly 115 chars instead of 80.

```
  # Perl
  my Arithmetic::PaperAndPencil::Action $action;
  [...]
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA02', w1l => 0, w1c => $len1 + 1
                                                                                  , w2l => 0, w2c => $len1 + $len2);
```

In other  cases, the vertical  alignment applies from the  second line
on, without  the first line. In  the example below, in  Raku the first
keywords are aligned in lines 1, 2,  3 and 4. In Perl, keyword `level`
from line 1 is not aligned and only keywirds `r1l`, `r2l` and `w1l` in
lines 2, 3 and 4 are aligned.

```
  # Raku
  my Arithmetic::PaperAndPencil::Action $action;
  [...]
      $action .= new(level => 0, label => 'MUL02'
                   , r1l => 0, r1c => 2, r1val => $multiplier.value   , val1 => $multiplier.value
                   , r2l => 1, r2c => 2, r2val => $multiplicand.value , val2 => $multiplicand.value
                   , w1l => 2, w1c => 2, w1val => $pdt.value          , val3 => $pdt.value
                   );
  # Perl
  my Arithmetic::PaperAndPencil::Action $action;
  [...]
      $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'MUL02'
                   , r1l => 0, r1c => 2, r1val => $multiplier->value   , val1 => $multiplier->value
                   , r2l => 1, r2c => 2, r2val => $multiplicand->value , val2 => $multiplicand->value
                   , w1l => 2, w1c => 2, w1val => $pdt->value          , val3 => $pdt->value
                   );
```

Maybe  I could  have called  the `new`  method as  an instance  method
instead of a class method?

```
  # Perl ?
  my Arithmetic::PaperAndPencil::Action $action;
  [...]
      $action = $action->new(level => 0, label => 'MUL02'
                           , r1l => 0, r1c => 2, r1val => $multiplier->value   , val1 => $multiplier->value
                           , r2l => 1, r2c => 2, r2val => $multiplicand->value , val2 => $multiplicand->value
                           , w1l => 2, w1c => 2, w1val => $pdt->value          , val3 => $pdt->value
                           );
```

But I think this would be considered bad programming style.

License
=======

Text  published  under the  CC-BY-ND  license:  Creative Commons  with
attribution and with no modification.
