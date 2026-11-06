## Name

Class::Abstract - Stop code from making objects of a class that is only a template

## Version

Version 0.03

## Synopsis

### 1. Make a Class Abstract (The Usual Way)

```perl
package Animal;
use parent 'Class::Abstract';    # Animal is now abstract

package Dog;
use parent -norequire, 'Animal'; # Dog is a normal (concrete) class

package main;
my $dog = Dog->new;              # works: you get a Dog object
my $bad = Animal->new;           # dies: "Cannot instantiate abstract class Animal directly"
```

### 2. Make a Class Abstract With "Use"

```perl
package Vehicle;
use Class::Abstract;             # same result as: use parent 'Class::Abstract'
```

### 3. A Child Class That Stores Its Own Data

```perl
package Dog;
use parent -norequire, 'Animal';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new;   # the check happens here
    $self->{name} = $args{name};     # then add your own data
    return $self;
}

package main;
my $rex = Dog->new(name => 'Rex');
```

### 4. An Abstract Class That Has Its Own New()

```perl
package Shape;
use parent 'Class::Abstract';

sub new {
    my ($class, %args) = @_;
    Class::Abstract::check_abstract($class);   # dies if $class is Shape
    return bless { colour => $args{colour} }, $class;
}

package Circle;
use parent -norequire, 'Shape';

package main;
my $c = Circle->new(colour => 'red');   # works
Shape->new(colour => 'red');            # dies
```

### 5. Ask Whether a Class Is Abstract

```
Animal->is_abstract;                        # 1
Dog->is_abstract;                           # 0
$rex->is_abstract;                          # 0 (asks about Dog)
Class::Abstract->is_abstract('Animal');     # 1
Class::Abstract->is_abstract($rex);         # 0
```

### 6. Make an Object of an Abstract Class Inside a Test

```perl
use Test::More;

my $animal = do {
    local $Class::Abstract::BYPASS = 1;    # turn the check off for this block only
    Animal->new;
};
is( $animal->legs, 4, 'default number of legs' );
```

### 7. Use With Sub::Abstract

```perl
package Animal;
use parent 'Class::Abstract';      # nobody can make an Animal directly
use Sub::Abstract qw(speak);       # every child class must write speak()
```

## Description

### What This Module Does

An _abstract class_ is a class that is only a template.  It holds code
that its child classes share, but it is not complete on its own.  You
should never make an object of it.  You make objects of its child classes
instead.

Perl has no built-in way to say "this class is abstract".  This module
adds one.  When code tries to make an object of an abstract class, the
program dies with a clear error message.  Child classes work normally.

### Terms Used in This Document

- class, package

    In Perl, a class is a package.  `Animal` and `Dog` are package names.

- parent class, child class, @ISA

    Each package has a list called `@ISA` that names its parent classes.
    If `@Dog::ISA` contains `Animal`, then `Dog` is a child of `Animal`,
    and `Dog` can use `Animal`'s methods.

- abstract, concrete

    A class is _abstract_ when `Class::Abstract` is in its **own** `@ISA`.
    All other classes are _concrete_ (normal).

- invocant

    The value on the left of the arrow in a method call.  In
    `Dog->new` the invocant is the string `'Dog'`.  In
    `$rex->speak` the invocant is the object `$rex`.

- croak, die

    Stop the program (or the current `eval` block) with an error message.

- bypass

    A setting that turns the check off.  See ["Turning the check off"](#turning-the-check-off).

- test harness

    The program that runs test files, for example `prove` or `make test`.
    It sets the environment variable `HARNESS_ACTIVE`.

### How to Make a Class Abstract

Put `Class::Abstract` in the class's own `@ISA`.  There are two ways:

```perl
package Animal;
use parent 'Class::Abstract';    # way 1 (recommended)

package Vehicle;
use Class::Abstract;             # way 2
```

Both ways have the same result.

### How the Check Works

`Class::Abstract` gives every class below it a method called `new()`.
When `new()` runs, it looks at the invocant (the class name on the left
of the arrow).  If that class has `Class::Abstract` in its **own**
`@ISA`, `new()` dies.  If not, `new()` makes and returns an empty
object.

This is why child classes work.  When `Dog` calls
`$class->SUPER::new`, the invocant is still `'Dog'`, not
`'Animal'`.  `Dog` does not have `Class::Abstract` in its own `@ISA`,
so the check passes.

### Only the Class That Asks Is Abstract

Being abstract is **not** passed down to child classes.  If you want an
abstract class below another abstract class, list `Class::Abstract` in
that class too:

```perl
package Animal;   use parent 'Class::Abstract';               # abstract
package Mammal;   use parent 'Class::Abstract', 'Animal';     # also abstract
package Dog;      use parent -norequire, 'Mammal';            # concrete
```

### Turning the Check Off

Sometimes a test needs an object of an abstract class.  Two settings turn
the check off.  If **either** one is on, the check is off.

- 1. The variable `$Class::Abstract::BYPASS`

    Set it to a true value.  Always use `local`, so the setting ends at the
    end of the block:

    ```perl
    my $animal = do { local $Class::Abstract::BYPASS = 1; Animal->new };
    ```

- 2. The setting `harness_bypass` together with a test harness

    If `$Class::Abstract::config{harness_bypass}` is true **and** the
    environment variable `HARNESS_ACTIVE` is true, the check is off.
    `harness_bypass` is false by default, so the check is **on** in your
    tests unless you change it.

`$BYPASS` is checked first.  If `$BYPASS` is true, setting
`harness_bypass` to 0 does **not** turn the check back on.

**Changed in version 0.03:** before 0.03, `harness_bypass` was 1 by
default.  That meant the check was **off** in every test suite.  To get
the old behaviour back, put this near the top of your test files:

```
$Class::Abstract::config{harness_bypass} = 1;
```

## Methods

### Import

```perl
use Class::Abstract;
```

Perl calls `import()` for you when you write `use Class::Abstract;`.
You do not normally call it yourself.

It makes the package that contains the `use` line abstract.  It does
this by adding `'Class::Abstract'` to that package's `@ISA`.  The
result is the same as `use parent 'Class::Abstract'`.

#### Arguments

None that you pass yourself.  Perl passes the string
`'Class::Abstract'` as the first argument.  Anything in an import list
(for example `use Class::Abstract qw(x y)`) is ignored.

#### Returns

The string `'Class::Abstract'`.  `use` throws this value away, so you
only see it if you call `Class::Abstract->import` yourself.

#### Side Effects

Adds `'Class::Abstract'` to the end of the calling package's `@ISA`.
It does **nothing** in these cases:

- `'Class::Abstract'` is already in that `@ISA`.  So writing
`use Class::Abstract;` twice is safe.
- The calling package is `Class::Abstract` itself.  A class cannot
be its own parent.
- Perl cannot tell which package is calling (this can happen in
unusual code, such as a `BEGIN` block inside a string `eval`).  Without
this rule, the module would change `@main::ISA` by mistake.

It does not change the global variables `$_`, `$@` or `$!`, and it
does not touch an `alarm()` timer.  (Before version 0.03 it cleared
`$@`.)

#### Example

```perl
package Vehicle;
use Class::Abstract;          # @Vehicle::ISA is now ('Class::Abstract')
use Class::Abstract;          # no change: it is already there

package Car;
our @ISA = ('Vehicle');       # Car is concrete

package main;
my $car = Car->new;           # works
Vehicle->new;                 # dies
```

To load the module **without** making the current package abstract, pass
an empty list.  Perl then does not call `import()`:

```perl
use Class::Abstract ();       # main is NOT made abstract
```

#### Api Specification

##### Input

```perl
{
    class => { type => 'string', optional => 0 },   # always 'Class::Abstract'
}
```

##### Output

```perl
{
    type => 'string',
}
```

#### Messages

None.  `import()` never dies and never warns.

### New

```perl
my $obj  = ConcreteClass->new;
my $obj  = ConcreteClass->new(name => 'Rex');   # arguments are ignored
my $copy = $obj->new;                           # new, empty object of the same class
```

Makes a new, empty object, but only for a concrete class.

- If the class is abstract, `new()` dies with an error message.
- If the class is concrete, `new()` returns an empty hash
reference blessed into that class.

Child classes usually call this through `$class->SUPER::new` from
their own `new()`.  That works because the check looks at the class name
on the left of the arrow (the child), not at the class where `new()` is
written.

#### Arguments

- `$invocant` (required)

    The class name or object on the left of the arrow.  In `Dog->new`
    it is the string `'Dog'`.  If it is an object, the object's class is
    used.  It must not be `undef`, the empty
    string, or a reference that is not an object (such as `[]` or `{}`).

- `%args` (optional)

    Any other arguments.  They are accepted and **ignored**.  This lets a
    child class pass its arguments to `SUPER::new` without errors.  The
    child class must store its own data after `SUPER::new` returns.

#### Returns

A new, empty hash reference, blessed into the class.

#### Side Effects

None, except that `bless` creates the package in Perl's symbol table if
it did not exist yet.  (The check itself never creates a package.)

It does not change the global variables `$_`, `$@` or `$!`, and it
does not touch an `alarm()` timer.

#### Example

```perl
package Animal;
use parent 'Class::Abstract';

package Dog;
our @ISA = ('Animal');

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new;   # the check happens here
    $self->{name} = $args{name};
    return $self;
}

package main;
my $rex = Dog->new(name => 'Rex');   # works: Dog is concrete

eval { Animal->new };                # dies: Animal is abstract
print $@;   # Cannot instantiate abstract class Animal directly at ...
```

#### Api Specification

##### Input

```perl
{
    invocant => {
        type     => 'string|object',   # class name, or an object of that class
        optional => 0,
        min      => 1,                 # a name must not be empty
    },
}
```

##### Output

```perl
{
    type => 'object',                  # a hashref blessed into the class
}
```

#### Messages

```
Message                                   What it means / What to do
-------                                   --------------------------
Cannot instantiate abstract class CLASS   CLASS is abstract and no bypass is on.
  directly                                Make an object of a child class instead.

new() invocant must be a class name or    new() was called as a plain function
  blessed object, got TYPE                with a reference that is not an object
                                          (TYPE is ARRAY, HASH, CODE, ...).
                                          Call it as Class->new or $obj->new.

new() requires a defined class name as    new() was called as a plain function
  invocant                                with undef or ''.  Pass a class name.
```

### Check\_Abstract

```
Class::Abstract::check_abstract($class);
```

Runs the same check as `new()`, but does not make an object.

Use it when your abstract class writes its **own** `new()` and that
`new()` does not call `$class->SUPER::new`.  In that case
`Class::Abstract::new()` never runs, so nothing checks the class.  Call
`check_abstract()` as the first line of your `new()` to put the check
back.

#### Arguments

- `$invocant` (required)

    The class to check: a class name (a string) or an object.  If it is an
    object, the object's class is used.  In your own `new()`, pass the
    `$class` variable.  It must not be `undef`, the empty string, or a reference
    that is not an object.

#### Returns

Nothing if the class is concrete or a bypass is on: `undef` in scalar
context, or an empty list in list context.  Otherwise it dies.

#### Side Effects

None.  It obeys `$BYPASS` and `harness_bypass` in exactly the same way
as `new()`.

It does not change the global variables `$_`, `$@` or `$!`, and it
does not touch an `alarm()` timer.

#### Example

```perl
package Shape;
use parent 'Class::Abstract';

sub new {
    my ($class, %args) = @_;
    Class::Abstract::check_abstract($class);   # dies if $class is Shape
    return bless { sides => $args{sides} }, $class;
}

package Square;
our @ISA = ('Shape');

package main;
my $sq = Square->new(sides => 4);    # works
Shape->new(sides => 4);              # dies: Shape is abstract
```

#### Api Specification

##### Input

```perl
{
    invocant => {
        type     => 'string|object',
        optional => 0,
        min      => 1,
    },
}
```

##### Output

```perl
{
    type => 'undef',
}
```

#### Messages

```perl
Message                                   What it means / What to do
-------                                   --------------------------
Cannot instantiate abstract class CLASS   The same as for new().
  directly

check_abstract() requires a class name    The argument was a reference that is
  or blessed object, got TYPE             not an object.  Pass $class or $self.

check_abstract() requires a defined       The argument was undef or ''.  This
  class name                              usually means "my $class = shift;"
                                          is missing from your new().
```

### Is\_Abstract

```perl
my $yes_or_no = SomeClass->is_abstract;
my $yes_or_no = $obj->is_abstract;
my $yes_or_no = Class::Abstract->is_abstract('SomeClass');
my $yes_or_no = Class::Abstract->is_abstract($obj);
```

Tells you whether a class is abstract.  It returns `1` (yes) or `0`
(no).

A class is abstract only when `Class::Abstract` is in its **own**
`@ISA`, or when the class **is** `Class::Abstract`.  A child of an
abstract class is **not** abstract, so `is_abstract()` returns `0` for
it.

Every class below `Class::Abstract` can call this method.

#### Arguments

- `$self`

    Required.  The class name or object on the left of the arrow.  If no target is given (see
    below), this is the class that is checked.

- `$target` (optional)

    A class name or an object to check **instead of** the invocant.  This is
    how you ask about any class: `Class::Abstract->is_abstract('Dog')`.
    If `$target` is `undef`, it is treated as "not given".

#### Returns

The integer `1` if the class is abstract, otherwise the integer `0`.

A class name that does not exist (for example, a spelling mistake) gives
`0`, not an error.

#### Side Effects

None.  Asking about a class that does not exist does **not** create it.

It does not change the global variables `$_`, `$@` or `$!`, and it
does not touch an `alarm()` timer.

#### Example

```perl
Animal->is_abstract;                         # 1
Dog->is_abstract;                            # 0

my $rex = Dog->new(name => 'Rex');
$rex->is_abstract;                           # 0 (asks about Dog)

Class::Abstract->is_abstract('Animal');      # 1
Class::Abstract->is_abstract($rex);          # 0 (asks about Dog)
Class::Abstract->is_abstract('Anmial');      # 0 (spelling mistake: no such class)
```

#### Api Specification

##### Input

```perl
{
    self   => { type => 'string|object', optional => 0, min => 1 },
    target => { type => 'string|object', optional => 1, min => 1 },
}
```

##### Output

```perl
{
    type => 'integer',
    min  => 0,
    max  => 1,
}
```

#### Messages

```
Message                                   What it means / What to do
-------                                   --------------------------
is_abstract() requires a class name or    The class to check was a reference
  object invocant, got TYPE               that is not an object.

is_abstract() requires a class name or    The class to check was undef or ''.
  object invocant
```

## Public Variables

### $Class::Abstract::BYPASS

Default: `0`.

When this is true, the check is off for **every** class.  Always change
it with `local`, so that it goes back to its old value at the end of the
block:

```perl
{
    local $Class::Abstract::BYPASS = 1;
    my $animal = Animal->new;    # works, even though Animal is abstract
}
Animal->new;                     # dies again
```

Any true value turns the check off.  This includes strings that look
false to a person, such as `"false"`, `"no"` and `"0E0"`.

### %Class::Abstract::config

Settings for the module.  It has one key.

- harness\_bypass

    Default: `0`.

    When this is true **and** the environment variable `HARNESS_ACTIVE` is
    true, the check is off.  `HARNESS_ACTIVE` is set by test harnesses such
    as `prove` and `make test`.

    The default was `1` before version 0.03.  Set it to `1` to get the old
    behaviour back.

## Error Messages

This is the full list of messages that the module can produce.  The text
is always plain English.  It does not change with the locale.  Each
message ends with the file and line number of **your** code, for example
`at script.pl line 12.`

```
Message                                                    Comes from
-------                                                    ----------
Cannot instantiate abstract class CLASS directly           new, check_abstract
new() invocant must be a class name or blessed object,     new
  got TYPE
new() requires a defined class name as invocant            new
check_abstract() requires a class name or blessed object,  check_abstract
  got TYPE
check_abstract() requires a defined class name             check_abstract
is_abstract() requires a class name or object invocant,    is_abstract
  got TYPE
is_abstract() requires a class name or object invocant     is_abstract
Class::Abstract internal error: unknown message key KEY    (a bug in this
                                                            module; please
                                                            report it)
```

CLASS is the class name.  TYPE is the kind of reference, such as
`ARRAY`, `HASH` or `CODE`.

## Common Pitfalls

- Your own new() skips the check

    If an abstract class writes its own `new()` and creates the object
    with `bless`, `Class::Abstract::new()` never runs.  Nothing stops
    `Shape->new`.  Fix: call
    `Class::Abstract::check_abstract($class)` on the first line, or build
    the object with `$class->SUPER::new`.

- The order of parents matters

    Perl uses the **first** `new()` it finds, reading `@ISA` from left to
    right.  In `use parent 'Animal', 'Class::Abstract'`, Perl finds
    `Animal::new` first, if `Animal` has one.  If that `new()` does not
    call `check_abstract()`, there is no check.

- Child classes are not abstract automatically

    `Mammal` below the abstract class `Animal` is **concrete** unless
    `Mammal` also lists `Class::Abstract` in its own `@ISA`.

- "use Class::Abstract;" changes the current package

    `use Class::Abstract;` makes the package it is written in abstract.  If
    you write it in a script only to call `is_abstract()`, the `main`
    package becomes abstract.  Write `use Class::Abstract ();` instead.
    With the empty list, Perl does not call `import()`.  The same is true
    for `require Class::Abstract;`: it does **not** make any class abstract.

- undef and empty strings

    `Class::Abstract::new(undef)`, `new('')` and the same calls to
    `check_abstract()` and `is_abstract()` die.  But an `undef`
    **target** in `$obj->is_abstract(undef)` is treated as "no target",
    so the invocant is checked.

- Spelling mistakes give 0, not an error

    `Class::Abstract->is_abstract('Anmial')` returns `0`, because no
    package with that name has `Class::Abstract` in its `@ISA`.  Check
    the spelling if you get `0` when you expect `1`.

- A bypass without "local" never ends

    `$Class::Abstract::BYPASS = 1;` without `local` turns the check off
    for the rest of the program, in every file.

- Strings that look false are true

    `$BYPASS = 'false'` and `$BYPASS = 'no'` turn the check **off**,
    because Perl treats every non-empty string except `'0'` as true.  Use
    `1` and `0`.

- $BYPASS wins over harness\_bypass

    If `$BYPASS` is true, setting `harness_bypass` to `0` does not turn
    the check on.  To be sure the check is on, set both:

    ```
    local $Class::Abstract::BYPASS                 = 0;
    local $Class::Abstract::config{harness_bypass} = 0;
    ```

- Tests that passed before 0.03 may now die

    Before version 0.03 the check was off inside a test harness.  If your
    tests make objects of abstract classes, they will now die.  See
    ["Turning the check off"](#turning-the-check-off).

- isa() is not the same as is\_abstract()

    `Dog->isa('Class::Abstract')` is true, because `Class::Abstract`
    is a grandparent of `Dog`.  Use `Dog->is_abstract` to ask whether
    `Dog` itself is abstract.

- new() throws away its arguments

    `Dog->SUPER::new(name => 'Rex')` does not store `name`.  Store it
    yourself after `SUPER::new` returns.

- Objects made during a bypass stay abstract

    An object made while the bypass was on still belongs to the abstract
    class.  Calling `$obj->new` on it later, with the check on, dies.

## Encoding

The module does not read files, the terminal or the network.  The only
text it handles is class names, and the error messages that contain them.

- Class names

    Class names may contain any characters that Perl allows in a package
    name.  This includes non-ASCII letters (`Café`, Japanese,
    Chinese) and, for names made with `bless` or symbolic references, emoji.
    The module compares names exactly, character by character.

    Two conditions apply:

    - Non-ASCII package names need Perl 5.16 or later.  The rest of
    the module works on Perl 5.8.
    - The name must be a **character string**, not raw UTF-8 bytes.
    Names written in source code under `use utf8;` are character strings.
    Names read from a file or the network must be decoded first (for example
    with ["decode" in Encode](https://metacpan.org/pod/Encode#decode)).  A name that is still raw bytes is a **different**
    name to Perl, so `is_abstract()` returns `0` for it.

- Error messages

    The fixed text of every message is plain ASCII English.  A message also
    contains the class name, so it can contain non-ASCII characters.  If you
    print such a message to a file handle that has no encoding layer, Perl
    warns `Wide character in print`.  Add a layer to avoid this:

    ```
    binmode STDERR, ':encoding(UTF-8)';
    ```

- Settings

    `$BYPASS`, `harness_bypass` and `HARNESS_ACTIVE` are only tested for
    true or false.  Their text is never used.

## Limitations

- Only the check in new() and check\_abstract() protects a class

    Code can still make an object of an abstract class with
    `bless {}, 'Animal'`, with ["dclone" in Storable](https://metacpan.org/pod/Storable#dclone), with `thaw`, or with a
    `new()` that forgets to call `check_abstract()`.  The check is a rule
    that the module follows when it is asked.  It is not built into Perl.

- can('new') returns a method that dies

    `Animal->can('new')` returns `\&Class::Abstract::new`.  This looks
    like "yes, you can call new()".  You can call it, but it dies.

- The bypass is global

    `$BYPASS` turns the check off for every class, not only for the class
    that a test is about.

- The old package separator is not supported

    Perl once allowed `'` between parts of a package name (`Foo'Bar`
    meaning `Foo::Bar`).  This module does not convert `'` to `::`, so
    such names are treated as concrete.

- Threads

    The module shares no data between threads, except `$BYPASS` and
    `%config`, which are normally only read.  `import()` changes the
    caller's `@ISA`, usually when the program is compiled.  This is safe if
    modules are not loaded with `require` from several threads at once.

- Not for Moo or Moose

    Moo and Moose have their own ways to make abstract classes and required
    methods.  This module is for plain Perl classes.

## Dependencies

[Carp](https://metacpan.org/pod/Carp) (part of Perl),
[Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil) (part of Perl),
[Readonly](https://metacpan.org/pod/Readonly),
[Return::Set](https://metacpan.org/pod/Return%3A%3ASet).

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Class-Abstract/coverage/)
- [Sub::Abstract](https://metacpan.org/pod/Sub%3A%3AAbstract)

    Makes child classes write certain methods.  Use it together with
    `Class::Abstract` for a complete abstract base class.

- [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)

    Makes a method callable only from its own class.

- [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected)

    Makes a method callable only from its own class and its child classes.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes the module in the Z notation.  You do not need to
read it to use the module.

### Definitions

```
Package == seq CHAR
[Object, Ref]                     -- objects and references; Object ⊆ Ref

┌─ Registry ────────────────────────────────────────────
│ bypass         : 𝔹
│ harness_bypass : 𝔹
│ HARNESS_ACTIVE : 𝔹
│ ISA            : Package ⇸ seq Package
└───────────────────────────────────────────────────────

┌─ InitRegistry ────────────────────────────────────────
│ Registry'
├───────────────────────────────────────────────────────
│ bypass' = false ∧ harness_bypass' = false
└───────────────────────────────────────────────────────

bypass_active ⇔ bypass ∨ (harness_bypass ∧ HARNESS_ACTIVE)

resolve : (Package ∪ Object) ⇸ Package
resolve(x) = class_of(x)  if x ∈ Object
           = x            if x ∈ Package ∧ #x > 0

is_direct_abstract : Package → 𝔹
is_direct_abstract(c) ⇔ c = 'Class::Abstract'
                      ∨ (c ∈ dom ISA ∧ 'Class::Abstract' ∈ ran ISA(c))

┌─ BadInvocant ─────────────────────────────────────────
│ ΞRegistry
│ inv? : Package ∪ Ref ∪ {⊥}
├───────────────────────────────────────────────────────
│ inv? ∈ Ref ∖ Object ∨ inv? = ⊥ ∨ inv? = ''
│ croak(message for the calling routine)
└───────────────────────────────────────────────────────

┌─ NewAbstract ─────────────────────────────────────────
│ ΞRegistry
│ inv? : Package ∪ Object
├───────────────────────────────────────────────────────
│ is_direct_abstract(resolve(inv?)) ∧ ¬bypass_active
│ croak('Cannot instantiate abstract class ' ⁀ resolve(inv?) ⁀ ' directly')
└───────────────────────────────────────────────────────
```

### Import

```
┌─ Import ──────────────────────────────────────────────
│ ΔRegistry
│ class?  : Package
│ caller? : Package ∪ {⊥}
│ result! : Package
├───────────────────────────────────────────────────────
│ registrable ⇔ caller? ≠ ⊥ ∧ #caller? > 0
│               ∧ caller? ≠ 'Class::Abstract'
│               ∧ ¬is_direct_abstract(caller?)
│ registrable ⇒ ISA'(caller?) = ISA(caller?) ⁀ ⟨'Class::Abstract'⟩
│ ¬registrable ⇒ ISA' = ISA
│ bypass' = bypass ∧ harness_bypass' = harness_bypass
│ result! = class?
└───────────────────────────────────────────────────────
```

### New

```
┌─ New ─────────────────────────────────────────────────
│ ΞRegistry
│ inv?    : Package ∪ Object
│ result! : Object
├───────────────────────────────────────────────────────
│ ¬is_direct_abstract(resolve(inv?)) ∨ bypass_active
│ class_of(result!) = resolve(inv?)
│ result! is a new, empty hash
└───────────────────────────────────────────────────────

NewOp ≙ New ∨ NewAbstract ∨ BadInvocant
```

### Check\_Abstract

```
┌─ CheckAbstract ───────────────────────────────────────
│ ΞRegistry
│ inv?    : Package ∪ Object
│ result! : {⊥}
├───────────────────────────────────────────────────────
│ ¬is_direct_abstract(resolve(inv?)) ∨ bypass_active
│ result! = ⊥
└───────────────────────────────────────────────────────

CheckAbstractOp ≙ CheckAbstract ∨ NewAbstract ∨ BadInvocant
```

### Is\_Abstract

```
┌─ IsAbstract ──────────────────────────────────────────
│ ΞRegistry
│ self?   : Package ∪ Object
│ target? : Package ∪ Object ∪ {⊥}
│ result! : {0, 1}
├───────────────────────────────────────────────────────
│ c = resolve(if target? = ⊥ then self? else target?)
│ result! = 1 ⇔ is_direct_abstract(c)
└───────────────────────────────────────────────────────

IsAbstractOp ≙ IsAbstract ∨ BadInvocant

-- ΞRegistry in New, CheckAbstract and IsAbstract means that
-- asking about a package never creates it or changes any @ISA.
```

## State Diagram

The module has two independent kinds of state: the state of **each
class**, and the global **check mode**.

### Class States

Every package is in exactly one of these states:

```
MISSING    The package does not exist yet.
PLAIN      The package exists.  Class::Abstract is not one of its
           ancestors, so it has no new() from this module.
ABSTRACT   'Class::Abstract' is in the package's own @ISA.
CONCRETE   The package inherits from an abstract class, but
           'Class::Abstract' is not in its own @ISA.
```

Transitions:

```perl
                   use Class::Abstract;
                   use parent 'Class::Abstract';
                   push @P::ISA, 'Class::Abstract'
    +---------+  ------------------------------->  +----------+
    | MISSING |                                    |          |
    +---------+                                    |          |
      |     |                                      |          |
      |     | Class::Abstract::new('P')            |          |
      |     | (bless creates P)                    | ABSTRACT |
      |     v                                      |          |
      |  +-------+   same triggers as above        |          |
      |  | PLAIN | ------------------------------> |          |
      |  |       | <------------------------------ |          |
      |  +-------+   remove 'Class::Abstract'      +----------+
      |     |        from @P::ISA (P->new now          ^   |
      |     |        fails: "Can't locate object       |   | remove
      |     |        method new")                      |   | 'Class::Abstract'
      |     | @P::ISA = ('Animal')                     |   | from @P::ISA
      |     | (Animal is ABSTRACT or CONCRETE)         |   | (an abstract
      |     v                                    add   |   | parent remains)
      |  +----------+  ----------------------------->--+   |
      +->| CONCRETE |   use parent 'Class::Abstract'       |
         |          |  <-----------------------------------+
         +----------+

@P::ISA = ('Animal') also moves MISSING directly to CONCRETE.
```

Calls that never change a class's state:

```perl
P->is_abstract, Class::Abstract->is_abstract('P')   any state  -> same state
Class::Abstract::check_abstract('P')                any state  -> same state
use Class::Abstract;  (again, in P)                 ABSTRACT   -> ABSTRACT
```

### Check Mode

```
+-----------+   local $Class::Abstract::BYPASS = 1               +----------+
|           | -------------------------------------------------> |          |
| ENFORCING |   $config{harness_bypass} = 1 while HARNESS_ACTIVE | BYPASSED |
|           |   HARNESS_ACTIVE set while harness_bypass is 1     |          |
|           | <------------------------------------------------- |          |
+-----------+   end of the block with "local"                    +----------+
                $BYPASS false AND (harness_bypass false
                OR HARNESS_ACTIVE false)

Start state: ENFORCING  ($BYPASS = 0, harness_bypass = 0).
```

### What New() and Check\_Abstract() Do in Each State

```
Class state  Check mode  P->new                       check_abstract('P')
-----------  ----------  ---------------------------  -------------------
ABSTRACT     ENFORCING   dies: "Cannot instantiate    dies (same message)
                         abstract class P directly"
ABSTRACT     BYPASSED    returns an object of P       returns undef
CONCRETE     either      returns an object of P       returns undef
PLAIN        either      dies: "Can't locate object   returns undef
                         method new" (Perl error)
MISSING      either      dies: "Can't locate object   returns undef
                         method new" (Perl error)
```

No call changes the check mode except the assignments shown above.

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
