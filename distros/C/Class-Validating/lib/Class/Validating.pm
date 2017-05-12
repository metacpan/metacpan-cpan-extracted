# $Id: Validating.pm 4 2005-01-06 06:22:24Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::Validating;
use strict;
use Class::Data::Inheritable ();
use Params::Validate         ();

our $VERSION = '0.02';

sub import
{
    my $class = shift;
    my($package) = caller;

    {
        no strict 'refs';
        my @isa = @{"${package}::ISA"};
        if (!grep { 'Class::Data::Inheritable' eq $_ } @isa) {
            @{"${package}::ISA"} = (@isa, 'Class::Data::Inheritable');
        }
        *{"${package}::validate_args"} = \&validate_args;
        *{"${package}::get_pv_spec"}   = \&get_pv_spec;
        *{"${package}::_get_pv_spec"}  = \&_get_pv_spec;
        *{"${package}::set_pv_spec"}   = \&set_pv_spec;
    }

}

# Hey, use the (slight) evil-ness that we wanted to fix :)
my @SetPVSpecValidate = (
    { type => Params::Validate::SCALAR() },
    { type => Params::Validate::HASHREF() | Params::Validate::ARRAYREF() }
);
sub set_pv_spec
{
    my $class = shift;
    my($name, $spec) = Params::Validate::validate_pos(@_, @SetPVSpecValidate);

    my $method = "pv_spec_$name";
    $class->mk_classdata($method);
    $class->$method($spec);
}

sub _get_pv_spec
{
    my($class, $sub) = @_;

    my $simple_sub  = ($sub =~ /([^:]+)$/)[0];
    my $pv_spec_name = "pv_spec_${simple_sub}";
    my $pv_spec      = $class->$pv_spec_name;
    return $pv_spec;
}

my @GetPVSpecValidate = (
    { type => Params::Validate::SCALAR() }
);
sub get_pv_spec
{
    my $class = shift;
    my($sub) = Params::Validate::validate_pos(@_, @GetPVSpecValidate);
    
    $class = ref($class) || $class;
    return $class->_get_pv_spec("${class}::${sub}");
}

my @ValidateArgsValidate = (
    { type => Params::Validate::ARRAYREF() },
    { type => Params::Validate::HASHREF(), optional => 1 }
);
sub validate_args(\@\%)
{
    my $self = shift;
    my($params, $extra_args) = Params::Validate::validate_pos(@_, @ValidateArgsValidate);

    my $sub  = (caller(1))[3];

    my $pv_spec = $self->_get_pv_spec($sub);
    if (!$pv_spec) {
        require Carp;
        Carp::croak("pv_spec for $sub is not defined.");
    }
    my @args = (
        spec   => $pv_spec,
        called => $sub,
    );
    if (defined $extra_args) {
        push @args, %{$extra_args};
    }
    push @args, (params => $params);
    return Params::Validate::validate_with(@args);
}

1;

__END__

=head1 NAME

Class::Validating - Provide Subclass-able Validation Mechanism

=head1 SYNOPSIS

  package MyClass;
  use Class::Validating;
  __PACKAGE__->set_pv_spec(foo => { type => Params::Validate::HASHREF() });

  sub foo
  {
      my $self = shift;

      # validate @_ according to set_pv_spec() above
      my %args = $self->validate_args(@_);
      ...
  }

  package MySubClass;
  use base qw(MyClass);

  __PACKAGE__->set_pv_spec(%newspec);

  sub foo
  {
      my $self = shift;
      # now validate @_ according to %newspec, not MyClass' spec for foo
      my %args = $self->validate_args(@_);

      # you can call the super class' method as well, and it will
      # use the correct spec
      $self->SUPER::validate_args(...);
  }

=head1 DESCRIPTION

Params::Validate is a great parameter validation tool, but because a lot
of the code that utilises Params::Validate tend to be written with a lexical
validation spec (like the code below) it was either hard or tedious to 
extend the class that uses Params::Validate.

A typical code that uses Params::Validate might look like this:

  package MyClass;
  use strict;
  use Params::Validate qw(validate SCALAR HASHREF);

  my %FooValidate = (
    arg1 => { type => SCALAR },
    arg2 => { type => HASHREF }
  );
  sub foo
  {
     my $self = shift;
     my %args = validate(@_, \%FooValidate);
     ....
  }

This code unfortunately doesn't allow too much flexibility for someone
trying to write a subclass, because %FooValidate is a lexical variable
and is not visible in the subclass.

This module tries to solve this problem by creating a data slot via
Class::Data::Inheritable.

Using Class::Validating, above example now look like this:

  package MyClass;
  use strict;
  use Class::Validating;

  __PACKAGE__->set_pv_spec(foo => {
    arg1 => {type => SCALAR},
    arg2 => {type => HASHREF}
  });
  sub foo
  {
     my $self = shift;
     my %args = $self->validate_args(@_);
     ...
  }

In your subclass, you will be able to change the validation behavior by
calling set_pv_spec():

  package MySubclass;
  use strict;
  use base qw(MyClass);

  __PACKAGE__->set_pv_spec(foo => {
    arg1 => {type => SCALAR},
    arg2 => {type => HASHREF},
    arg3 => {type => ARRAYREF}
  });
  sub foo
  {
     my $self = shift;
     my %args = $self->validate_args(@_);
     ....
     # you can safely call the parent's foo() method, and expect it
     # to validate using the parent's validation spec:
     $self->SUPER::foo(@args);
  }

=head1 METHODS

=head2 validate_args(\@args[, \%opts])

   @args = $self->validate_args(\@_);

   %opts = (called => "foo bar");
   @args = $self->validate_args(\@_, \%opts);

Validates @args, using the validation spec that the current subroutine
name points to. The validation spec must be defined via set_pv_spec()
prior to calling this method. If no spec matching the method name is
found, an exception will be thrown.

%opts may contain extra arguments to Params::Validate::validate_with(), 
such as 'allow_extra', 'called', etc. Note
that if you give the "spec" argument to %opts, it WILL override whatever
validation spec you defined in set_pv_spec(). See L<Params::Validate> for
more details

=head2 set_pv_spec(...)

Set the Params::Validate spec for a subroutine. The subroutine name must
be given as the unqualified name (no module prefixes).

set_pv_spec() can take either a hashref or arrayref as its second argument.

  $class->set_pv_spec(subname => \%spec);
  $class->set_pv_spec(subname => \@spec);

The difference is that a hashref implicitly means the subroutine expects
named parameters, and arrayref means the subroutine expects positional
parameters (i.e., the difference between P::V::validate() and P::V::validate_pos())

=head2 get_pv_spec($subname)

Returns the validation spec for the given subroutine name. The subroutine
name is passed as a unqualified name (i.e., no package prefixes)

  $spec = $class->get_pv_spec($subname)

=head1 SEE ALSO

L<Params::Validate>

=head1 AUTHOR

Daisuke Maki <dmaki@cpan.org>

=cut
