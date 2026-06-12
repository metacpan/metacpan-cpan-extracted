package Class::Abstract;

# Minimum required Perl version: 5.8.
use 5.008;
use strict;
use warnings;
use Carp         qw(croak);
use Readonly;
use Scalar::Util qw(blessed);
use Return::Set  qw(set_return);

=head1 NAME

Class::Abstract - Enforce abstract (non-instantiable) base classes for plain-Perl OO

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Self-referential constant: the canonical name of this package.
Readonly::Scalar my $SELF => __PACKAGE__;

# Error message emitted when direct instantiation of an abstract class is
# attempted.  Kept as a constant so tests can match against it exactly.
Readonly::Scalar my $ERR_ABSTRACT =>
	'Cannot instantiate abstract class %s directly';

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

# Set to a true value to suppress all abstract-class croaks globally.
# Always use 'local' in tests to prevent state from bleeding between cases.
our $BYPASS = 0;

# Runtime tunables.  Modify $config{harness_bypass} to control whether
# HARNESS_ACTIVE suppresses enforcement.
our %config = (
	harness_bypass => 1,    # 1 = suppress croaks when HARNESS_ACTIVE is set
);

# ---------------------------------------------------------------------------
# PUBLIC INTERFACE
# ---------------------------------------------------------------------------

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Prevents direct instantiation of a class while still allowing concrete
subclasses to call C<$class-E<gt>SUPER::new(...)> through the normal
inheritance chain.

A class becomes abstract by listing C<Class::Abstract> as a direct parent:

    package Animal;
    use parent 'Class::Abstract';   # Animal is abstract

or equivalently via C<use>:

    use Class::Abstract;            # also adds to @ISA

Only the class that has C<Class::Abstract> directly in its C<@ISA> is
abstract.  Subclasses of that class are B<not> automatically abstract; each
abstract class in a hierarchy must opt in explicitly.

The enforcement check is performed at runtime inside C<new()>.  When a
concrete subclass calls C<$class-E<gt>SUPER::new(...)>, C<$class> is the
concrete subclass, not the abstract base, so the check passes.

=head2 Usage forms

=over 4

=item Inheritance form (preferred)

    package Animal;
    use parent 'Class::Abstract';

C<parent.pm> adds C<Class::Abstract> to C<@Animal::ISA>, making
C<Class::Abstract::new> available via MRO.  No C<import()> call is made.
C<Animal->new> will croak; C<Dog->new> (where Dog inherits Animal) will not.

=item Import form

    package Vehicle;
    use Class::Abstract;

Calls C<import()>, which pushes C<Class::Abstract> onto C<@Vehicle::ISA>
if not already present.  Functionally identical to the inheritance form.

=back

=head2 Multiple abstract levels in a hierarchy

Each abstract class must opt in:

    package Animal;   use parent 'Class::Abstract';      # abstract
    package Mammal;   use parent 'Class::Abstract', 'Animal'; # also abstract
    package Dog;      use parent 'Mammal';               # concrete

=head2 Integration with Sub::Abstract

The two modules complement each other:

    use parent 'Class::Abstract';          # cannot instantiate directly
    use Sub::Abstract qw(speak eat);       # subclasses must implement speak + eat

=head2 Bypass for testing

Either condition alone (OR logic) suppresses the croak:

=over 4

=item * C<$Class::Abstract::BYPASS> set to a true value.  Use C<local> in tests.
Checked first; short-circuits the second condition.

=item * C<$ENV{HARNESS_ACTIVE}> set (the convention used by L<Test::Harness>/prove)
B<and> C<$config{harness_bypass}> is truthy (the default).

=back

B<Important:> C<$BYPASS> takes full precedence.  Setting
C<harness_bypass = 0> does not re-enable enforcement when C<$BYPASS> is
truthy.  To test enforcement inside a harness:

    local $Class::Abstract::BYPASS = 0;
    local $Class::Abstract::config{harness_bypass} = 0;

=head2 Error message format

    Cannot instantiate abstract class Animal directly

=head1 METHODS/SUBROUTINES

=head2 import

    use Class::Abstract;

Called automatically by C<use Class::Abstract>.  Adds C<Class::Abstract>
to the calling package's C<@ISA> (if not already present), making the
calling package abstract in the same way as C<use parent 'Class::Abstract'>.

Has no effect when called on C<Class::Abstract> itself (no self-registration).

=head3 Arguments

=over 4

=item C<$class> (required, implicit)

Always C<'Class::Abstract'> in normal usage.

=back

=head3 Returns

The class name (C<'Class::Abstract'>) as a plain string.

=head3 Example

    package Vehicle;
    use Class::Abstract;   # Vehicle is now abstract; Class::Abstract in @ISA

=head3 API SPECIFICATION

=head4 Input

    # No named-parameter schema: import() takes only the implicit $class.

=head4 Output

    { type => 'string' }    # always returns 'Class::Abstract'

=cut

sub import {
	my ($class) = @_;
	my $caller  = caller;

	# Guard: unusual contexts (e.g. BEGIN{} inside string eval) can produce an
	# empty-string caller; pushing onto @{"::ISA"} would silently mutate @main::ISA.
	return set_return($class, { type => 'string' })
		unless defined($caller) && length($caller);

	# Do not modify Class::Abstract's own @ISA -- that would be circular.
	return set_return($class, { type => 'string' }) if $caller eq $SELF;

	# Add Class::Abstract to the caller's @ISA unless already present.
	# This is the same effect as: use parent 'Class::Abstract';
	{
		no strict 'refs';
		push @{"${caller}::ISA"}, $SELF
			unless _is_direct_abstract($caller);
	}

	return set_return($class, { type => 'string' });
}

=head2 new

    my $obj = ConcreteChild->new;
    my $obj = ConcreteChild->new(%initial_attrs);

Base constructor with abstract-class enforcement.  When called on an
abstract class (one with C<Class::Abstract> directly in its C<@ISA>), it
croaks.  When called on a concrete subclass -- including via
C<$class-E<gt>SUPER::new(...)> from a child's own C<new()> -- it succeeds
and returns a blessed empty hashref.

The check is performed on the B<original invocant> (C<$class>), not on
the package where C<new()> is defined.  This means C<SUPER::new> works
correctly: C<$class> is the concrete subclass, so the abstract-class check
passes.

=head3 Arguments

=over 4

=item C<$class> (required)

The invocant -- either a class name or a blessed object (to support
C<ref($obj)->new>-style calls).

=item C<%initial_attrs> (optional, ignored)

Any additional arguments are accepted but not used by this base constructor.
They are silently discarded so that subclass C<new()> methods can pass
arguments through C<SUPER::new> without errors.  Subclasses should
populate object attributes themselves after calling C<SUPER::new>.

=back

=head3 Returns

A new blessed empty hashref of class C<$class>.

=head3 Example

    package Dog;
    our @ISA = ('Animal');   # Animal is abstract via Class::Abstract

    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new;   # delegates to Class::Abstract::new
        $self->{name} = $args{name};     # populate after SUPER
        return $self;
    }

    # Dog->new(name => 'Rex') works; Animal->new croaks.

=head3 API SPECIFICATION

=head4 Input

    # Positional: ($class, @ignored_args)
    # $class must be a defined non-reference scalar (package name or blessed ref).

=head4 Output

    { type => 'object', isa => $class }    # a blessed hashref of the given class

=head3 PSEUDOCODE

    new($class, @args):
        class <- ref($class) if blessed, else $class
        UNLESS bypass is active
            IF class is directly abstract
                CROAK "Cannot instantiate abstract class CLASS directly"
        END UNLESS
        RETURN bless({}, class)

=head3 MESSAGES

    Message                                              Meaning / Action
    -------                                              ----------------
    Cannot instantiate abstract class CLASS directly     CLASS has Class::Abstract
                                                         directly in its @ISA (or IS
                                                         Class::Abstract).  You are
                                                         trying to instantiate an
                                                         abstract class.  Action:
                                                         instantiate a concrete
                                                         subclass of CLASS instead.

=cut

sub new {
	my ($class) = @_;

	# Accept blessed objects as invocants (e.g. $obj->new style), but reject
	# plain (unblessed) references such as arrayrefs or coderefs.
	if (ref $class) {
		croak sprintf('new() invocant must be a class name or blessed object, got %s', ref $class)
			unless blessed($class);
		$class = ref($class);
	}

	croak 'new() requires a defined class name as invocant'
		unless defined($class) && length($class);

	# Enforce the abstract-class contract unless bypass is active.
	unless ($BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE})) {
		croak sprintf($ERR_ABSTRACT, $class)
			if _is_direct_abstract($class);
	}

	return bless {}, $class;
}

=head2 check_abstract

    Class::Abstract::check_abstract($class);
    $class->Class::Abstract::check_abstract;

Enforces the abstract-class contract from within a user-defined C<new()>.
Call this at the top of an abstract class's own C<new()> when that class
overrides C<new()> directly rather than delegating to C<SUPER::new()>.
Croaks if C<$class> is directly abstract and no bypass is active; returns
normally otherwise.

B<When to use:> If your abstract class defines its own C<new()> and that
C<new()> creates the object directly (via C<bless>) rather than calling
C<$class-E<gt>SUPER::new>, you must call C<check_abstract()> first -- otherwise
the enforcement in C<Class::Abstract::new> is never reached.

    package Animal;
    use parent 'Class::Abstract';

    sub new {
        my $class = shift;
        Class::Abstract::check_abstract($class);  # croaks if $class is Animal
        return bless { a => 'default' }, $class;  # only reaches here for subclasses
    }

=head3 Arguments

=over 4

=item C<$class> (required)

A class name string or a blessed object.  Unblessed references are rejected.

=back

=head3 Returns

C<undef> on success (i.e. C<$class> is concrete or bypass is active).
Croaks on failure.

=head3 MESSAGES

    Message                                              Meaning / Action
    -------                                              ----------------
    Cannot instantiate abstract class CLASS directly     Same as new() -- see above.
    check_abstract() requires a class name or           Invocant was an unblessed ref.
      blessed object
    check_abstract() requires a defined class name      Invocant was undef or empty string.

=cut

sub check_abstract {
	my ($class) = @_;

	if (ref $class) {
		croak 'check_abstract() requires a class name or blessed object'
			unless blessed($class);
		$class = ref($class);
	}

	croak 'check_abstract() requires a defined class name'
		unless defined($class) && length($class);

	unless ($BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE})) {
		croak sprintf($ERR_ABSTRACT, $class)
			if _is_direct_abstract($class);
	}
	return;
}

=head2 is_abstract

    my $bool = SomeClass->is_abstract;
    my $bool = $obj->is_abstract;
    my $bool = Class::Abstract->is_abstract('SomeClass');

Returns C<1> if the invocant (or named class) is a B<directly> abstract class
(i.e. has C<Class::Abstract> in its own C<@ISA>, or is C<Class::Abstract>
itself).  Returns C<0> for concrete subclasses even if they transitively
inherit from an abstract base.

Inheritable via MRO: any class that has C<Class::Abstract> in its ancestry
can call this as a class method or an instance method.

=head3 Arguments

=over 4

=item C<$self_or_class> (required)

The invocant -- a class name, a blessed object, or C<Class::Abstract>
itself.  When a class name is passed, C<is_abstract> is checked on that
class.  When a blessed object is passed, the object's class is used.

=item C<$class_name> (optional)

When provided, check this class name instead of resolving from the invocant.
Intended for the explicit form C<Class::Abstract->is_abstract('SomeClass')>.

=back

=head3 Returns

C<1> if directly abstract, C<0> otherwise, as a plain integer.

=head3 Example

    Animal->is_abstract;    # 1 (Animal has Class::Abstract in @ISA)
    Dog->is_abstract;       # 0 (Dog's @ISA contains Animal, not Class::Abstract)

    my $dog = Dog->new(name => 'Rex');
    $dog->is_abstract;      # 0 (checks ref($dog) = 'Dog')

=head3 API SPECIFICATION

=head4 Input

    # Positional: ($self_or_class)
    # Must be a defined value (class name string or blessed ref).

=head4 Output

    { type => 'integer', values => [0, 1] }

=cut

sub is_abstract {
	my ($self, $class_arg) = @_;

	# Three-argument form: Class::Abstract->is_abstract('SomeClass') -- use the arg.
	# Two-argument form: SomeClass->is_abstract or $obj->is_abstract -- use invocant.
	my $class = defined($class_arg) ? $class_arg : (ref($self) || $self);

	croak 'is_abstract() requires a class name or object invocant'
		unless defined($class) && length($class);

	return _is_direct_abstract($class);
}

# ---------------------------------------------------------------------------
# PRIVATE SUBROUTINES
# ---------------------------------------------------------------------------

# _is_direct_abstract
# Determine whether a class is directly abstract, meaning
#        Class::Abstract appears in its own @ISA (not transitively).
# Entry        : $class -- the package name to check (plain string)
# Exit status  : Returns 1 if directly abstract, 0 (empty string) if not.
# Notes        : Class::Abstract itself is treated as abstract (the module
#                cannot be instantiated directly).
#                This check is intentionally shallow: only the immediate @ISA
#                is inspected.  Concrete subclasses that inherit transitively
#                from an abstract class are NOT considered abstract by this
#                predicate, which is the correct behaviour.
sub _is_direct_abstract {
	my ($class) = @_;

	return 0 unless defined $class;

	# Class::Abstract itself must not be instantiable.
	return 1 if $class eq $SELF;

	# Check if Class::Abstract appears directly in the class's own @ISA.
	no strict 'refs';
	return (grep { $_ eq $SELF } @{"${class}::ISA"}) ? 1 : 0;
}

1;

__END__

=head1 KNOWN LIMITATIONS

=over 4

=item Only direct @ISA is checked

C<_is_direct_abstract> looks only at the immediate C<@ISA> of the invocant.
If C<Class::Abstract> appears higher in the MRO (e.g. C<Dog> inherits
C<Animal> which is abstract), C<Dog> is B<not> considered abstract -- which
is the intended behaviour.  However this also means that making a subclass
abstract requires an explicit opt-in:

    package Mammal;
    use parent 'Class::Abstract', 'Animal';   # both in @ISA; Mammal is abstract

=item C<isa()> cannot distinguish abstract from concrete

C<Dog-E<gt>isa('Class::Abstract')> returns true (Dog inherits Class::Abstract
transitively).  Use C<is_abstract()> to distinguish direct-abstract from
merely-related-to-abstract.

=item C<can('new')> returns the croak-stub

C<< Animal->can('new') >> returns C<Class::Abstract::new> (a truthy CODE ref),
suggesting the method is callable.  It is callable -- it will just croak.

=item new() discards constructor arguments

The base constructor ignores all arguments beyond C<$class> and returns an
empty blessed hashref.  Subclasses must populate their own attributes after
calling C<SUPER::new>.  If you need a smarter base constructor (e.g. one
that accepts named parameters and validates them), override C<new()> in
your abstract base class.

=item Bypass precedence

The bypass guard is C<$BYPASS || ($config{harness_bypass} &&
$ENV{HARNESS_ACTIVE})>.  C<$BYPASS> short-circuits the C<||>, so setting
C<$config{harness_bypass} = 0> does B<not> re-enable enforcement when
C<$BYPASS> is truthy.  Both must be cleared to test enforcement in a harness:

    local $Class::Abstract::BYPASS = 0;
    local $Class::Abstract::config{harness_bypass} = 0;

=item Thread safety

No shared mutable state is used beyond C<$BYPASS> and C<%config> (both
read-only in normal operation).  C<import()> modifies caller's C<@ISA>
at compile time; this is safe as long as modules are not C<require>d
concurrently from multiple threads.

=item DESTROY and Perl 5.42+

If a class marks C<DESTROY> as abstract via C<Sub::Abstract>, exceptions
thrown inside C<DESTROY> are silently discarded on Perl 5.42+ (emitted to
STDERR instead).  Test with C<lives_ok> for C<DESTROY> paths.

=item Not for Moo/Moose

Moo's C<requires> and Moose's C<abstract> provide similar guarantees within
their own object systems.  This module is for plain-Perl OO only.

=back

=head1 FORMAL SPECIFICATION

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

=head1 DEPENDENCIES

L<Carp> (core),
L<Scalar::Util> (core),
L<Readonly>,
L<Return::Set>.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Class-Abstract/coverage/>

=item * L<Sub::Abstract>

Sister module: enforces abstract (pure-virtual) method contracts.
Pair with C<Class::Abstract> to create fully enforced abstract base classes.

=item * L<Sub::Private>

Sister module: enforces strictly private (owner-only) access.

=item * L<Sub::Protected>

Sister module: enforces protected (owner + subclass) access.

=back

=head1 PUBLIC VARIABLES

=head2 C<$BYPASS>

Set to a true value to disable the abstract-class croak.  Use C<local>:

    local $Class::Abstract::BYPASS = 1;

B<Warning:> any truthy value (including C<"false">, C<"0E0">) enables bypass.

=head2 C<%config>

=over 4

=item C<harness_bypass> (default: 1)

When true, the abstract-class croak is suppressed whenever
C<$ENV{HARNESS_ACTIVE}> is set.  Set to 0 to test enforcement in a harness.
Note C<$BYPASS> takes precedence (see L</Bypass precedence>).

=back

=head1 FORMAL SPECIFICATION

=head2 import

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

=head2 new

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

=head2 is_abstract

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

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
