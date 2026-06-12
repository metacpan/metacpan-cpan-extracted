# NAME

Class::Abstract - Enforce abstract (non-instantiable) base classes for plain-Perl OO

# VERSION

Version 0.01

# SYNOPSIS

    # ---- Preferred: use parent -------------------------------------------
    package Animal;
    use parent 'Class::Abstract';

    # ---- Alternative: use Class::Abstract --------------------------------
    package Vehicle;
    use Class::Abstract;    # equivalent: adds Class::Abstract to @ISA

    # ---- Combine with Sub::Abstract for method contracts -----------------
    package Animal;
    use parent 'Class::Abstract';
    use Sub::Abstract qw(speak eat);   # subclasses must implement these

    # ---- Concrete subclass -----------------------------------------------
    package Dog;
    use parent 'Animal';

    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new;  # delegates through Animal to here
        $self->{name} = $args{name};
        return $self;
    }
    sub speak { 'Woof' }
    sub eat   { 'Nom'  }

    # ---- If Animal defines its own new(), call check_abstract() first ----
    package Animal;
    use parent 'Class::Abstract';

    sub new {
        my $class = shift;
        Class::Abstract::check_abstract($class);  # enforces abstract contract
        return bless { a => 'default' }, $class;
    }

    # ---- Runtime behaviour -----------------------------------------------
    Animal->new;             # croaks: Cannot instantiate abstract class Animal directly
    Dog->new(name => 'Rex'); # returns a blessed Dog hashref
    Animal->is_abstract;     # 1
    Dog->is_abstract;        # 0

# DESCRIPTION

Prevents direct instantiation of a class while still allowing concrete
subclasses to call `$class->SUPER::new(...)` through the normal
inheritance chain.

A class becomes abstract by listing `Class::Abstract` as a direct parent:

    package Animal;
    use parent 'Class::Abstract';   # Animal is abstract

or equivalently via `use`:

    use Class::Abstract;            # also adds to @ISA

Only the class that has `Class::Abstract` directly in its `@ISA` is
abstract.  Subclasses of that class are **not** automatically abstract; each
abstract class in a hierarchy must opt in explicitly.

The enforcement check is performed at runtime inside `new()`.  When a
concrete subclass calls `$class->SUPER::new(...)`, `$class` is the
concrete subclass, not the abstract base, so the check passes.

## Usage forms

- Inheritance form (preferred)

        package Animal;
        use parent 'Class::Abstract';

    `parent.pm` adds `Class::Abstract` to `@Animal::ISA`, making
    `Class::Abstract::new` available via MRO.  No `import()` call is made.
    `Animal-`new> will croak; `Dog-`new> (where Dog inherits Animal) will not.

- Import form

        package Vehicle;
        use Class::Abstract;

    Calls `import()`, which pushes `Class::Abstract` onto `@Vehicle::ISA`
    if not already present.  Functionally identical to the inheritance form.

## Multiple abstract levels in a hierarchy

Each abstract class must opt in:

    package Animal;   use parent 'Class::Abstract';      # abstract
    package Mammal;   use parent 'Class::Abstract', 'Animal'; # also abstract
    package Dog;      use parent 'Mammal';               # concrete

## Integration with Sub::Abstract

The two modules complement each other:

    use parent 'Class::Abstract';          # cannot instantiate directly
    use Sub::Abstract qw(speak eat);       # subclasses must implement speak + eat

## Bypass for testing

Either condition alone (OR logic) suppresses the croak:

- `$Class::Abstract::BYPASS` set to a true value.  Use `local` in tests.
Checked first; short-circuits the second condition.
- `$ENV{HARNESS_ACTIVE}` set (the convention used by [Test::Harness](https://metacpan.org/pod/Test%3A%3AHarness)/prove)
**and** `$config{harness_bypass}` is truthy (the default).

**Important:** `$BYPASS` takes full precedence.  Setting
`harness_bypass = 0` does not re-enable enforcement when `$BYPASS` is
truthy.  To test enforcement inside a harness:

    local $Class::Abstract::BYPASS = 0;
    local $Class::Abstract::config{harness_bypass} = 0;

## Error message format

    Cannot instantiate abstract class Animal directly

# METHODS/SUBROUTINES

## import

    use Class::Abstract;

Called automatically by `use Class::Abstract`.  Adds `Class::Abstract`
to the calling package's `@ISA` (if not already present), making the
calling package abstract in the same way as `use parent 'Class::Abstract'`.

Has no effect when called on `Class::Abstract` itself (no self-registration).

### Arguments

- `$class` (required, implicit)

    Always `'Class::Abstract'` in normal usage.

### Returns

The class name (`'Class::Abstract'`) as a plain string.

### Example

    package Vehicle;
    use Class::Abstract;   # Vehicle is now abstract; Class::Abstract in @ISA

### API SPECIFICATION

#### Input

    # No named-parameter schema: import() takes only the implicit $class.

#### Output

    { type => 'string' }    # always returns 'Class::Abstract'

## new

    my $obj = ConcreteChild->new;
    my $obj = ConcreteChild->new(%initial_attrs);

Base constructor with abstract-class enforcement.  When called on an
abstract class (one with `Class::Abstract` directly in its `@ISA`), it
croaks.  When called on a concrete subclass -- including via
`$class->SUPER::new(...)` from a child's own `new()` -- it succeeds
and returns a blessed empty hashref.

The check is performed on the **original invocant** (`$class`), not on
the package where `new()` is defined.  This means `SUPER::new` works
correctly: `$class` is the concrete subclass, so the abstract-class check
passes.

### Arguments

- `$class` (required)

    The invocant -- either a class name or a blessed object (to support
    `ref($obj)-`new>-style calls).

- `%initial_attrs` (optional, ignored)

    Any additional arguments are accepted but not used by this base constructor.
    They are silently discarded so that subclass `new()` methods can pass
    arguments through `SUPER::new` without errors.  Subclasses should
    populate object attributes themselves after calling `SUPER::new`.

### Returns

A new blessed empty hashref of class `$class`.

### Example

    package Dog;
    our @ISA = ('Animal');   # Animal is abstract via Class::Abstract

    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new;   # delegates to Class::Abstract::new
        $self->{name} = $args{name};     # populate after SUPER
        return $self;
    }

    # Dog->new(name => 'Rex') works; Animal->new croaks.

### API SPECIFICATION

#### Input

    # Positional: ($class, @ignored_args)
    # $class must be a defined non-reference scalar (package name or blessed ref).

#### Output

    { type => 'object', isa => $class }    # a blessed hashref of the given class

### PSEUDOCODE

    new($class, @args):
        class <- ref($class) if blessed, else $class
        UNLESS bypass is active
            IF class is directly abstract
                CROAK "Cannot instantiate abstract class CLASS directly"
        END UNLESS
        RETURN bless({}, class)

### MESSAGES

    Message                                              Meaning / Action
    -------                                              ----------------
    Cannot instantiate abstract class CLASS directly     CLASS has Class::Abstract
                                                         directly in its @ISA (or IS
                                                         Class::Abstract).  You are
                                                         trying to instantiate an
                                                         abstract class.  Action:
                                                         instantiate a concrete
                                                         subclass of CLASS instead.

## check\_abstract

    Class::Abstract::check_abstract($class);
    $class->Class::Abstract::check_abstract;

Enforces the abstract-class contract from within a user-defined `new()`.
Call this at the top of an abstract class's own `new()` when that class
overrides `new()` directly rather than delegating to `SUPER::new()`.
Croaks if `$class` is directly abstract and no bypass is active; returns
normally otherwise.

**When to use:** If your abstract class defines its own `new()` and that
`new()` creates the object directly (via `bless`) rather than calling
`$class->SUPER::new`, you must call `check_abstract()` first -- otherwise
the enforcement in `Class::Abstract::new` is never reached.

    package Animal;
    use parent 'Class::Abstract';

    sub new {
        my $class = shift;
        Class::Abstract::check_abstract($class);  # croaks if $class is Animal
        return bless { a => 'default' }, $class;  # only reaches here for subclasses
    }

### Arguments

- `$class` (required)

    A class name string or a blessed object.  Unblessed references are rejected.

### Returns

`undef` on success (i.e. `$class` is concrete or bypass is active).
Croaks on failure.

### MESSAGES

    Message                                              Meaning / Action
    -------                                              ----------------
    Cannot instantiate abstract class CLASS directly     Same as new() -- see above.
    check_abstract() requires a class name or           Invocant was an unblessed ref.
      blessed object
    check_abstract() requires a defined class name      Invocant was undef or empty string.

## is\_abstract

    my $bool = SomeClass->is_abstract;
    my $bool = $obj->is_abstract;
    my $bool = Class::Abstract->is_abstract('SomeClass');

Returns `1` if the invocant (or named class) is a **directly** abstract class
(i.e. has `Class::Abstract` in its own `@ISA`, or is `Class::Abstract`
itself).  Returns `0` for concrete subclasses even if they transitively
inherit from an abstract base.

Inheritable via MRO: any class that has `Class::Abstract` in its ancestry
can call this as a class method or an instance method.

### Arguments

- `$self_or_class` (required)

    The invocant -- a class name, a blessed object, or `Class::Abstract`
    itself.  When a class name is passed, `is_abstract` is checked on that
    class.  When a blessed object is passed, the object's class is used.

- `$class_name` (optional)

    When provided, check this class name instead of resolving from the invocant.
    Intended for the explicit form `Class::Abstract-`is\_abstract('SomeClass')>.

### Returns

`1` if directly abstract, `0` otherwise, as a plain integer.

### Example

    Animal->is_abstract;    # 1 (Animal has Class::Abstract in @ISA)
    Dog->is_abstract;       # 0 (Dog's @ISA contains Animal, not Class::Abstract)

    my $dog = Dog->new(name => 'Rex');
    $dog->is_abstract;      # 0 (checks ref($dog) = 'Dog')

### API SPECIFICATION

#### Input

    # Positional: ($self_or_class)
    # Must be a defined value (class name string or blessed ref).

#### Output

    { type => 'integer', values => [0, 1] }

# KNOWN LIMITATIONS

- Only direct @ISA is checked

    `_is_direct_abstract` looks only at the immediate `@ISA` of the invocant.
    If `Class::Abstract` appears higher in the MRO (e.g. `Dog` inherits
    `Animal` which is abstract), `Dog` is **not** considered abstract -- which
    is the intended behaviour.  However this also means that making a subclass
    abstract requires an explicit opt-in:

        package Mammal;
        use parent 'Class::Abstract', 'Animal';   # both in @ISA; Mammal is abstract

- `isa()` cannot distinguish abstract from concrete

    `Dog->isa('Class::Abstract')` returns true (Dog inherits Class::Abstract
    transitively).  Use `is_abstract()` to distinguish direct-abstract from
    merely-related-to-abstract.

- `can('new')` returns the croak-stub

    `Animal->can('new')` returns `Class::Abstract::new` (a truthy CODE ref),
    suggesting the method is callable.  It is callable -- it will just croak.

- new() discards constructor arguments

    The base constructor ignores all arguments beyond `$class` and returns an
    empty blessed hashref.  Subclasses must populate their own attributes after
    calling `SUPER::new`.  If you need a smarter base constructor (e.g. one
    that accepts named parameters and validates them), override `new()` in
    your abstract base class.

- Bypass precedence

    The bypass guard is `$BYPASS || ($config{harness_bypass} &&
    $ENV{HARNESS_ACTIVE})`.  `$BYPASS` short-circuits the `||`, so setting
    `$config{harness_bypass} = 0` does **not** re-enable enforcement when
    `$BYPASS` is truthy.  Both must be cleared to test enforcement in a harness:

        local $Class::Abstract::BYPASS = 0;
        local $Class::Abstract::config{harness_bypass} = 0;

- Thread safety

    No shared mutable state is used beyond `$BYPASS` and `%config` (both
    read-only in normal operation).  `import()` modifies caller's `@ISA`
    at compile time; this is safe as long as modules are not `require`d
    concurrently from multiple threads.

- DESTROY and Perl 5.42+

    If a class marks `DESTROY` as abstract via `Sub::Abstract`, exceptions
    thrown inside `DESTROY` are silently discarded on Perl 5.42+ (emitted to
    STDERR instead).  Test with `lives_ok` for `DESTROY` paths.

- Not for Moo/Moose

    Moo's `requires` and Moose's `abstract` provide similar guarantees within
    their own object systems.  This module is for plain-Perl OO only.

# FORMAL SPECIFICATION

The following schemas formally specify the module's behaviour.

    -- Type abbreviations
    Package  == seq CHAR    -- Perl package name string

    -- System state
    +-Registry--------------------------------------------+
    | bypass    : BOOL                                    |
    | config    : { harness_bypass : BOOL }               |
    +-----------------------------------------------------+

    -- Initial state
    +-InitRegistry----------------------------------------+
    | Registry                                            |
    |-----------------------------------------------------|
    | bypass    = false                                   |
    | config    = { harness_bypass |-> true }             |
    +-----------------------------------------------------+

    -- Bypass predicate
    bypass_active(R) <=>
        R.bypass
        or (R.config.harness_bypass and HARNESS_ACTIVE)

    -- Directly-abstract predicate
    is_direct_abstract(c) <=>
        c = 'Class::Abstract'
        \/ 'Class::Abstract' in direct_ISA(c)

    -- AbstractNew (success): concrete class or bypass active
    +-AbstractNew-----------------------------------------+
    | class?   : Package                                  |
    | result!  : class? (blessed hashref)                |
    |-----------------------------------------------------|
    | (not is_direct_abstract(class?))                    |
    | \/ bypass_active                                   |
    | result! = bless({}, class?)                        |
    +-----------------------------------------------------+

    -- AbstractNew (failure): abstract class, no bypass
    +-AbstractNewFail--------------------------------------+
    | class?   : Package                                  |
    |-----------------------------------------------------|
    | is_direct_abstract(class?) /\ not bypass_active     |
    | croak("Cannot instantiate abstract class "          |
    |        ++ class? ++ " directly")                    |
    +-----------------------------------------------------+

    -- Key properties:
    --   When Dog->SUPER::new is called, $class = 'Dog'.
    --   is_direct_abstract('Dog') is false (Dog's @ISA = ('Animal')).
    --   Enforcement never fires for concrete subclasses via SUPER::new.

# DEPENDENCIES

[Carp](https://metacpan.org/pod/Carp) (core),
[Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil) (core),
[Readonly](https://metacpan.org/pod/Readonly),
[Return::Set](https://metacpan.org/pod/Return%3A%3ASet).

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Class-Abstract/coverage/)
- [Sub::Abstract](https://metacpan.org/pod/Sub%3A%3AAbstract)

    Sister module: enforces abstract (pure-virtual) method contracts.
    Pair with `Class::Abstract` to create fully enforced abstract base classes.

- [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)

    Sister module: enforces strictly private (owner-only) access.

- [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected)

    Sister module: enforces protected (owner + subclass) access.

# PUBLIC VARIABLES

## `$BYPASS`

Set to a true value to disable the abstract-class croak.  Use `local`:

    local $Class::Abstract::BYPASS = 1;

**Warning:** any truthy value (including `"false"`, `"0E0"`) enables bypass.

## `%config`

- `harness_bypass` (default: 1)

    When true, the abstract-class croak is suppressed whenever
    `$ENV{HARNESS_ACTIVE}` is set.  Set to 0 to test enforcement in a harness.
    Note `$BYPASS` takes precedence (see ["Bypass precedence"](#bypass-precedence)).

# FORMAL SPECIFICATION

## import

    -- Type abbreviations
    Package == seq CHAR    -- Perl package name string

    -- Pre-condition
    caller? : Package
    caller? /= 'Class::Abstract'

    -- Post-condition
    'Class::Abstract' in ISA(caller?)

    -- Effect on ISA
    ISA(caller?)' = ISA(caller?) union {'Class::Abstract'}
                    if 'Class::Abstract' not in ISA(caller?),
                    ISA(caller?) otherwise

## new

    -- bypass_active predicate (OR; $BYPASS checked first)
    bypass_active <=>
        $BYPASS
        or ($config{harness_bypass} and HARNESS_ACTIVE)

    -- Successful construction
    +-- New (success) ----------------------------------------+
    | class?   : Package                                      |
    | result!  : blessed hashref                             |
    |---------------------------------------------------------|
    | not is_direct_abstract(class?) \/ bypass_active        |
    | result! = bless({}, class?)                            |
    +---------------------------------------------------------+

    -- Failed construction
    +-- New (failure) ----------------------------------------+
    | class?   : Package                                      |
    |---------------------------------------------------------|
    | is_direct_abstract(class?) /\ not bypass_active        |
    | croak("Cannot instantiate abstract class "             |
    |        ++ class? ++ " directly")                       |
    +---------------------------------------------------------+

## is\_abstract

    -- is_abstract predicate
    +-- IsAbstract -------------------------------------------+
    | self?   : Package | blessed ref                         |
    | result! : B                                             |
    |---------------------------------------------------------|
    | let c = ref(self?) if blessed, else self?               |
    | result! = is_direct_abstract(c)                         |
    +---------------------------------------------------------+

    -- is_direct_abstract predicate
    is_direct_abstract(c) <=>
        c = 'Class::Abstract'
        \/ 'Class::Abstract' in direct_ISA(c)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
