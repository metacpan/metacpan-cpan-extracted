package Agent::TCLI::Base;
#
# $Id: Base.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Agent::TCLI::Base - Base object for other TCLI objects

=head1 SYNOPSIS

Base object. Not for direct use.

=head1 DESCRIPTION

Base object. Not for direct use.

=cut

use warnings;
use strict;
use Carp;

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Base.pm 59 2007-04-30 11:24:24Z hacker $))[2];

use Object::InsideOut;
use Data::Dump qw(pp);

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods and may be set as a parameter to new unless otherwise noted.

=over

=cut

# Standard class utils
# I need to redo err handling as its not useful as is.
=item err

Error message if something went wrong with a method call. Cannot be set or
passed in with new. Not actually used, as erroring needs to be revisited.

=cut
my @err				:Field
					:Get('err');

=item verbose

Turns on/off internal state messages and warnings. Higher values produce more
verbosity.

=cut

# TODO change verbose to verbosity
my @verbose			:Field
					:Arg('Name' => 'verbose', 'Default' => 0 )
					:Acc('verbose');

=item do_verbose

A routine to output the results of a verbose call.
This allows it to be changed within an object.
B<do_verbose> will only accept code type values.

=cut
my @do_verbose		:Field
					:Arg('Name' => 'do_verbose', 'Default' => sub { print (@_) } )
					:Acc('do_verbose')
					:Type('CODE');

sub _set_err {
  my ($self, $args) = @_;
  $self->set(\@err, $args);
  $self->Verbose("Err called");
  return undef;
}

=back

=head2 METHODS

=over

=item Verbose (<message>, [ <level>, <dump_var> ]  )

This method is use to output all logging and debugging commands. It will use
the sub in do_verbose to output the message if the level is less than or
equal to the current value of $self->verbose. If level is not suppiled,
it defaults to one.
If a dump_var is included, its value will be output using the Data::Dump::pp
function. This can pe useful for checking the inside of array, hashes
and objects. If the object is an OIO object, use the objects own $obj->dump(1)
method in the message.

=cut

sub Verbose {
	my ($self, $message, $level, $var) = @_;
	$level = 1 unless defined($level);

	# Support Verbose in init before default is set:
	# That means it has to be set to zero. :)
	my $verbose = defined($self->verbose) ? $self->verbose : 0;
	# Dereference, if necessary
	$verbose = ref($verbose) ? $$verbose : $verbose;
	my $do_verbose = defined($self->do_verbose) ? $self->do_verbose :
		sub { print (@_) };
	# I suppose I could take out the defaults now, but that is better
	# so that the effective values can be read.

	return unless ( $verbose >= $level );
	my $class = $self->dump()->[0];
	my $txt = $level.":".$class.":".$message."\n";
	if (defined($var))
	{
		my $tmp = $var;
		if ( ref($tmp) =~ /TCLI/ ) # Its one of mine and OIO
		{
			$txt .= $tmp->dump(1)."\n";
		}
		else
		{
			$txt .= pp($tmp)."\n";
		}
	}

	# objects may override output format by changing do_verbose
	&{$do_verbose}($txt);
	return ($txt);
}

=item _automethod

Several TCLI classes take advantage of automethods to enable extending classes
to store information. There are also Numeric, Array and Hash automethods
that eliminate tedious programming. At some point, this _automethod may be
removed from the Agent::TCLI::Base or split up and only used in subclasses when
necessary.

=cut

sub _automethod :Automethod {
	my $self = $_[0];
	my $class = ref($self) || $self;
	my $method = $_;

	# Get meta data
	my $meta = $self->meta();
	my $meth = $meta->get_methods();

	# Numeric Methods
	my ($action, $field_name) = $method =~ /^(increment)_(.*)$/;
	my ($accessor,$mutator);
	if ($field_name)
	{
		$self->Verbose( "_automethod: action($action) field_name($field_name) \n",3);
		$self->Verbose("_automethod: field_name($field_name)",5,$meth);
		if (exists( $meth->{$field_name} ) &&
			exists( $meth->{$field_name}{'type'} ) &&
			$meth->{$field_name}{'type'} =~ /numeric/i )
		{
			# Has combined accessor
			$accessor = $mutator = $field_name;
			$self->Verbose( "_automethod: combined action($action) field_name($field_name) \n",3);
		}
		elsif ( exists( $meth->{"set_$field_name"} ) &&
			exists( $meth->{"set_$field_name"}{'type'} ) &&
			$meth->{"set_$field_name"}{'type'} =~ /numeric/i )
		{
			# Has standard accessor
			$accessor = "get_".$field_name;
			$mutator = "set_".$field_name;
			$self->Verbose("_automethod: standard action($action) mutator($mutator) accessor($accessor) \n",3);
		}
		my $handler;
		$self->Verbose("_automethod: self->accessor",4,$self->$accessor );

		if ( $action eq 'increment' )
		# Increment seems silly, and quite likely it is. But the alternative is
		# this ugly manipulation every time, or lvalues, both of which
		# have their own issues, so silly it is.
		{
			$handler = sub {
		        no strict 'refs';
				my ($self, $value) = @_;
				$value = defined($value) ? $value : 1 ;
				my $new = defined($self->$accessor) ?
					$self->$accessor + $value : $value ;
				$self->$mutator($new);
				return( $self->$accessor );
			}
		}
		else
		{
			print "Whoops bad action($action) field_name($field_name) \n";
			return;
		}
        ### OPTIONAL ###
        # Install the handler so it gets called directly next time
        no strict 'refs';
        *{$class.'::'.$method} = $handler;
        ################

        return ($handler);
	}

	# ARRAY Methods
	($action, $field_name) = $method =~ /^(print|depth|push|pop|shift|unshift)_(.*)$/;
	if ($field_name)
	{
		if (defined( $meth->{$field_name} ) &&
			$meth->{$field_name}{'type'} =~ /list|array/ )
		{
			# Has combined accessor
			$accessor = $mutator = $field_name;
			$self->Verbose( "_automethod combined action($action) field_name($field_name) \n",3);
		}
		elsif ( defined( $meth->{"set_$field_name"} ) &&
			$meth->{"set_$field_name"}{'type'} =~ /list|array/ )
		{
			# Has standard accessor
			$accessor = "get_".$field_name;
			$mutator = "set_".$field_name;
			$self->Verbose("_automethod standard action($action) mutator($mutator) accessor($accessor) \n",3);
		}
		elsif ($field_name =~ /array/ && !defined($meth->{"set_$field_name"} ) )
		{
			$accessor = "get_".$field_name;
			$mutator = "set_".$field_name;
			$self->Verbose("_automethod new standard action($action) mutator($mutator) accessor($accessor) \n",3);
			# Make standard mutator/accessor
			$self->$mutator( [  ] );
		}
		else
		{
			$self->Verbose("_automethod meth",0,$meth);
			return;  # Not an array or unrecognized.
		}

		my $handler;
		$self->Verbose("_automethod self",4,$self->$accessor );
		$self->Verbose("_automethod field_name($field_name)",5,$meth);

		if ( $action eq 'push' )
		{
			$handler = sub {
			my $self = shift;
			if ( defined($self->$accessor) )
			{
				return ( push( @{ $self->$accessor }, @_ ) )
			}
			else
			{
				$self->$mutator([ @_ ]);
				return( scalar ( @{ $self->$accessor } ));
			}

			};
		}
		elsif ( $action eq 'pop' )
		{
			$handler = sub {
			my $self = shift;
			return ( pop( @{ $self->$accessor } ) )
				if defined($self->$accessor);
			return undef;
			};
		}
		elsif ( $action eq 'shift' )
		{
			$handler = sub {
			my $self = shift;
			return ( shift (@{ $self->$accessor } ) )
				if defined($self->$accessor);
			return undef;
			};
		}
		elsif ( $action eq 'unshift' )
		{
			$handler = sub {
			my $self = shift;
			if ( defined($self->$accessor) )
			{
				return ( unshift( @{ $self->$accessor }, @_ ) );
			}
			else
			{
				$self->$mutator([ @_ ]);
				return( scalar ( @{ $self->$accessor } ));
			}
			};
		}
		elsif ( $action eq 'depth' )
		{
			$handler = sub {
			my $self = shift;
			return ( scalar( @{ $self->$accessor } ) )
				if defined($self->$accessor);
			return 0;
			};
		}
		elsif ( $action eq 'print' )
		{
			$handler = sub {
			my $self = shift;
			return ( join(' ', @{ $self->$accessor } ) )
				if defined($self->$accessor);
			return '';
			};
		}
		else
		{
			print "Whoops bad action($action) field_name($field_name) \n";
			return;
		}
        ### OPTIONAL ###
        # Install the handler so it gets called directly next time
        no strict 'refs';
        *{$class.'::'.$method} = $handler;
        ################

	        return ($handler);
	}

	# HASH Methods
	($action, $field_name) = $method =~ /^(sort)_(.*)$/;
	if ($field_name)
	{
		if ($meth->{"$field_name"}{'type'} &&
			$meth->{"$field_name"}{'type'} =~ /hash/ )
		{
			# Has combined accessor
		}
		elsif ($meth->{"$field_name"}{'type'} &&
			$meth->{"set_$field_name"}{'type'} =~ /hash/ )
		{
			# Has standard accessor
			$field_name = "get_".$field_name;
		}
		else
		{
			return;  # Not a hash or unrecognized.
		}

		my $handler;

		# need to make sure that a hash is there first....
		$self->$field_name({}) unless defined($self->$field_name);

		# TODO do I need to fix this? Where is field_name?
		if ( $action eq 'sort' )
		{
			$handler = sub {
			my ($self, $hash) = shift;
			my @array;
			foreach my $key ( sort keys %{$hash} )
				{
					push (@array, $hash->{$key} );
				}
			return ( \@array );
			};
		}
        ### OPTIONAL ###
        # Install the handler so it gets called directly next time
        no strict 'refs';
        *{$class.'::'.$method} = $handler;
        ################

	    return ($handler);
	}

	# AUTO create methods
	# Extract desired field name from get_/set_ method name
	($field_name) = $method =~ /^[gs]et_(.*)$/;
	if (! $field_name)
	{
    	return;    # Not a recognized method
	}
	# What happens when we pack this up and send it out over the wire.
	# When it gets recreated... It just works! At least in OIO 3.08.
	else
	{
		# If field name has a type, then set type.
		# and hey, don't try to combine them or it gets ugly.
		my $type = ( $field_name =~ /array/i ) ? " :Type('ARRAY') " : '';
		$type  .=   ( $field_name =~ /hash/i ) ? " :Type('HASH') " : '';
		$type  .=   ( $field_name =~ /numeric/i ) ? " :Type('Numeric') " : '';

		# Since I'm being so silly. let's add weak, but strip it off the final
		# field name. Whoops. Hmmm, but how do I test with a get to see if
		# it's been set? The get would create a non weak version....
		# Ok, i made is a plain regex again for now instead of s/_weak//i
		my $weak = ( $field_name =~ /weak/i ) ? " :Weak " : '';

		# Create the field and its standard accessors
		$self->Verbose("field($field_name) type($type) weak($weak) ",2);
		$class->create_field('@'.$field_name, ":Std($field_name) ".$type.$weak );

		# Return code ref for newly created accessor
		no strict 'refs';
		return *{$class.'::'.$method}{'CODE'};
	}
}


1; # Magic true value required at end of module
#__END__

=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object. It inherits methods from OIO.
Please refer to the OIO documentation for more details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
