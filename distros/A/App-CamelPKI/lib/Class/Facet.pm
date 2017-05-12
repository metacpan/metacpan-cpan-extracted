#!perl -w

package Class::Facet;
use strict;

=head1 NAME

B<Class::Facet> - Capability-discipline facet construct for Perl.

=head1 SYNOPSIS

In the class to facetize:

=for My::Tests::Below "synopsis main class" begin

  package Foo::TheRealOne;

  use Class::Facet;

  sub get_this { ... }
  sub get_that { ... }
  sub set_this { ... }
  sub set_that { ... }
  sub get_substuff { ... } # Returns an object

  sub facet_readonly {
    my ($self) = @_;
    my $facet_object =
        Class::Facet->make("Foo::ReadOnlyFacet", $self);
    $facet_object->facet_rescind if $self->in_a_bad_mood;
    return $facet_object;
  }

=for My::Tests::Below "synopsis main class" end

Meanwhile, in a nearby package (often in the same .pm file):

=for My::Tests::Below "synopsis facet class" begin

  package Foo::ReadOnlyFacet;

  use Class::Facet;

  BEGIN {
    Class::Facet->from(__PACKAGE__, "Foo::TheRealOne");
    Class::Facet->on_error(__PACKAGE__,
                           sub { my ($class, %args) = @_;
                                 die "forbidden method $args{-method}" });
    Class::Facet->delegate(__PACKAGE__, qw(get_this get_that));
  }

  sub get_substuff {
    my ($facetself, $origself) = Class::Facet->selves(\@_);
    return $origself->get_substuff(@_)->facet_readonly;
  }

=for My::Tests::Below "synopsis facet class" end

or if you don't like BEGIN blocks, then replace the one above with:

=for My::Tests::Below "synopsis without BEGIN" begin

  use Class::Facet from => "Foo::TheRealOne",
                   on_error => sub {
                          my ($class, %args) = @_;
                          die "forbidden method $args{-method}";
                   },
                   delegate => [ qw(get_this get_that) ];

=for My::Tests::Below "synopsis without BEGIN" end

=head1 DESCRIPTION

B<Facets> are a working concept of the E secure programming language
(see L</REFERENCES>) that in turn has its roots in a method of secure
programming known as B<capability discipline>.  Facets are a powerful
yet simple mechanism for writing secure code; as well as for
refactoring code into becoming secure, provided that said code already
be object-oriented (but see L</DISCLAIMER>).

=head2 Definitions

As demonstrated in L</SYNOPSIS>, a B<facet object> is simply a
delegate object (akin to what CPAN's L<Class::Delegate> does) that
only provides access to a subset of the methods in the B<original
object>, or restricts the range of arguments or return values to said
methods.  The facet object is blessed into a B<facet class>, here
I<Foo::ReadOnlyFacet>.

=head2 Purpose

The facet object closely follows the API of the original object, and
is intended to be used in lieu of the real thing in unsuspecting
third-party code.  By carefully selecting what the facet object can
and cannot do, one is able to restrict the privilege level handed down
to said third-party code in an extremely fine-grained fashion.  A very
common application of this technique (although by no means the only
one) is the I<read-only facet>, demonstrated in the synopsis: the
facet object is only allowed to call the read accessors of the
original one, and cannot alter it.

=head2 So how secure is this?

In itself, not much: Perl is B<not> a capability secure language, and
by reading the source code of this module, the astute reader will find
numerous ways to call methods that were purportedly faceted out,
thereby defeating any security that B<Class::Facet> seems to provide.
Still, B<Class::Facet> alone is helpful for B<applying capability
discipline>, that is, providing defense-in-depty to bona fide code
that already respects the Law of Demeter (see L</REFERENCES>).  The
aforementioned read-only facet is an example of this.  Capability
discipline in general (and B<Class::Facet> in particular) cover the
bases of high-level programming mistakes such as privilege management;
it is no substitute for the tips and tricks of L</perlsec>, that
describes how to prevent low-level vulnerabilities.

On the other hand, when combining B<Class::Facet> with L</Safe> and
caperl (see L</REFERENCES>), a whole lot more security can be
achieved.  (To be written.)

=head2 Inheriting facets

TODO: To be written.

=cut

use Carp qw(croak);

=head1 CLASS METHODS

=head2 import

Called at compile time for each occurence of C<use Class::Facet>;
converts the parameters, if any, into the calls to methods L</from>,
L</on_error> and L</delegate> such that e.g.

=for My::Tests::Below "import use simple" begin

    use Class::Facet from => "foo";

    use Class::Facet delegate => [ "bar", "baz" ];

=for My::Tests::Below "import use simple" end

are translated respectively into

=for My::Tests::Below "import converted into method calls" begin

    Class::Facet->from($callerpackage, "foo");

    Class::Facet->delegate($callerpackage, "bar", "baz");

=for My::Tests::Below "import converted into method calls" end

and so on.  Arguments to "use" are interpreted pair-wise, so that

=for My::Tests::Below "import use multiple" begin

    use Class::Facet from => "foo",  delegate => [ "bar", "baz" ];

=for My::Tests::Below "import use multiple" end

is again equivalent to the above.

=cut

sub import {
    my ($class, @args) = @_;
    croak('Bad number of arguments to "use" or "import"') if @args % 2;
    while(my ($methname, $args) = splice(@args, 0, 2)) {
        croak(qq'Unknown command to "use" or "import": $methname')
            unless ($methname =~ m/^(from|on_error|delegate)$/);
        $class->$methname(scalar(caller),
                          (ref($args) eq "ARRAY" ? @$args : $args));
    }
}

=head2 from($facetclass, $origclass)

Indicates that $facetclass is to be a facet class from $origclass.
This method must be called first before any B<Class::Facet> operation
on $facetclass.

=cut

sub from {
    my ($class, $facetclass, $origclass) = @_;
    no strict "refs";
    *{"${facetclass}::_facet_of"} = sub { $origclass };
    foreach my $miranda (qw(rescind error)) {
        *{"${facetclass}::facet_$miranda"} = \&{"_miranda_$miranda"};
    }
    *{"${facetclass}::AUTOLOAD"} = \&_miranda_AUTOLOAD;
}

=head2 delegate($facetclass, $methodname)

Indicates that the method named $methodname is to be delegated to the
original object without altering the parameters or the return value.
Is mostly equivalent to declaring a sub like this:

=for My::Tests::Below "delegate equivalent" begin

  sub foo {
    my (undef, $origself) = Class::Facet->selves(\@_);
    unshift(@_, $origself);
    goto $origself->can("foo");
  }

=for My::Tests::Below "delegate equivalent" end

except that the error management is better.

=cut

sub delegate {
    my ($class, $facetclass, @methods) = @_;
    foreach my $methodname (@methods) {
        no strict "refs";
        *{"${facetclass}::${methodname}"} = sub {
            my (undef, $origself) = Class::Facet->selves(\@_);
            unshift(@_, $origself);
            goto $origself->can($methodname);
        };
    }
}

=head2 on_error($facetclass, $sub)

Installs $sub as the error management callback method for $facetclass.
$sub will always be called as a class method in void context, and
should throw an exception with L<perlfunc/die>, L<Exception::Class> or
some such, and not return.  As shown in L</SYNOPSIS>, $sub should
accept the following named parameters:

=over

=item B<-file>

=item B<-line>

The filename and line number of the place in the code that invoked the
faulty operation.

=item B<-facetclass>

The facet class against which the error sub is being invoked.  This
will be $facetclass, unless $sub is the error management routine for
several facets at once.

=item B<-reason>

The reason why the error is thrown, as the name of the method in
B<Class::Facet> that triggered the error, or one of the special values
C<facet_error> (meaning that L</facet_error> was invoked manually) or
C<forbidden_method> (if one tries to invoke a forbidden method through
the facet object).

=item B<-details> (optional)

A message in english explaining the reason of the error.

=item B<-method> (optional)

Set when trying to invoke a method through a facet object, but this
method is neither delegated (using L</delegate>) nor defined in the
facet package.

=back

The default implementation (if C<on_error()> is not called) is to
throw a text message in english using L<perlfunc/die> that contains a
subset of the aforementioned information.

=cut

# See the default implementation of the error handler in L</_carp>.
sub on_error {
    my ($class, $facetclass, $sub) = @_;
    unless (ref($sub) eq "CODE") {
        $sub = "an undefined value" if ! defined $sub;
        croak("Class::Facet: cannot use $sub as an error handler");
    }
    no warnings "redefine"; no strict "refs";
    *{"${facetclass}::_facet_die"} = $sub;
}

=head2 make($facetclass, $origobject)

Returns a facet of $object in class $facetclass.  The returned facet
object is an ordinary hashref-based object, constructed like this:

=for My::Tests::Below "make structure" begin

    bless { delegate => $origobject }, $facetclass;

=for My::Tests::Below "make structure" end

and B<Class::Facet> will never use any other field in blessed hash
besides C<delegate>.  The facet class and facet constructor are
therefore free to add their own fields into the facet object.

=cut

sub make {
    my ($class, $facetclass, $origobject) = @_;
    
#	use Class::ISA;
#	use UNIVERSAL::can; 
	#Making a facet from a facet is forbidden !!!!
#	for my $int (Class::ISA::super_path($facetclass)) {
# 		eval {($int->can("from") && $int->can("delegate"))};
# 		throw App::CamelPKI::Error::User
# 			("Subclassing a facet is forbidden")
# 				if ($int->can("from") && $int->can("delegate"))';
#	}
	
    return bless { delegate => $origobject }, $facetclass;
}

=head2 selves($argslistref)

Interprets $argslistref as a reference to the argument list (@_) of a
class method, and modifies it in place by removing the first argument
(as L<perlfunc/shift> would do).  Returns a a ($facetself, $origself)
pair where $facetself is the facet object, and $origself is the
original object.

This class method is useful for creating custom facet methods, such as
the C<get_substuff> example in L</SYNOPSIS>.

=cut

sub selves {
    my ($class, $argslistref) = @_;
    my $facetobject = shift @$argslistref;
    return ($facetobject, $facetobject->{delegate});
}

=head1 MIRANDA METHODS

These methods can be called from any facet object, regardless of how
restricted the facet class; in capability discipline parlance, they
can thus be interpreted as unremovable rights, just like those
enumerated in the I<miranda warning> given by the police officer upon
arresting you.

=head2 facet_rescind()

Turns the facet into a useless object, that will not accept any
further method call.

=cut

sub _miranda_rescind {
    my ($self) = @_;
    bless $self, ref($self) . "::Rescinded";
}

=head2 facet_error(%named_args)

Throws an exception by invoking the error mechanism configured with
L</on_error> for this facet class.  This may be used from inside a
facetized method, so as to make error handling uniform.

=cut

sub _miranda_error {
    my $self = shift;
    push(@_, "???") if (@_ % 2);
    Class::Facet->_carp(ref($self), @_);
}

=head1 TODO

Release as a separate CPAN module.

Add faceting support for private fields, using tied objects (yow!)

=head1 REFERENCES

Capabilities and secure programming:
L<http://www.c2.com/cgi/wiki?CapabilitySecurityModel>,
L<http://www.erights.org/elib/capability/ode/index.html>

The Law of Demeter, a well-known best practice in object-oriented
programming that also happens to be a preliminary step to capability
discipline: L<http://www.c2.com/cgi/wiki?LawOfDemeter>

The E programming language: L<http://wiki.erights.org/wiki/Walnut>

Capabilities in Perl: L<http://caperl.links.org/>

The concept of facets: L<http://www.c2.com/cgi/wiki?FacetPattern>,
L<http://wiki.erights.org/wiki/Walnut/Secure_Distributed_Computing/Capability_Patterns#Facets>

Why facets and inheritance don't mix: FIXME add link

=head1 DISCLAIMER

Users of this package should be warned that B<Class::Facet> doesn't
provide any actual security of its own, as stated in L</So how secure
is this?>.  The author therefore makes B<no warranty>, implied or
otherwise, about the suitability of this software for any purpose
whatsoever.

The authors shall not in any case be liable for special, incidental,
consequential, indirect or other similar damages arising from the use
of this software.

Your mileage will vary. If in any doubt do not use it.

=begin internals

=head1 INTERNALS

B<Class::Facet> strives to be as unintrusive as possible, so as to
hide itself from the rest of the code; this is not for security, but
rather for testability (code that works with a ``normal'' object
should work out-of-the-box with a facet instead).

The facet class does B<not> inherit from the original class; rather,
it works by delegation, and delegating stubs are created on demand by
B<Class::Facet>.  Additionally, L</_miranda_AUTOLOAD> accounts for the
methods that exist in the original object, but not the facet object.

=head2 _carp($facetclass, %named_args)

Throws an error using $facetclass' configured error handler.
%named_args is a (flat) hash of named options similar to those
documented in L</on_error>; the C<-file>, C<-line> and C<-facetclass>
will be filled out (if not already present) and the resulting
associative array will be passed to the C<$sub> error handler declared
with C<on_error()>, if any.

=cut

sub _carp {
    my ($class, $facetclass, %args) = @_;
    my (undef, $filename, $line) = caller(1);
    $args{-facetclass} ||= $facetclass;
    $args{-file}       ||= $filename;
    $args{-line}       ||= $line;
    if (my $die = $facetclass->can("_facet_die")) {
        $die->($facetclass, %args);
    }
    # Still here? Either $die didn't, or there is no on_error handler.
    if (exists(&{"${facetclass}::"})) {
        no strict "refs";
        &{"${facetclass}::_facet_die"}(%args);
    }
    $args{-details} ||= "Class::Facet error";
    croak "$args{-details} ($args{-reason})"
        . " at $args{-file} line $args{-line}\n";
};


=head2 _miranda_AUTOLOAD

Installed as the facet class' AUTOLOAD method by L</from>.  Therefore,
as per L</perlsub/Autoloading>, I<_miranda_AUTOLOAD> catches calls to
functions that are unknown to the facet class.  If this call is to an
instance method (B<not> class method) of the original object,
I<_miranda_AUTOLOAD> invokes L</facet_error> on the facet object; in
all other cases (unknown method, function or class method call),
I<_miranda_AUTOLOAD> emulates Perl's original error message so as to
pretend that the function actually doesn't exist.

=cut

sub _miranda_AUTOLOAD {
    my ($thispackage, $methname);
    {
        no strict "refs";
        # ${"AUTOLOAD"} resolves to the $AUTOLOAD variable in whatever
        # package the sub will be transplanted to. This is just so
        # deliciously evil :-)
        ($thispackage, $methname) = (${"AUTOLOAD"} =~ m/^(.*)::(.*?)$/);
    }
    return if $methname eq "DESTROY";
    if ((ref($_[0]) eq $thispackage) &&
        ($_[0]->{delegate}->can($methname))) {
        Class::Facet->_carp($thispackage, -method => $methname,
                            -reason => "forbidden_method");
    }
    my (undef, $file, $line) = caller();
    die sprintf(qq{Can't locate object method "%s" via package "%s" }
                . qq{at %s line %d.\n},
                $methname, $thispackage, $file, $line);
}

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;

test "import" => sub {
    no warnings "redefine";
    our @calls;
    local *Class::Facet::from = sub { shift; push (@calls, "from", \@_) };
    local *Class::Facet::delegate = sub
        { shift; push (@calls, "delegate", \@_) };
    foreach my $snip ("import use simple",
                      "import converted into method calls",
                      "import use multiple") {
        @calls = ();
        my $callerpackage = "Foo::ReadOnlyFacet";
        eval "package $callerpackage; " .
            My::Tests::Below->pod_code_snippet($snip); die $@ if $@;
        is_deeply(\@calls,
                  [ from => [ "Foo::ReadOnlyFacet", "foo" ],
                    delegate => [ "Foo::ReadOnlyFacet", "bar", "baz" ] ]);
    }
};

=head2 Foo::TheRealOne

The bogus original class defined in L</SYNOPSIS> is the basis for all
tests.  The methods are all stubbed down to simply pushing a marker
into @Foo::TheRealOne::calls whenever they are called.

=cut

my $synopsis = My::Tests::Below->pod_code_snippet("synopsis main class");
$synopsis =~ s/sub get_substuff.*//g;
$synopsis =~ s|sub (.*) { \.\.\. }|sub $1 { push(our \@calls, "$1"); }|g;
eval $synopsis; die $@ if $@;

sub Foo::TheRealOne::new { bless {}, shift }
sub Foo::TheRealOne::in_a_bad_mood { 0 } # Lucky you!

=head2 Foo::TheRealOne::SubStuff

The class of the object returned by C<Foo::TheRealOne::get_substuff>.
Obviously no less bogus than the rest of the test fixture.

=cut

sub Foo::TheRealOne::get_substuff {
    return bless { }, "Foo::TheRealOne::SubStuff";
}

sub Foo::TheRealOne::SubStuff::facet_readonly { shift }

test "synopsis, BEGIN style" => sub {
    eval My::Tests::Below->pod_code_snippet("synopsis facet class");
    die $@ if $@;
    @Foo::TheRealOne::calls = ();
    my $facet = Foo::TheRealOne->new->facet_readonly;
    $facet->get_this();
    is_deeply(\@Foo::TheRealOne::calls, ["get_this"]);
    eval {
        $facet->set_that;
        fail("method should have thrown");
    };
    isnt($@, undef);
    is_deeply(\@Foo::TheRealOne::calls, ["get_this"]);
};

test 'synopsis, "use Class::Facet" style' => sub {
    eval "package Foo::ReadOnlyFacetToo;" .
        My::Tests::Below->pod_code_snippet("synopsis without BEGIN");
    die $@ if $@;
    @Foo::TheRealOne::calls = ();
    my $facet = Class::Facet->make
        ("Foo::ReadOnlyFacetToo", Foo::TheRealOne->new);
    $facet->get_this();
    is_deeply(\@Foo::TheRealOne::calls, ["get_this"]);
    eval {
        $facet->set_that;
        fail("method should have thrown");
    };
    isnt($@, undef);
    is_deeply(\@Foo::TheRealOne::calls, ["get_this"]);
};

test "facet structure" => sub {
    my $origobject = Foo::TheRealOne->new;
    my $facet = $origobject->facet_readonly;
    my $facetclass = "Foo::ReadOnlyFacet";
    my $facettoo = eval My::Tests::Below->pod_code_snippet
        ("make structure");
    die $@ if $@;
    is_deeply($facet, $facettoo);
};

test "transparently delegated method" => sub {
    local *Foo::TheRealOne::foo = sub { pass };
    eval "package Foo::ReadOnlyFacet; " .
        My::Tests::Below->pod_code_snippet("delegate equivalent");
    die $@ if $@;
    Foo::TheRealOne->new->foo();
};

test "bogus method calls in the facet look real" => sub {
    my $real = Foo::TheRealOne->new;
    my @errors;
    foreach my $object ($real, $real->facet_readonly) {
        eval { $object->glork(); };
        push(@errors, $@);
    }
    is(scalar(grep { defined } @errors), 2);
    ok($errors[1] =~ s/ReadOnlyFacet/TheRealOne/);
    is($errors[0], $errors[1]);
};

test "on_error and faceted-out methods" => sub {
    eval {
        Foo::TheRealOne->new->facet_readonly->set_this();
        fail;
    };
    like($@, qr/^forbidden method set_this/);
};

TODO:{
	local $TODO = "Defensiveness not implemented";
test "make defensiveness" => sub {
    @Bogus::SubFacet::ISA = qw(Foo::ReadOnlyFacet);
    my $object = Foo::TheRealOne->new;

    eval {
        Class::Facet->make("Bogus::SubFacet", $object);
        fail("subclassing a facet is a no-no");
    };

    @Foo::SubReal::ISA = qw(Foo::TheRealOne);
    Class::Facet->make("Foo::ReadOnlyFacet", Foo::SubReal->new);
    pass("->make works for subclasses too");
};
};

=end internals

=cut

