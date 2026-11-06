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

Class::Abstract - Stop code from making objects of a class that is only a template

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

=head2 1. Make a class abstract (the usual way)

    package Animal;
    use parent 'Class::Abstract';    # Animal is now abstract

    package Dog;
    use parent -norequire, 'Animal'; # Dog is a normal (concrete) class

    package main;
    my $dog = Dog->new;              # works: you get a Dog object
    my $bad = Animal->new;           # dies: "Cannot instantiate abstract class Animal directly"

=head2 2. Make a class abstract with "use"

    package Vehicle;
    use Class::Abstract;             # same result as: use parent 'Class::Abstract'

=head2 3. A child class that stores its own data

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

=head2 4. An abstract class that has its own new()

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

=head2 5. Ask whether a class is abstract

    Animal->is_abstract;                        # 1
    Dog->is_abstract;                           # 0
    $rex->is_abstract;                          # 0 (asks about Dog)
    Class::Abstract->is_abstract('Animal');     # 1
    Class::Abstract->is_abstract($rex);         # 0

=head2 6. Make an object of an abstract class inside a test

    use Test::More;

    my $animal = do {
        local $Class::Abstract::BYPASS = 1;    # turn the check off for this block only
        Animal->new;
    };
    is( $animal->legs, 4, 'default number of legs' );

=head2 7. Use with Sub::Abstract

    package Animal;
    use parent 'Class::Abstract';      # nobody can make an Animal directly
    use Sub::Abstract qw(speak);       # every child class must write speak()

=head1 DESCRIPTION

=head2 What this module does

An I<abstract class> is a class that is only a template.  It holds code
that its child classes share, but it is not complete on its own.  You
should never make an object of it.  You make objects of its child classes
instead.

Perl has no built-in way to say "this class is abstract".  This module
adds one.  When code tries to make an object of an abstract class, the
program dies with a clear error message.  Child classes work normally.

=head2 Terms used in this document

=over 4

=item class, package

In Perl, a class is a package.  C<Animal> and C<Dog> are package names.

=item parent class, child class, @ISA

Each package has a list called C<@ISA> that names its parent classes.
If C<@Dog::ISA> contains C<Animal>, then C<Dog> is a child of C<Animal>,
and C<Dog> can use C<Animal>'s methods.

=item abstract, concrete

A class is I<abstract> when C<Class::Abstract> is in its B<own> C<@ISA>.
All other classes are I<concrete> (normal).

=item invocant

The value on the left of the arrow in a method call.  In
C<< Dog->new >> the invocant is the string C<'Dog'>.  In
C<< $rex->speak >> the invocant is the object C<$rex>.

=item croak, die

Stop the program (or the current C<eval> block) with an error message.

=item bypass

A setting that turns the check off.  See L</Turning the check off>.

=item test harness

The program that runs test files, for example C<prove> or C<make test>.
It sets the environment variable C<HARNESS_ACTIVE>.

=back

=head2 How to make a class abstract

Put C<Class::Abstract> in the class's own C<@ISA>.  There are two ways:

    package Animal;
    use parent 'Class::Abstract';    # way 1 (recommended)

    package Vehicle;
    use Class::Abstract;             # way 2

Both ways have the same result.

=head2 How the check works

C<Class::Abstract> gives every class below it a method called C<new()>.
When C<new()> runs, it looks at the invocant (the class name on the left
of the arrow).  If that class has C<Class::Abstract> in its B<own>
C<@ISA>, C<new()> dies.  If not, C<new()> makes and returns an empty
object.

This is why child classes work.  When C<Dog> calls
C<< $class->SUPER::new >>, the invocant is still C<'Dog'>, not
C<'Animal'>.  C<Dog> does not have C<Class::Abstract> in its own C<@ISA>,
so the check passes.

=head2 Only the class that asks is abstract

Being abstract is B<not> passed down to child classes.  If you want an
abstract class below another abstract class, list C<Class::Abstract> in
that class too:

    package Animal;   use parent 'Class::Abstract';               # abstract
    package Mammal;   use parent 'Class::Abstract', 'Animal';     # also abstract
    package Dog;      use parent -norequire, 'Mammal';            # concrete

=head2 Turning the check off

Sometimes a test needs an object of an abstract class.  Two settings turn
the check off.  If B<either> one is on, the check is off.

=over 4

=item 1. The variable C<$Class::Abstract::BYPASS>

Set it to a true value.  Always use C<local>, so the setting ends at the
end of the block:

    my $animal = do { local $Class::Abstract::BYPASS = 1; Animal->new };

=item 2. The setting C<harness_bypass> together with a test harness

If C<< $Class::Abstract::config{harness_bypass} >> is true B<and> the
environment variable C<HARNESS_ACTIVE> is true, the check is off.
C<harness_bypass> is false by default, so the check is B<on> in your
tests unless you change it.

=back

C<$BYPASS> is checked first.  If C<$BYPASS> is true, setting
C<harness_bypass> to 0 does B<not> turn the check back on.

B<Changed in version 0.03:> before 0.03, C<harness_bypass> was 1 by
default.  That meant the check was B<off> in every test suite.  To get
the old behaviour back, put this near the top of your test files:

    $Class::Abstract::config{harness_bypass} = 1;

=cut

our $VERSION = '0.03';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Self-referential constant: the canonical name of this package.
Readonly::Scalar my $SELF => __PACKAGE__;

# Return::Set schema for import(): it always hands back the class name.
Readonly::Scalar my $IMPORT_SCHEMA => { type => 'string' };

# Every message this module can raise, in one place.  Keys are
# "<routine>:<condition>" so _resolve_class() can build them from the
# routine name.  The text is part of the public contract (see MESSAGES):
# callers and tests match on it, so change it only in a major release.
Readonly::Hash my %MESSAGE => (
	'abstract'              => 'Cannot instantiate abstract class %s directly',
	'new:unblessed'         => 'new() invocant must be a class name or blessed object, got %s',
	'new:undef'             => 'new() requires a defined class name as invocant',
	'check:unblessed'       => 'check_abstract() requires a class name or blessed object, got %s',
	'check:undef'           => 'check_abstract() requires a defined class name',
	'is_abstract:unblessed' => 'is_abstract() requires a class name or object invocant, got %s',
	'is_abstract:undef'     => 'is_abstract() requires a class name or object invocant',
	'internal:key'          => 'Class::Abstract internal error: unknown message key %s',
);

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

# Set to a true value to suppress all abstract-class croaks globally.
# Always use 'local' in tests to prevent state from bleeding between cases.
our $BYPASS = 0;

# Runtime tunables.  Modify $config{harness_bypass} to control whether
# HARNESS_ACTIVE suppresses enforcement.
our %config = (
	# 1 = suppress croaks when HARNESS_ACTIVE is set.  Off by default (since
	# 0.03) so that test suites catch accidental abstract instantiation.
	harness_bypass => 0,
);

# ---------------------------------------------------------------------------
# PUBLIC INTERFACE
# ---------------------------------------------------------------------------

=head1 METHODS

=head2 import

    use Class::Abstract;

Perl calls C<import()> for you when you write C<use Class::Abstract;>.
You do not normally call it yourself.

It makes the package that contains the C<use> line abstract.  It does
this by adding C<'Class::Abstract'> to that package's C<@ISA>.  The
result is the same as C<use parent 'Class::Abstract'>.

=head3 ARGUMENTS

None that you pass yourself.  Perl passes the string
C<'Class::Abstract'> as the first argument.  Anything in an import list
(for example C<use Class::Abstract qw(x y)>) is ignored.

=head3 RETURNS

The string C<'Class::Abstract'>.  C<use> throws this value away, so you
only see it if you call C<< Class::Abstract->import >> yourself.

=head3 SIDE EFFECTS

Adds C<'Class::Abstract'> to the end of the calling package's C<@ISA>.
It does B<nothing> in these cases:

=over 4

=item * C<'Class::Abstract'> is already in that C<@ISA>.  So writing
C<use Class::Abstract;> twice is safe.

=item * The calling package is C<Class::Abstract> itself.  A class cannot
be its own parent.

=item * Perl cannot tell which package is calling (this can happen in
unusual code, such as a C<BEGIN> block inside a string C<eval>).  Without
this rule, the module would change C<@main::ISA> by mistake.

=back

It does not change the global variables C<$_>, C<$@> or C<$!>, and it
does not touch an C<alarm()> timer.  (Before version 0.03 it cleared
C<$@>.)

=head3 EXAMPLE

    package Vehicle;
    use Class::Abstract;          # @Vehicle::ISA is now ('Class::Abstract')
    use Class::Abstract;          # no change: it is already there

    package Car;
    our @ISA = ('Vehicle');       # Car is concrete

    package main;
    my $car = Car->new;           # works
    Vehicle->new;                 # dies

To load the module B<without> making the current package abstract, pass
an empty list.  Perl then does not call C<import()>:

    use Class::Abstract ();       # main is NOT made abstract

=head3 API SPECIFICATION

=head4 Input

    {
        class => { type => 'string', optional => 0 },   # always 'Class::Abstract'
    }

=head4 Output

    {
        type => 'string',
    }

=head3 MESSAGES

None.  C<import()> never dies and never warns.

=cut

sub import {
	my ($class) = @_;
	my $caller  = caller;

	# Register the caller only when it is a real package other than this one
	# and is not already registered (keeps repeated 'use' idempotent).
	# The defined/length guard stops '' from resolving to @main::ISA.
	if (defined($caller) && length($caller) && ($caller ne $SELF) && !_is_direct_abstract($caller)) {
		# Writing another package's @ISA needs a symbolic reference.
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		push @{"${caller}::ISA"}, $SELF;
	}

	# set_return() validates through code that clears $@, which would wipe
	# an error the caller has not looked at yet.  Restore it afterwards.
	# (Not "local $@": on Perl < 5.14 that can lose a propagating die.)
	my $saved_error = $@;
	my $result      = set_return($class, $IMPORT_SCHEMA);
	$@ = $saved_error;    ## no critic (RequireLocalizedPunctuationVars)

	return $result;
}

=head2 new

    my $obj  = ConcreteClass->new;
    my $obj  = ConcreteClass->new(name => 'Rex');   # arguments are ignored
    my $copy = $obj->new;                           # new, empty object of the same class

Makes a new, empty object, but only for a concrete class.

=over 4

=item * If the class is abstract, C<new()> dies with an error message.

=item * If the class is concrete, C<new()> returns an empty hash
reference blessed into that class.

=back

Child classes usually call this through C<< $class->SUPER::new >> from
their own C<new()>.  That works because the check looks at the class name
on the left of the arrow (the child), not at the class where C<new()> is
written.

=head3 ARGUMENTS

=over 4

=item C<$invocant> (required)

The class name or object on the left of the arrow.  In C<< Dog->new >>
it is the string C<'Dog'>.  If it is an object, the object's class is
used.  It must not be C<undef>, the empty
string, or a reference that is not an object (such as C<[]> or C<{}>).

=item C<%args> (optional)

Any other arguments.  They are accepted and B<ignored>.  This lets a
child class pass its arguments to C<SUPER::new> without errors.  The
child class must store its own data after C<SUPER::new> returns.

=back

=head3 RETURNS

A new, empty hash reference, blessed into the class.

=head3 SIDE EFFECTS

None, except that C<bless> creates the package in Perl's symbol table if
it did not exist yet.  (The check itself never creates a package.)

It does not change the global variables C<$_>, C<$@> or C<$!>, and it
does not touch an C<alarm()> timer.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

    {
        invocant => {
            type     => 'string|object',   # class name, or an object of that class
            optional => 0,
            min      => 1,                 # a name must not be empty
        },
    }

=head4 Output

    {
        type => 'object',                  # a hashref blessed into the class
    }

=head3 MESSAGES

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

=cut

sub new {
	my ($invocant) = @_;

	# Validate the invocant, then refuse abstract classes; both helpers
	# croak on failure so reaching bless means the class is instantiable.
	my $class = _resolve_class('new', $invocant);
	_enforce($class);

	return bless {}, $class;
}

=head2 check_abstract

    Class::Abstract::check_abstract($class);

Runs the same check as C<new()>, but does not make an object.

Use it when your abstract class writes its B<own> C<new()> and that
C<new()> does not call C<< $class->SUPER::new >>.  In that case
C<Class::Abstract::new()> never runs, so nothing checks the class.  Call
C<check_abstract()> as the first line of your C<new()> to put the check
back.

=head3 ARGUMENTS

=over 4

=item C<$invocant> (required)

The class to check: a class name (a string) or an object.  If it is an
object, the object's class is used.  In your own C<new()>, pass the
C<$class> variable.  It must not be C<undef>, the empty string, or a reference
that is not an object.

=back

=head3 RETURNS

Nothing if the class is concrete or a bypass is on: C<undef> in scalar
context, or an empty list in list context.  Otherwise it dies.

=head3 SIDE EFFECTS

None.  It obeys C<$BYPASS> and C<harness_bypass> in exactly the same way
as C<new()>.

It does not change the global variables C<$_>, C<$@> or C<$!>, and it
does not touch an C<alarm()> timer.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

    {
        invocant => {
            type     => 'string|object',
            optional => 0,
            min      => 1,
        },
    }

=head4 Output

    {
        type => 'undef',
    }

=head3 MESSAGES

    Message                                   What it means / What to do
    -------                                   --------------------------
    Cannot instantiate abstract class CLASS   The same as for new().
      directly

    check_abstract() requires a class name    The argument was a reference that is
      or blessed object, got TYPE             not an object.  Pass $class or $self.

    check_abstract() requires a defined       The argument was undef or ''.  This
      class name                              usually means "my $class = shift;"
                                              is missing from your new().

=cut

sub check_abstract {
	my ($invocant) = @_;

	# Same rules as new(), minus the bless: the caller builds the object.
	_enforce(_resolve_class('check', $invocant));

	return;
}

=head2 is_abstract

    my $yes_or_no = SomeClass->is_abstract;
    my $yes_or_no = $obj->is_abstract;
    my $yes_or_no = Class::Abstract->is_abstract('SomeClass');
    my $yes_or_no = Class::Abstract->is_abstract($obj);

Tells you whether a class is abstract.  It returns C<1> (yes) or C<0>
(no).

A class is abstract only when C<Class::Abstract> is in its B<own>
C<@ISA>, or when the class B<is> C<Class::Abstract>.  A child of an
abstract class is B<not> abstract, so C<is_abstract()> returns C<0> for
it.

Every class below C<Class::Abstract> can call this method.

=head3 ARGUMENTS

=over 4

=item C<$self>

Required.  The class name or object on the left of the arrow.  If no target is given (see
below), this is the class that is checked.

=item C<$target> (optional)

A class name or an object to check B<instead of> the invocant.  This is
how you ask about any class: C<< Class::Abstract->is_abstract('Dog') >>.
If C<$target> is C<undef>, it is treated as "not given".

=back

=head3 RETURNS

The integer C<1> if the class is abstract, otherwise the integer C<0>.

A class name that does not exist (for example, a spelling mistake) gives
C<0>, not an error.

=head3 SIDE EFFECTS

None.  Asking about a class that does not exist does B<not> create it.

It does not change the global variables C<$_>, C<$@> or C<$!>, and it
does not touch an C<alarm()> timer.

=head3 EXAMPLE

    Animal->is_abstract;                         # 1
    Dog->is_abstract;                            # 0

    my $rex = Dog->new(name => 'Rex');
    $rex->is_abstract;                           # 0 (asks about Dog)

    Class::Abstract->is_abstract('Animal');      # 1
    Class::Abstract->is_abstract($rex);          # 0 (asks about Dog)
    Class::Abstract->is_abstract('Anmial');      # 0 (spelling mistake: no such class)

=head3 API SPECIFICATION

=head4 Input

    {
        self   => { type => 'string|object', optional => 0, min => 1 },
        target => { type => 'string|object', optional => 1, min => 1 },
    }

=head4 Output

    {
        type => 'integer',
        min  => 0,
        max  => 1,
    }

=head3 MESSAGES

    Message                                   What it means / What to do
    -------                                   --------------------------
    is_abstract() requires a class name or    The class to check was a reference
      object invocant, got TYPE               that is not an object.

    is_abstract() requires a class name or    The class to check was undef or ''.
      object invocant

=cut

sub is_abstract {
	my ($self, $target) = @_;

	# An explicit target (Class::Abstract->is_abstract('Foo') or ($obj))
	# wins; otherwise check the invocant itself.  Both go through the same
	# resolver, so an object argument is checked by its class, not by its
	# stringification ('Foo=HASH(0x...)').
	my $class = _resolve_class('is_abstract', defined($target) ? $target : $self);

	return _is_direct_abstract($class);
}

# ---------------------------------------------------------------------------
# PRIVATE SUBROUTINES
#
# Not exported and not part of the API.  The white-box tests (t/function.t,
# t/edge_cases.t, t/mutant_killers.t) call and spy on them directly, which
# is why they are plain named subs called by name: a spy installed on the
# glob is then seen by every caller.
# ---------------------------------------------------------------------------

# _fail
# Purpose      : The single place this module raises an error, so message
#                text lives only in %MESSAGE.
# Entry        : $key  -- a key of %MESSAGE.
#                @args -- sprintf arguments for that message.
# Exit status  : Never returns.
# Side effects : Throws via croak.  Every frame between here and the user
#                is in this package (or a subclass), so Carp reports the
#                user's line, not ours.
# Notes        : A Readonly hash returns undef for a missing key rather
#                than dying, so a mistyped key would croak with an empty
#                message.  Report the bad key instead.
sub _fail {
	my ($key, @args) = @_;

	my $template = $MESSAGE{$key};
	($template, @args) = ($MESSAGE{'internal:key'}, $key) unless defined $template;

	croak sprintf($template, @args);
}

# _resolve_class
# Purpose      : Turn an invocant into a validated class name, applying one
#                set of rules for every public routine.
# Entry        : $routine  -- message-key prefix: 'new', 'check' or
#                             'is_abstract'.
#                $invocant -- class name, blessed object, or junk.
# Exit status  : Returns a defined, non-empty class-name string.
#                Croaks if $invocant is an unblessed reference, undef or ''.
# Side effects : None.
# Notes        : blessed() is tested with defined(), not truth, because an
#                object blessed into package '0' has blessed() eq '0'
#                (and ref() eq '0'), which plain truth tests misread.
sub _resolve_class {
	my ($routine, $invocant) = @_;

	# An object stands in for its class.  Any other reference is a caller
	# error, never a class name.
	my $pkg = blessed($invocant);
	if (defined $pkg) {
		$invocant = $pkg;
	} elsif (ref $invocant) {
		_fail("${routine}:unblessed", ref $invocant);
	}

	# undef cannot name a package, and '' would silently mean main::.
	_fail("${routine}:undef") unless defined($invocant) && length($invocant);

	return $invocant;
}

# _bypass_active
# Purpose      : Decide whether enforcement is switched off.
# Entry        : None (reads $BYPASS, %config, $ENV{HARNESS_ACTIVE}).
# Exit status  : 1 if any bypass applies, else 0.
# Side effects : None.
# Notes        : $BYPASS is checked first and short-circuits, so it wins
#                over harness_bypass (documented under LIMITATIONS).
sub _bypass_active {
	return ($BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE})) ? 1 : 0;
}

# _enforce
# Purpose      : Croak if $class is directly abstract and no bypass is on.
# Entry        : $class -- an already-validated class name.
# Exit status  : Returns $class on success; croaks otherwise.
# Side effects : None.
# Notes        : The bypass test runs first so that, with a bypass on,
#                _is_direct_abstract() is never called.  t/function.t
#                counts those calls, so keep this order.
sub _enforce {
	my ($class) = @_;
	_fail('abstract', $class) if !_bypass_active() && _is_direct_abstract($class);
	return $class;
}

# _direct_isa
# Purpose      : Return a package's own @ISA without creating the package.
#                The obvious @{"${class}::ISA"} autovivifies the stash, so a
#                mere is_abstract('Typo::Name') would conjure an empty
#                package into existence.
# Entry        : $class -- package name string.  '' means main::.
# Exit status  : An arrayref.  It is the live @ISA if the package and its
#                @ISA exist, otherwise a new empty arrayref.
# Side effects : None.  The symbol table is only read, never written.
# Notes        : The old "'" package separator (Foo'Bar) is not recognised.
sub _direct_isa {
	my ($class) = @_;

	# Walk the stash tree one '::' segment at a time from main::.  Empty
	# segments (from '::Foo' or 'Foo::') are skipped, as Perl skips them.
	# A stash entry may hold a non-glob (e.g. an optimised constant), so
	# check that each entry really is a glob before dereferencing it.
	my $stash = \%main::;
	foreach my $segment (grep { length } split /::/, $class) {
		my $glob = $stash->{"${segment}::"};
		$stash = (defined($glob) && ref(\$glob) eq 'GLOB') ? *{$glob}{HASH} : undef;
		last unless $stash;
	}

	# The package exists only if every segment resolved.  *ISA{ARRAY} is
	# undef until @ISA is first used, so fall back to an empty list.
	my $isa = $stash ? $stash->{ISA} : undef;
	return (defined($isa) && ref(\$isa) eq 'GLOB' && *{$isa}{ARRAY}) || [];
}

# _is_direct_abstract
# Purpose      : Decide whether a class is directly abstract: it is
#                Class::Abstract, or Class::Abstract is in its own @ISA.
# Entry        : $class -- package name string, or undef.
# Exit status  : Exactly 1 or 0 (never undef or ''); the mutation tests in
#                t/mutant_killers.t rely on these exact integers.
# Side effects : None.  $_ is localised by grep.
# Notes        : Intentionally shallow: a subclass of an abstract class is
#                concrete unless it opts in too.  Undefined @ISA elements
#                are skipped so that they do not warn.
sub _is_direct_abstract {
	my ($class) = @_;

	# undef names nothing; Class::Abstract itself must never be built;
	# anything else is abstract iff we sit directly in its @ISA.
	my $abstract = !defined($class)  ? 0
		: ($class eq $SELF)       ? 1
		: (grep { defined($_) && ($_ eq $SELF) } @{ _direct_isa($class) }) ? 1
		: 0;

	return $abstract;
}

1;

__END__

=head1 PUBLIC VARIABLES

=head2 $Class::Abstract::BYPASS

Default: C<0>.

When this is true, the check is off for B<every> class.  Always change
it with C<local>, so that it goes back to its old value at the end of the
block:

    {
        local $Class::Abstract::BYPASS = 1;
        my $animal = Animal->new;    # works, even though Animal is abstract
    }
    Animal->new;                     # dies again

Any true value turns the check off.  This includes strings that look
false to a person, such as C<"false">, C<"no"> and C<"0E0">.

=head2 %Class::Abstract::config

Settings for the module.  It has one key.

=over 4

=item harness_bypass

Default: C<0>.

When this is true B<and> the environment variable C<HARNESS_ACTIVE> is
true, the check is off.  C<HARNESS_ACTIVE> is set by test harnesses such
as C<prove> and C<make test>.

The default was C<1> before version 0.03.  Set it to C<1> to get the old
behaviour back.

=back

=head1 ERROR MESSAGES

This is the full list of messages that the module can produce.  The text
is always plain English.  It does not change with the locale.  Each
message ends with the file and line number of B<your> code, for example
C<at script.pl line 12.>

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

CLASS is the class name.  TYPE is the kind of reference, such as
C<ARRAY>, C<HASH> or C<CODE>.

=head1 COMMON PITFALLS

=over 4

=item Your own new() skips the check

If an abstract class writes its own C<new()> and creates the object
with C<bless>, C<Class::Abstract::new()> never runs.  Nothing stops
C<< Shape->new >>.  Fix: call
C<Class::Abstract::check_abstract($class)> on the first line, or build
the object with C<< $class->SUPER::new >>.

=item The order of parents matters

Perl uses the B<first> C<new()> it finds, reading C<@ISA> from left to
right.  In C<use parent 'Animal', 'Class::Abstract'>, Perl finds
C<Animal::new> first, if C<Animal> has one.  If that C<new()> does not
call C<check_abstract()>, there is no check.

=item Child classes are not abstract automatically

C<Mammal> below the abstract class C<Animal> is B<concrete> unless
C<Mammal> also lists C<Class::Abstract> in its own C<@ISA>.

=item "use Class::Abstract;" changes the current package

C<use Class::Abstract;> makes the package it is written in abstract.  If
you write it in a script only to call C<is_abstract()>, the C<main>
package becomes abstract.  Write C<use Class::Abstract ();> instead.
With the empty list, Perl does not call C<import()>.  The same is true
for C<require Class::Abstract;>: it does B<not> make any class abstract.

=item undef and empty strings

C<< Class::Abstract::new(undef) >>, C<new('')> and the same calls to
C<check_abstract()> and C<is_abstract()> die.  But an C<undef>
B<target> in C<< $obj->is_abstract(undef) >> is treated as "no target",
so the invocant is checked.

=item Spelling mistakes give 0, not an error

C<< Class::Abstract->is_abstract('Anmial') >> returns C<0>, because no
package with that name has C<Class::Abstract> in its C<@ISA>.  Check
the spelling if you get C<0> when you expect C<1>.

=item A bypass without "local" never ends

C<$Class::Abstract::BYPASS = 1;> without C<local> turns the check off
for the rest of the program, in every file.

=item Strings that look false are true

C<$BYPASS = 'false'> and C<$BYPASS = 'no'> turn the check B<off>,
because Perl treats every non-empty string except C<'0'> as true.  Use
C<1> and C<0>.

=item $BYPASS wins over harness_bypass

If C<$BYPASS> is true, setting C<harness_bypass> to C<0> does not turn
the check on.  To be sure the check is on, set both:

    local $Class::Abstract::BYPASS                 = 0;
    local $Class::Abstract::config{harness_bypass} = 0;

=item Tests that passed before 0.03 may now die

Before version 0.03 the check was off inside a test harness.  If your
tests make objects of abstract classes, they will now die.  See
L</Turning the check off>.

=item isa() is not the same as is_abstract()

C<< Dog->isa('Class::Abstract') >> is true, because C<Class::Abstract>
is a grandparent of C<Dog>.  Use C<< Dog->is_abstract >> to ask whether
C<Dog> itself is abstract.

=item new() throws away its arguments

C<< Dog->SUPER::new(name => 'Rex') >> does not store C<name>.  Store it
yourself after C<SUPER::new> returns.

=item Objects made during a bypass stay abstract

An object made while the bypass was on still belongs to the abstract
class.  Calling C<< $obj->new >> on it later, with the check on, dies.

=back

=head1 ENCODING

The module does not read files, the terminal or the network.  The only
text it handles is class names, and the error messages that contain them.

=over 4

=item Class names

Class names may contain any characters that Perl allows in a package
name.  This includes non-ASCII letters (C<CafE<eacute>>, Japanese,
Chinese) and, for names made with C<bless> or symbolic references, emoji.
The module compares names exactly, character by character.

Two conditions apply:

=over 4

=item * Non-ASCII package names need Perl 5.16 or later.  The rest of
the module works on Perl 5.8.

=item * The name must be a B<character string>, not raw UTF-8 bytes.
Names written in source code under C<use utf8;> are character strings.
Names read from a file or the network must be decoded first (for example
with L<Encode/decode>).  A name that is still raw bytes is a B<different>
name to Perl, so C<is_abstract()> returns C<0> for it.

=back

=item Error messages

The fixed text of every message is plain ASCII English.  A message also
contains the class name, so it can contain non-ASCII characters.  If you
print such a message to a file handle that has no encoding layer, Perl
warns C<Wide character in print>.  Add a layer to avoid this:

    binmode STDERR, ':encoding(UTF-8)';

=item Settings

C<$BYPASS>, C<harness_bypass> and C<HARNESS_ACTIVE> are only tested for
true or false.  Their text is never used.

=back

=head1 LIMITATIONS

=over 4

=item Only the check in new() and check_abstract() protects a class

Code can still make an object of an abstract class with
C<bless {}, 'Animal'>, with L<Storable/dclone>, with C<thaw>, or with a
C<new()> that forgets to call C<check_abstract()>.  The check is a rule
that the module follows when it is asked.  It is not built into Perl.

=item can('new') returns a method that dies

C<< Animal->can('new') >> returns C<\&Class::Abstract::new>.  This looks
like "yes, you can call new()".  You can call it, but it dies.

=item The bypass is global

C<$BYPASS> turns the check off for every class, not only for the class
that a test is about.

=item The old package separator is not supported

Perl once allowed C<'> between parts of a package name (C<Foo'Bar>
meaning C<Foo::Bar>).  This module does not convert C<'> to C<::>, so
such names are treated as concrete.

=item Threads

The module shares no data between threads, except C<$BYPASS> and
C<%config>, which are normally only read.  C<import()> changes the
caller's C<@ISA>, usually when the program is compiled.  This is safe if
modules are not loaded with C<require> from several threads at once.

=item Not for Moo or Moose

Moo and Moose have their own ways to make abstract classes and required
methods.  This module is for plain Perl classes.

=back

=head1 DEPENDENCIES

L<Carp> (part of Perl),
L<Scalar::Util> (part of Perl),
L<Readonly>,
L<Return::Set>.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Class-Abstract/coverage/>

=item * L<Sub::Abstract>

Makes child classes write certain methods.  Use it together with
C<Class::Abstract> for a complete abstract base class.

=item * L<Sub::Private>

Makes a method callable only from its own class.

=item * L<Sub::Protected>

Makes a method callable only from its own class and its child classes.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf8

=head1 FORMAL SPECIFICATION

This section describes the module in the Z notation.  You do not need to
read it to use the module.

=head2 Definitions

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

=head2 import

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

=head2 new

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

=head2 check_abstract

    ┌─ CheckAbstract ───────────────────────────────────────
    │ ΞRegistry
    │ inv?    : Package ∪ Object
    │ result! : {⊥}
    ├───────────────────────────────────────────────────────
    │ ¬is_direct_abstract(resolve(inv?)) ∨ bypass_active
    │ result! = ⊥
    └───────────────────────────────────────────────────────

    CheckAbstractOp ≙ CheckAbstract ∨ NewAbstract ∨ BadInvocant

=head2 is_abstract

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

=head1 STATE DIAGRAM

The module has two independent kinds of state: the state of B<each
class>, and the global B<check mode>.

=head2 Class states

Every package is in exactly one of these states:

    MISSING    The package does not exist yet.
    PLAIN      The package exists.  Class::Abstract is not one of its
               ancestors, so it has no new() from this module.
    ABSTRACT   'Class::Abstract' is in the package's own @ISA.
    CONCRETE   The package inherits from an abstract class, but
               'Class::Abstract' is not in its own @ISA.

Transitions:

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

Calls that never change a class's state:

    P->is_abstract, Class::Abstract->is_abstract('P')   any state  -> same state
    Class::Abstract::check_abstract('P')                any state  -> same state
    use Class::Abstract;  (again, in P)                 ABSTRACT   -> ABSTRACT

=head2 Check mode

    +-----------+   local $Class::Abstract::BYPASS = 1               +----------+
    |           | -------------------------------------------------> |          |
    | ENFORCING |   $config{harness_bypass} = 1 while HARNESS_ACTIVE | BYPASSED |
    |           |   HARNESS_ACTIVE set while harness_bypass is 1     |          |
    |           | <------------------------------------------------- |          |
    +-----------+   end of the block with "local"                    +----------+
                    $BYPASS false AND (harness_bypass false
                    OR HARNESS_ACTIVE false)

    Start state: ENFORCING  ($BYPASS = 0, harness_bypass = 0).

=head2 What new() and check_abstract() do in each state

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

No call changes the check mode except the assignments shown above.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
