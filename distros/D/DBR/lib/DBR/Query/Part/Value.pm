# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Query::Part::Value;

use strict;
use base 'DBR::Common';
use Scalar::Util 'looks_like_number';
use Carp;

#### Constructors ###############################################

sub new{
      my( $package ) = shift;
      my %params = @_;

      my $field = $params{field}; # optional


      my $self = {
		  session => $params{session},
		  field  => $field
		 };

      bless( $self, $package );

      if (defined $field){ #field object is optional
	    ref($field) eq 'DBR::Config::Field' or croak 'invalid field object';
      }

      exists($params{value}) || croak 'value must be specified'; # undef and 0 are both legal, so cannot check for defined or truth
      my $value = $params{value};

      if ( ref($value) eq 'DBR::Util::Operator' ) {
	    my $wrapper = $value;

	    $value   = $wrapper->value;
	    $self->{op_hint} = $wrapper->operator;
      }

      $value = [$value] unless ref($value) eq 'ARRAY';

      if(ref($field) eq 'DBR::Config::Field'){ # No Anon

	    my $trans = $field->translator;
	    if($trans){

		  my @translated;
		  foreach (@$value){
			my @tv = $trans->backward($_);

			# undef is ok... but we Must have at least one element, or we are bailing
			scalar(@tv) or croak 'invalid value ' . (defined($_)?"'$_'":'undef') . ' for field ' . $field->name . ' (translator)';
			push @translated, @tv;
		  }
		  $value = \@translated;
	    }
	    $self->{is_number}  = $field->is_numeric;

	    my $testsub = $field->testsub or confess 'failed to retrieve testsub';

	    foreach (@$value){
		 $testsub->($_) or croak 'invalid value ' . (defined($_)?"'$_'":'undef') . ' for field ' . $field->name;
	    }

      }else{
	    defined($params{is_number}) or croak 'is_number must be specified';

	    $self->{is_number}  = $params{is_number}? 1 : 0;

	    if( $self->{is_number} ){
		  foreach my $val ( @{$value}) {
			$val = '' unless defined $val;
			looks_like_number($val) or croak "value '$val' is not a legal number";
		  }
	    }
      }

      $self->{value}    = $value;

      return $self;

}


1;

## Methods #################################################
sub op_hint  { return $_[0]->{op_hint}               }
sub is_number{ return $_[0]->{is_number}             }
sub count    { return scalar(  @{ $_[0]->{value} } ) }

sub sql {
      my $self = shift;
      my $conn = shift or croak 'conn is required';

      my $sql;

      my $values = $self->quoted($conn);

      if (@$values != 1) {
	    $sql .= '(' . join(',',@{$values}) . ')';
      } elsif(@$values == 1){
	    $sql = $values->[0];
      }

      return $sql;

}

sub is_null{
      my $self = shift;

      return 1 if $self->count == 1 and !defined( $self->{value}->[0] );
      return 0;
}

sub is_emptyset{ $_[0]->count == 0 }

sub quoted{
      my $self = shift;
      my $conn = shift or croak('conn is required');

      if ($self->is_number){
	    return [ map { defined($_)?$_:'NULL' } @{$self->{value}} ];
      }else{
	    return [ map { defined($_)?$_:'NULL' } map { $conn->quote($_) } @{$self->{value}} ];
      }

}

sub raw{ wantarray?@{ $_[0]->{value} } : $_[0]->{value} }

sub _session { $_[0]->{session} }


