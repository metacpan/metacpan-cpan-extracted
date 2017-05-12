package Class::AccessorMaker;

##
## Class::AccessorMaker by Hartog "Sinister" de Mik
##

use strict;
no strict 'refs';

our $VERSION = "1.11";

use Carp;

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
    ## construct the method if it is not defined yet.
    next if ( defined &{"${pkg}::$sub"} );

    *{"${pkg}::$sub"} = sub {
      my ( $self, $value ) = @_;

      # fill with default at first run
      if ( !exists $self->{$sub} ) {
	my $val = $subs->{$sub};
	my $rval = ref($val);
	if (!$rval) {
	  #scalar
	  $self->{$sub} = $val;
	} elsif ($rval =~ /ARRAY/) {
	  my @val = @{$val};
	  $self->{$sub} = \@val;
	} elsif($rval =~ /HASH/) {
	  my %val = %{$val};	
	  $self->{$sub} = \%val;
	} else {
	  #object ref.. use at own risk.
	  $self->{$sub} = $val;	      
	}
      }

      # more then just self, something has to be set.
      if ($#_ > 0) {
	warn "The value supplied to '$sub()' is not of propper type"
	  if (ref($subs->{$sub}) and !ref($value));
  
	# set the value and return the object.
	$self->{$sub} = $value;
	return $self;
      }

      # return the value;
      return $self->{$sub};
      
    } or warn "Method: $sub not implemented\n";
  }
  return 1;			# import succeeded
}


1;

__END__

=pod

=head1 NAME

Class::AccessorMaker - generate accessor methods with default values.

=head1 SYNOPSIS

=head2 With constructor

  package Users;

  use Class::AccessorMaker {
    username => "guest",
    password => "",
    role     => "guest",
    groups   => [ "guest" ] };

  package main;

  my $usr = Users->new(username => $uname, password => $pw);
  

=head2 With init constructor

  package MailThing;

  use Class::AccessorMaker {
    to     => "",
    from   => "hartog\@2organize.com",
    cc     => "",
    bcc    => "",
    bounce => "" }, "new_init";

  sub init {
    my ($self) = @_;
    ...
  }

  package main;

  my $mlr = MailThing->new();

=head2 Without constructor

  package HitMan;

  use Class::AccessorMaker {
    victim   => "",
    location => "",
    data     => {} }, "no_new";

  sub new {
    my $class = ref($_[0]) or $_[0]; shift;
    return bless({}, $class);
  }

Of course the first example describes some sort of user system, which
assumes you are a guest by default. The second example is some sort of
mailer-object. And the third is used by a lot of serial killers out
there...

=head1 DESCRIPTION

The AccesorMaker takes in, at use-time, a hash-reference and an extra
keyword. It uses the keys of the hash-reference to create
accessor-methods in the name-space of the caller. The values that are
given to the keys are the default value of the accessor.

Class::AccessorMaker will create a constructor (called C<new()>) by
default. This constructor will be able to take that nice and shiny
hash-like structure as you can see in the first example.

If you want your constructor to run your objects C<init()> routine you
can specify the keyword "new_init". If you want to write your own
C<new()> routine you can use "no_new". Note that Class::AccessorMaker
expects your object to be a hash-reference.

=head1 BUT I WANT TO ...

test the value of my accessor or perhaps even slightly alter it...

Too bad, Class:AccessorMaker does not do this for you. You will have to
write your own accessor method. It is up to you how you write it, but
it would be wise to keep the objects data-structure, which is just a
plain hash if you let Class::AccessorMaker make the constructor.

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


=head1 NOW HERE THIS

This module is still under some sort of development, and I am
expecting to release things like ReadOnly / WriteOnce accessors methods
in the near future. I already have Class::AccessorMaker::Private out
there for you, which could prove to be very useful for you.

=head1 PITFALLS

Please do not put those perl-reserved names in there like DESTROY,
import, AUTOLOAD, and so on. It will hurt you badly.

Q: "But why do you not filter those?"

A: "This is perl baby, you can do whatever you like..."

And besides, there is going to be someone out there who is actualy
going to put it to good use...

=head1 AUTHOR

Hartog 'Sinister' de Mik <hartog@2organize.com>

=head1 COPYRIGHT

Copyright (c) 2002 Hartog C. de Mik. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
