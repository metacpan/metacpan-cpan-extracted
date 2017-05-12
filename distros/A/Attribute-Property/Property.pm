package Attribute::Property;

# $Id: Property.pm,v 1.48 2003/04/21 16:04:14 juerd Exp $

use 5.006;
use Attribute::Handlers;
use Carp;

# use Want qw(want rreturn);
BEGIN {
    if (eval { require Want }) {
        *want    = *Want::want;
        *rreturn = *Want::rreturn;
    } else {
        *want    = sub { 0 };
        *rreturn = sub { 0 };
    }
}

no strict;
no warnings;

our $VERSION = '1.05';

$Carp::Internal{Attribute::Handlers}++;	 # may we be forgiven for our sins
$Carp::Internal{+__PACKAGE__}++;

my %p;

sub UNIVERSAL::Property : ATTR(CODE) {
    my (undef, $s, $r) = @_;
    croak "Cannot use Property attribute with anonymous sub" unless ref $s;
    my $n = *$s{NAME};
    *$s = defined &$s
        ? sub : lvalue {
            croak "Too many arguments for $n method" if @_ > 2;
            if (want 'RVALUE') {
                rreturn $_[0]{$n} if @_ != 2;
                $r->($_[0], local $_ = $_[1]) 
                    or croak "Invalid value for $n property";
                rreturn $_[0]{$n} = $_;
            }
            tie my $foo, __PACKAGE__, ${ \$_[0]{$n} }, $r, $_[0], $n;
            @_ == 2 ? ( $foo = $_[1] ) : $foo
        }
        : sub : lvalue {
            croak "Too many arguments for $n method" if @_ > 2;
            @_ == 2 ? ( $_[0]{$n} = $_[1] ) : ${ \$_[0]{$n} }
        };
    undef $p{\&$s};
}

sub TIESCALAR { bless \@_, shift }  # @_ = (class, lvalue, subref, object, name)
sub FETCH { $_[0][0] }

sub STORE {
    $_[0][1]->($_[0][2], local $_ = $_[1])
        or croak "Invalid value for $_[0][3] property";
    $_[0][0] = $_;
}

sub UNIVERSAL::New : ATTR(CODE) {
    my ($P, $s, $r) = @_;
    my $n = *$s{NAME};
    undef $r if not defined &$s;
    *$s = sub {
        my $c = shift;
        croak qq(Can't call method "$n" on a reference) if ref $c;
        croak "Odd number of arguments for $c->$n" if @_ % 2;
        my $o = bless {}, $c;
        my $l = \&Carp::shortmess;
        local *Carp::shortmess = sub { $_[-1] .= " in $c->$n"; &$l; };
        while (my ($p, $v) = splice @_, 0, 2) {
            my $m = $o->can($p);
            $m and exists $p{$m} or croak qq(No such property "$p");
            $m->($o, $v);
        }
        return $r->($o) if $r;
        return $o;
    };
}

1;

=head1 NAME

Attribute::Property - Easy lvalue accessors with validation. ($foo->bar = 42)

=head1 SYNOPSIS

=head2 CLASS

    use Attribute::Property;
    use Carp;

    package SomeClass;

    sub new : New { further initialization here ... }
    
    sub nondigits : Property { /^\D+\z/ }
    sub digits    : Property { /^\d+\z/ or croak "custom error message" }
    sub anyvalue  : Property;
    sub another   : Property;

    sub value     : Property {
	my $self = shift;  # Object is accessible as $_[0]
	s/^\s+//;          # New value can be altered through $_ or $_[1]

	$_ <= $self->maximum or croak "Value exceeds maximum";
    }

    package Person;

    sub new  : New;
    sub name : Property;
    sub age  : Property { /^\d+\z/ and $_ > 0 }

=head2 USAGE

    my $object = SomeClass->new(digits => '123');

    $object->nondigits = "abc";
    $object->digits    = "123";
    $object->anyvalue  = "abc123\n";

    $object->anyvalue('archaic style still works');

    my $john = Person->new(name => 'John Doe', age => 19);
    
    $john->age++;
    printf "%s is now %d years old", $john->name, $john->age;

    # These would croak
    $object->nondigits = "987";
    $object->digits    = "xyz";

=head1 DESCRIPTION

This module introduces two attributes that make object oriented programming
much easier.  You can just define a constructor and some properties without
having to write accessors.

=over 4

=item C<Property>

    sub color : Property;
    sub color : Property { /^#[0-9A-F]{6}$/ }

The C<Property> attribute turns a method into an object property.  The original
code block is used only to validate new values, the module croaks if it returns
false.  The method returns an I<lvalue>, meaning that you can create a reference
to it, assign to it and apply a regex to it.

Undefined subs (subs that have been declared but do not have a code block) with
the C<Property> attribute will be properties without any value validation.

In the validation code block, the object is in C<$_[0]> and the value to be
validated is aliased as C<$_[1]> and for regexing convenience as C<$_>.

Feel free to croak explicitly if you don't want the default error message.

=item C<New>

    sub new : New;
    sub new : New { my $self = shift; ...; return $self; }

The C<New> attribute turns a method into an object constructor.  The original
code block can be used for further initialization, but it is completely
optional.

The constructor takes named arguments in C<< property => value >> pairs and
populates the hash with the given pairs.  After validating them, of course.

The new object is passed to the initialization code block as C<$_[0]>.  Be
sure to return the object if you use any initialization block.  If there is
no initialization code block, Attribute::Property takes care of returning
the new object.

=back

=head1 PREREQUISITES

Your object must be a blessed hash reference.  The property names will be used
for the hash keys.

For class properties of C<Some::Module>, the hash C<%Some::Module> is used.
For class properties of packages without C<::>, the behaviour is undefined.

In short: C<< $foo->bar = 14 >> and C<< $foo->bar(14) >> assign 14 to 
C<< $foo->{bar} >> after positive validation.  The same thing happens with C<< my
$foo = Class->new(bar => 14); >> given that C<Class::new> uses the C<New>
property.

If you have the Want module installed, Attribute::Property will use it to make
rvalue method calls more efficient.

=head1 COMPATIBILITY

Old fashioned C<< $object->property(VALUE) >> is still available.

This module requires a modern Perl (5.6.0+), fossils like Perl 5.00x don't
support our chicanery.

=head1 BUGS

=over 2

=item *

The C<New> attribute should really be called C<Constructor>, but that would
conflict with the existing Attribute::Constructor module.

=back

=head1 LICENSE

There is no license.  This software was released into the public domain.  Do
with it what you want, but on your own risk.  Both authors disclaim any
responsibility.

=head1 AUTHORS

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

Matthijs van Duin <xmath@cpan.org>

=cut

# vim: ft=perl sts=0 noet sw=8 ts=8

