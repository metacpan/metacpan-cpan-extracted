package DBR::Config::Trans::Enum;

use strict;
use base 'DBR::Config::Trans';

use Clone qw(clone);
use constant {
	      # Cache Constants
	      x_list  => 0,
	      x_hmap  => 1,
	      x_idmap => 2,

	      # Value Constants
	      v_id     => 0,
	      v_handle => 1,
	      v_name   => 2,
	     };

my %FIELDMAP;

sub moduleload{
      my( $package ) = shift;
      my %params = @_;

      my $self = { session => $params{session} };
      bless( $self, $package ); # Dummy object

      my $instance  = $params{instance}    || return $self->_error('instance is required');

      my $field_ids = $params{field_id} || return $self->_error('field_id is required');
      $field_ids = [$field_ids] unless ref($field_ids) eq 'ARRAY';

      my $dbrh = $instance->connect || return $self->_error("Failed to connect to ${\$instance->name}");

      return $self->_error('Failed to select from enum_map') unless
	my $maps = $dbrh->select(
				 -table => 'enum_map',
				 -fields => 'field_id enum_id sortval',
				 -where  => { field_id => ['d in',@$field_ids] },
				);

      my @enumids = $self->_uniq( map {  $_->{enum_id} } @$maps);

      my $values = [];
      if(@enumids){
	    return $self->_error('Failed to select from enum') unless
	      $values = $dbrh->select(
				      -table => 'enum',
				      -fields => 'enum_id handle name override_id',
				      -where  => { enum_id => ['d in',@enumids ] },
				     );
      }

      my %VALUES_BY_ID;
      foreach my $value (@$values){
	    my $enum_id = $value->{enum_id};
	    my $id = defined($value->{override_id}) ? $value->{override_id} : $enum_id;

	    $VALUES_BY_ID{ $enum_id } = [$id,$value->{handle},$value->{name}]; #
      }

      foreach my $map (sort {( $a->{sortval}||0 ) <=> ( $b->{sortval}||0 ) } @$maps){
	    my $enum_id = $map->{enum_id};
	    my $value = $VALUES_BY_ID{ $enum_id };

	    my $ref = $FIELDMAP{ $map->{field_id} } ||=[];
	    push @{$ref->[ x_list ]}, $value;
	    $ref->[ x_hmap  ]->{ $value->[ v_handle ] } = $value; # Forward
	    $ref->[ x_idmap ]->{ $value->[ v_id     ] } = $value; # Backward

      }

      return 1;
}


sub new { die "Should not get here" }

sub options{
      my $self = shift;

      my $opts = $FIELDMAP{ $self->{field_id} }->[ x_list ];
      return [ map { bless([$_,$self->{field_id}], 'DBR::_ENUM') } @$opts  ];
}

sub forward{
      my $self = shift;
      my $id   = shift;

      if (defined($id)){
	    return bless( [ $FIELDMAP{ $self->{field_id} }->[ x_idmap ]->{ $id }, $self->{field_id} ] , 'DBR::_ENUM');
      }else{
	    # Looks like a null value. return a dummy object
	    return bless( [ ['','',''] , $self->{field_id} ] , 'DBR::_ENUM');
      }
}


sub backward{
      my $self = shift;
      my $value = shift;

      return undef unless defined($value) && length($value);

      if( ref($value) eq 'DBR::_ENUM' ){ # smells like an enum object
	    $value = $value->handle;     # swap it out for the handle, so we can make sure they didn't mix up enum objects
	    return $FIELDMAP{ $self->{field_id} }->[ x_hmap ]->{ $value }->[ v_id ]; # id
      }

      my @out;
      foreach ( $self->_split($value) ){
	    #otherwise hit the lookup
	    my $id =  $FIELDMAP{ $self->{field_id} }->[ x_hmap ]->{ $_ }->[ v_id ];
	    return () unless defined($id);

	    push @out, $id;
      }

      return @out;

}

###############################################################################################################
###############################################################################################################
###############################################################################################################
###############################################################################################################

package DBR::_ENUM;

use constant {
	      # Cache Constants
	      x_list  => 0,
	      x_hmap  => 1,
	      x_idmap => 2,

	      # Value Constants
	      v_id     => 0,
	      v_handle => 1,
	      v_name   => 2,
	     };
use strict;
use Carp;
use overload
# Values
'""' => sub { $_[0]->name },

# Operators
'eq' => sub { $_[0]->handle eq _strhandle($_[1]) },
'ne' => sub { $_[0]->handle ne _strhandle($_[1]) },
'nomethod' => sub {croak "Enum object: Invalid operation '$_[3]' The ways in which you can use an enum are restricted"}
;

*TO_JSON = \&chunk;

sub id     { $_[0][0]->[ v_id     ] }
sub handle { $_[0][0]->[ v_handle ] }
sub name   { $_[0][0]->[ v_name   ] }
sub chunk {return { handle => $_[0]->handle, name => $_[0]->name} }
sub field_id { $_[0][1] }

sub in{
      my $self = shift;

      my $hmap = $FIELDMAP{ $self->field_id }->[ x_hmap ] or die 'Unable to locate field in cache';

      my $id = $self->id;
      my @ids = map {
	    $hmap->{$_}->[ v_id ] or croak "Enum->in: Invalid value $_" 
      }
	map {
	      split(/\s+/,$_)
	} @_;

      map { return 1 if $id eq $_ } @ids;

      return 0;
}

#######################################
#########   Util   ####################
#######################################

sub _strhandle{
      my $val = $_[1] || $_[0]; # can be OO or functional
      return $val->handle if ref($val) eq __PACKAGE__;
      return $val;
}


1;
