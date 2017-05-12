# DWH_File (the Deep 'n' Wide Hash)
# - persistence for complex datastructures and objects in Perl
#
# version 0.03
#
# Special characters
# ^ as first char in a key indicates that the value is helper-data
#   the following few chars will always be digits designating the
#   helper ID or node ID
# ^ as the first char in a value indicates that the value is a reference
#   the following few chars will be digits indicating the helper ID or node ID
# % used as escape char for stored values and keys begining with ^ or %
#
# Global entries:
# ^L             Last ID generated
# ^N             Name formerly used
# ^I<0..n>       Entries in ID pool
# ^^<key>        Existence tester in base hash
# Future version:
# ^V             File type/version identifier
# ^S             Standard settings - implementations of SCALAR^ARRAY^HASH
#                these are three-digit figures starting with 100
#
# General reference entries:
# ^ID            TYPE | TYPE^Class (and as value)
# ^ID^^R         Reference Count
# Future version:
# ^ID^^V         Implementation type for this data -
#                for instance hashes may be saved in different
#                ways individually
#
# References to data in other .dwh file:
# ^ID^file_id    (as value)
#
# Hash entries
# ^ID^^          First key node (in linked list)
#
# Array entries
# ^ID^]          Array size

# "abstract methods" required in derived classes:
# STORE_NAIVE
# FETCH_NAIVE
# SetLoaded
# Master
# FarName

##########################################################################
# The registry keeps track of DWH_File objects to manage references to
# objects stored in different files

package DWH_File::Registry;

use strict;

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    
    return $self;
}

sub Register
{
    my ( $self, $instance ) = @_;
    
    unless ( ref( $instance ) =~ /DWH_File/ )
    {
	warn "Attempt to register non-DWH_File in DWH_File::Registry";
	return undef;
    }
    unless ( $instance->{ name } )
    {
	warn "Attempt to register DWH_File with no name tag";
	return undef;
    }
    if ( exists( $self->{ $instance->{ name } } ) and
	 $self->{ $instance->{ name } } ne $instance )
    {
	die
      "Registering more than one DWH_File with name tag '$instance->{name}'";
    }
    $self->{ $instance->{ name } } = $instance;
}

sub Unregister
{
    my ( $self, $instance ) = @_;
    
    unless ( ref( $instance ) =~ /DWH_File/ )
    {
	warn "Attempt to unregister non-DWH_File in DWH_File::Registry";
	return undef;
    }
    unless ( exists( $self->{ $instance->{ name } } ) and
	     $self->{ $instance->{ name } } eq $instance )
    {
	warn
      "Unegistering unregistered DWH_File with name tag '$instance->{name}'";
    }
    delete $self->{ $instance->{ name } };
}

sub Resolve
{
    my ( $self, $instance, $refID ) = @_;
    
    if ( $self->{ $instance } )
    {
	$self->{ $instance }->FETCH_FAR( $refID );
    }
    else { warn "Attempt to resolve from non-registered DWH: $instance" }
}

1;

##########################################################################
# DWH_File::Base is base class of the helper classes and the working
# class ( and this has nothing to do with marxism :-) )
#
package DWH_File::Base;

use strict;
use vars qw( %tieing );

# used by Work HashHelper and ArrayHelper - overridden by ScalarHelper but
# called by the overriding method
sub STORE
{
    my ( $self, $subscript, $value ) = @_;
    
    # DWH_File stringifies undefined subscripts into the empty string
    defined( $subscript ) or $subscript = '';
    # %-escape any leading special-character (% or ^) in the subscript
    my $s = substr $subscript, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $subscript, 0, 0 ) =  '%' }

    # if a reference is already stored at the key decrease it's refcount
    my $oldval = $self->FETCH_NAIVE( $subscript );
    if ( defined $oldval and substr( $oldval, 0, 1 ) eq '^' )
    {
	$self->{ master }->DecRefCount( $oldval );
    }

    if ( defined $value )
    {
	if ( ref $value )
	{
	    my $far;
	    my $tied = _tied( $value );

	    if ( $value =~ /HASH/ )
	    {
		if ( ref( $tied ) eq "DWH_File::HashHelper" )
		{
		    if ( $tied->{ master } != $self->{ master } )
		    {
			$far = $tied->FarName;
		    }
		}
		elsif ( $tied )
		{
		    warn "Attempt to store reference to hash data tied to " .
			ref( $tied );
		    # future project: tie to TiedHashHelper
		}
		else
		{
		    $tied = tie( %$value, 'DWH_File::HashHelper', $value,
				 $self->{ master } );
		}
	    }
	    elsif ( $value =~ /ARRAY/ )
	    {
		if ( ref( $tied ) eq "DWH_File::ArrayHelper" )
		{
		    if ( $tied->{ master } != $self->{ master } )
		    {
			$far = $tied->FarName;
		    }
		}
		elsif ( $tied )
		{
		    warn "Attempt to store reference to array data tied to " .
			ref( $tied );
		    # future project: tie to TiedArrayHelper
		}
		else
		{
		    $tied = tie( @$value, 'DWH_File::ArrayHelper', $value,
				 $self->{ master } );
		}
	    }
	    elsif ( $value =~ /SCALAR/ )
	    {
		if ( ref( $tied ) eq "DWH_File::ScalarHelper" )
		{
		    if ( $tied->{ master } != $self->{ master } )
		    {
			$far = $tied->FarName;
		    }
		}
		elsif ( $tied )
		{
		    warn "Attempt to store reference to scalar data tied to " .
			ref( $tied );
		    # future project: tie to TiedScalarHelper
		}
		else
		{
		    $tied = tie( $$value, 'DWH_File::ScalarHelper', $value,
				 $self->{ master } );
		}
	    }
        
	    # if $tied is undefined at this point, tie has been refused
	    # indicating a non-persistent object or previously tied data
	    # reference
	    if ( $tied )
	    {
		if ( $far )
		{
		    $self->STORE_NAIVE( $subscript, $tied->{ id } . '^' .
					$far );
		}
		else { $self->STORE_NAIVE( $subscript, $tied->{ id } ) }

		# remember that one more reference to this data has been stored
		$tied->IncMyRefcount;
	    }
	}
	else
	{
	    # %-escape any leading special-character (% or ^)  in the value
	    $s = substr $value, 0, 1;
	    if ( $s eq '^' or $s eq '%' ) { substr( $value, 0, 0 ) =  '%' }
	    $self->STORE_NAIVE( $subscript, $value );
	}
    } # end of if ( defined $value )
    else { $self->STORE_NAIVE( $subscript, undef ) };
}

sub FETCH
{
    my ( $self, $key ) = @_;

    defined( $key ) or $key = '';
    # %-escape any leading special-character (% or ^) in the subscript
    my $s = substr $key, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $key, 0, 0 ) = '%' }

    my $val = $self->FETCH_NAIVE( $key );
    defined( $val ) or return undef;

    # if the value is a reference
    if ( substr( $val, 0, 1 ) eq '^' )
    {
        # if the reference has already been registered in memory
        # return it - otherwise load it and return the result
        return $self->{ master }->Reference( $val );
    }
    else
    {
        # if its a plain scalar just de-escape and return it
	substr( $val, 0, 1 ) eq '%' and substr( $val, 0, 1 ) = '';
	return $val;
    }
}

sub _tied
{
    my $ty;
    if ( "$_[ 0 ]" =~ /HASH/ ) { $ty = tied( %{ $_[ 0 ] } ) }
    elsif ( "$_[ 0 ]" =~ /ARRAY/ ) { $ty = tied( @{ $_[ 0 ] } ) }
    elsif ( "$_[ 0 ]" =~ /SCALAR/ ) { $ty = tied( ${ $_[ 0 ] } ) }

    if ( ref $ty ) { return $ty }
    elsif ( exists $tieing{ $_[ 0 ] } ) { return $tieing{ $_[ 0 ] } }
    else { return '' }
}

sub _tieing
{
    # print "tieing: $_[ 1 ]\n";
    $tieing{ $_[ 1 ] } = $_[ 0 ];
}

sub _didtie
{
    # print "didtie: $_[ 1 ]\n";
    delete $tieing{ $_[ 1 ] };
}

############################################################################
package DWH_File::Helper;

@DWH_File::Helper::ISA = qw( DWH_File::Base );

use strict;

# "abstract methods" required in derived classes:
# 
# RestoreOriginal
# StdType

sub TranslatePackage
{
    # parameter examples:
    # "Fruit::Strawberry", "Red" returns "Fruit/Red.pm"
    # "Fruit::Strawberry", undef returns "Fruit/Strawberry.pm"
    # "Cucumber", "Vegetable" returns "Vegetable.pm"
    # "Cucumber", undef returns "Cucumber.pm"
    my ( $class, $module ) = @_;
    
    my @path = split "::", $class;
    $module and $path[ $#path ] = $module;
    
    return( join( "/", @path ) . '.pm' );
}

sub TIE_GENERIC
{
    my ( $self, $this, $master, $ID ) = @_;
    
    # note that the thing is being tied
    my $in = "$this";
    $self->_tieing( $in );

    # Helper attributes reference to the data structure and master
    $self->{ dataref } = $this;
    $self->{ master } = $master;
    $self->{ hash } = $master->{ hash };

    # if an ID is provided then the reference is to be associated with the
    # corresponding slice of the DB file. Otherwise a new slice is to
    # be created.
    
    if ( $ID )
    {
        # this happens when a stored reference is FETCHED for the first time
        # during the current session
        
        # check that the ID is present in the master
        #$self->EXISTS_NAIVE( $ID ) or
        #   die  "File Corrupted: Nonexistent reference ID dereferenced";
        
        # the $this is initialized to become a reference to whatever $ID
        # represents
        
	# reference IDs qualifiers are represented as
	# <TYPE> for standard types ( HASH, ARRAY or SCALAR )
	# <TYPE>^<CLASS>^<MODULE> for objects of type class
	# <MODULE> being the "relative" name of the module file
	# containing the package defining the class
	# if <CLASS> is Gumbo::Hot and <MODULE> is Yummy then
	# the package is expected to reside in the file
	# 'Gumbo/Yummy.pm' somewhere in the @INC directories.
	# If the qualifier says <TYPE>^<CLASS> then the class
	# package is expected to reside in a unonymously named
	# file (eg. with class Gumbo::Hot the file would be
	# (some dir in @INC)/Gumbo/Hot.pm
        my ( $stdtype, $refclass, $module ) = split( /\^/,
            $self->{ master }->FETCH_NAIVE( $ID ) );

        # The standard type must match
        $stdtype ne $self->StdType and
            die "Attempt to tie to the wrong kind of DWH_File::Helper";
    
        # helper attribute the ID
        $self->{ id } = $ID;

        if ( $refclass )
        {
            # if it's an object - require the corresponding module
            my $modulepath = &TranslatePackage( $refclass, $module );
            require( $modulepath ) or die
         "Can't include file: '$modulepath' holding package: '$refclass' - $!";
            
	    no strict 'refs';
            if ( ${ $refclass.'::iamDWHcapable' } eq "Yes" )
            {
                # if it's a registered persistent object
                # create an empty object. The state of the object will be
                # present in $self->{ master }->{ dbm }
                bless $this, $refclass;
		# call any 'restore' routine set up by the class
		${ $refclass.'::restoresetup' } and
		    &${ $refclass.'::restoresetup' }( $this, $self );
            }
            else
            {
		warn "Class $refclass does note acknowledge DWH_File";
		return( undef );
	    }
        } 
        # if it's just a plain variable no further actions are needed

        # register that the ID is associated with a real live variable now
        $self->SetMeLoaded;
    }
    else
    {
        # this happens when a reference to a standard type or object is
        # being assigned somewhere in the persistent structure
        
        # a new entry slice in the DB File is created
        
        $ID = $self->{ master }->NewID;
        
        # get the class of the referenced object or type
        my $refclass = ref( $this );
        
        # store id => '<TYPE>' or id => '<TYPE>^<CLASS>[^<MODULE>]
        if ( $refclass ne $self->StdType )
        {
            no strict 'refs';
            unless ( ${ $refclass.'::iamDWHcapable' } eq "Yes" )
            {
                $self->{ master }->AddIDPool( $ID );
                return( undef );
            }
	    my $qualifier = $self->StdType . '^' . $refclass;
	    ${ $refclass.'::mymodulename' } and $qualifier .=
                "^${ $refclass.'::mymodulename' }";
            $self->{ master }->STORE_NAIVE( $ID, $qualifier );
        }
        else
        {
            $self->{ master }->STORE_NAIVE( $ID, $self->StdType );
        }
    
        # helper attribute the ID
        $self->{ id } = $ID;
        # register that the ID is associated with a real live variable now
        $self->SetMeLoaded;
     
        {
	    no strict 'refs';
	    # restore original contents
	    if ( ${ $refclass.'::intervene' } )
            {
                &${ $refclass.'::intervene' }( $this, $self );
            }
            else { $self->RestoreOriginal }
        }
    }

    delete $self->{ dataref };

    # note that we're done tieing
    $self->_didtie( $in );
}

sub SetMeLoaded
{
    my $self = shift;
    
    $self->{ master }->SetLoaded( $self->{ id }, $self->{ dataref } );
}

sub SetLoaded
{
    my ( $self, $ID, $ref ) = @_;
    
    $self->{ master }->SetLoaded( $ID, $ref );
}

sub IncMyRefcount
{
    my $self = shift;
    
    $self->{ master }->IncRefCount( $self->{ id } );
}

sub AnnihilateMe
{
    my $self = shift;
    
    # Remove data present in any reference
    # 1 the refcount
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^^R' );
    # and 2 the qualifier
    $self->{ master }->DELETE_NAIVE( $self->{ id } );
    
    # and remove the thing from the list of loaded stuff
    delete $self->{ master }->{ isloaded }->{ $self->{ id } };
}

sub FarName
{
    my $self = shift;
    
    return $self->{ master }->{ name };
}

###########################################################################
# this package implements a node class which the HashHelper instantiates
# twice. One instance works as an iterator for the FIRSTKEY and NEXTKEY
# methods. The other stores and retrieves values for the HashHelper

package DWH_File::HashHelper::KeyNode;

use strict;

sub new
{
    my ( $class, $master, $ownerID ) = @_;

    my $self = {
	ownerID => $ownerID,
	master => $master,
	hash => $master->{ hash }
    };

    bless $self, $class; # begin the show
}

sub Go
{
    # point the node to the specified key and return the ID
    my ( $self, $key ) = @_;
    defined( $key ) or return undef;
    $self->{ key } = $key;
    $self->{ id } = $self->{ master }->FETCH_NAIVE( $self->{ ownerID } . '^' .
						    $key );
}

sub GoFirst
{
    # point the node to the "first node" entry of the owner and return the key
    my $self = shift;

    $self->{ id } = $self->{ master }->FETCH_NAIVE( $self->{ ownerID } .
						    '^^' );
    defined $self->{ id } or return undef;
    $self->{ key } = $self->{ master }->FETCH_NAIVE( $self->{ id } . '^k' );
}

sub Venture
{
    # try to go to the specified key and if it's not there then make it
    # return the new ID if one is made. Otherwise return the old one.
    my ( $self, $key ) = @_;

    my $res;
    if ( $res = $self->Go( $key ) ) { return $res }

    # invariant: the key wazzent there before
    $self->{ id } = $self->{ master }->NewID;
    $self->{ master }->STORE_NAIVE( $self->{ ownerID } . '^' . $key,
				    $self->{ id } );
    $self->{ master }->STORE_NAIVE( $self->{ id } . '^k', $key );

    # make it the first node in the list
    my $nextid = $self->{ master }->FETCH_NAIVE( $self->{ ownerID } . '^^' );
    if ( defined $nextid )
    {
	$self->{ master }->STORE_NAIVE( $nextid . '^p', $self->{ id } );
	$self->{ master }->STORE_NAIVE( $self->{ id } . '^n',  $nextid );
    }
    $self->{ master }->STORE_NAIVE( $self->{ ownerID } . '^^', $self->{ id } );

    return $self->{ id };
}

sub SucceedingKey
{
    # point the node to the key succeeding the specified key
    # and return that key
    my ( $self, $key ) = @_;
    defined( $key ) or return undef;

    unless ( defined( $self->{ key } ) and $key eq $self->{ key } )
    {
	$self->Go( $key );
    }
    unless ( defined $self->{ id } ) { return undef }
    my $nextid = $self->{ master }->FETCH_NAIVE( $self->{ id } . '^n' );
    if ( defined $nextid )
    {
	$self->{ id } = $nextid;
	$self->{ key } = $self->{ master }->FETCH_NAIVE( $nextid . '^k' );
	return $self->{ key };
    }
    else
    {
	$self->{ id } = undef;
	$self->{ key } = undef;
	return undef;
    }
}

sub Value
{
    # return the value string
    my $self = shift;

    $self->{ master }->FETCH_NAIVE( $self->{ id } . '^v' );
}

sub SetValue
{
    # set return the value string
    my ( $self, $val ) = @_;
    if ( defined $val )
    {
	$self->{ master }->STORE_NAIVE( $self->{ id } . '^v', $val );
    }
    else { $self->{ master }->DELETE_NAIVE( $self->{ id } . '^v' ) }
}

sub Kill
{
    # delete the node and return the value string
    my $self = shift;

    defined( $self->{ id } ) or return undef;
    my $gone = $self->{ id };

    my $res = $self->{ master }->FETCH_NAIVE( $gone . '^v' );
    my $prev = $self->{ master }->FETCH_NAIVE( $gone . '^p' );
    
    # move to the next node
    $self->SucceedingKey( $self->{ key } );

    if ( defined $self->{ id } )
    {
	if ( $prev )
	{
	    # if prev then make it's "next" point to this node
	    $self->{ master }->STORE_NAIVE( $prev . '^n', $self->{ id } );
	    $self->{ master }->STORE_NAIVE(  $self->{ id } . '^p', $prev );
	}
	else
	{
	    # if no prev - then register this as the first node
	    $self->{ master }->STORE_NAIVE( $self->{ ownerID } . '^^',
					    $self->{ id } );
	    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^p' );
	}
    }
    elsif ( $prev )
    {
	# there's nothing after the goner
	$self->{ master }->DELETE_NAIVE( $prev . '^n' );
    }
    else
    {
	# empty hash
	$self->{ master }->DELETE_NAIVE( $self->{ ownerID } . '^^' );
    }
    $self->{ master }->DELETE_NAIVE( $gone . '^p' );
    $self->{ master }->DELETE_NAIVE( $gone . '^n' );
    $self->{ master }->DELETE_NAIVE( $gone . '^k' );
    $self->{ master }->DELETE_NAIVE( $gone . '^v' );
    $self->{ master }->AddIDPool( $gone );

    return $res;
}

############################################################################
# this package heps out when hash references are entered in an DWH_File

package DWH_File::HashHelper;

use strict;

@DWH_File::HashHelper::ISA = qw( DWH_File::Helper );

sub TIEHASH
{
    my ( $class, $this, $master, $ID ) = @_;
    
    my $self = {};
    
    bless $self, $class; # fire her up
    
    # get a node for FETCH and STORE
    $self->{ livenode } = DWH_File::HashHelper::KeyNode->new( $master, $ID );
    # and a node for FIRST/NEXTKEY
    $self->{ curnode } = DWH_File::HashHelper::KeyNode->new( $master, $ID );
    
    $self->TIE_GENERIC( $this, $master, $ID );

    $self->{ curnode }->GoFirst;
    
    return $self;
}

sub FETCH_NAIVE
{
    my ( $self, $key ) = @_;

    $self->{ livenode }->Go( $key ) and return( $self->{ livenode }->Value );
    return undef;
}

sub STORE_NAIVE
{
    my ( $self, $key, $value ) = @_;

    $self->{ livenode }->Venture( $key );
    if ( defined $value ) { $self->{ livenode }->SetValue( $value ) }
    else { $self->{ livenode }->SetValue( undef ) }
}

sub DELETE
{
    my ( $self, $key ) = @_;

    defined( $key ) or $key = '';
    # %-escape any leading special-character (% or ^) in the key
    my $s = substr $key, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $key, 0, 0 ) = '%' }

    # if a reference is stored at the key decrease it's refcount
    my $val = $self->FETCH_NAIVE( $key );
    if ( defined $val and substr( $val, 0, 1 ) eq '^' )
    {
	$self->{ master }->DecRefCount( $val );
    }
    
    $self->DELETE_NAIVE( $key );
}

sub DELETE_NAIVE
{
    my ( $self, $key ) = @_;

    defined( $self->{ livenode }->Go( $key ) ) or return undef;
    $self->{ curnode }->SucceedingKey( $key );
    $self->{ livenode }->Kill;
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^' . $key );
}

sub CLEAR
{
    my $self = shift;
    
    $self->{ livenode }->GoFirst;
    # don't bother restoring the current node in DELETE()
    $self->{ curnode }->{ id } = '';
    $self->{ curnode }->{ key } = '';
    
    while ( defined $self->{ livenode }->{ id } )
    {
	# if a reference is stored at the key decrease it's refcount
	my $val = $self->{ livenode }->Value;
	if ( defined $val and substr( $val, 0, 1 ) eq '^' )
	{
	    $self->{ master }->DecRefCount( $val );
	}
	$self->DELETE_NAIVE( $self->{ livenode }->{ key } );
        # this will point the node to the next entry so the loop will be finite
    }
}

sub AnnihilateMe
{
    my $self = shift;
    
    # clear the contents of the structure
    $self->CLEAR;
    
    # remove the first-node pointer
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^^' );
    
    # perform cleanup related to any reference
    $self->SUPER::AnnihilateMe;
}

sub StdType { 'HASH' }
    
sub RestoreOriginal
{
    my $self = shift;

    # when RestoreOriginal runs it means that the nodes owner ID aren't
    # initialized
    $self->{ livenode }->{ ownerID } = $self->{ id };
    $self->{ curnode }->{ ownerID } = $self->{ id };

    return( undef ) unless defined $self->{ dataref };
    
    foreach ( keys %{ $self->{ dataref } } )
    {
        $self->STORE( $_, $self->{ dataref }->{ $_ } );
    }
}

sub FIRSTKEY
{
    my $self = shift;
    
    my $key = $self->{ curnode }->GoFirst;

    defined( $key ) or return undef;
    # de-escape the key
    substr( $key, 0, 1 ) eq '%' and substr( $key, 0, 1 ) = '';

    return $key;
}

sub NEXTKEY
{
    my ( $self, $k) = @_;
    
    defined( $k ) or $k = '';
    # %-escape any leading special-character (% or ^) in the input key
    my $s = substr $k, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $k, 0, 0 ) = '%' }

    my $key = $self->{ curnode }->SucceedingKey( $k );
    return( undef ) unless defined $key;

    # de-escape the output key
    substr( $key, 0, 1 ) eq '%' and substr( $key, 0, 1 ) = '';

    return $key;
}

sub EXISTS
{
    my ( $self, $key ) = @_;

    defined( $key ) or $key = '';
    # %-escape any leading special-character (% or ^) in the input key
    my $s = substr $key, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $key, 0, 0 ) = '%' }

    if ( defined( $self->{ master }->FETCH_NAIVE( $self->{ id } . '^' .
						  $key ) ) )
    {
	return 1;
    }
    else { return undef }
}

1;


#############################################################################
# this package heps out when array references are entered in an DWH_File

package DWH_File::ArrayHelper;

use strict;

@DWH_File::ArrayHelper::ISA = qw( DWH_File::Helper );

sub TIEARRAY
{
    my ( $class, $this, $master, $ID ) = @_;
    
    if ( $[ != 0 ) { die
  "Sorry but DWH_File requires \$[ to be set to zero to work with arrays\n" }
    
    my $self = { };

    bless $self, $class; # fire her up
    
    $self->TIE_GENERIC( $this, $master, $ID );
    
    return $self;
}

sub FETCH_NAIVE
{
    my ( $self, $index ) = @_;

    return $self->{ master }->FETCH_NAIVE( $self->{ id } . '^' . $index );
}

sub STORE_NAIVE
{
    my ( $self, $index, $value ) = @_;
    
    if ( defined( $value ) and $index >= $[ )
    {
        $self->{ master }->STORE_NAIVE( $self->{ id } . '^' . $index, $value );
    }
    else
    {
	# if the value is undefined then save the space
        $self->DELETE( $index );
    }

    # whether or not the value is defined
    if ( $index >= $self->FETCHSIZE ) { $self->STORESIZE( $index + 1 ) }
}

sub DELETE
{
    my ( $self, $index ) = @_;

    my $val = $self->FETCH_NAIVE( $index );
    
    # if the value is a reference then decrement it's refcount
    if ( defined $val and substr( $val, 0, 1 ) eq '^' )
    {
	$self->{ master }->DecRefCount( $val );
    }
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^' . $index );
}

sub FETCHSIZE
{
    my $self = shift;

    my $res = $self->FETCH_NAIVE( ']' );

    defined( $res ) and return $res;
    return 0;
}

sub STORESIZE
{
    my ( $self, $size ) = @_;

    my $i;
    my $oldsize = $self->FETCHSIZE;
    for ( $i = $size ; $i < $oldsize ; $i++ )
    {
	$self->DELETE( $i );
    }

    $self->STORESIZE_DUMB( $size );
}

sub STORESIZE_DUMB
{
    my ( $self, $size ) = @_;

    $self->{ master }->STORE_NAIVE( $self->{ id } . '^]', $size );
}

sub CLEAR
{
    my $self = shift;

    $self->STORESIZE( 0 );
}

sub PUSH
{
    my $self = shift;

    for ( @_ ) { $self->STORE( $self->FETCHSIZE, $_ ) }
}

sub POP
{
    my $self = shift;

    my $res = $self->FETCH( $self->FETCHSIZE - 1 );
    $self->STORESIZE( $self->FETCHSIZE - 1 );
    return $res;
}

sub SHIFT
{
    my $self = shift;

    my $res = $self->FETCH( 0 );
    $self->DELETE( 0 );

    my $i;
    my $oldsize = $self->FETCHSIZE;
    my $h = $self->{ hash };
    my $id = $self->{ id };
    for ( $i = 1 ; $i < $oldsize ; $i++ )
    {
	$h->{ $id . '^' . ( $i - 1 ) } = $h->{ $id . '^' . $i };
    }
    delete $h->{ $id . '^' . ( $oldsize - 1 ) };
    $self->STORESIZE_DUMB( $oldsize - 1  ); # we don't wanna reduce any
                                            # more refcounts

    return $res;
}

sub UNSHIFT
{
    my $self = shift;
    my $l = @_;

    my $h = $self->{ hash };
    my $id = $self->{ id };
    my $i;
    for ( $i = $self->FETCHSIZE - 1 ; $i >= 0 ; $i-- )
    {
	$h->{ $id . '^' . ( $i + $l ) } = $h->{ $id . '^' . $i };
    }

    $self->STORESIZE( $self->FETCHSIZE + $l );

    $i = 0;
    for ( @_ )
    {
	$self->STORE( $i, $_ );
	$i++;
    }
}

sub SPLICE
{
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    # negative offsets count backwards from the end of the array
    # an offset -1 means the last item
    if ( $offset < 0 ) { $offset = $self->FETCHSIZE + $offset }

    # store #length items from offset to be returned and clear the
    # original array entries
    my $i;
    my @res = ();
    for ( $i = $offset; $i < $offset + $length; $i++ )
    {
	push @res, $self->FETCH( $i );
	$self->DELETE( $i );
    }

    my $oldsize = $self->FETCHSIZE;
    my $id = $self->{ id };
    my $h = $self->{ hash };
    if ( $length > scalar( @_ ) )
    {
	# compress array
	my $d = $length - scalar( @_ );
	for ( $i = $offset + $length; $i < $oldsize; $i++ )
	{
	    $h->{ $id . '^' . ( $i - $d ) } = $h->{ $id . '^' . $i };
	    $i >= $oldsize - $d and delete $h->{ $id . '^' . $i };
	}
	$self->STORESIZE_DUMB( $oldsize - $d );
    }
    elsif ( $length < scalar( @_ ) )
    {
	# expand array
	my $d = scalar( @_ ) - $length;
	for ( $i = $oldsize - 1; $i >= $offset + $length; $i-- )
	{
	    $h->{ $id . '^' . ( $i + $d ) } = $h->{ $id . '^' . $i };
	}
	$self->STORESIZE_DUMB( $oldsize + $d );
    }

    $i = $offset;
    for ( @_ )
    {
	$self->STORE( $i, $_ );
	$i++;
    }

    return @res;
}

sub StdType { 'ARRAY' }

sub AnnihilateMe
{
    my $self = shift;
    
    # clear the contents of the array
    $self->CLEAR;
    
    # remove the size entry
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^]' );

    # perform cleanup related to any reference
    $self->SUPER::AnnihilateMe;
}
    
sub RestoreOriginal
{
    my $self = shift;
    
    my @orig = @{ $self->{ dataref } } if defined $self->{ dataref };
    
    if ( @orig )
    {
        my $i;
        for ( $i = 0 ; $i <= $#orig ; $i++ )
        {
            $self->STORE( $i, $orig[ $i ] );
        }
    }
}

1;


#############################################################################
# this package heps out when scalar references are entered in an DWH_File

package DWH_File::ScalarHelper;

use strict;

@DWH_File::ScalarHelper::ISA = qw( DWH_File::Helper );

sub TIESCALAR
{
    my ( $class, $this, $master, $ID ) = @_;
    
    my $self = {};
    
    bless $self, $class; # fire her up
    
    $self->TIE_GENERIC( $this, $master, $ID );
    
    return $self;
}

sub StdType { 'SCALAR' }
    
sub RestoreOriginal
{
    my $self = shift;
    
    if ( defined $self->{ dataref } ) { $self->STORE( $self->{ dataref } ) }
}

sub FETCH_NAIVE
{
    my ( $self ) = @_;
    
    return $self->{ master }->FETCH_NAIVE( $self->{ id } . '^' );
}

sub STORE
{
    my ( $self, $value ) = @_;
    
    $self->SUPER::STORE( '', $value );
}

sub STORE_NAIVE
{
    my ( $self, $subscript, $value ) = @_;
    
    # the subscript is ignored
    if ( defined $value )
    {
	$self->{ master }->STORE_NAIVE( $self->{ id } . '^', $value );
    }
    else { $self->{ master }->DELETE_NAIVE( $self->{ id } . '^' ) }
}

sub AnnihilateMe
{
    my $self = shift;
    
    # clear the contents
    $self->STORE( undef ); # this will take care of refcount administration
    
    $self->{ master }->DELETE_NAIVE( $self->{ id } . '^' );
    
    # perform clean up related to any reference
    $self->SUPER::AnnihilateMe;
}

1;


###########################################################################
# the working package begins here                                         #
###########################################################################

package DWH_File::Work;

use Fcntl;
use FileHandle;
use strict;
use vars qw( $_registry @lockfiles );

@DWH_File::Work::ISA = qw( DWH_File::Base );

BEGIN
{
    defined( $_registry ) or $_registry = DWH_File::Registry->new;
    defined( @lockfiles ) or @lockfiles = ();
}

sub TIEHASH
{
    # Params:
    # class (usually DWH_File), filename, access rights, mode, tag
    
    my ( $class, $file, $fc, $pms, $name ) = @_;  
    
    # variables for a hash, DB_File object, hash reference, lock file
    my ( %r, $dbm, $hashref, $lock );
    
    # add .dwh extension
    # eg. "file" becomes "file.dwh" - "file.dbm" becomes "file.dwh.dbm"
    # "file.abc.dbm" becomes "file.abc.dwh.dbm"
    if ( $file =~ /\./ ) { $file =~ s/\.(\w*)$/.dwh.$1/ }
    else { $file .= '.dwh' }
    
    # enforce mutual exclusion
    my $exfile = -e $file;
    $exfile and $lock = _Lock( $file, $fc );
    # tie %r to an *_File object
    $dbm = tie( %r, $DWH_File::dbmf, $file, $fc, $pms ) or
        die "DWH_File couldn't tie to file $file: $!";
    $exfile or $lock = _Lock( $file, $fc );
    $hashref = \%r;
    
    # make sure that if a name is specified it doesn't conflict with
    # any formerly used name in this file
    if ( defined $name )
    {
	if ( defined $r{ '^N' } )
	{
	    $name ne $r{ '^N' } and warn
		"Specified tag '$name' differs from file tag '$r{ '^N' }'";
	    $name = $r{ '^N' };
	}
	else { $r{ '^N' } = $name }
    }
    else { defined( $r{ '^N' } ) or $r{ '^N' } = '' }

    # DWH_File object attributes
    my $self =
    {
        dbm => $dbm,
        hash => $hashref,
        name => $r{ '^N' },
        file => $file,
        isloaded => {},
	garbage => {},
	idpool => undef
    };
    $self->{ master } = $self;
    if ( $DWH_File::log )
    {
	my $fh = new FileHandle ">> $file.$DWH_File::log";
	if ( defined $fh ) { $self->{ logFH } = $fh }
	else { warn "Couldn't open log $file.$DWH_File::log for append" }
    }
    if ( defined( $lock ) and $lock ) { $self->{ lock } = $lock }

    bless $self, $class;

    # Register this instance with the registry
    $_registry->Register( $self ) if $self->{ name };

    # initialize ID counter if not already present in the file
    unless ( defined $self->FETCH_NAIVE( '^L' ) )
    {
	$self->STORE_NAIVE( '^L', -1 );
    }

    return $self;
}

sub _Lock
{
    # lock by the configured method and return the name of the lockfile
    if ( $DWH_File::muex =~ /standard/ ) { _LockStandard( @_ ) }
    elsif ( $DWH_File::muex =~ /fork/ ) { _LockFork( @_ ) }
}

sub _LockStandard
{
    my ( $file, $fc ) = @_;

    # if write lock exists no lock can be granted
    opendir( DIR, "." ) or die "Couldn't open locks dir: $!" ;
    my $i;
    my @locks;
    my $lock;
    for ( $i = 1 ; $i <= 10 ; $i++ )
    {
	rewinddir DIR;
	@locks = grep /^W_.+_$file/, readdir DIR;
	@locks or last;
	sleep 1;
    }
    @locks and &_PurgeLocks( \@locks );
    @locks and
	die "DWH couldn't lock file $file. Previous write locks";
    

    if ( $fc & O_WRONLY or $fc & O_RDWR )
    {
	# write lock needed
	
	# store the lock name globally
	$file =~ /[^\/]+$/; # match all chars from after the last slash
	$lock = $` . "W_" . $$ . "_$&";
	link( $file, $lock ) or
	    die "DWH couldn't lock file $file for writing. Link failed: $!";

	for ( $i = 1 ; $i <= 10 ; $i++ )
	{
	    rewinddir DIR;
	    @locks = grep /^R_.+_$file/, readdir DIR;
	    @locks or last;
	    sleep 1;
	}
	@locks and &_PurgeLocks( \@locks );
	@locks and
	    die "DWH couldn't lock file $file for writing. Previous locks";
	# check at link count på filen er 2 - ellers error.
    }
    else
    {
	# read lock needed

	# store the lock name globally
	$lock = "R_" . $$ . "_$file";
	link( $file, $lock ) or
	    die "DWH couldn't lock file $file for reading. Link failed: $!";
    }
    return $lock;
}

sub _LockFork
{
    my ( $file, $fc ) = @_;
    # get the directory containing the module. This will also contain the
    # Excluder script
    my $dir = &_FindMyDir;

    # run the Excluder script (reading its  STDERR as well as STDOUT)
    my @reply = `$dir/DWH_Excluder.pl $$ $file $fc 2>&1`;

    if ( $reply[ 0 ] =~ /^(R|W_.+_$file)$/ ) { return $reply[ 0 ] }
    else { die "DWH error: fork locking failed: $reply[ 0 ]" }
}

sub _FindMyDir
{
    # find der directory in @INC that contains this module
    my $inc;
    foreach $inc ( @INC ) { -e "$inc/DWH_File.pm" and return $inc }
    die "Can't find directory in \@INC containing DWH_File.pm";
}

sub _PurgeLocks
{
    # make sure that locks' processes are alive
    my $locksref = shift;

    my $i = 0;
    for ( @$locksref )
    {
	/[WR]_(\d+)_/;
	# my $lpid = $1;
	my @ps = `ps c $1`;
	# remove the lock if the embedded pid doesn't match a perly process
	unless ( $ps[ 1 ] =~ /\bperl\b/ )
	{
	    if ( unlink $_ )  { undef $_ }
	    else { warn "couldn't unlink lock file: $_" }
	}
    }
    @$locksref = grep defined, @$locksref;
}

sub eat_log
{
    my ( $self, $logfile ) = @_;
    
    unless ( open LOGFILE, $logfile )
    {
	warn "Couldn't open log file to eat: $!";
	return;
    }

    my ( $key, $value, $i );
    while ( <LOGFILE> )
    {
	if ( /^\^(\d+)$/ )
	{
	    $key = '';
	    for ( $i = 0; $i < $1; $i++ ) { $key .= <LOGFILE> }
	    chop $key;
	}
	else
	{
	    warn "Found $logfile to be corrupted. Data may be corrupted";
	    last;
	}
	$_ = <LOGFILE>;
	if ( /^\*(\d+)$/ )
	{
	    if ( $1 )
	    {
		$value = '';
		for ( $i = 0; $i < $1; $i++ ) { $value .= <LOGFILE> }
		chop $value;
		$self->STORE_NAIVE( $key, $value );
	    }
	    else { $self->STORE_NAIVE( $key, undef ) }
	}
	elsif ( /^\*d$/ ) { $self->DELETE_NAIVE( $key ) }
	else
	{
	    warn "Found $logfile to be corrupted. Data may be corrupted";
	    last;
	}
    }

    close LOGFILE;
}

sub NewID
{
    my $self = shift;
    
    # try getting an ID from the ID pool
    my $num = $self->GetFromIDPool;
    
    # if this doesn't succeed get a new ID
    unless ( defined( $num ) )
    {
        $self->{ hash }->{ '^L' } = $self->{ hash }->{ '^L' } + 1;
        $num = $self->{ hash }->{ '^L' };
    }
    
    return '^' . $num;
}

sub GetFromIDPool
{
    my $self = shift;
    
    my $recycleID;

    # if no ID pool is present try loading it
    defined( $self->{ idpool } ) or $self->LoadIDPool;
    
    # shift an ID off the pool
    $recycleID = shift @{ $self->{ idpool } };
    if ( defined( $recycleID ) ) { $self->{ idpoolaltered } = 1 }
    
    # and return it
    return $recycleID;
}

sub LoadIDPool
{
    my $self = shift;
    
    my @pool = ();
    my $bulk;
    my $i = 0;
    
    # load all the '^Ix' portions and push them into the @pool
    $bulk = $self->FETCH_NAIVE( '^I' . $i );
    while ( defined( $bulk ) )
    {
        push @pool, split /\n/, $bulk;
        $i++;
        $bulk = $self->FETCH_NAIVE( '^I' . $i );
    }
    
    $self->{ idpool } = \@pool;
}

sub AddIDPool
{
    my ( $self, $reclaim ) = @_;
    # if no ID pool is present try loading it
    defined( $self->{ idpool } ) or $self->LoadIDPool;
    
    # isolate the actual ID number
    substr( $reclaim, 0, 1 ) = '';
    
    push @{ $self->{ idpool } }, $reclaim;
    $self->{ idpoolaltered } = 1;
}

sub StoreIDPool
{
    my $self = shift;

    # wipe out the old pool
    my $i = 0;
    while ( defined $self->FETCH_NAIVE( '^I' . $i ) )
    {
        $self->DELETE_NAIVE( '^I' . $i );
        $i++;
    }
    
    my @pool = @{ $self->{ idpool } };
    my $ID = shift @pool;
    $i = 0;
    while ( defined( $ID ) )
    {
        my $p = '';
        while ( defined( $ID ) and ( length( $p . $ID ) < 2048 ) )
        {
            $p .= $ID . "\n";
            $ID = shift @pool;
        }
        chop $p; # remove the trailing newline
        $self->STORE_NAIVE( '^I' . $i, $p );
        $i++;
    }
}

sub FarName
{
    my $self = shift;
    
    return $self->{ name };
}

sub STORE_NAIVE
{
    my ( $self, $key, $value ) = @_;

    defined $key or $key = '';

    $self->{ dbm }->STORE( $key, $value );
    defined( $self->{ logFH } ) or return;
    my @a;
    my $fh = $self->{ logFH };
    my $lines = scalar( @a = split /\n/, $key, -1 );
    print $fh "^$lines\n", "$key\n";
    $lines = scalar( @a = split /\n/, $value, -1 );
    print $fh "*$lines\n", "$value\n";

    # logfile format:
    #  ^number-of-newlines-in-key + 1
    #  key...
    #  *number-of-newlines-in-value + 1
    #  value...
}

sub FETCH_FAR
{
    my ( $self, $ID ) = @_;
    
    return $self->Reference( $ID );
}

sub FETCH_NAIVE
{
    my $self = shift;
    
    $self->{ dbm }->FETCH( @_ );
}

sub dump_pretty
{
    my $self = shift;

    foreach ( sort keys %{ $self->{ hash } } )
    {
	print "$_ => ", $self->{ hash }{ $_ }, "\n";
    }
}

sub Reference
{
    my ( $self, $ID ) = @_;
    
    my $ref = $self->{ isloaded }->{ $ID };
    $ref or $ref = $self->LoadReference( $ID );
    return $ref;
}

sub LoadReference
{
    my ( $self, $ID ) = @_;
    
    my $result;
    my ( $fid, $far ) = $ID =~ /^(\^\d+)(\^.+)/;
    # far references format: ^refID^farname

    if ( $far )
    {
        # if the reference is stored in a different file ask the registry
        $result = $_registry->Resolve( $far, $fid );
	$self->SetLoaded( $ID, $result );
    }
    else
    {
        # if the reference is bound to this file
        my $ref = $self->FETCH_NAIVE( $ID );
    
        # tie to appropriate helper using the 5-argument version of TIE...
        if ( $ref =~ /HASH/ )
              { tie( %$result, 'DWH_File::HashHelper', $result, $self, $ID ) }
        elsif ( $ref =~ /ARRAY/ )
             { tie( @$result, 'DWH_File::ArrayHelper', $result, $self, $ID ) }
        elsif ( $ref =~ /SCALAR/ )
            { tie( $$result, 'DWH_File::ScalarHelper', $result, $self, $ID ) }
    }
    
    return $result;
}

sub SetLoaded
{
    my ( $self, $ID, $ref ) = @_;
    
    $self->{ isloaded }{ $ID } = $ref;
}

sub IncRefCount
{
    my ( $self, $ID ) = @_;
    
    my $rc = $self->FETCH_NAIVE( $ID . '^^R' );
    
    defined $rc or $rc = 0;
    ++$rc;
    
    $self->STORE_NAIVE( $ID . '^^R', $rc );
    
    # remove the ID from garbage check-list if it's there
    delete( $self->{ garbage }->{ $ID } )
        if $self->{ garbage }->{ $ID };
}

sub DecRefCount
{
    my ( $self, $ID ) = @_;
    
    my $rc = $self->FETCH_NAIVE( $ID . '^^R' );
    
    defined $rc or $rc = 0;
    --$rc if $rc > 0;
    
    $self->STORE_NAIVE( $ID . '^^R', $rc );
    
    # take down the reference ID for checking at destruction
    # if the refcount is zero
    $self->{ garbage }->{ $ID } = '1' if $rc <= 0;
}

sub STORE
{
    my ( $self, $key, $value ) = @_;

    defined( $key ) or $key = '';

    # store existence indicator whether or not the value is defined:
    $self->STORE_NAIVE( '^^' . $key, 1 );

    # remove value entry if undefined value
    # this achieves standard behaviour with respect to exists() and undef
    # values in base hash (subhashes also implement standard behaviour):
    # FETCH may return undef though EXISTS returns true
    unless ( defined $value )
    {
	# %-escape any leading special-character (% or ^) in the input key
	my $s = substr $key, 0, 1;
	if ( $s eq '^' or $s eq '%' ) { substr( $key, 0, 0 ) = '%' }

	my $val = $self->FETCH_NAIVE( $key );
	if ( defined( $val ) and substr( $val, 0, 1 ) eq '^' )
	{
	    $self->DecRefCount( $val );
	}
	$self->DELETE_NAIVE( $key );
    }
    else { $self->SUPER::STORE( $key, $value ) }
}

sub FIRSTKEY
{
    my $self = shift;
    
    my $k = $self->{ dbm }->FIRSTKEY;
    defined $k or return undef;

    while ( substr( $k, 0, 2 ) ne '^^' )
    {
	$k = $self->{ dbm }->NEXTKEY( $k );
	defined $k or return undef;
    }

    return substr $k, 2;
}

sub NEXTKEY
{
    my ( $self, $key ) = @_;

    my $k = $self->{ dbm }->NEXTKEY( '^^' . $key );
    defined( $k ) or return undef;

    while ( substr( $k, 0, 2 ) ne '^^' )
    {
	$k = $self->{ dbm }->NEXTKEY( $k );
	defined $k or return undef;
    }

    return substr $k, 2;
}

sub EXISTS
{
    my ( $self, $key ) = @_;

    defined( $key ) or $key = '';

    return defined $self->FETCH_NAIVE( '^^' . $key );
}

sub DELETE_NAIVE
{
    my ( $self, $key ) = @_;

    defined $key or $key = '';

    $self->{ dbm }->DELETE( $key );
    defined( $self->{ logFH } ) or return;
    my @a;
    my $fh = $self->{ logFH };
    my $lines = scalar( @a = split /\n/, $key, -1 );
    print $fh "^$lines\n", "$key\n";
    print $fh "*d\n";

    # logfile format:
    #  ^number-of-newlines-in-key + 1
    #  key...
    #  *d (for delete)
}

sub DELETE
{
    my ( $self, $key ) = @_;

    defined( $key ) or $key = '';

    # remove the existence indicator
    $self->DELETE_NAIVE( '^^' . $key );

    # %-escape any leading special-character (% or ^) in the input key
    my $s = substr $key, 0, 1;
    if ( $s eq '^' or $s eq '%' ) { substr( $key, 0, 0 ) = '%' }

    my $val = $self->FETCH_NAIVE( $key );
    if ( defined $val )
    {
	if ( substr( $val, 0, 1 ) eq '^' )
	{
	    $self->DecRefCount( $val );
	    $val = $self->FETCH( $key );
	}
	else
	{
	    # de-escape any leading special-character in the values
	    substr( $val, 0, 1 ) eq '%' and substr( $val, 0, 1 ) = '';
	}
    }

    $self->DELETE_NAIVE( $key );  

    return $val;
}

sub CLEAR
{
    my $self = shift;

    my $key = $self->FIRSTKEY;

    while ( defined( $key ) )
    {
        $self->DELETE( $key );
        $key = $self->FIRSTKEY;
    }
}

sub ANNIHILATE
{
    my ( $self, $ID ) = @_;

    my $ref = $self->Reference( $ID );
    if ( $ref =~ /HASH/ ) { tied( %$ref )->AnnihilateMe }
    elsif ( $ref =~ /ARRAY/ ) {  tied( @$ref )->AnnihilateMe }
    else { tied( $$ref )->AnnihilateMe }
}

sub Wipe
{
    my $self = shift;

    # Collect garbage
    while ( %{ $self->{ garbage } } ) # annihilate may spawn new garbage
    {
        my @garb = keys( %{ $self->{ garbage } } );
        %{ $self->{ garbage } } = ();
	my $ID;
        foreach $ID ( @garb )
        {
            $self->ANNIHILATE( $ID );
            $self->AddIDPool( $ID );
        }
    }

    # break any circular references and untie helpers
    my ( $key, $ref );
    while ( ( $key, $ref ) = each( %{ $self->{ isloaded } } ) )
    {
	delete $self->{ isloaded }->{ $key };
        if ( $ref =~ /HASH/ ) { untie( %$ref ) }
        elsif ( $ref =~ /ARRAY/ ) { untie( @$ref ) }
        elsif ( $ref =~ /SCALAR/ ) { untie( $$ref ) }
    }
    delete $self->{ master };

    # write back ID pools to disk if necessary
    $self->{ idpoolaltered } and $self->StoreIDPool;

    # close log
    if ( defined $self->{ logFH } )
    {
	$self->{ logFH }->close;
	delete $self->{ logFH };
    }
    # remove locks
    if ( defined $self->{ lock } )
    {
	unlink $self->{ lock };
	delete $self->{ lock };
    }

    # Unregister this instance from the registry
    $_registry->Unregister( $self ) if $self->{ name };
}

sub DESTROY
{
    my $self = shift;
    
    # close log
    if ( defined $self->{ logFH } )
    {
	$self->{ logFH }->close;
	delete $self->{ logFH };
    }
    # remove locks
    if ( defined $self->{ lock } )
    {
	unlink $self->{ lock };
	delete $self->{ lock };
    }
    
}

1;


###########################################################################
# the primary package begins here                                         #
###########################################################################
#
# The purpose of objects of this class is to contain a
# DWH_File::Work object and link to it's methods.
# The motive for not using the Work object as tied object is that
# it makes circular references with it's helpers and thus wouldn't
# be DESTROYed at untie time.
#
package DWH_File;

use strict;
use vars qw( $dbmf $muex $log );
# $dbmf is the DBM package used. Default is 'AnyDBM_File'
# $muex is the locking scheme used for mutual exclusion. Default is 'none'
# $log  is a filename extension to be used for any dbm-activity log.
#       Default is '' (no logging). The value must be one that evaluates
#       to logical true for logging to take place. Whitespace is replaced by
#       underscores.

$DWH_File::VERSION = 0.03;

BEGIN
{
    defined( $dbmf ) or $dbmf = 'AnyDBM_File';
    defined( $muex ) or $muex = 'none';
    defined( $log ) or $log = '';
}

sub import
{
    my $class = shift;
    # set some package level variables
    ( $dbmf, $muex, $log ) = @_;

    unless ( defined( $dbmf ) and $dbmf ) { $dbmf = 'AnyDBM_File' }
    require "$dbmf.pm" or die "Couldn't use $dbmf.pm: $!";

    unless ( defined( $muex ) and $muex ) { $muex = 'none' }

    unless ( defined $log ) { $log = '' }
    else { $log =~ s/\s/_/g }
}

sub eat_log
{
    ${ $_[ 0 ] }->eat_log( $_[ 1 ] );
}

sub TIEHASH
{
    my $class = shift;

    my $worker = DWH_File::Work->TIEHASH( @_ );
    my $self = \$worker;
    bless $self, $class;
    return $self;
}

sub FETCH
{
    ${ $_[ 0 ] }->FETCH( $_[ 1 ] );
}

sub STORE
{
    ${ $_[ 0 ] }->STORE( @_[ 1, 2 ] );
}

sub FIRSTKEY
{
    ${ $_[ 0 ] }->FIRSTKEY;
}

sub NEXTKEY
{
    ${ $_[ 0 ] }->NEXTKEY( $_[ 1 ] );
}

sub EXISTS
{
    ${ $_[ 0 ] }->EXISTS( $_[ 1 ] );
}

sub DELETE
{
    ${ $_[ 0 ] }->DELETE( $_[ 1 ] );
}

sub CLEAR
{
    ${ $_[ 0 ] }->CLEAR;
}

sub DESTROY
{
    ${ $_[ 0 ] }->Wipe;
    ${ $_[ 0 ] } = undef;
}

sub dbm
{
    ${ $_[ 0 ] }->{ dbm }
}

sub dump_pretty
{
    ${ $_[ 0 ] }->dump_pretty;
}

sub Wipe
{
    ${ $_[ 0 ] }->Wipe;
}

1;

__END__

=head1 NAME

DWH_File 0.03 - data and object persistence in deep and wide hashes

=head1 SYNOPSIS

    use DWH_File qw/ GDBM_File standard myLog /;
    # the use arguments set the DBM module used, the file locking scheme
    # and the log files name extension

    tie( %h, DWH_File, 'myFile', O_RDWR|O_CREAT, 0644 );

    tie( %h, DWH_File, 'myFile', O_RDWR|O_CREAT, 0644, 'TAG');

    untie( %h ); # essential!

TAG being the DWH_File ID for the file

=head1 DESCRIPTION

DWH_File is used in a manner resembling NDBM_File, DB_File etc. These
DBM modules are limited to storing flat scalar values. References to data
such as arrays or hashes are stored as useless strings and the data in the
referenced structures will be lost.

DWH_File uses one of the DBM modules (configurable through the parameters
to C<use()>), but extends the functionality to not only save referenced data
structures but even object systems.

This is why I made it. It makes it extremely simple to achieve persistence in
object oriented Perl programs and you can skip the cumbersome interaction with
a conventional database.

See L<MODELS> section below for the various incantations needed to make
objects persistent.

DWH_File tries to make the tied hash behave as much like a standard Perl hash
as possible. Besides the capability to store nested data structures DWH_File
also implements C<exists()>, C<delete()> and C<undef()> functionality like
that of a standard hash (as opposed to all the DBM modules).

=head2 MULTIPLE DBM FILES

It is possible to distribute for instance an object system over several files
if wanted. This might be practical to avoid huge single files and may also
make it easier make a reasonable structure in the data. If this feature is
used the same set of files should be tied each time if any of the contents
that may refer across files is altered. See L<MODELS>.

=head2 GARBAGE COLLECTION

DWH_File uses a garbage collection scheme similar to that of Perl itself.
This means that you actually don't have to worry about freeing anything
(see the circular reference caveat though).
Just like Perl DWH_File will remove entries that nothing is pointing to (and
therefore noone can ever get at). If you've got a key whose value refers to an
array for instance, that array will be swept away if you assign something else
to the key. Unless there's a reference to the array somewhere else in the
structure. This works even across different dbm files when using multiple
files.

The garbage collection housekeeping is performed at untie time - so it is 
mandatory to call untie (and if you keep any references to the tied object
to undef those in advance). Otherwise you'll leave the object at the mercy
of global destruction and garbage won't be properly collected.

=head2 MUTUAL EXCLUSION

Since DWH_File was originally inteded to be used in CGI programming
the file would need to be locked at write time and DWH_File supplies
two ways to do this. Both use links to the file as locks (meaning that
they may not work in non-UNIX environments).

The second parameter in C<use()> (not counting 'DWH_File') will decide
which method is used. The options are none, standard and fork. The
standard method will just go ahead and create links - which is why all
scripts using DWH_File with this option must be setuid. I found this a
bit disturbing so I deviced an alternative method called fork. If this
is chosen DWH_File will fork to run the DWH_Excluder.pl script (which
should reside in the same directory as DWH_File.pm if the fork option
is used). Now only that script needs to be setuid - which I found
somehow comforting.

It is of course possible to enforce the mutual exclusion in other ways
(external to DWH_File). In that case just choose the 'none' option
(default).

=head2 LOGGING

The third parameter in C<use()> (not counting 'DWH_File') sets an
extension (to be added to the name of the dbm files to generate log
file names) for log files. If this is set any editing in hashes tied
to DWH_File is logged. That is - the information is appended to a file
called the name of the dbm file plus the extension.

The point of this feature is to make it possible to have a local
DWH_File based objectsystem to tamper with at home and then be able to
upload the log and get any changes registered at a remote
host. Independently of the dbms used. The eat_log method does the
updating:

    use Fcntl;
    use DWH_File;
    DWH_File->eat_log( "dat.dwh.dbm.log", "dat.dwh.dbm" );
    # first param: logfile to eat, second param: dbm file to eat it

=head2 FURTHER INFORMATION

For further information visit http://aut.dk/orqwood/dwh/ - home of
the DWH_File

=head1 MODELS

=head2 A typical script using DWH_File

    use Fcntl;
    use DWH_File;
    # with no extra parameters to use() DWH_File defaults to:
    # AnyDBM_File, no locking and no logging
    tie( %h, DWH_File, 'myFile.dbm', O_RDWR|O_CREAT, 0644 );
    # ties %h to whatever filename the chosen (in DWH_Config) DBM package
    # converts 'myFile.dwh.dbm' to.
    # DWH_File inserts '.dwh' before the last period in the
    # supplied name.

    # use the hash ... 

    # cleanup
    # (necessary whenever reference values have been tampered with)
    untie %h;

=head2 A script using data in three different files

The data in one file may refer to that in another and even that
reference will be persistent.

    use Fcntl;
    use DWH_File;
    tie( %a, DWH_File, 'fileA', O_RDWR|O_CREAT, 0644, 'HA' );
    tie( %b, DWH_File, 'fileB', O_RDWR|O_CREAT, 0644, 'HB' );
    tie( %c, DWH_File, 'fileC', O_RDWR|O_CREAT, 0644, 'HC' );
    # the last parameter is a name tag on the file - it must be the same
    # every time you tie to that file or DWH will complain. This
    # mechanism frees you to change the filename much as you please.

    # use the hashes ...

    # like in:
    $a{ doo } = [ qw(doo bi dee), { a => "ah", u => "uh" } ];
    $b{ bi } = $a{ doo }[ 3 ];
    # this will work

    print "$b{ bi }{ a }\n";
    # prints "ah";

    $b{ bi }{ a } = "I've changed";
    print "$a{ doo }[ 3 ]{ a }\n"; # prints "I've changed"

    # note that if - in another program - you tie %g to 'fileB'
    # without also having tied some other hash variable to 'fileA')
    # then $g{ bi } will be undefined. The actual data is in 'fileA'.
    # Moreover there will be a high risk of corrupting the data.

    # and so on and so forth ...

    # cleanup
    # (necessary whenever reference values have been tampered with)
    untie %a;
    untie %b;
    untie %c;

=head2 A persistent class

If a class contains the following then an object $obj of that class
which is referenced somewhere in a hash %h (eg. $h{ myobj } = $obj
or $h{ myobs } = [ $obj, "other", "data" ] ) tied to DWH_File will still
be an object of that class next time the program runs.

    package Persis;

    BEGIN
    {
        $iamDWHcapable = "Yes";
        # DWH_File will only play with classes
        # which set this variable to "Yes"
    }

    # that's it - now put in all your own methods (don't forget a
    # constructor) and you're rolling...

In case the module containing the package - against convention - has a
different name from the package (plus .pm) you'll have to tell
DWH_File about it as in:

    package Aix;

    BEGIN
    {
        $iamDWHcapable = "Yes";
        $mymodulename = "Provence"; # omit the .pm as ever
    }

And if you're class needs more action to get moving than just the
restoring of it's state (the data (attributes) in whatever datatype
you blessed in your constructor) you'll have to give DWH_File a
reference to some subrutine to take care of that:

    package Alice;

    BEGIN
    {
	$iamDWHcapable = "Yes";
	$mymodulename = "Wonderland"; # omit the .pm as ever
	$restoresetup = \&WhatINeedToGetBy;
    }

    sub WhatINeedToGetBy
    {
	my $self = shift;

        # Whatever ...  Maybe you want to open some files or pipes or
        # socket connections - how should I know

	# You can call the rutine what you want (might be a good
        # idea to make one that the constructor can use as well)
        # just make sure that $restoresetup points to it (see the
        # below example as well)
    }

Furthermore you may want to entirely alter the way the inner workings of
an object is stored by DWH_File. In that case define $intervene to
point to a subroutine:

    package Mystery;

    BEGIN
    {
        $iamDWHcapable = "Yes";
        $intervene = sub {
	    # In here I get to do the RestoreOriginal operaton
	    # Since I'm a real nerd I may for instance wish to
	    # tie some of the contents to a class of my own in
	    # stead of DWH_File::*Helper...

            # Whether the function references are made as references
            # to anonymous sub as this one or to named subs as the
            # above is of course insignificant
        };
    }

This last feature is rather hairy and should only be used by people
with a perfect understanding of the way DWH_File does it's stuff.

Go to http://aut.dk/orqwood/dwh/ for some examples.

=head1 NOTES

=head2 OTHER PLATFORMS

DWH_File works on UNIX-like systems. It also works without changes on
other platforms if you don't need object persistence. To make it work
with persistent classes on the Macinthosh you'll have to change a few
lines in the TranslatePackage subrutine (see comments in the code).
Similar changes are probably necessary on WinDOS (tell me which and
I'll include them).

The locking methods use the UNIX ability to link more than one
filename to file. This may not be possible on other platforms. You can
either run without mutual exclusion - no problem on a single user
system - or you can make up your own locking scheme suitable to you
platform.

=head2 COMPETITION

It appears that DWH_File does much of the same stuff that the MLDBM
module from CPAN does. There are substantial differences though, which
means that both modules outperform the other in certain
situations. DWH_Files main attractions are (a) it only has to load the
data actually acessed into memory (b) it restores all referential
identity (MLDBM sometimes makes duplicates) (c) it has an approach to
setting up dynamic state elements (like sockets, pipes etc.) of
objects at load time.

=head1 CAVEATS

=over 4

=item REMEMBER UNTIE

It is very important that untie be called at the end of any script
that changes data referenced by the entries in the hash. Otherwise the
file will be corrupted. Also remember to remove any references to the
tied object before untieing.

=item BEWARE OF DBM

Using DWH_File with NDBM_File I found that arrays wouldn't hold more
than a few hundred entries. Assignment seemed to work OK but when
global destruction came along (and the data should be flushed to disk)
a segmentation error occured. It seems to me that this must be a
NDBM_File related bug. I've tried it with DB_File (under linuxPPC) -
100000 entries no problem :-)

I haven't tested DWH_File with other DMB modules than DB_File (under
LinuxPPC) and NDBM_File (in MacPerl and Linux (Pentium)).

At all times be aware of the limitations to data size imposed by the
DBM module you use. See AnyDBM_File(3) for specs of the various DMB
modules.  Also some DBM modules may not be complete (I had trouble
with the EXIST method not existing in NDBM_File in MacPerl).

=item BEWARE OF CIRCULAR REFERENCES

Your data may contain circular references which mean that the
reference count is above zero eventhough the data is unreachable. This
will defeat the DWH_File garbage collection scheme an thus may cause
your file to swell with useless unreachable data.

    # %h being tied to DWH_File $h{ a } = [ qw( foo bar ) ];
    push @{ $h{ a } }, $h{ a };
    # the anonymous array pointed
    # to by $h{ a } now contains a
    # reference to itself
    $h{ a } = "Gone with the wind";
    # so it's refcount will now # be 1 and it won't be garbage
    # collected

To avoid the problem, break the self reference before losing touch:

    # %h being tied to DWH_File
    $h{ a } = [ qw( foo bar ) ];
    push @{ $h{ a } }, $h{ a };
    # now break the reference
    $h{ a }[ 2 ] = '';
                              
    $h{ a } = "Gone with the wind";
    # the anonymous array will be
    # garbage collected at untie time

The problem will be addressed in a future version of DWH_File so you won't
have to think so much.

=item ALWAYS USE THE SAME FILES TOGETHER

If you use a set of hashes tied to a set of files and these hashes contain
references to data in each other you must always tie the same set of
files to hases when editing the content. Otherwise the data in the files
may become corrupted.

=item LIMITATION 1

Data structures saved to disk using DWH_File must not be tied to
any other class. DWH_File needs to internally tie the data to some
helper classes - and Perl does not allow data to be tied to more than
one class at a time. There's a (near) workaround for this which I might
implement one of these day.

=item LIMITATION 2

You're not allowed to assign references to constants in the DWH
structure as in (%h being tied to DWH_File)

    $h{ statementref } = \"I am a donut";
    # won't wash

You can't do an exact equivalent, but you can of course say

    $r = "All men are born equal";
    $h{ statementref } = \$r;

=item LIMITATION 3

Autovivification doen't always work. This may depend on the DBM module
used. I haven't really investigated this problem but it seems that
the problems I have experienced using DB_File arise either from some
quirks in either DB_File or Perl itself.

This means that if you say

    %h = ();
    $h{ a }[ 3 ]{ pie } = "Apple!";

you be sure that the implicit anonymous array and hash "spring into existence"
like they should. You'll have to make them exist first:

    %h = ( a =E<gt> [ undef, undef, undef, {} ] );
    $h{ a }[ 3 ]{ pie } = "Apple!";

Strangely though I have found that often autovivification does actually work
but I can't find the pattern.

I don't plan on trying to fix this right now because it appears to be quite
mysterious and that I can't really do anything about it on DWH_File's side.

=item LIMITATION 4

DWH_File hashes store straight scalars and references (blessed or not)
to scalars, hashes and arrays - in other words: data. File handles and 
subrutine (CODE) references are not stored.


These are the only known limitations. If you encounter any others please
tell me.

=back

=head1 BUGS

Please let me know if you find any.

As the version number (0.03) indicates this is a very early beta state
piece of software. Please contact me if you have any comments or suggestions
- also language corrections or other comments on the documentation.

=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2000.
DWH_File is free software and may be used and distributed under the same
terms as Perl itself.

=head1 AUTHOR(S)

Jakob Schmidt <sumus@aut.dk>

=cut
