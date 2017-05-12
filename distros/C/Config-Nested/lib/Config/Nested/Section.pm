#! /usr/bin/env perl

=head1 NAME

Config::Nested::Section - contain the configuration from a section statement in a Config::Nested configuration file.

=head1 SYNOPSIS

  use Config::Nested;
  use Data::Dumper;

  my $obj = new Config::Nested::Section(
	list	=> [],
	owner	=> '',
	location=> '',
	colour	=> {},
	contents=> {},
  );

  $obj->owner('Fred');
  $obj->location('here');
  $obj->list(qw(a b c d e));

  my $clone = $obj->new();

  print Dumper($obj);

This produces the output:

  $VAR1 = bless( {
                 'colour'	=> {},
                 'contents'	=> {},
                 'list'		=> [ 'a', 'b', 'c', 'd', 'e' ],
                 'location'	=> 'here',
                 'owner'	=> 'Fred'
               }, 'Config::Nested::Section' );

=head1 DESCRIPTION

Config::Nested::Section is a hash array containing the configuration for
a individual section parsed from a Config::Nested configuration file.

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=cut

# Config::Nested::Sect
#
#			Anthony Fletcher 1st Jan 2007
#

package Config::Nested::Section;

$VERSION = '1.0';

use 5;
use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

# Standard modules.
use Data::Dumper;
use Storable qw(dclone);
use Carp;

use overload
	#'='	=> sub { die; },
	#'='	=> sub { print join(',', caller(0)), "\n"; die; 1; },
	#'bool'	=> sub { print join(',', caller(0)), "\n"; die; 1; },
	#'bool'	=> sub { return (defined($_[0]) ? 1 : 0); },
;


my $PACKAGE = __PACKAGE__ ;

# module configuration
$Data::Dumper::Sortkeys = 1;

=pod

=head2 $section = B<Config::Nested::Section-E<gt>new( options )>

=head2 B<$section-E<gt>configure( options )>

Construct a new Config::Nested::Section object;
options can be listed as I<key =E<gt> value> pairs.
The keys are

=over 4

=item *

scalar =E<gt> E<lt>array of variableE<gt>

=item *

array =E<gt> E<lt>array of variableE<gt>

=item *

hash =E<gt> E<lt>array of variableE<gt>

=back

If this constructor is applied to an existing Config::Nested::Section
object, then the object is cloned, augmented with the extra options and returned.

=cut

# Create a new object
sub new
{
	# Create an object.
	my $this = shift;

	my $self;
	if (ref($this))
	{
		# $this is already an object!
		# Clone it.
		$self = dclone($this);
	}
	else
	{
		my $class = ref($this) || $this;
		$self = { };
		bless $self, $class;
	}

	croak "Odd number of arguments" if @_ % 2;

	my %arg = @_;
	for my $k (keys %arg)
	{
		$self->{$k} = $arg{$k};
	}

	#warn Dumper(\$self);

	$self;
}

=head2 B<$section-E<gt>member(..)>

Either lookup or set the member variable corresponding to the keys of
the hash array underlying the Config::Nested::Section object. If the
particular member key is not present in the underlying hash, an
error occurs.

If the function is given arguments, then the value is set in the object,
before returning the new value. This allows the following:

	my $b = new Config::Nested::Section(array => 'path');
	$b->path->[0] ='first step';

The only member function that does not work this way is 'new', which is
the constructor function and returns a cloned copy.

=cut

# Autoload all of the member functions.
sub AUTOLOAD
{
	my $this = shift;

	# DESTROY messages should never be propagated.
	return if $AUTOLOAD =~ /::DESTROY$/;

	# Isolate the function name.
	$AUTOLOAD =~ s/^\Q$PACKAGE\E:://;

	# Is this a real function?
	unless (exists $this->{$AUTOLOAD})
	{
		croak "member variable '$AUTOLOAD' does not exist";
	}

	# Values to set?
	if (@_)
	{
		# Set the value?
		if (ref $this->{$AUTOLOAD} eq '')
		{
			$this->{$AUTOLOAD} = shift;
		}
		elsif (ref $this->{$AUTOLOAD} eq 'ARRAY')
		{
			$this->{$AUTOLOAD} = [ @_ ];
		}
		else
		{
			croak "case not handled for $AUTOLOAD";
		}

		# Interesting but usuab;e from with the parent class.
		# Trigger a side effect.
		#if (exists $this->{'-sideeffect'}->{$AUTOLOAD})
		#{
		#	&{$this->{'-sideeffect'}->{$AUTOLOAD}}($this);
		#}
	}
	
	$this->{$AUTOLOAD};
}

=pod

=head1 SEE ALSO

Config::Nested

=head1 COPYRIGHT

Copyright (c) 1998-2008 Anthony Fletcher. All rights reserved.
These modules are free software; you can redistribute them and/or modify
them under the same terms as Perl itself.

This code is supplied as-is - use at your own risk.

=head1 AUTHOR

Anthony Fletcher

=cut

###################################

sub test
{
	my $obj = new Config::Nested::Section(
		list	=> [],
		path	=> [],
		owner	=> '',
		location=> '',
		colour	=> {},
		contents=> [],
		hash1	=> {},
		hash2	=> {},
		number	=> 3,
		firstname=> '',
		surname	=> '',
	);
	print "obj = ", Dumper($obj);

	$obj->owner('Fred');
	$obj->location('here');
	$obj->list(qw(a b c d e));

	my $obj2 = dclone($obj);
	my $obj3 = $obj->new(scalar => 'name');

	$obj2->owner('Harold');

	unshift @{$obj->list}, 'zero';
	$obj2->colour->{head} = 'blue';

	print "obj = ", Dumper($obj);
	print "obj2= ", Dumper($obj2);
	print "obj3= ", Dumper($obj3);

	#eval { $obj->job; }; print $@;

	my $b = new Config::Nested::Section(path => [], contact => {});
	$b->path->[0] ='first step';
	$b->contact->{'parent'} ='Mum';
	print "b=", Dumper($b);

	# Register side effect for 'owner'.
	#$obj->{-sideeffect}->{owner} = sub {
	#
	#	my ($this) = @_;
	#	my ($firstname, @names) = split(/\s+/, $this->owner());
	#	if (@names)
	#	{
	#		$this->firstname($firstname);
	#		$this->surname(pop(@names));
	#	}
	#	else
	#	{
	#		$this->firstname('');
	#		$this->surname('');
	#	}
	#
	#	1;
	#};
	#
	#$obj->owner('Fred Smith');
	#print "\nobj = ", Dumper($obj);
	#
	# Doesn't work! dclone won't copy CODE.
	#my $obj5 = dclone($obj);

}

&test if ( __FILE__ eq $0);

1;


