package Attribute::Signature;

use 5.006;
use strict;
#use warnings::register;

use Carp;
use Scalar::Util qw ( blessed );

#use Data::Dumper;
use Attribute::Handlers;
use attributes ();
#local $^W=0;

our $VERSION    = '1.11';
my  $SIGNATURES = {};

sub UNIVERSAL::with : ATTR(CODE,INIT) {
  my ($package, $symbol, $referent, $attr, $data) = @_;

  my $large   = *{$symbol}{NAME};
  my $subname = substr($large, rindex($large, ':') + 1);

  no warnings qw( redefine );

  ## make sure we have an array ref, so its easier
  if (!ref($data)) {
    $data = [ $data ];
  }

  ## save this for later use
  $SIGNATURES->{$package}->{with}->{$subname} = $data;

  my $attributes = { map { ($_, 1) } attributes::get( $referent ) };

  if ($attributes->{method}) {
    print "Signature on sub $subname is for a method\n" if $::AS_DEBUG;
    unshift @$data, $package;  ## put a placeholder in the front
  }

  *{$symbol} = sub {
    my $i = 0;
    my $count = scalar(@_);

    if ($attributes->{method}) {
      $i = 1;
    }

    if ($count != scalar(@$data)) {
      if ($attributes->{method}) {
	croak("invalid number of arguments passed to method $subname");
      } else {
	croak("invalid number of arguments passed to subroutine $subname ($count passed, ".scalar(@$data)." required");
      }
    }

    my $m = 0;
    print "Comparisons\n" if $::AS_DEBUG;
    print "\tSignature\tValue\n" if $::AS_DEBUG;
    my @failed;
    while($i <= $count) {
      print "\t$data->[$i]\t\t$_[$i]\n" if $::AS_DEBUG;
      last unless $data->[$i];
      my $ok=0;
      if (lc($data->[$i]) eq $data->[$i]) {
	## here we are checking for little types
	my $type = $data->[$i];
	if (Attribute::Signature->can( $type )) {
	  if (Attribute::Signature->$type( $_[$i] )) {
	    $ok++;
	  }
	}
      } elsif ((blessed($_[$i])) && $_[$i]->isa( $data->[$i]) ) {
      # || string($_[$i])
	$ok++;
      } elsif (!blessed($_[$i]) && ref($_[$i]) eq $data->[$i]) {
	$ok++;
      }
      if ($ok) {
        $m++ ;
      } else {
        push @failed,$i;
      }
      $i++;
    }

    if ($attributes->{method}) { $m++; }

    print "Out of band:\n\tCount\tMatched\n\t$count\t$m\n" if defined $::AS_DEBUG && $::AS_DEBUG;

    if ($m != $count) {
      croak("call to $subname does not match signature (failed args:".join(',',@failed).")");
    } else {
      #$referent->( @_ );
      goto &$referent;
    }
  };
}

sub UNIVERSAL::returns : ATTR(CODE,INIT) {
  my ($package, $symbol, $referent, $attr, $data) = @_;

  my $large   = *{$symbol}{NAME};
  my $subname = substr($large, rindex($large, ':') + 1);

  no warnings qw( redefine );

  ## make sure we have an array ref, so its easier
  if (!ref($data)) {
    $data = [ $data ];
  }

  ## save this for later use
  $SIGNATURES->{$package}->{returns}->{$subname} = $data;

  my $attributes = { map { ($_, 1) } attributes::get( $referent ) };

  if ($attributes->{method}) {
    print "Signature on sub $subname is for a method\n" if $::AS_DEBUG;
    unshift @$data, $package;  ## put a placeholder in the front
  }

  *{$symbol} = sub {

    my @return = $referent->( @_ );

    my $i = 0;
    my $count = scalar(@return);

    if ($count != scalar(@$data)) {
      if ($attributes->{method}) {
	croak("invalid number of arguments returned from method $subname");
      } else {
	croak("invalid number of arguments returned from subroutine $subname");
      }
    }

    my $m = 0;
    print "ReturnComparisons\n" if $::AS_DEBUG;
    print "\tSignature\tValue\n" if $::AS_DEBUG;
    while($i <= $count) {
      print "\t$data->[$i]\t\t$return[$i]\n" if $::AS_DEBUG;
      last unless $data->[$i];
      if (lc($data->[$i]) eq $data->[$i]) {
	## here we are checking for little types
	my $type = $data->[$i];
	if (Attribute::Signature->can( $type )) {
	  if (Attribute::Signature->$type( $return[$i] )) {
	    $m++;
	  }
	}
      } elsif ($data->[$i] eq 'REF' && ref($return[$i])) {
	$m++;
#      } elsif ((blessed($return[$i]) || string($return[$i])) && $return[$i]->isa( $data->[$i]) ) {
      } elsif (blessed($return[$i]) && $return[$i]->isa( $data->[$i]) ) {
	$m++;
      } elsif (!blessed($return[$i]) && ref($return[$i]) eq $data->[$i]) {
	$m++;
      } else {
	# no match
      }
      $i++;
    }

    if ($attributes->{method}) { $m++; }

    print "ReturnOut of band:\n\tCount\tMatched\n\t$count\t$m\n" if $::AS_DEBUG;

    if ($m != $count) {
      croak("Arguments returned from $subname do not match signature $m != $count");
    } else {
      $referent->( @_ );
    }
  };
}

sub getSignature  {
  my $class = shift;
  my $fqsn  = shift;

  ## this is my sub && package
  my $subname = substr($fqsn, rindex($fqsn, ':') + 1);
  my $package = substr($fqsn, 0, rindex($fqsn, '::'));

  if (wantarray) {
    return($SIGNATURES->{$package}->{with}->{$subname}, $SIGNATURES->{$package}->{returns}->{$subname});
  } else {
    return $SIGNATURES->{$package}->{with}->{$subname};
  }
}

sub string {
  my $class = shift;
  return not ref $_[0];
}

sub number {
  my $class = shift;
  return $class->float($_[0]) || $class->integer($_[0]);
}

sub float {
  my $class = shift;
  return $_[0] =~ /^\d*\.\d*$/;
}

sub integer {
  my $class = shift;
  return $_[0] =~ /^\d+$/;
}

1;

__END__

=head1 NAME

Attribute::Signature - allows you to define a call signature for subroutines

=head1 SYNOPSIS

  package Some::Package;
  use Attribute::Signature;

  sub somesub : with(float, string, Some::Other::Class) returns(float) {
    # .. do something ..
  }

  package main;
  my $array = Attribute::Signature->getSignature('Some::Package::somesub');

=head1 DESCRIPTION

This module allows you to declare calling and returning signatures for
a method.  As yet it does not provide multimethod type functionality,
but it does prevent you from writing lots of annoying code to check
argument types inside your subroutine.  C<Attribute::Signature> takes
two forms, the first is attributes on standard subroutines, in which
it examines every parameter passed to the subroutine.  However, if the
subroutine is marked with the method attribute, then
Attribute::Signature will not examine the first argument, which can be
either the class or the instance.

C<Attribute::Signature> can also  check  the values that  are returned
from the method / subroutine, by use of the C<returns> attribute.

C<Attribute::Signature> checks for the following types:

=over 4

=item HASH

=item ARRAY

=item GLOB

=item CODE

=item REF

=back

as well as, in the case of classes, that the object's class inherits from the named class.
For example:

  sub test : (Some::Class) {
    # .. do something ..
  }

would check to make sure that whatever was passed as the argument was blessed into a class
which returned 1 when the C<isa> method was called on it.

Finally C<Attribute::Signature> allows for some measure of type testing.  Any type that is
all in lower case is tested by calling a function having the same name in the Attribute::Signature
namespace.  Attribute::Signature comes with the following type tests:

=over 4

=item float

=item integer

=item string

=item number

=back

Note that the float type mistakenly decides that 10.0 is not a float
as Perl optimises it to be 10. You can define more tests by declaring
subs in the Attribute::Signature namespace.

=head1 OTHER FUNCTIONS

=over 4

=item getSignature( string )

C<Attribute::Signature> also allows you to call the getSignature
method.  The string should be the complete namespace and subroutine.
This returns the attribute signature and returned values signature for
the function as two array references.

=back

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>
Leon Brocard <leon@fotango.com>
Alexandr Ciornii (alexchorny AT gmail.com)

=head1 SEE ALSO

perl(1) UNIVERSAL(3)

=cut

