#!/usr/bin/perl -w
#
# Data::Toolkit
#
# Andrew Findlay
# Jan 2008
# andrew.findlay@skills-1st.co.uk
#
# $Id: Toolkit.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit;

use strict;
use Data::Dumper;
use Carp;
use Clone qw(clone);

=head1 NAME

Data::Toolkit

=head1 DESCRIPTION

Toolkit for pumping data from one source to another,
directory synchronisation etc.

=head1 SYNOPSIS


=head1 DEPENDENCIES

   Carp
   Clone
   Data::Dumper

=cut

########################################################################
# Package globals
########################################################################

use vars qw($VERSION);
$VERSION = '1.1';

# Set this non-zero for debug logging
#
my $debug = 0;

########################################################################
# Constructors and destructors
########################################################################

=head1 Constructor

=head2 new

   my $map = Data::Toolkit->new();

Creates an object of type Data::Toolkit

=cut

sub new {
	my $class = shift;
	my $configParam = shift;

	my $self  = {};

	# Take a copy of the config hash if we were given one
	# - we don't want to store a ref to the one we were given
	#   in case it is part of another object
	#
	if (defined($configParam)) {
		if ((ref $configParam) ne 'HASH') {
			croak "Data::Toolkit->new expects a hash ref but was given something else"
		}

		$self->{config} = clone($configParam);
	}
	else {
		# Start with empty config
		$self->{config} = {};
	}


	bless ($self, $class);

	carp "Data::Toolkit->new $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Data::Toolkit Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut


########################################################################
# Debugging methods
########################################################################

=head1 Debugging methods

=head2 debug

Set and/or get the debug level for Data::Toolkit

   my $currentDebugLevel = Data::Toolkit->debug();
   my $newDebugLevel = Data::Toolkit->debug(1);

Any non-zero debug level causes the module to print copious debugging information.

Note that this is a package method, not an object method. It should always be
called exactly as shown above.

All debug information is reported using "carp" from the Carp module, so if
you want a full stack backtrace included you can run your program like this:

   perl -MCarp=verbose myProg

=cut

# Class method to set and/or get debug level
#
sub debug {
	my $class = shift;
	if (ref $class)  { croak "Class method 'debug' called as object method" }
	# print "DEBUG: ", (join '/', @_), "\n";
	$debug = shift if (@_ == 1);
	return $debug
}


########################################################################
########################################################################

=head1 Author

Andrew Findlay

Skills 1st Ltd

andrew.findlay@skills-1st.co.uk

http://www.skills-1st.co.uk/

=cut

########################################################################
########################################################################
1;
