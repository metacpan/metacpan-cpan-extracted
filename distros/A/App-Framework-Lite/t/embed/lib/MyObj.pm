package MyObj ;

=head1 NAME

MyObj - Adds error handling to basic object

=head1 SYNOPSIS

use MyObj ;


=head1 DESCRIPTION

Any object derived from this class can throw an error and some registered error handler will catch (and handle) that error.

Hierarchy of catch handlers is:

	catch_fn set for this object instance
	any registered global catch function (last registered first)
	default handler
	
Global catch functions, when registered, are added to a stack so that the last one registered is called first.

Each handler must return either 1=handled, or 0=not handled to tell this object whether to move on to the next handler.

NOTE: The default handler may be over-ridden by any derived object. 

This object is set up such that when used as stand-alone objects (i.e. outside of an application framework), then errors are handled
with die(), warn() etc.


=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price C<< <sdprice at cpan.org> >>

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut

use strict ;
use Carp ;

our $VERSION = "1.004" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Lite::Object ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Lite::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (
	'errors'	=> [],		# List of errors for this object
	'catch_fn'	=> undef,	# Function called if error is thrown
) ;

# Keep track of all errors
my @all_errors = () ;

# Error type priority
my %ERR_TYPES = (
	'fatal'		=> 0x80,
	'nonfatal'	=> 0x40,
	'warning'	=> 0x08,
	'note'		=> 0x04,
	'none'		=> 0x00,
	
) ;

# Error handler stack
my @GLOBAL_ERROR_HANDLERS = () ;

# Some useful masks
my $ERR_TYPE_MASK = 0xF0 ;
my $ERR_TYPE_WARN = 0x08 ;
my $ERR_TYPE_NOTE = 0x04 ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

=item B<new([%args])>

Create a new MyObj.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	
	return($this) ;
}



#============================================================================================
# CLASS METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item B<init_class([%args])>

Initialises the MyObj object class variables. Creates a class instance so that these
methods can also be called via the class (don't need a specific instance)

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	if (! keys %args)
	{
		%args = () ;
	}
	
	# Add extra fields
	foreach (keys %FIELDS)
	{
		$args{'fields'}{$_} = $FIELDS{$_} ;
	}
	$class->SUPER::init_class(%args) ;

	# Create a class instance object - allows these methods to be called via class
	$class->class_instance(%args) ;

}


#-----------------------------------------------------------------------------

=item B<add_global_error($error)>

Add a new error to the Class list keeping track of all runtime errors

=cut

sub _global_error
{
	my $class = shift ;
	my ($error) = @_ ;
	
	push @all_errors, $error ;	
}

#-----------------------------------------------------------------------------

=item B<global_error([%args])>

Add a new error to the Class list keeping track of all runtime errors

%args hash contains:

	* type = fatal, nonfatal, warning, note
	* message = text message
	* errorcode = integer error code value

=cut

sub global_error
{
	my $class = shift ;
	my (%args) = @_ ;
	
	# Convert args into an error
	my $error = _create_error('parent'=>$class, %args) ;

	$class->_global_error($error) ;	
}


#-----------------------------------------------------------------------------

=item B<global_last_error()>

Returns a hash containing the information from the last error stored in the global list

Hash contains:

	* type = fatal, nonfatal, warning, note
	* message = text message
	* errorcode = integer error code value

If there are no errors, returns undef

=cut

sub global_last_error
{
	my $class = shift ;
	my (%args) = @_ ;

	my $error = _latest_worst_error(\@all_errors) ;
	
	return $error ;
}

#-----------------------------------------------------------------------------

=item B<global_errors()>

Returns the list of all errors

=cut

sub global_errors
{
	my $class = shift ;
	
	return @all_errors ;
}

#-----------------------------------------------------------------------------

=item B<any_error()>

Returns a hash containing the information from the last actual error (i.e. only 'fatal' or 'nonfatal' types) stored 
in the global list

Hash contains:

	* type = fatal, error, warning, note
	* message = text message
	* errorcode = integer error code value

If there are no errors, returns undef

=cut

sub any_error
{
	my $class = shift ;

	my $error = $class->global_last_error() ;
	
	# Ensure this is something worth reporting
	return $class->is_error($error) ;
}

#-----------------------------------------------------------------------------

=item B<error_check($error, $mask)>

Returns TRUE if the $error object type matches the mask 

=cut

sub error_check
{
	my $class = shift ;

	my ($error, $mask) = @_ ;
	
	# Ensure this is something worth reporting
	if ($error)
	{
		my $type = $ERR_TYPES{$error->{'type'}} ;
		unless ($type & $mask)
		{
			$error = undef ;
		}
	}
		
	return $error ;
}



#-----------------------------------------------------------------------------

=item B<is_error($error)>

Returns TRUE if the $error object is either 'fatal' or 'nonfatal' 

=cut

sub is_error
{
	my $class = shift ;

	my ($error) = @_ ;
	return $class->error_check($error, $ERR_TYPE_MASK) ;
}

#-----------------------------------------------------------------------------

=item B<is_warning($error)>

Returns TRUE if the $error object is 'warning' 

=cut

sub is_warning
{
	my $class = shift ;

	my ($error) = @_ ;
	return $class->error_check($error, $ERR_TYPE_WARN) ;
}

#-----------------------------------------------------------------------------

=item B<is_note($error)>

Returns TRUE if the $error object is 'note' 

=cut

sub is_note
{
	my $class = shift ;

	my ($error) = @_ ;
	return $class->error_check($error, $ERR_TYPE_NOTE) ;
}


#-----------------------------------------------------------------------------

=item B<error_split($error)>

Split the error object into component parts and return them in an ARRAY:

 [0] = Message
 [1] = Error code
 [2] = Type
 [3] = Parent 

=cut

sub error_split
{
	my $class = shift ;

	my ($error) = @_ ;
	my @parts ;
	
	if ($error)
	{
		@parts = @$error{qw/message errorcode type parent/} ;
	}
	
	return @parts ;
}

#-----------------------------------------------------------------------------

=item B<register_global_handler($code_ref)>

Add a new global error handler on to the stack

=cut

sub register_global_handler
{
	my $class = shift ;
	my ($code_ref) = @_ ;
	
	push @GLOBAL_ERROR_HANDLERS, $code_ref ;
}

#-----------------------------------------------------------------------------

=item B<default_error_handler($error)>

Last ditch attempt to handle errors. Uses die(), warn() etc as appropriate.

=cut

sub default_error_handler
{
	my $this = shift ;
	my ($error) = @_ ;

	my $handled = 0 ;

	# If it's an error, stop
	if ($this->is_error($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		die "Error: $msg\n" ;
		$handled = 1 ;
	}
	if ($this->is_warning($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		warn "Warning: $msg\n" ;
		$handled = 1 ;
	}
	if ($this->is_note($error))
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		print "Note: $msg\n" ;
		$handled = 1 ;
	}

	return $handled ;
}


#============================================================================================
# OBJECT METHODS 
#============================================================================================


#-----------------------------------------------------------------------------

=item B<_throw_error($error)>

Add a new error to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub _throw_error
{
	my $this = shift ;
	my ($error) = @_ ;
	
	# Add to this object's list
	push @{$this->errors()}, $error ;

	# Add to global list
	$this->_global_error($error) ;
	
	## Handle the error 
	my $handled = 0 ;

	# See if we have a registered catch function
	my $catch_fn = $this->catch_fn() ;
	if ($catch_fn)
	{
		$handled = &$catch_fn($error) ;
	}
	
	# if not handled, try global
	if (!$handled)
	{
		for (my $i = scalar(@GLOBAL_ERROR_HANDLERS)-1; ($i>=0) && !$handled; --$i)
		{
			$catch_fn = $GLOBAL_ERROR_HANDLERS[$i] ;
			$handled = &$catch_fn($error) ;
		}
	}

	# when all else fails, do it yourself
	if (!$handled)
	{
		$handled = $this->default_error_handler($error) ;
	}
	
	# If all REALLY fails, die!	
	if (!$handled)
	{
		my ($msg, $exitcode) = $this->error_split($error) ;
		die "Unhandled Error: $msg ($exitcode)\n" ;
	}

}

#-----------------------------------------------------------------------------

=item B<rethrow_error($error_ref)>

Throws an error for this object based on an error object associated with a different object
 
=cut

sub rethrow_error
{
	my $this = shift ;
	my ($error) = @_ ;
	
	# Create copy of error
	my %err_copy = () ;
	foreach (keys %$error)
	{
		$err_copy{$_} = $error->{$_} ;
	}
	$err_copy{'parent'} = $this ;
	
	$this->_throw_error(\%err_copy) ;
	
}


#-----------------------------------------------------------------------------

=item B<throw_error([%args])>

Add a new error to this object instance, also adds the error to this Class list
keeping track of all runtime errors

%args hash contains:

	* type = fatal, nonfatal, warning, note
	* message = text message
	* errorcode = integer error code value

=cut

sub throw_error
{
	my $this = shift ;
	my (%args) = @_ ;
	
	# Convert args into an error
	my $error = _create_error('parent'=>$this, %args) ;

	$this->_throw_error($error) ;
	
}

#-----------------------------------------------------------------------------

=item B<throw_fatal($message, [$errorcode])>

Add a new error (type=fatal) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_fatal
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	# Convert args into an error
	$this->throw_error('type'=>'fatal', 'message'=>$message, 'errorcode'=>$errorcode) ;
	
}


#-----------------------------------------------------------------------------

=item B<throw_nonfatal($message, [$errorcode])>

Add a new error (type=nonfatal) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_nonfatal
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	# Convert args into an error
	$this->throw_error('type'=>'nonfatal', 'message'=>$message, 'errorcode'=>$errorcode) ;
	
}

#-----------------------------------------------------------------------------

=item B<throw_warning($message, [$errorcode])>

Add a new error (type=warning) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_warning
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	# Convert args into an error
	$this->throw_error('type'=>'warning', 'message'=>$message, 'errorcode'=>$errorcode) ;
	
}

#-----------------------------------------------------------------------------

=item B<throw_note($message, [$errorcode])>

Add a new error (type=note) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_note
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	# Convert args into an error
	$this->throw_error('type'=>'note', 'message'=>$message, 'errorcode'=>$errorcode) ;
	
}



#-----------------------------------------------------------------------------

=item B<last_error()>

Returns a hash containing the information from the last (worst case) error stored for this object
i.e. if a 'fatal' error is followed by some 'note's then the 'fatal' error is returned

Hash contains:

	* type = fatal, error, warning, note
	* message = text message
	* errorcode = integer error code value

If there are no errors, returns undef

=cut

sub last_error
{
	my $this = shift ;
	my (%args) = @_ ;

	my $errors_aref = $this->errors() ;

	my $error = _latest_worst_error($errors_aref) ;
	
	return $error ;
}


#-----------------------------------------------------------------------------

=item B<error()>

Returns a hash containing the information from the last actual error (i.e. only 'fatal' or 'nonfatal' types) stored for this object

Hash contains:

	* type = fatal, error, warning, note
	* message = text message
	* errorcode = integer error code value

If there are no errors, returns undef

=cut

sub error
{
	my $this = shift ;
	my (%args) = @_ ;

	my $error = $this->last_error() ;
	
	# Ensure this is something worth reporting
	if ($error)
	{
		my $type = $ERR_TYPES{$error->{'type'}} ;
		unless ($type & $ERR_TYPE_MASK)
		{
			$error = undef ;
		}
	}
		
	return $error ;
}



# ============================================================================================
# PRIVATE FUNCTIONS
# ============================================================================================

#-----------------------------------------------------------------------------

=item B<_create_error()>

Returns a hash containing the information from the last error stored for this object

Hash contains:

	* type = fatal, error, warning, note
	* message = text message
	* errorcode = integer error code value

If there are no errors, returns undef

=cut

sub _create_error
{
	my (%args) = @_ ;

	# TODO: Convert errors into error objects then add to the list
	my $error = {
		'type' => $args{'type'},
		'message' => $args{'message'},
		'errorcode' => $args{'errorcode'},
		'parent' => $args{'parent'},
	} ;
	
	return $error ;
}

#-----------------------------------------------------------------------------

=item B<_cmp_error($err1, $err2)>

Compares error types. If the type of $err1 is more srious than $err2 then returns positive;
if type $err1 is less serious than $err2 then returns negative; otherwise returns 0

Order of seriousness:

	* fatal
	* error
	* warning
	* note

=cut

sub _cmp_error
{
	my ($err1, $err2) = @_ ;

# TODO: Add checks for valid error object & type get

	my ($err1_pri, $err2_pri) = (0, 0) ;
	$err1_pri = $ERR_TYPES{$err1->{'type'}} if exists($ERR_TYPES{$err1->{'type'}}) ;
	$err2_pri = $ERR_TYPES{$err2->{'type'}} if exists($ERR_TYPES{$err2->{'type'}}) ;

	return $err1_pri <=> $err2_pri ;
}

#-----------------------------------------------------------------------------

=item B<_latest_worst_error($errors_aref)>

Works through the specified errors list and returns the latest, worst error

=cut

sub _latest_worst_error
{
	my ($errors_aref) = @_ ;

	my $error = undef ;
	my $num_errors = scalar(@$errors_aref) ;
	if ($num_errors)
	{
		# Run backwards looking for worst error
		foreach my $ix (0..$num_errors-1)
		{
			my $error_num = $num_errors-1-$ix ;
			if (!$error || _cmp_error($errors_aref->[$error_num], $error)>0 )
			{
				$error = $errors_aref->[$error_num] ;
			}
		}
	}

	return $error ;	
}

# ============================================================================================
# END OF PACKAGE
1;

__END__


