
#Time-stamp: "2004-12-29 20:13:16 AST"

require 5;
package Class::Classless;
use strict;
use vars qw($VERSION @ISA $Debug $ROOT %Pretty_form);
use Carp;

$VERSION = "1.35";
@ISA = ();
$Debug = 0 unless defined $Debug;

###########################################################################

=head1 NAME

Class::Classless -- framework for classless OOP

=head1 SYNOPSIS

  use strict;
  use Class::Classless;
  my $ob1 = $Class::Classless::ROOT->clone;
  $ob1->{'NAME'} = 'Ob1';
  $ob1->{'stuff'} = 123;
  $ob1->{'Thing'} = 789;
  
  my $ob2 = $ob1->clone;
  $ob2->{'NAME'} = 'Ob2';
  
  printf "ob1 stuff: <%s>\n", $ob1->{'stuff'};
  printf "ob2 stuff: <%s>\n", $ob2->{'stuff'};
  printf "ob1 Thing: <%s>\n", $ob1->{'Thing'};
  printf "ob2 Thing: <%s>\n", $ob2->{'Thing'};
  
  $ob1->{'METHODS'}{'zaz'} =  sub {
     print "Zaz! on ", $_[0]{'NAME'}, "\n";
  };
  
  $ob1->zaz;
  $ob2->zaz;
  $ob1->EXAMINE;
  $ob2->EXAMINE;

This prints the following:

    ob1 stuff: <123>
    ob2 stuff: <123>
    ob1 Thing: <789>
    ob2 Thing: <>
    Zaz! on Ob1
    Zaz! on Ob2
    <Class::Classless::X=HASH(0x200236f4)>
       'stuff', 123, 
       'NAME', 'Ob1', 
       'Thing', 789, 
       'METHODS', { 'zaz', 'CODE(0x20068360)' }, 
       'PARENTS', [ 'ROOT' ], 
    <Class::Classless::X=HASH(0x2002cb48)>
       'stuff', 123, 
       'NAME', 'Ob2', 
       'METHODS', {  }, 
       'PARENTS', [ 'Ob1' ], 

=head1 DESCRIPTION

In class-based OOP frameworks, methods are applicable to objects by
virtue of objects belonging to classes that either provide those
methods, or inherit them from classes that do.

In classless OOP frameworks (AKA delegation-and-prototypes
frameworks), what methods an object is capable of is basically an
attribute of that object.  That is, in Perl terms: instead of methods
being entries in the symbol table of the package/class the object
belongs to, they are entries in a hash table inside the object.
Inheritance is implemented not by having classes inheriting from other
classes (via ISA lists), but by having objects inherit from other
objects (via PARENTS lists).

In class-based OOP frameworks, you get new objects by calling
constructors.  In a classless framework, you get new objects by
copying ("cloning") an existing object -- and the new clone becomes a
child (inheritor) of the original object.  (Where do you get the one
original object?  The language provides one, which has no parents, and
which contains some general purpose methods like "clone".)

=head1 WHAT'S IN AN OBJECT

Each classless object is a reference to a hash, containing:

* an entry 'PARENTS', which is a reference to a list of this node's
parents.  (For ROOT, this will be an empty list; for most nodes, there
will be just one item in this list; with multiple parents, you get
multiple inheritance.)

* An entry 'NAME', which is initialized to a unique value (like
"x_11") when the object has just been created by cloning.  The 'NAME'
attribute is not required, and deleting it is harmless.

* An entry 'METHODS', which is a reference to a hash that maps method
names (e.g., "funk") to coderefs or to constant values.  When you
call $foo->funk(@stuff), Class::Classless's dispatcher looks to see if
there's a $foo->{'METHODS'}{'funk'}.  If so, and if it's a coderef, then
that coderef is called with ($foo, $callstate, @stuff) as its
parameter list  (See the section "What A Method Sees", below, for
an explanation of this).  If
there's a $foo->{'METHODS'}{'funk'} and it's I<not> a coderef, then the
value is returned, possibly with automagical dereferencing.  (See the
section "Constant Methods", below.)  But, finally, if there is no such
method, Class::Classless's dispatcher looks in $foo's parent to see
if there's a $foo_parent->{'METHODS'}{'funk'}, and so on up the
inheritance tree.  If no 'funk' method is found in $foo or any of
$foo's ancestors, Class::Classless dies with an error to that effect.
(But see the section on the NO_FAIL attribute, below.)

* Anything else you want to put in the hash.  I provide no inherent
mechanism for accessing attributes (unlike, say, Self, which can
automagically treat method calls as accessors, roughly speaking), so
you're down to setting with $a->{'foo'} = VAL, reading with
$a->{'foo'}, and possibly testing for the attribute with an
exists($a->{'foo'}).  (However, do have a look at the C<get_i>,
C<set_i>, and C<exists_i> methods, below.)

=head2 METHODS IN ROOT

ROOT provides various methods you might find helpful:

* $thing->clone -- makes a new object based on an existing one.  The
only way you get to produce new objects is to clone existing ones.
Existing objects are either clones of ROOT, or clones of clones of
ROOT, and so on.  A newly cloned object has a copy of all its parent's
attributes whose names don't match /^[A-Z]/s (i.e., that don't begin
with a letter between ASCII capital A and ASCII capital Z, inclusive).
The new object is then initialized with a per-session-unique name like
"x_12"; its PARENT attribute is set to a list containing its one
parent; and its 'METHODS' attribute is set to an empty hash.  (Note
that the copying of parent attributes is B<not> a deep copy -- the
parent has foo => [bar, baz], then the child will have a reference to
that same list, B<not> a copy of that list!)

(Also, if $thing->is_lineage_memoized is true, the clone will have a
memoized lineage too.  And note that $Class::Classless::ROOT has
lineage memoization off.  See the description of
"$thing->memoize_lineage", below, for a description of what this all
means.)

* $thing->polyclone($thing2, $thing3...) -- makes a new object based
on $thing, $thing2, $thing3, etc.  Attributes in $thing overrride
those in $thing2, and so on.  The PARENTS list will consist of $thing,
$thing2, $thing3, etc., in that order.  
Also, if $thing->is_lineage_memoized is true, the clone will have
a memoized lineage too.

* $thing->get_i('attrib') -- ("get, with inheritance").
$thing->get_i('foo') returns the value of the 'foo' attribute for
$thing.  If there is no $thing->{'foo'}, it looks for a 'foo'
attribute in each of $thing's ancestors.  Returns the first one found.
If none are found, returns undef.  (But note that undef could result
if $thing->{'foo'} or $some_parent->{'foo'} is undef.)

* $thing->exists_i('attrib') -- ("exists, with inheritance").
$thing->exists('foo') returns true if either $thing or any of its
ancestors contains a 'foo' attribute (as tested with simply
exists($node->{'foo'})).  Otherwise, returns false.

* $thing->put_i('attrib', VALUE) -- ("put, with inheritance").  put_i
looks across $thing and its ancestors, and for the first one that
contains an 'attrib' attribute, sets its value to VALUE, and then
returns VALUE.  If neither $thing nor any of its ancestors contain a
'attrib' attribute, this will set $thing->{'attrib'} = VALUE and
return VALUE, but will warn (via C<carp>) if $^W (warnings, usually
from giving Perl a C<-w> switch) is true.

* $thing->EXAMINE -- prints a somewhat simpleminded dump of the
contents of the object.  Like a cheapo version of Data::Dumper's
Dump() function.

* $thing->FLATTEN -- deletes all attributes (and their values) in the
object whose names do not match /^[A-Z]/s (i.e., whose names don't
begin with a letter between ASCII capital A and ASCII capital Z,
inclusive).  You can use this if you don't need an object's data, but
don't feel bold enough to destroy it, because it may have
clone-children that would be orphaned (a bad thing) if this node lost
its PARENT attribute, say.

* $thing->allcan('baz') -- returns the list (in order) of all 'baz'
methods in $thing's ISA tree.  This may be an empty list.  (Note that
the NO_FAIL attribute has no effect on the allcan method.)
Note especially that the magic dereferencing magic for constant
method values is not triggered.  That is, what allcan('baz') returns is
simply a list of the values of $x->{'METHODS'}{'baz'} wherever such
a METHODS entry exists, for all objects in $thing's inheritance tree.

* $thing->howcan('baz') -- just like allcan, but the list returned
consists of pairs of values, where each pair consists of 1) the object
that provides the 'baz' method, followed by 2) the value it provides
for that method.  (Remember that that value may be a coderef, or it
may be any kind of other reference (which will I<not> be magically
resolved as it would have been by the dispatcher -- see the section
"Constant Methods", or it may be any nonreference scalar value --
including 0 or undef!)  The pairs are in order.  You can read this
list into a hash that maps from the methods to the method-values, but
of course then you lose the ordering.

* $thing->can('baz') -- if $thing is capable of the method 'baz', this
returns true, otherwise it returns false.  Do not try to override the
can method.  (Note that the NO_FAIL attribute has no effect on the
can method.)  Note also that this does NOT return the method's value,
as it did in the first version of Class::Classless, which (like Perl's
normal object system) would return the (coderef) value of the method
'baz' for the first object in $thing's tree that provided such a
method.

That worked then, since all method values under the first version
of Class::Classless had to be coderefs (which were, of course, true
in a boolean context).  However, now that a Class::Classless
method have have a constant value that is false, having can() return
that value would be indistinguishable from having it return any
false value meant as a signal the object incapable of the method.
In short, can() simply has to return either true or false now.  If
you need the value of the methods, use allcan() or howcan().

* $thing->VERSION -- same as $thing->get_i('VERSION').  Note that ROOT
has an entry of 'VERSION' => '0.00'.  Do not try to override the
VERSION method.

* $thing->VERSION(version_number) -- dies if $thing->VERSION is
less than version_number.  Otherwise returns $thing->VERSION.

* $thing->isa($thing2) -- returns true if $thing2 is in $thing's ISA
tree -- i.e., if it's an ancestor of $thing.  (Also returns true if
$thing2 B<is> $thing.)  Otherwise returns false.  Do not try to
override the isa method.

* $thing->ISA_TREE -- returns $thing's ISA tree, linearized -- i.e.,
the list of nodes, in order, starting with $thing (and presumably
ending with $ROOT), that you would search thru for method calls on
$thing, or get_i calls on $thing.  Do not try to override the ISA_TREE
method.

* $thing->memoize_lineage -- makes this object eligible for having its
ISA_TREE cached.  Normally, every method call on an object causes the
routine ISA_TREE to be called, so that Class::Classless knows where to
look for methods, and in what order.  You can avoid this having to
happen each time by causing the results of $thing->ISA_TREE to be
memoized (cached); then, subsequent method calls on $thing will just
use the cached linearization.  This means, however, that you must not
change any of $thing's ancestry (who its parents are, or any of its
parents' parents, etc.), or the changes will not be noticed.  (If you
do want to change any such thing, unmemoize the lineage first, as
below.  Also remember that you will need to unmemoize the lineages of
all existing clones, too.)

(The ISA_TREE cache happens to be stored in $thing->{'ISA_CACHE'}.)

$thing->memoize_lineage has no effect if memoization is already on.
This always returns $thing, which makes it convenient for calling on
newly cloned objects:

  $thing = $foo->clone->memoize_lineage;

Note that as described above, the normal behavior of $foo->clone is to
turn on ISA_TREE memoization for any new clones of $foo if $foo has
its ISA_TREE memoization turned on.

* $thing->unmemoize_lineage -- this turns off the above-mentioned
ISA_TREE cache for $thing.  Has no effect if lineage-memoization is
already off.  Like $thing->memoize_lineage, this returns $thing.
Think carefully about how you use this.  It's never going to be a
problem if the only way you call it is as:

  $thing = $foo->clone->unmemoize_lineage;

I.e., when you want a new object whose lineage you want to be
free to alter later without having to worry about caching.
(And when in doubt, leave caching off.)

However, note that this is wrong:

  $thing = $foo->clone->memoize_lineage;
  ...stuff...
  push @{$thing->{'PARENTS'}}, $yorp;
  $thing->unmemoize_lineage;

...because the 'unmemoize_lineage' call on $thing will be using an
already out-of-date cache of its old ISA_TREE.  That is likely to be
harmless, though, unless $yorp overrides the normal
'unmemoize_lineage' method.  But this is better:

  $thing = $foo->clone->memoize_lineage;
  ...stuff...
  $thing->unmemoize_lineage;
  push @{$thing->{'PARENTS'}}, $yorp;
  $thing->memoize_lineage;

But consider this harder case:

  $thing = $foo->clone->memoize_lineage;
  ...stuff...
  $zaz = $thing->clone; # so it will have memoization 
  ...more stuff...
  $thing->unmemoize_lineage;
  push @{$thing->{'PARENTS'}}, $yorp;
  $thing->memoize_lineage;

Even though you correctly turned off $thing's cache at the right
moment, you forgot about $zaz's cache, which was and still is out of
date.

* $thing->is_lineage_memoized -- returns true iff $thing is using
lineage memoization.

* $thing->DESTROY -- this is here to trap DESTROY calls that Perl
makes when it's about to deallocate an object, either when the
object's reference count goes to 0, or at global destruction time.
Currently it's a no-op, for many annoyingly complicated reasons.  Do
I<not> try to override the DESTROY method!  If you don't know what
DESTROY methods are for anyway, don't worry about it.

=head1 CONSTANT METHODS

I expect that most methods (i.e., things in the $foo->{'METHODS'}
hash) will be coderefs.  However, if you want the value of a method
to be a constant, I figure there's no point in making you say:

  $foo->{'METHODS'}{'funk'} = sub { 7 };

just so $foo->funk can return the constant value 7.

So instead, I've made it so that when you call $foo->funk, and
Class::Classless finds that $foo->{'METHODS'}{'funk'} exists,
or that $some_ancestor->{'METHODS'}{'funk'} exists, it takes that
value and decides what to do with that value, like so:

* Unless that value (which, by the way, is free to be undef!) is a
reference, then it's a constant, so return it.  That means that if you
set $foo->{'METHODS'}{'funk'} = 7, then $foo->funk will always return
7.

* If it's an unblessed coderef, call it with arguments as explained
in the "What a Method Sees" section, below.  Note that I<blessed>
coderefs (as rare at they are) are I<not> called.

* Otherwise, it must be some sort other sort of constant to return,
which happens to be a reference.

* If it's a reference of the class '_deref_array', then it's
array-dereferenced before being returned.  So if you wanted
$foo->band_members to return a constant list ('Ad Rock', 'MCA', 'Mike
D'), you can do it with: $foo->{'METHODS'}{'band_members'} = bless [
'Ad Rock', 'MCA', 'Mike D'], '_deref_array'. When you call
$foo->band_members then, Class::Classless's dispatcher will
basically say:
return(@{$foo->{'METHODS'}{'band_members'}});

* If it's a reference of the class '_deref_scalar', then it's
scalar-dereferenced before being returned.  This is not as
immediately and obviously useful as the same trick with
'_deref_array', but it does make possible a few tricks.  First off,
you can have something like:

    my $counter = 0;
    bless $counter, '_deref_scalar';
    $fee->{'METHODS'}{'counter_value'} = \$counter;
    $fye->{'METHODS'}{'counter_value'} = \$counter;
    $foe->{'METHODS'}{'counter_value'} = \$counter;

to have these all share the same value, which you'd get from going
$fee->counter_value, $fye->counter_value, or $foe->counter_value.

Second off, suppose (as unlikely as it is) you actually wanted a
I<constant> value to be returned -- but the value you want returned
is an unblessed coderef!  If you just stuck that value in
$foo->{'METHODS'}, it'd get called instead of returned as a constant.
Well, you can just go:

    my $cr = sub { ...whatever... };
    $foo->{'METHODS'}{'zaz'} = bless \$cr, '_deref_scalar';

So when you call $foo->zaz, Class::Classless sees a scalar of class
'_deref_scalar', and returns it, like
return(${$foo->{'METHODS'}{'zaz'}}).  That value is, of course, your
coderef.

* And finally, if the value in $foo->{'METHODS'}{'funk'} was a
reference, but was neither an unblessed coderef, nor a reference of
class '_deref_array', nor of class '_deref_scalar', then it's just
returned.

=head1 WHAT A METHOD SEES

Under Perl's I<normal> object system, when you call

  $foo->bar($x, @y ...)

C<bar>'s C<@_> will consist of

  ($foo, $x, @y ...)

So normally the first thing C<bar> will do is something like:

  my($obj, $first, @rest) = @_;

or

  my $obj  = shift @_;
  my $first = shift @_;
  my @rest = @_;

I<However>, subs called as methods by Class::Classless's dispatcher
have one extra argument; $_[1] is the "callstate", an object created
every time you call a Class::Classless object, and belonging to the class
'Class::Classless::CALLSTATE'.  Normally all you'd ever want to do
with it is say:

  $callstate->NEXT('foo', $bar, @baz)

which is equivalent to $callstate->SUPER::foo($bar, @baz) under Perl's
normal object system.  See the section "More on NEXT".

So, in other words, the first line of a Class::Classless method to be
called as

  $foo->bar($x, @y ...)

would be

  my($obj, $callstate, $first, @rest) = @_;

or the like.

=head1 SHARED DATA

I considered making some sort of mechanism for having private
attributes versus inherited attributes, but decided on just letting
the user work it out with C<get_i>, C<set_i>, and C<exists_i>; onto
this I added the feature that attributes whose names start
with a character in the ASCII range C<[A-Z]> (as opposed to C<[a-z]>,
or anything else) don't get copied by the C<clone> method, and also
aren't deleted by the C<FLATTEN> method.  That's the
I<complete extent> of the special treatment that Class::Classless
accords to attributes whose names start with C<[A-Z]>.

The upshot of this is that you can have something like "class
data" by just taking a generic object (i.e., one you expect
to be cloned) and setting attributes in it like

    $generic->{'Interface'} = 'Tk';

then all clones of that attribute can effectively 'share' that value
like so...

    # send in the clones...
    $w1 = $generic->clone;
    $w2 = $generic->clone;
    $w3 = $generic->clone;
    ...etc...
    
    print $w1->get_i('Interface');  # to read it
    print $w2->get_i('Interface');  # to read it (same value)
    print $w3->get_i('Interface');  # to read it (same value)
    
    print $w2->put_i('Interface', 'VT320');  # to set it

and even this, if this makes any useful sense:

    print $whatever->exists_i('Interface');  # to make sure it exists

However, to repeat myself somewhat, the only reason this is shared is
that C<clone> didn't copy the 'Interface' method when it made clones
of $generic, so calling C<get_i> on any of the children so produced
will find the attribute not in the children, but will fall back on
finding it in $generic->{'Interface'}.

But if you go and set $w1->{'Interface'} (as opposed to using
C<set_i>), then $w1->get_i('Interface') will get you the value of
$w1->{'Interface'}, not the value of $generic->{'Interface'}. In other
words, you'd be overriding the value you'd still be getting at with
$generic->{'Interface'}, $w2->get_i('Interface'),
$w3->get_i('Interface'), or even (uninterestingly)
$generic->get_i('Interface').

And in any case, you can really share data by virtue of the fact that
the clone method (at least, not the default clone method) doesn't do
copying of references (AKA "deep copying") -- so you can just have all
the objects that you want to share data simply have a reference to a
common piece of data:

    my $bar = 123;
    $w->{'foo'} = \$bar;
    # Then any clones of $w will have a reference to that value --
    #  not to copies of it!
    # Similarly:
    $w->{'zaz'} = [5,6,7];
    $w->{'quux'} = {a => 11, b => 12};


=head1 INHERITANCE SYSTEM

If all you want is single-inheritance, you can skip this section,
since things will work as you expect: objects inherit from their
parents, and so on, all the way back to a parentless object (i.e.,
ROOT).

As to how this works with multiple inheritance, consider first how
Perl's built-in mechanism for class inheritance works: first, a
depth-first search of the ISA tree, and then falling back to the class
UNIVERSAL, which is the implicit root for all classes.

Class::Classless's system is different -- consider this case:

    ROOT/UNIVERSAL
        |
        Y
       /  \
     A      X
     |      /
     B    /
      \ /
       C

Here, Perl's depth-first search would linearize the tree (i.e.,
convert it to a flat list consisting of search path) as:

    C   B   A   Y   X   Root/Universal

However, I think this is just not the right way to do things.  The
point of X being a child of Y is so that X can have a chance to
override Y.  Perl's normal depth-first search doesn't allow that in
cases like this.  So my rule is: search over ancestors depth-first,
but never search a node until you've searched all its children (that
is, children that are still ancestors of the node you've built this
tree for -- any other children are irrelevant).  So I linearize that
list as:

    C   B   A   X   Y   Root/Universal

So X does override Y.  (And Root/Universal is not a special case in
the searching rule.)

Now, fatal errors B<may> result with bizarre trees -- namely ones with
cyclicity in them, such as: X's parents are A and B, A's parent is B,
and B's parent is A.  But in some cases Class::Classless B<might> just
try to ignore the cyclic part.  So just don't make any cyclic trees,
OK?

=head1 THE NO_FAIL ATTRIBUTE

If you call $thing->zaz and there is no 'zaz' method that $thing is
capable of, then normally Class::Classless with throw a fatal error.
However, if $thing->get_i{'NO_FAIL'} is true, then a no-operation
(like sub { return; } ) simply results.

(NO_FAIL also controls what happens if you call $thing->NEXT('zaz')
and there is no NEXT 'zaz' method; if NO_FAIL is true, a no-operation
results; otherwise, a fatal error results.  See the section 
"More on NEXT", below.)

Implementationally, the way this is implemented is that when you call
a method, a routine of Class::Classless's called the dispatcher looks
figures out the linearization of the inheritance tree of the target
object of the method call, and then, one-at-a-time, goes over the
objects in the linearization, looking for an object whose METHODS
hash contains an entry for the name of the method. ("Linearization"
meaning simply a list of objects, in the order in which they should
be searched.)

Each call also creates an object, called a "callstate" object, one of
whose attributes is called "no_fail" (note lowercase), and whose
value starts out being undef.  If the dispatcher, while going thru
the linearization and looking at the METHODS, sees an object with a
defined 'NO_FAIL' attribute (note uppercase), it uses that value
(the value of the first object in the list with a defined NO_FAIL
attribute) to set the no_fail attribute of the callstate.  If it
finishes searching the list and hasn't seen an object with a METHODS
entry for the method it's dispatching for, one of two things will happen:
if no_fail is set to true, the dispatcher will act as if it found
the method and its value was sub{return}.  Otherwise, the dispatcher
will die with a fatal error like:

  Can't find method foo in OBJECT_NAME or any ancestors

So, normally, the only way for the no_fail attribute of the callstate
to be usefully set is for the dispatcher to have seen an object with
a NO_FAIL attribute set.  In other words, if you want method lookup
in an object to be unfailing, set $x->{'NO_FAIL'} = 1 for it or
any of its ancestors; and if you want to override B<that> for a
descendant, set its $y->{'NO_FAIL'} = 0.
(Note that just for sake of sanity, the NO_FAIL of $ROOT is set to 0.)

But in the case of using callstate->NEXT call to continue a method
dispatch (i.e., getting the dispatcher to pick up where it left off),
you may want to control the callstate's no_fail attribute directly,
regardless of the NO_FAIL attributes of any of the objects the
dispatcher's seen so far.  In that case, you can use the
$callstate->set_no_fail_true to set no_fail to true (i.e., lookup
failures from NEXTing off of this callstate don't generate fatal
errors).  See the section on callstates, below, for more options.

=head1 CALLSTATES

Every time you call a method on a Class::Classless object (whether
normally, or via a $callstate->NEXT(...) call), a new
Class::Classless::CALLSTATE object is created, and passed as $_[1] to
that method.  Besides this being the way I happen to implement
$callstate->NEXT(I<methodname>, I<arguments>) (by recording the state
of the dispatcher for later resumption), you can use this object to
get metainformation about this method call.  You can access that
information like so:

* $callstate->target -- the object that was the target of the method
call.  Same as the $_[0] that the method sees.

* $callstate->found_name -- the name this method was called as.

* $callstate->lineage -- the list of objects representing the
linearization of the target object's ISA tree.  (Same as
$obj->ISA_TREE.)

* $callstate->home -- the object the called method was found in.

* $callstate->sub_found -- the routine that is being called.
Same as $callstate->home->{'METHODS'}{$callstate->target}.

* $callstate->found_depth -- the number representing the index in the
$callstate->lineage list where this method was found.  In other words,
$callstate->home is ($callstate->lineage)[$callstate->found_depth].

* $callstate->set_no_fail_true -- set the no_fail attribute of this
callstate to true -- meaning failure is impossible for any NEXT calls
based on this call.  (Obviously it's meaningless to consider failure
of the current method -- it was already found, otherwise how could
there be code that's accessing its callstate!)  I expect this is
useful for cases where you want to NEXT, but aren't sure that there
is a next method in the tree.  With the no_fail set, failure in the
NEXT lookup will act as if it triggered a method consisting of just
sub { return; }.

* $callstate->set_no_fail_false -- set the no_fail attribute of this
callstate to true -- meaning failure is possible for any NEXT calls
in the contituation of the current call state.  I don't anticipate
this being useful, but I provide it for completeness.

* $callstate->set_no_fail_undef -- set the no_fail attribute of this
callstate to undef -- meaning that failure is possible, but that this
value can be set by the next object in the linearization of the
inheritance tree.  I don't anticipate this being useful, but I
provide it for completeness.

* $callstate->no_fail -- returns the value of no_fail attribute of
this callstate so far.  See the section "The NO_FAIL attribute",
above.  I don't anticipate this being useful, but I provide it for
completeness.

* $callstate->via_next -- return true the current method was
called via $callstate->NEXT.  Otherwise returns false.

The whole callstate mechanism (used by the above methods as well as by
the NEXT method) assumes you don't change the object's ISA tree (or
any of the METHODS hashes in any part of the ISA tree) in the middle
of the call.  If you do, the information in $callstate will be out of
synch with reality (since it contains the linearization as of the
B<beginning> of the call)), which is fine as long as you don't use it
for anything (like NEXTing) after that point, in that call.

=head1 MORE ON NEXT

Calling $callstate->NEXT is the mechanism I allow for doing what
Perl's built-in object system does with SUPER:: calls, and like what
some object systems do with "before- and after-demons".

The basic syntax to NEXT is as follows:

  $callstate->NEXT( method_name , ...arguments... );

However, if you call it with a method_name of undef, it will
use the current value of $callstate->found_name, i.e., the name
the currently running method was found as.  Note that this
can come to de undefined in two ways -- either by the parameter
list being null, as in either of:

  $callstate->NEXT;
   ...AKA...
  $callstate->NEXT();

or by being explicitly undef:

  $callstate->NEXT(undef, $foo, $bar);

In either case, the undef is interpreted as $callstate->found_name.
I offer this as just a (hopefully) convenient shortcut.

Now, if you call NEXT and there is no method with the desired
name in the remainder of the linearization of the inheritance tree,
what happens depends on the no_fail attribute; if you want to
insure that the NEXT will not fail (since failing would mean a
fatal error), you can set the callstate's no_fail attribute to true:

  $callstate->set_no_fail_true

(which means it can't fail.)

Note, by the way, that NEXTing never automatically copies the
argument list of the current method for the next one. You have to do
that yourself.  There's many ways to do it, but consider something
like:

  $x->{"METHODS"}{"foo"} = sub {
    my($o, $cs) = splice(@_,0,2);
    # then copy arguments from @_, but don't change @_ any further:
    my($zaz, @foo) = @_
    
    ...stuff...
    
    # then you can pass on the arguments still in @_
    $cs->NEXT(undef,@_);
      # undef to mean 'the name I was called as'
    
    ...stuff...
    
  };

If you forgot and just said $cs->NEXT() or (pointlessly) $cs->NEXT(undef),
then the next 'foo' method would have nothing in its argument list after
its usual two first items (the target object and the callstate).

A further note: currently, each method call (whether normal, or via a
NEXT) creates a new callstate object.  However, when NEXTing, the
attributes of the current callstate object are copied into the new
callstate object -- except for the via_next attribute, which is forced
to true, of course.

=head1 BASIC IMPLEMENTATION STRATEGY

This module does what it does by blessing all "Class::Classless"
objects into a class (Class::Classless::X, in point of fact)
that provides no methods except for an AUTOLOAD
method that intercepts all method calls and does the dispatching.
This is how I fiendishly usurp Perl's normal method dispatching
scheme.  (Actually I do provide other methods upfront: C<can>,
C<VERSION>, C<isa>, C<DESTROY>, and C<ISA_TREE>, as I basically
have to, it turns out.)

Consult the source for details.  It's not that long.

=head1 CAVEATS AND MUSINGS

* The moral of this module is that if you don't like the object
framework that comes with a language, quit your bitching and just
make your own!  And the meta-moral is that object systems aren't
black boxes that have to be fused with the language itself.

* Note that the C<can> you may export from UNIVERSAL has nothing
at all to do with the C<can> that you should be using for
Class::Classless objects.  The only way you should call C<can>
on classless objects is like $obj->can('foo').

* How to test if something is a classless object:
C<ref($obj) eq 'Class::Classless::X'>

* Don't make cyclic trees.  I don't go to extreme lengths to stop
you from doing so, but don't expect sane behavior if you do.

* The reason the $callstate->NEXT('foo') is called NEXT is because it
starts looking in the I<next> object in the linearization of the
ISA_TREE.  This next object is not necessarily an ancestor (i.e., a
I<super>ior object) of the current object -- in the above section,
X is A's next node, altho A is clearly not a superior node.

* Don't try to derive new I<classes> from any of the classes that
Class::Classless defines.  First off, it may not work, for any
reading of "work".  Second off, what's the point?

* Note that there's currently no mechanism for parent objects to know
what their children are.  However, if you needed this, you could
override the clone method with something that would track this.  But
note that this would create circular data structures, complicating
garbage collection -- you'd have to explicitly destroy objects, the
way you have to with Tree::DAG_Node nodes.

* Why don't I let objects define their own DESTROY methods?  One short
reason: this unpredictably and intermittently triggers a strange bug
in Perl's garbage collection system during global destruction.
Better, longer reason: I don't see any way to make sure that, during
global destruction, Perl never destroys a parent before its children.
If a parent is destroyed before its children, and that parent provides
a DESTROY that the children inherit, then when it comes time for the
children to be destroyed, the DESTROY method they planned on using
would have become inaccessible.  This seems an intractable problem.

* Callstate objects were added as an afterthought.  They are meant to
be small and inexpensive, not extensible.  I can't imagine a use for
them other than the uses outlined in the documentation -- i.e.,
getting at (or sometimes modifying) an attribute of the current state
of the method dispatcher. If you're considering any other use of
callstate objects, email me -- I'd be interested in hearing what you
have in mind.

* While I was writing Class::Classless, I read up on Self.  To quote
FOLDOC (C<http://foldoc.doc.ic.ac.uk/foldoc/foldoc.cgi?query=Self>),
Self is/was "a small, dynamically typed object-oriented language,
based purely on prototypes and delegation. Self was developed by the
Self Group at Sun Microsystems Laboratories, Inc. and Stanford
University. It is an experimental exploratory programming language."
For more information, see C<http://www.sunlabs.com/research/self/>

=head1 YOU KNOW WHAT THEY SAY...

To Marx, a classless society never meant the absolute equality of
result, but merely the absence of artificial barriers between social
groups. According to David McClellan, a Marx scholar, Marx "had a
dynamic or subjective element in his definition of class; a class only
existed when it was conscious of itself as such, and this always
implied common hostility to another social group." In I<The Thought of
Karl Marx>, (New York: Harper & Row, 1971) p. 155.

-- C<http://www.polyconomics.com/searchbase/kmnotes.htm>

The thanks for the quote as well as for thinking of the
name "Class::Classless" go to Veblen, who can be seen making
that secret potato soup of his at
C<http://www.llnl.gov/llnl/art-cv/image1.jpg>

Thanks to my many minions in EFNet #perl for help, suggestions, and
encouragement.  Especial thanks to Merlyn, Halfjack, and Skrewtape for
assuring me that the idea of objects-without-class wasn't just some
Felliniesque fever dream I had, but is a concept that has precedent in
other programming languages.

And thanks to Damian Conway for stritching the brines of his poor
students with this module.

=head1 SEE ALSO

For information on Perl's classy OOP system, see L<perlobj>,
L<perltoot>, L<UNIVERSAL>, and 
Damian Conway's excellent book I<Object Oriented Perl> from
Manning Press.

=head1 COPYRIGHT

Copyright (c) 1999, 2000 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke, sburke@cpan.org

=cut

###########################################################################
###########################################################################

$Class::Classless::NAMES = 0;

# Instantiate the one prototype object, and pack it with all the handy
#  methods that we want it to have.

$ROOT = bless {
  'PARENTS' => [], # I am the obj that has no parents
  'NAME'    => 'ROOT',
  'NO_FAIL' => 0,
  'VERSION' => 0.00,

  'METHODS' => {

    'clone' => sub {
       my $orig = $_[0];
       my $new = bless { %$orig }, ref($orig); # copy
       
       delete @{$new}{grep m/^[A-Z]/s, keys %$new};
        # Delete entries whose keys start with A-Z

       # Now define some niceties:
       $new->{'PARENTS'} = [ $orig ];
       $new->{'METHODS'} = { };
       $new->{'NAME'} = 'x_' . $Class::Classless::NAMES++;

       $new->{'ISA_CACHE'} = 1 if $orig->{'ISA_CACHE'};

       return $new;
    },

    'polyclone' => sub { # make a new obj be a clone of all of
       # $X->polyclone($Y, $Z...)
       my @origs = @_;
       splice(@origs, 1, 1); # snip out the callstate 

       if($Debug) {
         print "Parameters to polyclone: ", join(' ',@origs), "\n";
       }
       foreach my $o (@origs) {
         carp "Parameter $o to polyclone is not an object\n" unless ref($o);
       }
       my $new = bless {
         map(%$_, reverse(@origs))
       }, ref($origs[0]);
        # copy 'em off backwords so the origs[0] overrides all others, etc
       
       delete @{$new}{grep m/^[A-Z]/s, keys %$new};
        # Delete entries whose keys start with A-Z

       # Now define some niceties:
       $new->{'PARENTS'} = \@origs;
       $new->{'METHODS'} = { };

       $new->{'ISA_CACHE'} = 1 if exists $origs[0]{'ISA_CACHE'};

       $new->{'NAME'} = 'x_' . $Class::Classless::NAMES++;
       return $new;
    },

    'FLATTEN' => sub {
      # Delete all attributes except for ones /^[A-Z]/s
      delete @{$_[0]}{ grep !m/^[A-Z]/s, keys %{$_[0]} };
      return;
    },

    'EXAMINE' => sub {
      my $in = $_[0];
      my($key,$value);
      print "<$in>\n";
        while(($key,$value) = each %$in) {
          print '   ', Class::Classless::pretty($key, $value), ", \n";
          #print "  # <$key> <$value>\n";
        }
      return;
    },

    'DESTROY'  => \&Class::Classless::X::DESTROY,
    'ISA_TREE' => \&Class::Classless::X::ISA_TREE,
    'VERSION'  => \&Class::Classless::X::VERSION,
    'can'      => \&Class::Classless::X::can,
    'isa'      => \&Class::Classless::X::isa,
    # But don't try to override these!!  No sirree!!
    # These are here just so that can() can see them.

    'get_i' => sub { # get, with interitance
      croak "usage:  \$z = \$it->get_i('attribute_name')" unless @_ == 3;
      my($it, $attribute) = @_[0,2];
      foreach my $ancestor (@{$_[1][2]}) {
        return $ancestor->{$attribute} if exists $ancestor->{$attribute};
      }
      return undef; # nothing found
    },

    'put_i' => sub { # put, with inheritance
      croak "usage:  \$it->put_i('attribute_name', \$newval)" unless @_ == 4;
      my($it, $attribute, $newval) = @_[0,2,3];
      foreach my $ancestor (@{$_[1][2]}) {
        return $ancestor->{$attribute} = $newval
         if exists $ancestor->{$attribute};
      }
      carp "put_i can't find attribute \"$attribute\" in "
        . ($it->{'NAME'} || $it) . 
        " or ancestors -- setting it here.\n" if $^W;
      return $it->{$attribute} = $newval;
    },

    'exists_i' => sub { # exists? with inheritance
      croak "usage:  \$z = \$it->exists_i('attribute_name')" unless @_ == 3;
      my($it, $attribute) = @_[0,2];
      foreach my $ancestor (@{$_[1][2]}) {
        return 1 if exists $ancestor->{$attribute};
      }
      return 0; # nothing found
    },
    
    'allcan' => sub {
      # Return all so-named methods in $it's ISA tree, or () if none.
      my($it, $m) = @_[0,2];
      return unless ref $it;

      croak "undef is not a valid method name"       unless defined($m);
      croak "null-string is not a valid method name" unless length($m);

      print "AllCan-seeking method <$m> for <", $it->{'NAME'} || $it,
        ">\n" if $Debug > 1;
      return
        map
        {
          (   ref($_->{'METHODS'}     || 0)  # sanity
           && exists($_->{'METHODS'}{$m})
          )
          ? $_->{'METHODS'}{$m} : ()
        }
        @{$_[1][2]};
    },

    'howcan' => sub {
      # like allcan, but returns a list consisting of pairs, where
      #  each pair is the object that provides the so-named method
      #  and then the value of the method
      my($it, $m) = @_[0,2];
      return unless ref $it;

      croak "undef is not a valid method name"       unless defined($m);
      croak "null-string is not a valid method name" unless length($m);

      print "AllCan-seeking method <$m> for <", $it->{'NAME'} || $it,
        ">\n" if $Debug > 1;
      return
        map
        {
          (   ref($_->{'METHODS'}     || 0)  # sanity
           && exists($_->{'METHODS'}{$m})
          )
          ? ($_, $_->{'METHODS'}{$m}) : ()
        }
        @{$_[1][2]};
    },

    # deep voodoo...
    'memoize_lineage' => sub {
      $_[0]{'ISA_CACHE'} ||= $_[1][2]; # copy it right from the callstate
      return $_[0];
    },

    'unmemoize_lineage' => sub {
      delete $_[0]->{'ISA_CACHE'};
      return $_[0];
    },

    'is_lineage_memoized' => sub {
      return exists $_[0]{'ISA_CACHE'};
    }

    ##
    #
    # Bad idea -- because if you've changed the real lineage,
    # even the call to $thing->reset_memoize_lineage will use
    # a corrupted lineage in trying to look up this method.
    #'reset_memoize_lineage' => sub {
    #  $_[0]{'ISA_CACHE'} = 1;
    #  Class::Classless::X::ISA_TREE($_[0]); # force-set now.
    #  return $_[0];
    #},
    #
    #* $thing->reset_memoize_lineage -- If you are using lineage
    #memoization and I<do> change $thing's ancestry, you can reset its
    #cache using this method, to force it to take note of any changes in
    #its ancestry.  If lineage memoization is off, this turns it on.  Like
    #$thing->memoize_lineage, this returns $thing.
    #
    ##

  }, # end of METHODS hash.
},
'Class::Classless::X'   # the class where classless things live!
;
# End of creating $ROOT and its methods.

*Class::Classless::X::VERSION = \( $ROOT->{'VERSION'} ); # alias it
@Class::Classless::X::ISA = ();

###########################################################################
###########################################################################

sub Class::Classless::X::AUTOLOAD {
  # This's the big dispatcher.
  
  my $it = shift @_;
  my $m =  ($Class::Classless::X::AUTOLOAD =~ m/([^:]+)$/s ) 
             ? $1 : $Class::Classless::X::AUTOLOAD;

  croak "Can't call Class::Classless methods (like $m) without an object"
    unless ref $it;  # sanity, basically.

  my $prevstate;
  $prevstate = ${shift @_}
   if scalar(@_) && defined($_[0]) &&
      ref($_[0]) eq 'Class::Classless::CALLSTATE::SHIMMY'
  ;   # A shim!  we were called via $callstate->NEXT

  print "\nAbout to call method <$m> on object <",
        $it->{'NAME'} || $it,
        ">", $prevstate ? ' with a shim' : '',
        "\n" if $Debug > 1;

  my $no_fail = $prevstate ? $prevstate->[3] : undef;
  my $i       = $prevstate ? ($prevstate->[1] + 1) : 0;
   # where to start scanning
  my $lineage;

  # Get the linearization of the ISA tree
  if($prevstate) {
    $lineage = $prevstate->[2];
  } elsif(defined $it->{'ISA_CACHE'} and ref $it->{'ISA_CACHE'} ){
    $lineage = $it->{'ISA_CACHE'};
  } else {
    $lineage = [ &Class::Classless::X::ISA_TREE($it) ];
  }

  # Was:
  #my @lineage =
  #  $prevstate ? @{$prevstate->[2]}
  #             : &Class::Classless::X::ISA_TREE($it);
  # # Get the linearization of the ISA tree
  # # ISA-memoization happens in the ISA_TREE function.
  
  for(; $i < @$lineage; ++$i) {
    print "Looking in ", $lineage->[$i]{'NAME'} || $lineage->[$i], "\n"
      if $Debug;

    if( !defined($no_fail) and exists($lineage->[$i]{'NO_FAIL'}) ) {
      $no_fail = ($lineage->[$i]{'NO_FAIL'} || 0);
      # so the first NO_FAIL sets it
      print
        "Setting no_fail for this call to $no_fail from ",
        $lineage->[$i]{'NAME'} || $lineage->[$i], "\n"
       if $Debug;
    }

    if(     ref($lineage->[$i]{'METHODS'}     || 0)  # sanity
      && exists($lineage->[$i]{'METHODS'}{$m})
    ){
      # We found what we were after.  Now see what to do with it.
      my $v = $lineage->[$i]{'METHODS'}{$m};
      return $v unless defined $v and ref $v;

      if(ref($v) eq 'CODE') { # normal case, I expect!
        # Used to have copying of the arglist here.
        #  But it was apparently useless, so I deleted it
        unshift @_, 
          $it,                   # $_[0]    -- target object
          # a NEW callstate
          bless([$m, $i, $lineage, $no_fail, $prevstate ? 1 : 0],
                'Class::Classless::CALLSTATE'
               ),                # $_[1]    -- the callstate
        ;
        goto &{ $v }; # yes, magic goto!  bimskalabim!
      }
      return @$v if ref($v) eq '_deref_array';
      return $$v if ref($v) eq '_deref_scalar';
      return $v; # fallthru
    }
  }

  if($m eq 'DESTROY') { # mitigate DESTROY-lookup failure at global destruction
    print "Ignoring failed DESTROY lookup\n" if $Debug;
    # should be impossible
  } else {
    if($no_fail || 0) {
      print "Ignoring lookup failure on ",
          $prevstate ? 'NEXT method' : 'method',
          " $m in ", $it->{'NAME'} || $it,
          " or any ancestors\n" if $Debug;
      return;
    }
    croak "Can't find ", $prevstate ? 'NEXT method' : 'method',
          " $m in ", $it->{'NAME'} || $it,
          " or any ancestors\n";
  }
}

###########################################################################
###########################################################################

sub Class::Classless::X::DESTROY {
  # noop
}

###########################################################################
sub Class::Classless::X::ISA_TREE {
  # The linearizer!
  # Returns the search path for $_[0], starting with $_[0]
  # Possibly memoized.

  # I stopped being able to understand this algorithm about five
  #  minutes after I wrote it.
  use strict;
  
  my $set_cache = 0; # flag to set the cache on the way out
  
  if(exists($_[0]{'ISA_CACHE'})) {
    return    @{$_[0]{'ISA_CACHE'}}
     if defined $_[0]{'ISA_CACHE'}
        and ref $_[0]{'ISA_CACHE'};
     
    # Otherwise, if exists but is not a ref, it's a signal that it should
    #  be replaced at the earliest, with a listref
    $set_cache = 1;
  }
  
  print "ISA_TREEing for <", $_[0]{'NAME'} || $_[0], ">\n"
   if $Debug > 1;

  my $has_mi = 0; # set to 0 on the first node we see with 2 parents!
  # First, just figure out what's in the tree.
  my %last_child = ($_[0] => 1); # as if already seen

  # if $last_child{$x} == $y, that means:
  #  1) incidentally, we've passed the node $x before.
  #  2) $x is the last child of $y,
  #     so that means that $y can be pushed to the stack only after
  #      we've pushed $x to the stack.
  
  my @tree_nodes;
  {
    my $current;
    my @in_stack = ($_[0]);
    while(@in_stack) {
      next unless
       defined($current = shift @in_stack)
       && ref($current) # sanity
       && ref($current->{'PARENTS'} || 0) # sanity
      ;

      push @tree_nodes, $current;

      $has_mi = 1 if @{$current->{'PARENTS'}} > 1;
      unshift
        @in_stack,
        map {
          if(exists $last_child{$_}) { # seen before!
            $last_child{$_} = $current;
            (); # seen -- don't re-explore
          } else { # first time seen
            $last_child{$_} = $current;
            $_; # first time seen -- explore now
          }
        }
        @{$current->{'PARENTS'}}
      ;
    }

    print "Contents of tree_nodes: ", nodelist(@tree_nodes), 
      $has_mi ? " (has MI)\n" : " (no MI)\n"
     if $Debug > 1;

    # If there was no MI, then that first scan was sufficient.
    unless($has_mi) {
      $_[0]{'ISA_CACHE'} = \@tree_nodes if $set_cache;
      return @tree_nodes;
    }

    # Otherwise, toss this list and rescan, consulting %last_child
  }

  # $last_child{$parent} holds the last (or only) child of $parent
  # in this tree.  When walking the tree this time, only that
  # child is authorized to put its parent on the @in_stack.
  # And that's the only way a node can get added to @in_stack,
  # except for $_[0] (the start node) being there at the beginning.

  # Now, walk again, but this time exploring parents the LAST
  # time seen in the tree, not the first.

  my @out;
  {
    my $current;
    my @in_stack = ($_[0]);
    while(@in_stack) {
      next unless defined($current = shift @in_stack) && ref($current);
      push @out, $current; # finally.
      unshift
        @in_stack,
        grep(
          (
            defined($_) # sanity
            && ref($_)  # sanity
            && $last_child{$_} eq $current,
          ),
          # I'm lastborn (or onlyborn) of this parent
          # so it's OK to explore now
          @{$current->{'PARENTS'}}
        )
       if ref($current->{'PARENTS'} || 0) # sanity
      ;
    }

    unless(scalar(@out) == scalar(keys(%last_child))) {
      # the counts should be equal
      my %good_ones;
      @good_ones{@out} = ();
      croak
        "ISA tree for " .
        ($_[0]{'NAME'} || $_[0]) .
        " is apparently cyclic, probably involving the nodes " .
        nodelist( grep { ref($_) && !exists $good_ones{$_} }
          values(%last_child) )
        . "\n";
    }
  }
  #print "Contents of out: ", nodelist(@out), "\n";
  
  $_[0]{'ISA_CACHE'} = \@out if $set_cache;
  return @out;
}

###########################################################################

sub Class::Classless::X::can { # NOT like UNIVERSAL::can ...
  # return 1 if $it is capable of the method given -- otherwise 0
  my($it, $m) = @_[0,1];
  return undef unless ref $it;

  croak "undef is not a valid method name"       unless defined($m);
  croak "null-string is not a valid method name" unless length($m);

  print "Can-seeking method <$m> for <", $it->{'NAME'} || $it,
    ">\n" if $Debug > 1;

  foreach my $o (&Class::Classless::X::ISA_TREE($it)) {
    return 1
     if  ref($o->{'METHODS'} || 0)   # sanity
      && exists $o->{'METHODS'}{$m};
  }

  return 0;
}

###########################################################################

sub Class::Classless::X::VERSION {
  # like UNIVERSAL::VERSION.
  print "Searching in ", ( $_[0]->{'NAME'} || $_[0] ),
        " for VERSION\n" if $Debug;
  if(defined($_[1])) {
    my $v = $_[0]->get_i('VERSION');
    $v = '' unless defined $v;  # insanity
    croak(( $_[0]->{'NAME'} || $_[0])
          . " version $_[1] required--this is only version $v"
         )
      if $v < $_[1];
    return $v;
  } else {
    #print "V<", $_[0]->get_i('VERSION'), ">\n";
    return $_[0]->get_i('VERSION');
  }
}

###########################################################################

sub Class::Classless::X::isa { # Like UNIVERSAL::isa
  # Returns true for $X->isa($Y) iff $Y is $X or is an ancestor of $X.

  return unless ref($_[0]) && ref($_[1]);
  print "Testing isa for ", ( $_[0]->{'NAME'} || $_[0] ),
        " and ", ( $_[1]->{'NAME'} || $_[1] ), "\n" if $Debug;
  return scalar(grep {$_ eq $_[1]} &Class::Classless::X::ISA_TREE($_[0])); 
}

###########################################################################
###########################################################################
###########################################################################

%Pretty_form = (
  "\a" => '\a', # ding!
  "\b" => '\b', # BS
  "\e" => '\e', # ESC
  "\f" => '\f', # FF
  "\t" => '\t', # tab
  "\cm" => '\cm',
  "\cj" => '\cj',
  "\n" => '\n', # probably overrides one of either \cm or \cj
  '"' => '\"',
  '\\' => '\\\\',
  '$' => '\\$',
  '@' => '\\@',
  '%' => '\\%',
  '#' => '\\#',
);

sub pretty { # for Pretty-Print, but doesn't print
  # Based somewhat on MIDI.pm's _dump_quote
  my @stuff = @_; # copy
  my $Seen = (@stuff
                and defined($stuff[0])
                and ref($stuff[0]) eq 'Class::Classless::PRETTYENV'
             )
             ? shift(@stuff)
             : bless({}, 'Class::Classless::PRETTYENV');
   # $Seen is my hash for noting what structures I've already explored.

  my $out = 
    join(",\n",
         map
         { # the cleaner-upper function
           $_ = $_->{'NAME'}
             if defined($_)
                && ref($_) eq 'Class::Classless::X'
                && $_->{'NAME'}
           ;

           if(!defined($_)) { # undef
             "undef";

           } elsif(ref($_) eq 'ARRAY') { # arrayref
             $Seen->{$_}++
              ? "\'$_\'"
              :  ("[ " . &pretty($Seen, @$_) . " ]")
             ;
           } elsif(ref($_) eq 'HASH') {  # hashref
             $Seen->{$_}++
              ? "\'$_\'"
              :  ("{ " . &pretty($Seen, %$_) . " }")
             ;

           } elsif(!length($_)) { # empty string
             "''";

           } elsif($_ eq '0' or m/^-?(?:[1-9]\d*)$/s) {  # integers
	     # Was just: m/^-?\d+(?:\.\d+)?$/s
             # but that's over-broad, as let "0123" thru, which is
             # wrong, since that's octal 0123, == decimal 83.

             # m/^-?(?:(?:[1-9]\d*)|0)(?:\.\d+)?$/s and $_ ne '-0'
             # would let thru all well-formed numbers, but also
             # non-canonical forms of them like 0.3000000.
             # Better to just stick to integers I think.
             $_;

           } elsif( # text with junk in it
              #s<([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E])>
              # <'\\x'.(unpack("H2",$1))>eg
              s<([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E])>
               <$Pretty_form{$1} || '\\x'.(unpack("H2",$1))>eg
             ) {
             "\"$_\"";
           } else { # text with no junk in it
             s<'><\\'>g;
             "\'$_\'";
           }
         }
         @stuff
        )
  ;
  $out =~ tr<\n>< > if 1; #length($out) < 72;
  return $out;
}

###########################################################################

sub nodelist { join ', ', map { "" . ($_->{'NAME'} || $_) . ""} @_ }

###########################################################################
###########################################################################
###########################################################################
# Methods for the CALLSTATE class.
#  Basically, CALLSTATE objects represent the state of the dispatcher,
#   frozen at the moment when the method call was dispatched to the
#   appropriate sub.
#  In the grand scheme of things, this needn't be a class -- I could
#   have just made the callstate data-object be a hash with documented
#   keys, or a closure that responded to only certain parameters,
#   etc.  But I like it this way.  And I like being able to say simply
#   $cs->NEXT
#  Yes, these are a bit cryptically written, but it's behoovy for
#   them to be very very efficient.

*Class::Classless::CALLSTATE::VERSION = \$Class::Classless::VERSION;
@Class::Classless::ISA = ();
sub Class::Classless::CALLSTATE::found_name { $_[0][0] }
   #  the method name called and found
sub Class::Classless::CALLSTATE::found_depth { $_[0][1] }
   #  my depth in the lineage
sub Class::Classless::CALLSTATE::lineage { @{$_[0][2]} }
   #  my lineage
sub Class::Classless::CALLSTATE::target { $_[0][2][  0          ] }
   #  the object that's the target -- same as $_[0] for the method called
sub Class::Classless::CALLSTATE::home   { $_[0][2][  $_[0][1]   ] }
   #  the object I was found in
sub Class::Classless::CALLSTATE::sub_found {
  $_[0][2][  $_[0][1]   ]{'METHODS'}{ $_[0][0] }
}  #  the routine called

sub Class::Classless::CALLSTATE::no_fail          {  $_[0][3]         }
sub Class::Classless::CALLSTATE::set_no_fail_true {  $_[0][3] = 1     }
sub Class::Classless::CALLSTATE::set_fail_false   {  $_[0][3] = 0     }
sub Class::Classless::CALLSTATE::set_fail_undef   {  $_[0][3] = undef }

sub Class::Classless::CALLSTATE::via_next         {  $_[0][4] }

sub Class::Classless::CALLSTATE::NEXT {
  #croak "NEXT needs at least one argument: \$cs->NEXT('method'...)"
  # unless @_ > 1;
   # no longer true.
  my $cs = shift @_;
  my $m  = shift @_; # which may be (or come out) undef...
  $m = $cs->[0] unless defined $m; #  the method name called and found

  ($cs->[2][0])->$m(
    bless( \$cs, 'Class::Classless::CALLSTATE::SHIMMY' ),
    @_
  );
}

###########################################################################

1;

__END__

