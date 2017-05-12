#!perl -w

package App::CamelPKI::RestrictedClassMethod;
use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::RestrictedClassMethod> - Application of the "brand"
capability discipline pattern to sensitive constructors and classes.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  package App::CamelPKI::Foo;

  use App::CamelPKI::RestrictedClassMethod ":Restricted";

  sub new : Restricted {
      my ($class) = @_;
      # ...
  }

  App::CamelPKI::RestrictedClassMethod->lockdown(__PACKAGE__);

  # Meanwhile, in a nearby piece of privileged code...

  my $brand = grab App::CamelPKI::RestrictedClassMethod("App::CamelPKI::Foo");
  my $object = $brand->invoke("new", @args);

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

B<App::CamelPKI::RestrictedClassMethod> is an implementation of the "brand"
pattern, which is of general use in capability discipline (see
L<App::CamelPKI::CodingStyle/Capability discipline>).  It is used to
ascertain that the security-sensitive class methods, especially the
construction of objects that use the ambiant autority of the process,
are kept secure in capability discipline style.

=head1 CAPABILITY DISCIPLINE

An instance of I<App::CamelPKI::RestrictedClassMethod> represents the right
to invoke methods marked as C<Restricted> in an given Perl class.

=cut

use Class::Inspector;
use App::CamelPKI::Error;

=head1 "use" form

The L</SYNOPSIS> formula

    use App::CamelPKI::RestrictedClassMethod ":Restricted";

indicates that the calling package wants to use the C<Restricted>
attribute for its methods.  When affixed the C<Restricted> on a method
class (again as shown in the synopsis) prevents the execution of this
method to all excepted to holder of the corresponding
I<App::CamelPKI::RestrictedClassMethod> object (see L</METHODS>).

=cut

sub import {
    my ($class, @args) = @_;
    return if ! @args;
    die "unsupported import form" unless (@args == 1 &&
                                          $args[0] eq ":Restricted");
    my ($caller) = caller;
    no strict "refs";
    *{$caller . "::MODIFY_CODE_ATTRIBUTES"} = sub {
        my ($package, $coderef, @attrs) = @_;
        return @attrs unless (@attrs == 1 && $attrs[0] eq "Restricted");
        __PACKAGE__->_create($package)->
            _register_restricted_constructor($coderef);
        return;
    };
}

=head1 CONSTRUCTORS

=head2 grab($classname)

Commences an hostile takeover on $classname. I<grab> will only succeed
once on any given $classname during the lifetime of the Perl
interpreter; when it succeeds, it returns an instance of the
I<App::CamelPKI::RestrictedClassMethod> class which represents the right to
invoke methods marked as C<Restricted> in $classname.

=cut

sub grab {
    my ($class, $wantclass) = @_;
    # Can also be invoked as an instance method from inside this
    # package:
    my $self = ref($class) ? $class : $class->_get($wantclass);
    throw App::CamelPKI::Error::Privilege("$wantclass is not loaded yet")
        if (! defined $self);
    throw App::CamelPKI::Error::Privilege("$wantclass is already taken")
        if ($self->{grabbed});
    $self->lockdown();
    $self->{grabbed}++;
    return $self;
}

=head2 fake_grab($classname)

Returns an object of class
L</App::CamelPKI::RestrictedClassMethod::FakeBrand>.  Unlike the real
L</grab>, a C<fake_grab()> has no security consequences: restricted
methods are not locked down (see L</lockdown>), and C<fake_grab()> may
succeed several times for the same $classname.

=cut

sub fake_grab {
    my ($class, $wantclass) = @_;
    return bless { class => $wantclass },
        "App::CamelPKI::RestrictedClassMethod::FakeBrand";
}

=head1 CLASS METHODS

=head2 grab_all

=head2 grab_all(@classnames)

Performs a call to L</grab> on all classes which have not yet been
grabbed; returns an associative array ("flat hash") alternating class
names and the corresponding brands. This method is meant to be called
at the end of the application's initialization sequence, so as to
guarantee that there are no restricted constructors lingering out
unprotected.  It is also possible for said initialization sequence to
make use of the return value, and distribute all brands by itself to
the appropriate places; in this case, L</grab> will not be called at
all by application code.

=cut

sub grab_all {
    my ($class) = @_;
    my @retval;
    foreach my  $wantclass ($class->_allpackages) {
        my $brand = $class->_get($wantclass);
        next if ($brand->{grabbed});
        push(@retval, $wantclass, scalar($brand->grab));
    }
    return @retval;
}

=head2 lockdown($classname)

Prevents the restricted class methods in $classname from being called,
but don't L</grab> them just yet.  This is optional, as C<grab()>
performs a lockdown anyway.  This class method is idempotent.

=cut

sub lockdown {
    # Also an instance method (for internal calls from L</grab>)
    my $self = ref($_[0]) ? shift : shift->_create(shift);

    while(my $coderef = shift @{$self->{constructor_refs}}) {
        no strict "refs";
        my $codename;
        foreach (@{Class::Inspector->functions($self->{class})}) {
            $codename = $_, last if
                (*{$self->{class} . "::$_"}{CODE} == $coderef);
        }
        throw App::CamelPKI::Error::Internal("ASSERTION_FAILED")
            if (! $codename);
        $self->{constructors}->{$codename} = $coderef;
        no warnings "redefine";
        *{$self->{class} . "::$codename"} = sub {
            throw App::CamelPKI::Error::Privilege
                ("This constructor is restricted");
        };
    }
    return;
}

=head1 METHODS

=head2 is_fake()

Returns false.  See also
L</App::CamelPKI::RestrictedClassMethod::FakeBrand>.

=cut

sub is_fake { 0 }

=head2 invoke($methname, @args)

Invokes the restricted class method named $methname with @args
arguments in the package guarded by this object (that is, the
$classname that was passed as an argument to L</grab>).

=cut

sub invoke {
    my $self = shift; my $meth = shift; unshift @_, $self->{class};
    goto $self->{constructors}->{$meth};
}

=head1 App::CamelPKI::RestrictedClassMethod::FakeBrand

This ancillary class is for fake brand objects created with
L</fake_grab>.  Instances of the class act somewhat like brands (that
is, they also implement L</invoke>); they are intended for testability
purposes, so that code that uses B<App::CamelPKI::RestrictedClassMethod>
can use fake brands for tests, and real ones for production.

=cut

package App::CamelPKI::RestrictedClassMethod::FakeBrand;

=head2 invoke($method, @args)

Invokes $method with arguments @args directly from the package the
brand was constructed from (ie the C<$class> parameter to
L</fake_grab>).

=cut

sub invoke {
    my $self = shift; my $meth = shift; unshift @_, $self->{class};
    goto $self->{class}->can($meth);
}

=head2 is_fake

Returns true.

=cut

sub is_fake { 1 }

=begin internals

=head1 PRIVATE METHODS

=cut

package App::CamelPKI::RestrictedClassMethod;

=head2 _get($classname)

=head2 _create($classname)

These two class methods return the I<App::CamelPKI::RestrictedClassMethod>
instance for $classname. I<_create> creates it if doesn't already
exist.

=head2 _allpackages()

This class method returns the list of all packages that have been
created using L</create>, and are therefore valid arguments to
L</grab>.

=cut

{
    my %brands;
    sub _get { $brands{$_[1]} }
    sub _allpackages { keys %brands }
    sub _create {
        my ($class, $branded) = @_;
        $brands{$branded} ||= bless { class => $branded,
                                      constructor_refs => [] }, $class;
    }
}

=head2 _register_restricted_constructor($coderef)

Called each time a C<Restricted> attribute is seen in some caller
package's source code; adds $coderef to the list of symbols to
protect.

=cut

sub _register_restricted_constructor {
    my ($self, $coderef) = @_;
    push @{$self->{constructor_refs}}, $coderef;
}

require My::Tests::Below unless caller;
1;

__END__

=head1 TESTS

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Error;

test "synopsis" => sub {
    my $code = My::Tests::Below->pod_code_snippet("synopsis");
    ($code =~ s|# ...|return bless {}, \$class;|)
        or die "Could not fudge ->new() code";
    ($code =~ s|# Meanwhile.*$|package main;|m)
        or die "Could not fudge the synopsis code";

    my @args;
    my $object = eval $code; die $@ if $@;
    ok($object->isa("App::CamelPKI::Foo"));

    try {
        grab App::CamelPKI::RestrictedClassMethod("App::CamelPKI::Foo");
        fail("must not succeed more than once");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };

    try {
        App::CamelPKI::Foo->new();
        fail("access to the constructor should be forbidden");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };
};

test "grab_all" => sub {
    {
        package Restricted::Foo;
        use App::CamelPKI::RestrictedClassMethod ":Restricted";
        sub new : Restricted { };
        package Restricted::Bar;
        use App::CamelPKI::RestrictedClassMethod ":Restricted";
        sub new : Restricted { };
    }
    ok(App::CamelPKI::RestrictedClassMethod->grab("Restricted::Foo")
       ->isa("App::CamelPKI::RestrictedClassMethod"));
    my %grabbed = App::CamelPKI::RestrictedClassMethod->grab_all;
    ok(! exists $grabbed{"Restricted::Foo"}, "already grabbed");
    $grabbed{"Restricted::Bar"}->invoke("new");
    try {
        App::CamelPKI::RestrictedClassMethod->grab("Restricted::Bar");
        fail("grab_all did not work");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };
    try {
        Restricted::Bar->new;
        fail("grab_all did not lockdown");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };
};

test "fake_grab" => sub {
    # Must add a new fake class at run time to evade the ->grab_all
    # above:
    eval <<"STUFF"; die $@ if $@;
        package Restricted::Baz;
        use App::CamelPKI::RestrictedClassMethod ":Restricted";
        sub new : Restricted { bless {}, shift };
STUFF
    my $fakebrand = App::CamelPKI::RestrictedClassMethod
        ->fake_grab("Restricted::Baz");
    App::CamelPKI::RestrictedClassMethod
        ->fake_grab("Restricted::Baz");
    ok($fakebrand->invoke("new")->isa("Restricted::Baz"));
    App::CamelPKI::RestrictedClassMethod->grab("Restricted::Baz");
    try {
        $fakebrand->invoke("new");
        fail;
    } catch App::CamelPKI::Error::Privilege with {
        pass("real grab cancels fake one");
    };
};

=end internals

=cut
