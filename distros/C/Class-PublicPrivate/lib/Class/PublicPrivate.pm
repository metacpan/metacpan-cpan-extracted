package Class::PublicPrivate;
use strict;

# version
our $VERSION = '0.82';

#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

Class::PublicPrivate - Class with public keys with any name and a separate set
of private keys

=head1 SYNOPSIS

PublicPrivate is intended for use as a base class for other classes.  Users of
class based on PublicPrivate can assign any keys to the object hash without
interfering with keys used internally.  The private data can be accessed by
retrieving the private hash with the C<private> method.  For example, the
following code outputs two different values, one for the public value of
C<start> and another for the private value of C<start>.

 package ExtendedClass;
 use base 'Class::PublicPrivate';

 sub new{
    my $class = shift;
    my $self = $class->SUPER::new();
    my $private = $self->private;

    # initialize one of the private properties
    $private->{'start'}=time();

    return $self;
 }

 package main;
 my ($var);
 $var = ExtendedClass->new();
 $var->{'start'} = 1;

 print $var->{'start'}, "\n";
 print $var->private()->{'start'}, "\n";

=head1 INSTALLATION

Class::PublicPrivate can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 METHODS

=head2 YourClass->new(classname ,[initikey1=>initvalue [, ...]])

Returns an instantiation of YourClass, where YourClass is a class that extends
Class::PublicPrivate.  Additional key=>value pairs are stored in the private
hash.  Programs that use your class can store any date directly in it w/o
affecting the object's private data.

=head2 $ob->private()

Returns a reference to the hash of private data.

=head1 TERMS AND CONDITIONS

Copyright (c) 2015 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=cut

#
# opening POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new
#
sub new {
	my $class = shift;
	my (%nv, $self);
	
	# reference nv in hash
	tie %nv, 'Class::PublicPrivate::Tie', @_;
	$self = bless(\%nv, $class);
	
	# return
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# private
# returns the private hash
# 
sub private {
	return (tied(%{$_[0]}))->{'private'};
}
# 
# private
#------------------------------------------------------------------------------



###############################################################################
# Class::PublicPrivate::Tie
# 
package Class::PublicPrivate::Tie;
use strict;

sub TIEHASH {
	my ($class, %opts) = @_;
	my $self = bless({}, $class);
	
	$self->{'private'} = $opts{'private'} || {};
	$self->{'public'} = $opts{'public'} || {};
	
	return $self;
}

sub STORE {
	$_[0]->{'public'}->{$_[1]} = $_[2];
}

sub FETCH {
	return $_[0]->{'public'}->{$_[1]};
}

sub DELETE {
	delete $_[0]->{'public'}->{$_[1]};
}

sub CLEAR {
	$_[0]->{'public'} = {};
}

sub EXISTS {
	exists $_[0]->{'public'}->{$_[1]};
}

sub FIRSTKEY {
	my $self = shift;
	my $a = keys(%{$self->{'public'}});
	return $self->NEXTKEY;
}

sub NEXTKEY {
	my $self = shift;
	my $v = (each %{$self->{'public'}})[0];
	return $v;
}
# 
# Class::PublicPrivate::Tie
###############################################################################



# return 
1;

=head1 VERSION

Version: 


=head1 HISTORY

=over

=item Version 0.80, June 29, 2002

First public release

=item Version 0.81 May 18, 2014

Minor tightening up of code. Fixed problems in packaging for CPAN.

=item Version 0.82 January 2, 2015

Minor tidying up code formatting and POD. Modifed tests to include test names.
Modifed files to use Unix style newlines, and to be encoded UTF-8.

=back

=cut
