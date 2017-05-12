package Class::AccessorMaker::Private;

##
## Class::AccessorMaker::Private by Hartog 'Sinister' de Mik
##

use strict;
no strict 'refs';

our $VERSION = "1.0";

use Carp;

# lexical for data-hiding

my %obj_ = ();

sub import {
  my ($class, $subs, $xtra) = @_;
  my $pkg = ref(caller) || caller;
  $xtra ||="";

  croak "Can't make methods out of an empty hash-ref\n" if !defined $subs;

  ## define a constructor
  if ( $xtra ne "no_new" ) {
    # we have a green light for 'new()' creation
    if ( $xtra ne "new_init" ) {
      *{"${pkg}::new"} = sub {
	my $class = ref($_[0]) || $_[0]; shift;
	my $self = bless({}, $class);

	while ( @_ ) {
	  my ($sub, $value) = (shift, shift);
	  $self->$sub($value);
	}

	return $self;
      };
    } elsif ( $xtra eq "new_init" ) {
      *{"${pkg}::new"} = sub {
	my $class = ref($_[0]) || $_[0]; shift;
	my $self = bless({}, $class);

	while ( @_ ) {
	  my ($sub, $value) = (shift, shift);
	  $self->$sub($value);
	}

	$self->init();
	return $self;
      };
    }
  } 
   

  foreach my $sub ( keys %$subs ) {
    # construct the method if it is not defined yet.
    next if ( defined &{"${pkg}::$sub"} );

    *{"${pkg}::$sub"} = sub {
      my ( $self, $value ) = @_;

      # fill with default at first run
      $obj_{$self}->{$sub} = $subs->{$sub} if !exists $obj_{$self}->{$sub};

      # more then just self, something has to be set.
      if ($#_ > 0) {
	warn "The value supplied to '$sub()' is not of propper type"
	  if (ref($subs->{$sub}) and !ref($value));
  
	# set the value and return the object.
	$obj_{$self}->{$sub} = $value;
	return $self;
      }

      # return the value;
      return $obj_{$self}->{$sub};
      
    } or warn "Method: $sub not implemented\n";
  }
  return 1;			# import succeeded
}


1;

__END__

=pod

=head1 NAME

Class::AccessorMaker::Private - generate private accessor method with default values.

=head1 DESCRIPTION

For further SYNOPSIS, DESCRIPTION and PITFALLS please read the perldoc of
Class::AccessorMaker.

This 'AccessorMaker' makes you private methods. Actually the methods are
accessible from just about anywhere you like em to, but the data
structure that lies beneath it all is hidden in a far away place. This
forces the users of your object to actually use the acccessor methods,
instead of trying to temper with your objects internals.

=head1 BUT I WANT TO ...

test the value of my accessor or perhaps even slightly alter it...

Too bad, Class:AccessorMaker::Private does not do this for you. You
will have to write your own accessor method. Ah, too bad again,
AccessorMaker::Private does not even give your object reachable data,
but the object self is a blessed hash, be it very empty, so you can
use that...

But if you wish to use global-data for it, be my guest, not that I
advice it, cause it is generally a bad idea to use global data, and if
you use it, you do not even need accessor methods, right?

=head2 an example:

  sub seperator {
    my ($self, $value) = @_;

    # set the default value.
    $self->{seperator} = '$$' if !exists $self->{seperator}

    if ( $#_ > 0 ) {
      $self->{seperator} = quotemeta($value);
      return $self;
    } 

    return $self->{seperator};
  }

I think I can skip a code explanation, right?

=head1 AUTHOR

Hartog 'Sinister' de Mik <hartog@2organize.com>

=head1 COPYRIGHT

Copyright (c) 2002 Hartog C. de Mik. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
