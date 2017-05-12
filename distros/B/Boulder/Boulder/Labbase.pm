# NOTE:  This implementation is obviously incomplete.  Don't try to use it.

package Boulder::Labbase;

# Given access to a boulderio schema for Labbase, return information
# about tokens (materials).

use Boulder::Stream;

require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();

use Carp;
use LabBase;

# To create a new Boulder::Stream use new().
# new() takes named parameters:
# -schema=> A Stone() object containing the schema for the token.
# -in=> LabBase object to get tokens from.
# -out=> LabBase object to store tokens into.
#

# To fetch the Stone object corresponding to a token
# use get() -or- read_record().
# The semantics of tag name lists are the same as in 
# Boulder::Stream.

# To store the Stone object corresponding to a token:
# use put() -or- write_record().
# parameters:
# -token=> token to write
# -step=> the current step
# -workflow=> the current workflow name
# -state=> name of the current state

sub new {
    my($package) = shift;
    my($schema,$in,$out) = rearrange([SCHEMA,IN,OUT],@_);
    $out = $in unless $out;
    croak "Usage: Boulder::Labbase::new(-schema=>schema,-in=>lb_in,-out=>lb_out)\n"
	unless ref($schema)=~/Stone/ && ref($in)=~/LabBase/;

    # superclass constructor
    my($self) = new Boulder::Stream(); 

    # Add some extra parameters to the object
    $self->{'schema'} = $schema;
    $self->{'IN'} = $in;
    $self->{'OUT'} = $out;
    $self->{'passthru'} = undef;
}

# This is a low-level routine for "priming the pump" on a token.
# It sends a query to the database which will be used later to
# create the token stream.  You must pass it all the LabBase materials
# that are
# 
sub fetch_token {
    my($self) = shift;
    my($
}

sub rearrange {
    my($self,$order,@param) = @_;
    return () unless @param;
    
    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-')
	|| $self->use_named_parameters;

    my $i;
    for ($i=0;$i<@param;$i+=2) {
	$param[$i]=~s/^\-//;     # get rid of initial - if present
	$param[$i]=~tr/a-z/A-Z/; # parameters are upper case
    }
    
    my(%param) = @param;		# convert into associative array
    my(@return_array);
    
    my($key)='';
    foreach $key (@$order) {
	my($value);
	# this is an awful hack to fix spurious warnings when the
	# -w switch is set.
	if (ref($key) eq 'ARRAY') {
	    foreach (@$key) {
		last if defined($value);
		$value = $param{$_};
		delete $param{$_};
	    }
	} else {
	    $value = $param{$key};
	    delete $param{$key};
	}
	push(@return_array,$value);
    }
    push (@return_array,$self->make_attributes(\%param)) if %param;
    return (@return_array);
}
