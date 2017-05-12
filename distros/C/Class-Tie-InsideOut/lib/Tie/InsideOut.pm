package Tie::InsideOut;

use 5.006001;
use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( refaddr );

our $VERSION = '0.11';

our @ISA = qw( );

my %NameSpaces;               # default namespace for each hash
my %Keys;                     # tracks defined keys and namespaces

=begin internal

The %Keys hash is structured as follows:

  $Keys{$id}->{$key}->{$namespace}        = $hash_ref

C<$id> refers to the unique object identifier (returned by the L</_get_id> method).

C<$key> refers to the name of the hash key, qhich corresponds to the name of a hash
variable in the C<$namespace>.

C<$namespace> refers to the namespace that the value is in. Encapsulation means
that child classes can use the same key names without conflict.

C<$hash_ref> is a reference to the hash variable that contains the value. Which is
accessible:

  $Keys{$id}->{$key}->{$namespace}->{$id} = $value

We maintain a structure that incidcates where all of the keys are so that we can
clean up the data when the object is destroyed.  It also allows us to serialize
and deserialize data.

=end internal

=cut

sub TIEHASH {
  my $class  = shift || __PACKAGE__;

  my $scalar;
  my $self  = \$scalar;
  bless $self, $class;

  my $id    = $self->_get_id;
  {
    my $caller = shift || (caller)[0];
    no strict 'refs';
    $NameSpaces{$id} = $caller;
  }
  $self->CLEAR;

  return $self;
}

BEGIN {
  *new = \&TIEHASH;
}

sub DESTROY {
  my $self = shift;
  my $id   = $self->_get_id;

  $self->CLEAR;

  delete $Keys{$id};
  delete $NameSpaces{$id};
}

sub CLEAR {
  my $self = shift;
  my $id   = $self->_get_id;

  foreach my $key (keys %{$Keys{$id}}) {
    foreach my $namespace (keys %{$Keys{$id}->{$key}}) {
      delete $Keys{$id}->{$key}->{$namespace}->{$id};
      delete $Keys{$id}->{$key}->{$namespace};
    }
    delete $Keys{$id}->{$key};
  }
  $Keys{$id} = { };
}

sub SCALAR {
  my $self = shift;
  my $id   = $self->_get_id;
  return scalar (%{$Keys{$id}});
}

sub FETCH {
  my $self = shift;
  my $key  = shift;

  my ($id, $hash_ref) = $self->_validate_key($key);
  $hash_ref->{$id};
}

sub EXISTS {
  my $self = shift;
  my $key  = shift;

  my ($id, $hash_ref) = $self->_validate_key($key);
  exists $hash_ref->{$id};
}

# Being able to iterate over the keys is useful, but limited. After version
# 0.04, encapsulation is enforced.

sub FIRSTKEY {
  my $self = shift;
  my $id   = $self->_get_id;
  my $aux  = keys %{$Keys{$id}}; # reset each iterator
  return each %{$Keys{$id}};
}

sub NEXTKEY {
  my $self = shift;
  my $id   = $self->_get_id;
  return each %{$Keys{$id}};
}

sub DELETE {
  my $self = shift;
  my $key  = shift;

  my ($id, $hash_ref) = $self->_validate_key($key);
  delete $Keys{$id}->{$key};
  delete $hash_ref->{$id};
}

sub STORE {
  my $self = shift;
  my $key  = shift;
  my $val  = shift;

  my ($id, $hash_ref, $namespace)  = $self->_validate_key($key);
  $Keys{$id}->{$key}->{$namespace} = $hash_ref;
  $hash_ref->{$id}    = $val;
}

sub STORABLE_freeze {
  my $self = shift;
  my $deep = shift; # return if ($deep);
  my $id   = $self->_get_id;

  my $struc = { };
  my $refs  = [ $NameSpaces{$id}, $struc ];
  my $index = @$refs;

  foreach my $key (keys %{$Keys{$id}}) {
    foreach my $namespace (keys %{$Keys{$id}->{$key}}) {
      my $package = *{$Keys{$id}->{$key}->{$namespace}}{PACKAGE};
      $struc->{$key}->{$package} = $index;
      $refs->[$index++] = $Keys{$id}->{$key}->{$namespace}->{$id};
    }
  }

  return ($index, $refs);
}

sub STORABLE_thaw {
  my $self = shift;
  my $deep = shift; # return if ($deep);

  $self->CLEAR;
  my $id   = $self->_get_id;

  my ($size, $refs) = @_;

  $self->CLEAR if (exists $Keys{$id});

  $NameSpaces{$id} = $refs->[0] unless (defined $NameSpaces{$id}); # Storable just blesses
  croak("Namespaces do not match: ", $NameSpaces{$id}, " and ", $refs->[0]),
    unless ($NameSpaces{$id} eq $refs->[0]);

  no strict 'refs';

  my $struc = $refs->[1];
  foreach my $key (keys %$struc) {
    foreach my $namespace (keys %{$struc->{$key}}) {
      my $index = $struc->{$key}->{$namespace};
      croak "No namespace defined" if ($namespace eq "");

      my $hash_ref = *{$namespace."::"};
      if ((exists $hash_ref->{$key}) &&  (ref *{$hash_ref->{$key}}{HASH})) {
	$Keys{$id}->{$key}->{$namespace} = $hash_ref->{$key};
	$hash_ref->{$key}->{$id} = $refs->[$index];
      }
      else {
	croak "Symbol \%".$key." not defined in namespace ".$namespace;
      }
    }
  }
  return $self;
}

sub _get_id {
  my $self = shift;
  return refaddr($self);
}

sub _validate_key {
  my ($self, $key) = @_;
  my $id   = $self->_get_id;

  # We get the name of the subroutine that called us, and use its
  # namespace to look for the hash that contains the key value.

  # Warning: Perl documentation notes that the caller information may
  # be optimized away when the value is greater than 1.

  my $caller_namespace = (caller(2))[3];
  my $hash_ref;

  if (defined $caller_namespace) {
    no strict 'refs';

    # If we're in an eval, then we resort to using the caller package

    if ($caller_namespace eq "(eval)") {
      $caller_namespace = (caller(2))[0];
      $caller_namespace =~ s/\s(eval\(\s\d+)?\)$//; # remove eval
    }
    else {
      $caller_namespace =~ s/::(((?!::).)+)$//;
    }
    $hash_ref = *{$caller_namespace."::"};
  }
  else {
    croak "Cannot determine namespace of caller"
      unless (exists $NameSpaces{$id});
    no strict 'refs';
    $hash_ref = *{$NameSpaces{$id}."::"};
    $caller_namespace = *{$hash_ref}{PACKAGE};
  }

  if ((exists $hash_ref->{$key}) &&  (ref *{$hash_ref->{$key}}{HASH})) {
    return ($id, $hash_ref->{$key}, $caller_namespace);
  }
  else {

#     print STDERR "\n\x23 key=$key\n\x23",
#       join(" ", map {$_||""} (caller(0))), "\n\x23",
#       join(" ", map {$_||""} (caller(1))), "\n\x23",
#       join(" ", map {$_||""} (caller(2))), "\n\x23",
#       join(" ", map {$_||""} (caller(3))), "\n";

    my $err_msg = "Symbol \%".$key." not defined";
    if ($caller_namespace ne "main") {
      $err_msg .= " in namespace ".$caller_namespace;
    }
    croak $err_msg;
  }
}

1;
__END__


=head1 NAME

Tie::InsideOut - Tie hashes to variables in caller's namespace

=begin readme

=head1 REQUIREMENTS

Perl 5.6.1, and L<Scalar::Util>.

=head1 INSTALLATION

Installation can be done using the traditional Makefile.PL or the newer
Build.PL methods.

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

Using Build.PL (if you have Module::Build installed):

  perl Build.PL
  perl Build test
  perl Build install

=end readme

=head1 SYNOPSIS

  use Tie::InsideOut;

  our %GoodKey;

  tie %hash, 'Tie::InsideOut';

  ...

  $hash{GoodKey} = 1; # This will set a value in %GoodKey

  $hash{BadKey}  = 1; # This will cause an error if %BadKey does not exist

=head1 DESCRIPTION

This package ties hash so that the keys are the names of variables in the caller's
namespace.  If the variable does not exist, then attempts to access it will die.

An alternative namespace can be specified, if needed:

  tie %hash, 'Tie::InsideOut', 'Other::Class';

This gives a convenient way to restrict valid hash keys, as well as provide a
transparent implementation of inside-out objects, as with L<Class::Tie::InsideOut>.

This package also tracks which keys were set, and attempts to delete keys when an
object is destroyed so as to conserve resources. (Whether the overhead in tracking
used keys outweighs the savings is yet to be determined.)

Note that your keys must be specified as C<our> variables so that they are accessible
from outside of the class, and not as C<my> variables.

=head2 Serialization

Hashes can be serialized and deserialized using the L<Storable> module's hooks:

  use Tie::Hash 0.05; # version which added support

  tie %hash, 'Tie::InsideOut';

  ...

  my $frozen = freeze( \%hash );

  my $thawed = thaw( $frozen );
  my %copy   = %{ $thawed };

or one can use the C<dclone> method

  my $clone = dclone(\%hash);
  my %copy  = %{ $clone };

Deserializing into a different namespace than a tied hash was created in will
cause errors.

Serialization using packages which do not use these hooks will I<not> work.

=head1 KNOWN ISSUES

This version does little checking of the key names, beyond that there is a
global hash variable with that name.  It might be a hash intended as a
field, or it might be one intended for something else. (You could hide
them by specifying them as C<my> variables, though.)

There are no checks against using the name of a tied L<Tie::InsideOut> or
L<Class::Tie::InsideOut> global hash variable as a key for itself, which
has unpredicable (and possibly dangerous) results.

Keys are only accessible from the namespace that the hash was tied. If you pass the
hash to a method in another object or a subroutine in another module, then it will
not be able to access the keys.  This is an intentional limitation for use with
L<Class::Tie::InsideOut>.

Because of this, naive serialization and cloning using packages like
L<Data::Dumper> will not work. See the L</Serialization> section.

=head1 SEE ALSO

L<perltie>

L<Class::Tie::InsideOut>

If you are looking for a method of restricting hash keys, try
L<Hash::Utils>.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2006 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
