=head1 NAME

DBIx::DBO2::Fields - Construct methods for database fields


=head1 SYNOPSIS

  package MyCDs::Disc;
  
  use DBIx::DBO2::Record '-isasubclass';
  
  use DBIx::DBO2::Fields (
    { name => 'id', field_type => 'number', required => 1 },
    { name => 'name', field_type => 'string', length => 64, required => 1 },
    { name => 'year', field_type => 'number' },
    { name => 'artist', field_type => 'number' },
    { name => 'genre', field_type => 'number' },
  );
  
  1;


=head1 DESCRIPTION

This package creates methods for DBIx::DBO2::Record objects.

It's based on Class::MakeMethods::Template.

=head2 Accessing Field Attributes

Calling C<-E<gt>fields()> on a class or instance returns a hash of field-name => field-attribute-hash pairs. 

  my %fields = EBiz::Customer::Account->fields();
  foreach my $fieldname ( sort keys %fields ) {
    my $field = $fields{ $fieldname };
    print "$fieldname is a $field->{meta_type} field\n";
    print "  $fieldname is required\n" if ( $field->{required} );
    print "  $fieldname max length $field->{length}\n" if ( $field->{length} );
  }

You can also pass in a field name to retrieve its attributes.

  print EBiz::Customer::Account->fields('public_id')->{'length'};

The results of C<-E<gt>fields()> includes field information inherited from superclasses. To access only those fields declared within a particular class, call C<-E<gt>class_fields()> instead.

=cut

########################################################################

package DBIx::DBO2::Fields;

use strict;

use Class::MakeMethods::Template;
use base qw( Class::MakeMethods::Template );

use DBIx::SQLEngine::Criteria::Equality;
use DBIx::SQLEngine::Criteria::And;

########################################################################

sub make {
  my $callee = shift;
  if ( ref( $_[0] ) eq 'HASH' ) {
    $callee->SUPER::make( map { $_->{field_type} => $_ } @_ )
  } else {
    $callee->SUPER::make( @_ )    
  }
}

########################################################################

my %ClassInfo;

sub generic {
  {
    '-import' => { 'Template::Hash:generic' => '*' },
    'behavior' => {
      'detect_column_attributes' => q{ 
	  DBIx::DBO2::Fields::_column_autodetect( _SELF_, $m_info, )
			  if ( $m_info->{column_autodetect} );
	},
      -register => sub {
	my $m_info = shift;
	$ClassInfo{$m_info->{target_class}} ||= {};
	my $target_info = $ClassInfo{$m_info->{target_class}};
	$target_info->{ $m_info->{name} } = $m_info;
	push @{ $target_info->{'-order'} }, $m_info;

	# warn "Installing field method: " .join(', ', %$m_info ) ."\n";
	
	if ( my $hooks = $m_info->{'hook'} ) {
	  while ( my ( $method, $code ) = each %$hooks ) {
	    if ( ref($code) eq 'CODE' ) {
	    } elsif ( ! ref($code) ) {
	      my $mname = $code;
	      $mname =~ s/\*/$m_info->{name}/g;
	      $code = sub { (shift)->$mname() };
	    } else {
	      die "Unsurpported Field hook $method => '$code'";
	    }
	    # warn "Installing field hook " . $m_info->{target_class} . "->" . $method . " for $m_info->{name} ($m_info->{method_type}/$m_info->{interface})";
	    $m_info->{target_class}->$method( 
	      Class::MakeMethods::Composite::Inheritable->Hook( $code )
	    )
	  }
	}
	
	return (
	  'class_fields' => sub { 
	    my $self = shift;
	    ( scalar(@_) == 0 ) ? map { $_->{name}, $_ } @{ $target_info->{'-order'} }: 
	    ( scalar(@_) == 1 ) ? $target_info->{$_[0]} : 
				  @{$target_info}{ @_ };
	  },
	  'fields' => sub { 
	    my $self = shift;
	    my @sources = ref($self) || $self;
	    my @results;
	    
	    # Extract field information for all superclasses
	    while ( my $class = shift @sources ) {
	      no strict;
	      push @sources, @{"$class\::ISA"};
	      unshift @results, $class->class_fields() 
					  if ( $class->can('class_fields') );
	    }
	    
	    # Re-definitions in later classes override earlier ones of same name
	    my %results = @results;
	    
	    # But names are added in order defined, from earlier to later
	    my ( @names, %names );
	    while ( scalar @results ) {
	      my ( $name, $info ) = splice( @results, 0, 2 );
	      push @names, $name unless ( $names{ $name } ++ );
	    }
	    
	    foreach my $field ( values %results ) {
	      DBIx::DBO2::Fields::_column_autodetect( $self, $field )
			  if ( $field->{column_autodetect} );
	    }
	    
	    ( scalar(@_) == 0 ) ? 
			(wantarray ? @results{@names} : [@results{@names}] ) : 
	    ( scalar(@_) == 1 ) ? $results{$_[0]} : 
				(wantarray ? @results{ @_ } : [@results{ @_ }] )
	  },
	  'field_columns' => sub { 
	    my $self = shift;
	    my @columns;
	    foreach my $info ( $self->fields ) {
	      my %colinfo = ( 
		name => $info->{hash_key}, 
		type => $info->{column_type}, 
		( $info->{length} ? ( length => $info->{length} ) : () ),
		( $info->{required} ? ( required => $info->{required} ) : () ),
	      );
	      push @columns, \%colinfo if ( $colinfo{type} );
	    }
	    wantarray ? @columns : \@columns;
	  },
	);
      }
    },
  }
}

sub scalar {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'hash_key' => '*',
      'column_autodetect' => [],
    },
    'interface' => {
      default       => { '*'=>'get_set', '*_invalid' => 'invalid' },
      read_only	    => { '*'=>'get' },
      init_and_get  => { '*'=>'get_init', -params=>{init_method=>'init_*'} },
    },
    'code_expr' => { 
      _VALUE_ => '_SELF_->{_STATIC_ATTR_{hash_key}}',
      '-import' => { 'Template::Generic:generic' => '*' },
    },
    'behavior' => {
      'get_set' => q{ 
	  if ( scalar @_ ) {
	    _BEHAVIOR_{set}
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get' => q{ 
	  _GET_VALUE_
	},
      'set' => q{ 
	  _SET_VALUE_{ $_[0] }
	},
      'get_init' => q{
	  my $init_method = _ATTR_{'init_method'};
	  _SET_VALUE_{ _SELF_->$init_method( @_ ) } unless ( defined _VALUE_ );
	  _GET_VALUE_;
	},
    },
  }
}

sub _look_for_column {
  my ($record, $colname) = @_;
  return unless ( UNIVERSAL::can($record, 'table') );
  my @columns = eval { local $SIG{__DIE__}; $record->table->columns };
  foreach my $column ( @columns ) {
    return $column if ( $column->name eq $colname );
  }
}

sub _column_autodetect {
  my ($record, $field) = @_;

  my @attribs = @{ $field->{column_autodetect} };
  my $autocol;
  while ( scalar @attribs ) {
    my($name, $default) = (shift(@attribs), shift(@attribs));
    if ( ! defined $field->{$name} ) {
      $autocol ||= _look_for_column($record, $field->{hash_key});
      if ( $autocol and $autocol->can($name) ) {
	$field->{$name} = $autocol->$name();
      } else {
	$field->{$name} = defined($default) ? $default : 0;
      }
    }
  }
  delete $field->{column_autodetect};
}

########################################################################

=head1 STRING FIELDS

=head2 Field Type string

Generates methods corresponding to a SQL varchar column.

=head3 Default Interface

The general usage for a string field is:

  use DBIx::DBO2::Fields (
    string => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the value of field x for the given record.

=item *

I<$record>-E<gt>x( I<value> ) 

Sets the value of field x for the given record.

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

Check for any error conditions regarding the current value of field x. See Validation, below.

=back

=head3 Validation

String fields provide basic error-checking for required values or text that is too long to fit into the associated database column.

You may specify the length of the column and whether a field is required in your field declaration:

  use DBIx::DBO2::Fields (
    string => '-required 1 -length 64 x',
    string => '-required 0 -length 255 y',
  );

If you leave the required and length attributes undefined, an attempt will be made to detect them automatically, by checking the database table associated with the current object for a column whose name matches the field's.

  use DBIx::DBO2::Fields (
    string => 'x',
    string => 'y',
  );

  create table xyzzy ( 
    x varchar(64) not null,
    y varchar(255)
  );


=head3 The --init_and_get Interface

The string field also supports the following declaration for values which only need to be calculated once:

  use DBIx::DBO2::Fields (
    string => '--init_and_get x',
  );

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the value of field x for the given record.

If the value of field x is undefined, it first calls an initialization method and stores the result. The default it to call a method named init_x, but you can override this by providing a different value for the init_method attribute.

  use DBIx::DBO2::Fields (
    string => '--init_and_get -init_method find_spot x',
  );

Or equivalently, and perhaps more readably:

  use DBIx::DBO2::Fields (
    string => [ '--init_and_get', x, { init_method => 'find_spot' } ],
  );

=back

=cut

sub string {
  {
    '-import' => { '::DBIx::DBO2::Fields:scalar' => '*' },
    'params' => {
      'length' => undef,
      'required' => undef,
      'column_type' => 'text',
      'column_autodetect' => [ 'required', 0, 'length', 0 ],
    },
    'behavior' => {
      'set' => q{ 
	  Carp::carp "Setting " . _ATTR_{name} . " to object value" 
							if ( ref $_[0] );
	  _SET_VALUE_{ "$_[0]" };
	},
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  my $value = _GET_VALUE_;
	  if ( _ATTR_{required} and ! length( $value ) ) {
	    return _ATTR_{name} => "This field can not be left empty."
	  }
	  if ( my $length = _ATTR_{length} ) {
	    return _ATTR_{name} => "This field can not hold more than " . 
		      "$length characters." if ( length( $value ) > $length );
	  }
	  return;
	},
    },
  }
}


########################################################################

=head2 Field Type binary

Identical to the string type, except that it specifies a binary column_type for the underlying SQL DBMS column, allowing DBIx::SQLEngine to produce a platform-specific data type such as C<blob> or C<bytea>.

=cut

sub binary {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'params' => {
      'length' => 65536,
      'column_type' => 'binary',
    },
  }
}

########################################################################

=head1 STRUCTURED TEXT FIELDS

=head2 Field Type phone_number

Identical to the string type except for validation.

=cut

sub phone_number {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'EBiz::Postal::Address',
    },
    'behavior' => {
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  my $value = _GET_VALUE_;
	  if ( _ATTR_{required} and ! length( $value ) ) {
	    return _ATTR_{name} => "This field can not be left empty."
	  }
	  if ( $value ) {
	    my $error_msg = _QUANTITY_CLASS_->invalid_phone($value);
	    $value =~ s/\D+//g;
	    if ( length($value) < 7 ) {
	      return _ATTR_{name} => 'This is to short to be a phone number.' 
	    } elsif ( length($value) < 10 ) {
	      return _ATTR_{name} => 'Please include your area code.';
	    }
	  }
	  if ( my $length = _ATTR_{length} ) {
	    return _ATTR_{name} => "This field can not hold more than " . 
		      "$length characters." if ( length( $value ) > $length );
	  }
	  return;
	},
    },
  }
}

=head2 Field Type post_code

Identical to the string type except for validation.

=cut

sub post_code {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'EBiz::Postal::Address',
    },
    'behavior' => {
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  my $value = _GET_VALUE_;
	  if ( _ATTR_{required} and ! length( $value ) ) {
	    return _ATTR_{name} => "This field can not be left empty."
	  }
	  if ( $value ) {
	    my $error_msg = $self->invalid_postcode($value);
	    return _ATTR_{name} => $error_msg if $error_msg;
	  }
	  if ( my $length = _ATTR_{length} ) {
	    return _ATTR_{name} => "This field can not hold more than " . 
		      "$length characters." if ( length( $value ) > $length );
	  }
	  return;
	},
    },
  }
}

=head2 Field Type state_province

Identical to the string type except for validation.

=cut

sub state_province {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'EBiz::Postal::Address',
    },
    'behavior' => {
      'set' => q{ 
	  Carp::carp "Setting " . _ATTR_{name} . " to canonical value";
	  if ($self->state_object( $_[0] )) {
	    _SET_VALUE_{ $self->state_object( $_[0] )->id };
	  } else {
	    _SET_VALUE_{ $_[0] };
	  }
	},
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  my $value = _GET_VALUE_;
	  if ( _ATTR_{required} and ! length( $value ) ) {
	    return _ATTR_{name} => "This field can not be left empty."
	  }
	  if ( $value ) {
	    my $error_msg = $self->invalid_state($value);
	    return _ATTR_{name} => $error_msg if $error_msg;
	  }
	  if ( my $length = _ATTR_{length} ) {
	    return _ATTR_{name} => "This field can not hold more than " . 
		      "$length characters." if ( length( $value ) > $length );
	  }
	  return;
	},
    },
  }
}

=head2 Field Type email_addr

Identical to the string type except for validation.

=cut

sub email_addr {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'behavior' => {
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  my $value = _GET_VALUE_;

	  if ( _ATTR_{required} and ! length( $value ) ) {
	    return _ATTR_{name} => "This field can not be left empty."
	  }
	  if ( $value ) {
	    my $error_msg = DBIx::DBO2::Fields::invalid_email_address(_GET_VALUE_);
	    return _ATTR_{name} => $error_msg if $error_msg;
	  }
	  return;
      },
    }
  }
}

## Validation

# $boolean = invalid_email_address()
sub invalid_email_address {
  my $email = shift;
  require Net::DNS;
  return 'This does not appear to be a valid e-mail address.'
    unless $email =~ /^([\w\.-]+)\@([\w\.-]+)$/o;
  my($User, $Host) = ($1, $2);
  return 'This does not appear to be a valid e-mail domain.'
    unless ( defined(Net::DNS::mx($Host)) or defined(gethostbyname($Host)) );
  return;
}

########################################################################

=head2 Field Type creditcardnumber

If you declare the following:

  use DBIx::DBO2::Fields (
    creditcardnumber => "ccnum",
  );

You can now use these methods:

  # Set and get raw value
  $customer->ccnum('4242424242424242');
  $customer->ccnum() eq '4242424242424242';

  # Analyze card number
  $customer->ccnum_checksum() == 1;
  $customer->ccnum_flavor() eq 'VISA card';

  # Opaque readable value for display
  $customer->ccnum_readable() eq '************4242';

  # Setting the readable value to the prior opaque value has no effect
  $customer->ccnum_readable('************4242');
  $customer->ccnum() eq '4242424242424242';

  # But setting the readable value to another value overwrites the contents
  $customer->ccnum_readable('1234-5678-9101-1213');
  $customer->ccnum() eq '1234-5678-9101-1213';

  # Recognize bogus cards by the following characteristics...
  $customer->ccnum_checksum() == 0;
  $customer->ccnum_flavor() eq 'Unrecognized';
  $customer->ccnum_readable() eq '1234-5678-9101-1213';

B<DEPENDCIES:> Note that this type of field requires the following modules: Data::Quantity::Finance::CreditCardNumber.

=cut

sub creditcardnumber {
  {
    '-import' => { '::DBIx::DBO2::Fields:number' => '*' },
    'interface' => {
      default	    => { 
	'*'=>'get_set',
	# 'clear_*'=>'clear',
	'*_readable'=>'readable',
	'*_flavor'=>'flavor',
	'*_invalid'=>'invalid',
	'*_checksum'=>'checksum',
      },
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Finance::CreditCardNumber',
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Data::Quantity::Finance::CreditCardNumber;
	  return;
	} ],
      'get' => q{ 
	  my $value = _GET_VALUE_;
	  length($value) ? sprintf( '%.0f', $value ) : undef;
	},
      'set' => q{ 
	  _SET_VALUE_{ _QUANTITY_CLASS_->new( shift() )->value }
	},
      'readable' => q {
	  if ( scalar @_ ) {
	    # warn "in readable, got input";
	    my $value = shift;
	    if ( ! length( $value ) ) {
	      _SET_VALUE_{ undef }
	    } elsif ( $value ne _QUANTITY_CLASS_->readable_value(_GET_VALUE_) ) {
	      # warn "in readable, setting input to '$value' for " . _QUANTITY_CLASS_->readable_value(_GET_VALUE_) . ' aka ' . (_GET_VALUE_ + 0);
	      _SET_VALUE_{ _QUANTITY_CLASS_->new( $value )->value }
	    }
	  } else {
	      # warn "in readable, didn't get input";
	    _QUANTITY_CLASS_->readable_value(_GET_VALUE_)
	  }
	},
      'flavor' => q {
	  _QUANTITY_CLASS_->flavor_value(_GET_VALUE_)
	},
      'checksum' => q {
	  _QUANTITY_CLASS_->checksum_value(_GET_VALUE_)
	},
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  for ( _GET_VALUE_ ) {
	    if ( _ATTR_{required} and ! length( $_ ) ) {
	      return _ATTR_{name} => "This field can not be left empty."
	    }
	    if ( my $length = _ATTR_{length} ) {
	      return _ATTR_{name} => "Number must not be longer than ".
		"$length characters." if ( length( $_ ) > $length );
	    }
	    if ( length $_ ) {
	      return _ATTR_{name} => "This does not appear to be a valid credit card number." unless ( _QUANTITY_CLASS_->checksum_value($_) );
	    }
	  }
	  return;
	},
    },
  }
}

########################################################################

=head1 NUMERIC QUANTITY FIELDS

=head2 Field Type number

Generates methods corresponding to a SQL int or float column.

The general usage for a number field is:

  use DBIx::DBO2::Fields (
    number => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the value of field x for the given record.

=item *

I<$record>-E<gt>x( I<value> ) 

Sets the value of field x for the given record.

=item *

I<$record>-E<gt>x_readable() : I<value>

Returns the value of field x for the given record formatted for display, including commas for thousands separators.

=item *

I<$record>-E<gt>x_readable( I<value> ) 

Sets the value of field x for the given record from a possibly formatted value.

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

Check for any error conditions regarding the current value of field x. See Validation, below.

=back

=head3 Validation

Number fields provide error-checking for required values or values which are not numeric.

You may specify whether a field is required or allow this to be detected based on whether the corresponding database column allows null values.

=head3 The -init_and_get Interface

The number field also supports the -init_and_get provided by the string field type.

B<DEPENDCIES:> Note that this type of field requires the following modules: Data::Quantity::Number::Number.

=cut

sub number {
  {
    '-import' => { '::DBIx::DBO2::Fields:scalar' => '*' },
    'params' => {
      'required' => '0',
      'column_type' => 'int',
      'column_autodetect' => [ 'required', 0, ],
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Number::Number',
    },
    'interface' => {
      default       => { '*'=>'get_set', '*_readable' => 'readable', '*_invalid' => 'invalid' },
      read_only	    => { '*'=>'get' },
      init_and_get  => { '*'=>'get_init', -params=>{init_method=>'init_*'} },
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Data::Quantity::Number::Number;
	  return;
	} ],
      'get' => q{ 
	  for ( _GET_VALUE_ ) { return ( length($_) ? $_ + 0 : $_ ) }
	},
      'set' => q{ 
	  Carp::carp "Setting " . _ATTR_{name} . " to non-numeric value" 
				if ( ref $_[0] or $_[0] =~ /[^\d\-\.]/ );
	  _SET_VALUE_{ length($_[0]) ? $_[0] + 0 : $_[0] };
	},
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  for ( _GET_VALUE_ ) {
	    if ( ref $_[0] or $_[0] =~ /[^\d\-\.]/ ) {
	      return _ATTR_{name} => " can only contain numeric values."
	    }
	    if ( _ATTR_{required} and ! length( $_ ) ) {
	      return _ATTR_{name} => "This field can not be left empty."
	    }
	  }
	  return;
	},
      'readable' => q {
	  if ( scalar @_ ) {
	    _SET_VALUE_{ _QUANTITY_CLASS_->new( @_ )->value }
	  } else {
	    _QUANTITY_CLASS_->readable_value(_GET_VALUE_ + 0)
	  }
	},
    },
  }
}

########################################################################

sub time_absolute {
  {
    '-import' => { '::DBIx::DBO2::Fields:number' => '*' },
    'interface' => {
      default	    => { 
	'*'=>'get_set', 
	'touch_*'=>'set_current', 
	'*_obj'=>'get_obj', 
	'*_readable'=>'readable' 
      },
      created	    => { 
	-base => 'default', 
	-params => {
	  hook => { post_new => 'touch_*' }
	},
      },
      modified	    => { 
	-base => 'default', 
	-params => {
	  hook => { pre_insert => 'touch_*', pre_update => 'touch_*'}
	},
      },
    },
    'params' => {
      'default_readable_format' => undef,
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'croak "Abstract code_expr should contain Quantity"',
    },
    'behavior' => {
      'set_current'	=> q{ 
	_SET_VALUE_{ _QUANTITY_CLASS_->current()->value }; 
	# warn "Setting time for " . _ATTR_{name};
      },
      'set' => q{ 
	  _SET_VALUE_{ _QUANTITY_CLASS_->new( shift() )->value }
	},
      'get_obj'	=> q{ 
	  _QUANTITY_CLASS_->new( _GET_VALUE_ ) 
	},
      'readable' => q{ 
	  _QUANTITY_CLASS_->new(_GET_VALUE_)->readable( 
	      scalar( @_ ) ? shift() : _ATTR_{default_readable_format}
	  )
	},
    },
  }
}

=head2 Field Type timestamp

Generates methods corresponding to a SQL int column storing a date and time in Unix seconds-since-1970 format.

=head3 Default Interface

The general usage for a timestamp field is:

  use DBIx::DBO2::Fields (
    timestamp => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the raw numeric value of field x for the given record.

=item *

I<$record>-E<gt>x( I<value> ) 

I<$record>-E<gt>x( I<readable_value> ) 

Sets the value of field x for the given record. You may provide either a raw numeric value or a human-entered formatted value. 

=item *

I<$record>-E<gt>touch_x() 

Sets the value of field x to the current date and time.

=item *

I<$record>-E<gt>x_readable() : I<readable_value> 

Returns the value of field x formatted for display. 

=item *

I<$record>-E<gt>x_readable(I<format_string>) : I<readable_value> 

Returns the value of field x formatted in particular way. (See L<Data::Quantity::Time::Timestamp> for supported formats.)

=item *

I<$record>-E<gt>x_obj() : I<quantity_object> 

Gets the value of field x as a Data::Quantity::Time::Timestamp object.

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

Inherited from the number field. 

=back

B<DEPENDCIES:> Note that this type of field requires the following modules: Data::Quantity::Time::Timestamp.

=cut


sub timestamp {
  {
    '-import' => { '::DBIx::DBO2::Fields:time_absolute' => '*' },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Time::Timestamp',
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Data::Quantity::Time::Timestamp;
	  return;
	} ],
    },
  }
}


=head2 Field Type julian_day

Generates methods corresponding to a SQL int column storing a date in the Julian days-since-the-invention-of-fire format.

=head3 Default Interface

The general usage for a julian_day field is:

  use DBIx::DBO2::Fields (
    julian_day => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the raw numeric value of field x for the given record.

=item *

I<$record>-E<gt>x( I<value> ) 

I<$record>-E<gt>x( I<readable_value> ) 

Sets the value of field x for the given record. You may provide either a raw numeric value or a human-entered formatted value. 

=item *

I<$record>-E<gt>touch_x() 

Sets the value of field x to the current date.

=item *

I<$record>-E<gt>x_readable() : I<readable_value> 

Returns the value of field x formatted for display. 

=item *

I<$record>-E<gt>x_readable(I<format_string>) : I<readable_value> 

Returns the value of field x formatted in particular way. (See L<Data::Quantity::Time::Date> for supported formats.)

=item *

I<$record>-E<gt>x_obj() : I<quantity_object> 

Gets the value of field x as a Data::Quantity::Time::Date object.

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

Inherited from the number field. 

=back

B<DEPENDCIES:> Note that this type of field requires the following modules: Data::Quantity::Time::Date.

=cut

sub julian_day {
  {
    '-import' => { '::DBIx::DBO2::Fields:time_absolute' => '*' },
    'params' => {
      'default_readable_format' => 'mm/dd/yyyy',
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Time::Date',
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Data::Quantity::Time::Date;
	  return;
	} ],
    },
  }
}

########################################################################


=head2 Field Type currency_uspennies

Generates methods corresponding to a SQL int column storing a US currency value in pennies.

=head3 Default Interface

The general usage for a currency_uspennies field is:

  use DBIx::DBO2::Fields (
    currency_uspennies => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<value>

Returns the raw numeric value of field x for the given record.

=item *

I<$record>-E<gt>x( I<value> ) 

Sets the raw numeric value of field x for the given record.

=item *

I<$record>-E<gt>x_readable() : I<readable_value> 

Returns the value of field x formatted for display. 

=item *

I<$record>-E<gt>x_readable(I<readable_value>) 

Set the value of x based on a human-entered value

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

Inherited from the number field. 

=back

B<DEPENDCIES:> Note that this type of field requires the following modules: Data::Quantity::Finance::Currency.

=cut

sub currency_uspennies {
  {
    '-import' => { '::DBIx::DBO2::Fields:number' => '*' },
    'interface' => {
      default	    => { '*'=>'get_set', '*_readable'=>'readable' },
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Finance::Currency->type("USD")',
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Data::Quantity::Finance::Currency;
	  return;
	} ],
      'set' => q{ 
	  _SET_VALUE_{ _QUANTITY_CLASS_->new( shift() )->value }
	},
      'readable' => q {
	  if ( scalar @_ ) {
	    my $value = shift;
	    if ( ! length( $value ) ) {
	      _SET_VALUE_{ undef }	      
	    } else {
	      # Stick $ on front if not there already, so Q::C knows it's not raw
	      # warn "INPUT VALUE $value";
	      $value = '$' . $value if ( $value =~ m/\A\-?\d/ );
	      # warn "VALUE $value CLASS VALUE " . _QUANTITY_CLASS_->new( $value )->value;
	      _SET_VALUE_{ _QUANTITY_CLASS_->new( $value )->value }
	    }
	  } else {
	    _QUANTITY_CLASS_->readable_value(_GET_VALUE_)
	  }
	},
    },
  }
}

########################################################################

=head2 Field Type saved_total

Used to store numeric values which only have to be calculated when the related records change.

A declaration of

  use DBIx::DBO2::Fields (
    saved_total => 'x',
    reset_checker => 'status_is_cart',
  );

Is equivalent to the following method definitions:

  # Recalculate if status_is_cart; else return previously stored value
  sub x { 
    my $self = shift; 
    if ( $self->status_is_cart() ) {
      $self->{x} = $self->init_x();
    } else {
      $self->{x};
    }
  }
  
  # Recalculate and store the value.
  sub reset_x { 
    my $self = shift; 
    $self->{x} = $self->init_x();
  }
  
  # Is our stored value out of synch with current calculations?
  sub x_difference { 
    my $self = shift; 
    $self->init_x() - $self->{x};
  }

You are expected to provide an 'init_x' method which calculates and returns the value, but does not save it.

=cut

sub saved_total {
  {
    '-import' => { '::DBIx::DBO2::Fields:number' => '*' },
    'interface' => {
      default	    => { 
	'*'       => 'get_or_init_or_set', 
	'reset_*' => 'reset', 
	'*_difference' => 'difference', 
      },
    },
    'params' => {
      'hash_key' => '*',
      'reset_checker' => '',
      'init_method' => 'init_*',
    },
    'code_expr' => {
    },
    'behavior' => {
      'get_or_init' => q{
	my $check_method = _ATTR_{reset_checker};
	my $value = _GET_VALUE_;
	if ( ! length $value or $check_method and $self->$check_method() ) {
	  _BEHAVIOR_{reset}
	} else {
	  $value;
	}
      },
      'get_or_init_or_set' => q{
  	if ( scalar @_ ) { 
	    _BEHAVIOR_{set}
	} else {
	  my $check_method = _ATTR_{reset_checker};
	  my $value = _GET_VALUE_;
	  if ( ! length $value or $check_method and $self->$check_method() ) {
	    _BEHAVIOR_{reset}
	  } else {
	    $value;
	  }
	}
      },
      'reset' => q{
	my $init_method = _ATTR_{init_method};
	_SET_VALUE_{ $self->$init_method() };
      },
      'difference' => q{
	my $init_method = _ATTR_{init_method};
	$self->$init_method() - _GET_VALUE_;
      },
    },
  }
}

=head2 Field Type saved_total_uspennies

Like saved_total, but also has a read-only *_readable method that provides US Currency formatting.

=cut

sub saved_total_uspennies {
  {
    '-import' => { '::DBIx::DBO2::Fields:saved_total' => '*' },
    'interface' => {
      default	    => { 
	'*'       => 'get_or_init_or_set', 
	'set_*' => 'set', 
	'reset_*' => 'reset', 
	'*_difference' => 'difference', 
	'*_readable' => 'readable',
      },
    },
    'params' => {
      'hash_key' => '*',
      'reset_checker' => '',
      'init_method' => 'init_*',
    },
    'code_expr' => {
      _QUANTITY_CLASS_ => 'Data::Quantity::Finance::Currency->type("USD")',
    },
    'behavior' => {
      'set' => q{
	_SET_VALUE_{ _QUANTITY_CLASS_->new( @_ )->value }
      },
      'reset' => q{
	my $init_method = _ATTR_{init_method};
	_SET_VALUE_{ int( $self->$init_method() ) };
      },
      'difference' => q{
	my $init_method = _ATTR_{init_method};
	$self->$init_method() - _GET_VALUE_;
      },
      'readable' => q{
	my $check_method = _ATTR_{reset_checker};
	my $value = _GET_VALUE_;
	if ( ! length $value or $check_method and $self->$check_method() ) {
	  _BEHAVIOR_{reset}
	  $value = _GET_VALUE_;
	} else {
	  $value;
	}
	_QUANTITY_CLASS_->readable_value( $value )
      },
    },
  }
}

########################################################################

=head1 ID AND RELATIONAL FIELDS

=head2 Field Type sequential

Represents an auto-incrementing or database-assigned sequential value that forms the primarily for a table. 

It is expected that you'll only have one of these per class.

=cut

sub sequential {
  {
    '-import' => { '::DBIx::DBO2::Fields:number' => '*' },
    'params' => {
      'column_type' => 'sequential',
      'required' => 1,
    }
  }
}


=head2 Field Type unique_code

Used to generate and store a unique code for this object.

The identifiers generally look like 'QX3P6N' or the like -- a mix of the digits from 0 to 9 and upper case consonants (skipping the vowels to avoid confusion between 0/O and 1/I, and to avoid constructing real words). The size is controlled by the "length" meta-method attribute.

Here's a sample declaration:

  package Acme::Order::Order;
  use DBIx::DBO2::Fields ( 
      "unique_code --length 6 => 'public_id',
  );

This field is automatically assigned and confirmed to be unique when the record is inserted.

Here's how you retrieve a specific row:

  my $pubid = 'QX3P6N';
  $order = Acme::Order::Order->fetch_public_id( $pubid );

With 31 possible characters, a length of 2 gives almost a thousand chocies, 4 gives almost a million, 6 gives almost a billion, and 8 gives 852 billion, or almost a trillion possible choices.

Note that you'll want to have many more choices than you are actually going to use, both to avoid conflicts and to prevent guessing.

B<DEPENDCIES:> Note that if you use the "dated" parameter, this type of field requires the following module: Time::JulianDay.

=cut

sub unique_code {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'params' => {
      length => 6,
      # chars => [ grep { 'AEIOU' !~ /$_/ } ( 'A'..'Z') ],
      chars => [ (0 .. 9), grep { 'AEIOU' !~ /$_/ } ( 'A'..'Z') ],
      date_chars => [ grep { 'AEIOU' !~ /$_/ } ( 'A'..'Z') ],
      hook => { pre_insert=>'assign_*' },
      prohibited => '^\\d+$',
    },
    'interface' => {
      default	    => { '*'=>'get_set', 'assign_*'=>'assign', 
			  'generate_*'=>'generate', 'fetch_*'=>'fetch' },
    },
    'behavior' => {
      assign => q{
  	return if ( _GET_VALUE_ );
	my $generator = 'generate_' . _STATIC_ATTR_{name};
	my $fetcher = 'fetch_' . _STATIC_ATTR_{name};
	do {
	  _SET_VALUE_{ $self->$generator() };
        } while ( 
	  $self->table->count_rows({ _STATIC_ATTR_{hash_key} => _GET_VALUE_ }) 
	);
      },
      generate => q{
	my $char = _STATIC_ATTR_{chars};
	my $date_char = _STATIC_ATTR_{date_chars};
	my $dated = _STATIC_ATTR_{dated} || 0;
	my $length = _STATIC_ATTR_{length};
	$length -= 4 if ( $dated );
	my $prohibited_rx = _STATIC_ATTR_{prohibited};
	if ( $length < 1 ) { 
	  Carp::confess("Unable to generate unique_code: field length is misisng or insufficient")
	}
	my $code;
	do { 
	  $code = '';
	  if ( $dated ) {
	    require Time::JulianDay;
	    my $today = Time::JulianDay::local_julian_day(time);
	    my $incr = $today - $dated;
	    my $charcnt = scalar(@$date_char);
	    while ( $incr > 0 ) {
	      use integer;
	      my $diff = $incr % $charcnt;
	      $incr = int( $incr / $charcnt );
	      $code = $date_char->[ $diff ] . $code;
	    }
	    if ( my $length = length($code) and length($code) < 3 ) {
	      $code = ( $date_char->[0] x ( 3 - $length ) ) . $code;
	    }
	    if ( length($code) ) {
	      $code .= '-';
	    }
	  }
	  foreach  (1 .. $length ) {
	    $code .= $char->[ rand( scalar(@$char) ) ];
	  }
	  # Don't generate all-numeric codes
	} until ( $code and ! $prohibited_rx or $code !~ /$prohibited_rx/ );
	return $code;
      },
      fetch => q{
	my $value = shift() 
	  or return;
	$self->fetch_one(criteria => { _STATIC_ATTR_{hash_key} => $value });
      },
    },
  }
}

########################################################################

=head2 Field Type foreign_key

Generates methods corresponding to a SQL int or varchar column storing a value which corresponds to the primary key of a related record from another table.

=head3 Default Interface

The general usage for a foreign_key field is:

  use DBIx::DBO2::Fields (
    foreign_key => 'x',
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x_id() : I<value>

Returns the raw numeric value of field x_id for the given record.

=item *

I<$record>-E<gt>x_id( I<value> ) 

Sets the raw numeric value of field x_id for the given record.

=item *

I<$record>-E<gt>x() : I<related_object>

Fetches and returns the related record. 

If the x_id value is empty, or if there is not a record with the corresponding value in the related table, returns undef.

=item *

I<$record>-E<gt>x( I<related_object> ) 

Sets the raw numeric value of field x_id based on the corresponding field in the related object.

=item *

I<$record>-E<gt>x_required() : I<related_object>

Fetches and returns the related record, in a case where your code depends on it existing, generally because it calls additional methods without checking the result. 

If the x_id value is empty, or if there is not a record with the corresponding value in the related table, croaks with a fatal exception. This makes it easier to spot the problem then Perl's generic "can't call method on undefined value" message.

=item *

I<$record>-E<gt>x_invalid() : I<fieldname> => I<error_message>, ...

If the field is marked required (or the underlying column is defined as not null), reports an error for missing values. 

If a value is provided, attempts to fetch the associated record and reports an error if can not be found.

=back

=head3 Attributes

=over 4

=item *

hash_key - defaults to *_id

=item *

related_class

=item *

related_id_method

=back

=head3 Example

  package EBiz::Order::Order;
  use DBIx::DBO2::Fields ( 
      foreign_key => { name=>'account',  related_class => 'Account' },
  );
  ...
  $order->account_id( 27 );
  print $order->required_account->email();

=cut

sub foreign_key {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'hash_key' => '*_id',
      'related_class' => undef,
      'related_id_method' => 'id',
      'column_type' => 'int',
      'column_autodetect' => [ 'required', 0, ],
    },
    'interface' => {
      default	    => { 
	'*_id'=>'id', 
	'*'=>'obj', 
	'*_parse_text'=>'parse_text',
	'required_*'=>'req_obj', 
	'*_readable' => 'readable', 
	'*_invalid' => 'invalid' 
      },
    },
    'code_expr' => {
    },
    'behavior' => {
      'id' => q{ 
	  if ( scalar @_ ) {
	    _SET_VALUE_{ shift() }
	  } else {
	    _GET_VALUE_
	  }
	},
      'readable' => q{
	  my $related = _ATTR_REQUIRED_{related_class};
	  my $value = _GET_VALUE_ or return;
	  my $id_method = _ATTR_REQUIRED_{related_id_method};
	  my $foreign = $related->fetch_one(criteria => { $id_method=>$value })
	    or croak "Couldn't find related _STATIC_ATTR_{name} record based on $id_method '$value'";
	  if ( my $display_method = _ATTR_{related_display_method} ) {
	    $foreign->$display_method();
	  } else {
	    $related =~ s{.*::}{}g;
	    "$related ID #$value"
	  }
	},
      'req_obj' => q{
	  my $related = _ATTR_REQUIRED_{related_class};
	  my $value = _GET_VALUE_
	    or croak "No _STATIC_ATTR_{name} foreign key ID for " . ref($self) . " ID '$self->{id}'";
	  my $id_method = _ATTR_REQUIRED_{related_id_method};
	  $related->fetch_one(criteria => { $id_method => $value })
	    or croak "Couldn't find related _STATIC_ATTR_{name} record based on $id_method '$value'";
	},
      'obj' => q{ 
	  my $related = _ATTR_REQUIRED_{related_class};
	  
	  if ( scalar @_ ) {
	    my $obj = shift();
	    UNIVERSAL::isa($obj, $related) 
		or Carp::croak "Inappropriate object type for " . _ATTR_{name} . ": '$obj' should be a $related";
	    my $id_method = _ATTR_REQUIRED_{related_id_method};
	    my $id = $obj->$id_method()
		or Carp::croak "Can't store reference to unsaved record";
	    _SET_VALUE_{ $id }
	  } else {
	    my $value = _GET_VALUE_
	      or return undef;
	    my $id_method = _ATTR_REQUIRED_{related_id_method};
	    $related->fetch_one(criteria => { $id_method => $value })
	  }
	},
      'invalid' => q{ 
	  _BEHAVIOR_{detect_column_attributes}
	  for ( _GET_VALUE_ ) {
	    if ( _ATTR_{required} and ! length( $_ ) ) {
	      return _ATTR_{name} => "This field can not be left empty."
	    }
	    if ( length( $_ ) ) {
	      my $related = _ATTR_REQUIRED_{related_class};
	      my $id_method = _ATTR_REQUIRED_{related_id_method};
	      $related->fetch_one(criteria => { $id_method => $_ })
		or return _ATTR_{name} => "This field can not be left empty."
	    }
	  }
	  return;
	},
      'parse_text' => q{ 
	  my $related = _ATTR_REQUIRED_{related_class};

	  my $text = shift;
	  
	  my $id_method = _ATTR_REQUIRED_{related_id_method};
	  my $display_method = _ATTR_{related_display_method};

	  my $display_field = 'name';
	  if ( ! $text ) {
	    _SET_VALUE_{ undef }

	  } elsif ( my $match = ! $display_method ? undef : $related->fetch_records( criteria => { $display_field => $text } )->record(0) ) {
	    _SET_VALUE_{ $match->$id_method() }

	  } elsif ( $match = $related->fetch_records( criteria => { $id_method => uc($text) } )->record(0) ) {
	    _SET_VALUE_{ $match->$id_method() }

	  } elsif ( $match = $related->fetch_records( criteria => [ 'synonyms like ?', "% $text %" ] )->record(0) ) {
	    _SET_VALUE_{ $match->$id_method() }

	  } else {
	    _SET_VALUE_{ undef }
	  }
	},
      '-subs' => sub {
	  my $m_info = shift();
	  my $name = $m_info->{'name'};
	  
	  my $forward = $m_info->{'delegate'}; 
	  my @forward = ! defined $forward ? ()
					: ref($forward) eq 'ARRAY' ? @$forward 
						  : split ' ', $forward;
	  
	  my $access = $m_info->{'accessors'}; 
	  my @access = ! defined $access ? ()
					: ref($access) eq 'ARRAY' ? @$access 
						    : split ' ', $access;
	  
	  map({ 
	    my $fwd = $_; 
	    $fwd, sub { 
	      my $obj = (shift)->$name() 
		or Carp::croak("Can't forward $fwd because $name is empty");
	      $obj->$fwd(@_) 
	    } 
	  } @forward ),
	  map({ 
	    my $acc = $_; 
	    "$name\_$acc", sub { 
	      my $obj = (shift)->$name() 
		or return;
	      $obj->$acc(@_) 
	    }
	  } @access ),
	},
    },
  }
}

########################################################################

=head2 Field Type line_items

Generates methods to retrieve records from another table which have a foreign_key relationship to the current record. Depends on there being a primary key column, but does not require a separate database column of its own.

=head3 Default Interface

The general usage for a line_items field is:

  package Y;
  use DBIx::DBO2::Fields (
    line_items => { name=>'x', 'related_field'=>'y_id', related_class=>'X' },
  );

This declaration will generate methods to support the following interface:

=over 4

=item *

I<$record>-E<gt>x() : I<related_objects>

Fetches the related records. Returns a RecordSet.

=item *

I<$record>-E<gt>x( I<rel_col> => I<rel_value>, ...) : I<related_objects>

Fetches a subset of the related records which also meet the indicated criteria. Returns a RecordSet.

=item *

I<$record>-E<gt>count_x() 

Returns the number or related records.

=item *

I<$record>-E<gt>new_x() : I<related_object>

Creates and returns a new related record, setting its foreign key field to refer to our record's ID. 

(Note that the record is created but not inserted; you need to call -E<gt>save() yourself.)

=item *

I<$record>-E<gt>delete_x()

Deletes B<all> of the related records. 

=back

You can also specify an array-ref value for the default_criteria attribute; if present, it is treated as a list of fieldname/value pairs to be passed to the fetch and new methods of the related class.


=head3 restrict_delete Interface

Identical to the default interface except as follows: an ok_delete hook is installed to check for the existance of any related records, in which case the deletion is cancelled. This prevents you from deleting the "parent" record for a number of related records.

=head3 cascade_delete Interface

Identical to the default interface except as follows: a post_delete hook is installed to delete all of the related records after the parent record is deleted.

=head3 nullify_delete Interface

Identical to the default interface except as follows: a post_delete hook is installed to change all of the related records to have a default value.

=cut

sub line_items {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'id_method' => 'id',
      'related_class' => undef,
      'related_field' => undef,
      'default_criteria' => undef,
      'default_order' => 'id',
    },
    'interface' => {
      default	    => { 
	'*'=>'fetch', 
	'count_*'=>'count', 
	'new_*'=>'new', 
	'delete_*'=>'delete',
      },
      restrict_delete => { 
	-base => 'default', 
	'check_for_*'=>'check_count', 
	-params => {
	  hook => { ok_delete => 'check_for_*' }
	},
      },
      nullify_on_delete  => { 
	-base => 'default', 
	'nullify_*'=>'nullify', 
	-params => {
	  delete_default => undef,
	  hook => { post_delete => 'nullify_*' }
	},
      },
      cascade_delete  => { 
	-base => 'default', 
	-params => {
	  hook => { post_delete => 'delete_*' }
	},
      },
    },
    'behavior' => {
      'fetch' => q{
	  my $related = _ATTR_REQUIRED_{related_class};

	  my %params = @_;
	  
	  my $r_field = _ATTR_REQUIRED_{related_field};
	  my $id_method = _ATTR_REQUIRED_{id_method};
	  my $d_crit = _ATTR_{default_criteria};
	  $d_crit = { @$d_crit } if ( ref($d_crit) eq 'ARRAY' );
	  my $id = $self->$id_method()
		or return DBIx::DBO2::RecordSet->new();
	  my $criteria = DBIx::SQLEngine::Criteria->auto_and(
	      DBIx::SQLEngine::Criteria::Equality->new($r_field=>$id),
	      ( $d_crit || () ), 
	      ( $params{criteria} ? $params{criteria} : () ),
	  );
	  $params{criteria} = $criteria;
	  if ( my $default_order = _ATTR_{default_order} ) {
	    $params{order} ||= $default_order
	  }
	  $related->fetch_records(%params);
	},
      'count' => q{
	  my $related = _ATTR_REQUIRED_{related_class};

	  my %params = @_;
	  
	  my $r_field = _ATTR_REQUIRED_{related_field};
	  my $id_method = _ATTR_REQUIRED_{id_method};
	  my $d_crit = _ATTR_{default_criteria};
	  $d_crit = { @$d_crit } if ( ref($d_crit) eq 'ARRAY' );
	  my $id = $self->$id_method()
		or return 0;
	  # warn "Counting from " . $related->table->name;
	  my $criteria = DBIx::SQLEngine::Criteria->auto_and(
	      DBIx::SQLEngine::Criteria::Equality ->new($r_field=>$id),
	      ( $d_crit || () ), 
	      ( $params{criteria} ? $params{criteria} : () ),
	  );
	  delete $params{criteria};
	  $related->table->count_rows($criteria);
 	},
      'delete' => q{
	  my $fetch_method = _STATIC_ATTR_{name};
	  foreach my $item ( $self->$fetch_method(@_)->records ) {
	    $item->delete_record();
	  }
 	},
      'nullify' => q{
	  my $fetch_method = _STATIC_ATTR_{name};
	  my $r_field = _ATTR_REQUIRED_{related_field};
	  my $default = _ATTR_{delete_default};
	  foreach my $item ( $self->$fetch_method(@_)->records ) {
	    $item->$r_field( $default );
	  }
 	},
      'check_count' => q{
	  my $count_method = "count_" . _STATIC_ATTR_{name};
	  my $count = $self->$count_method();
	  # warn "Checking count $count_method: $count";
	  return $count ? 0 : 1;
 	},
      'new' => q{
	  my $related = _ATTR_REQUIRED_{related_class};
	  
	  my $r_field = _ATTR_REQUIRED_{related_field};
	  my $id_method = _ATTR_REQUIRED_{id_method};
	  my $d_crit = _ATTR_{default_criteria};
	  $related->new( $r_field=>$self->$id_method(), ((ref($d_crit) eq 'ARRAY' ) ? @$d_crit : ()), @_ );
	},
    },
  }
}

########################################################################

=head1 FIELDS WITH AUTOMATIC BEHAVIOR

=head2 Field Type subclass_name

  use DBIx::DBO2::Fields ( subclass_name => 'type' );

This field type allows you to have different records in the same table be handled as various subclasses of some common Record type.

  package MyClass;
  use DBIx::DBO2::Fields ( 
    subclass_name => 'type',
    string => 'name',
  );

  package MyClass::Subber;

  sub foo { ... }
  
  package main;
  
  my $obj = MyClass->new;
  $obj->type('Subber');             # Rebless to subclass
  $obj->foo;                        # New methods available
  $obj->save_record;                # Subclass name stored in text field
  ...
  my $obj = MyClass->fetch_one(...);
  print $obj->type;                 # Type is remembed after fetch,
  $obj->foo if $obj->can('foo')     # and objects are auto-reblessed.

=cut

sub subclass_name {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'interface' => {
      default => { 
	'*'=>'get_set', 
	'*_pack' => 'pack', 
	'*_unpack' => 'unpack' 
      },
    },
    'params' => {
      hook => { post_fetch=>'*_unpack', post_new=>'*_pack', pre_insert=>'*_pack', pre_update=>'*_pack' }
    },
    'behavior' => {
      'get' => q{
	  my $type = ref( $self ) ? _GET_VALUE_ : 
	    Class::MakeMethods::Template::ClassName::_pack_subclass
			( _ATTR_{target_class}, $self );
	  defined( $type ) ?  $type : '';
	},
      'set' => q{ 
	  my $type = shift;
	  my $subclass = 
		Class::MakeMethods::Template::ClassName::_unpack_subclass( 
				_ATTR_{target_class}, $type );
	# my $class = Class::MakeMethods::Template::ClassName::_provide_class( 
	#      _ATTR_{target_class}, $subclass );
	  my $class = Class::MakeMethods::Template::ClassName::_require_class( 
	      $subclass );
	  
	  if ( ref _SELF_ ) {
	    _SET_VALUE_{ $type };
	    bless $self, $class;
	  }
	  return $class;
	},
      'pack' => q{ 
	  my $class = ref( $self ) or Carp::confess "Not a class method";
	  my $type = Class::MakeMethods::Template::ClassName::_pack_subclass
			( _ATTR_{target_class}, $class );
	  _SET_VALUE_{ $type };
	},
      'unpack' => q{ 
	  my $type = _GET_VALUE_;
	  my $subclass = Class::MakeMethods::Template::ClassName::_unpack_subclass( 
				_ATTR_{target_class}, $type );
	# my $class = Class::MakeMethods::Template::ClassName::_provide_class( 
	#      _ATTR_{target_class}, $subclass );
	  my $class = Class::MakeMethods::Template::ClassName::_require_class( 
	      $subclass );
	  
	  if ( ref _SELF_ ) {
	    bless $self, $class;
	  }
	  return $class;
	},
    },
  }
}

########################################################################

=head2 Field Type stringified_hash

  use DBIx::DBO2::Fields ( stringified_hash => 'data' );

This field type allows you to manipulate a simple hash of key-value pairs for each record, which is automatically converted to and from a stringified form in the database. Don't store nested data structures in the values.

A reference to the hash structure is stored in the record using the field name as the hash key, but this is not saved in the database. The text version of the data is packed into and unpacked outof a string stored under the hash key "packed_I<name>", using the string2hash and hash2string functions from String::Escape.

  package MyClass;
  use DBIx::DBO2::Record '-isasubclass';
  use DBIx::DBO2::Fields ( 
    stringified_hash => 'data',
    ...
  );

  package main;
  my $obj = MyClass->new;
  $obj->data( 'key' => $non_ref_value );
  print $obj->data('key');
  %info = $obj->data();
  $obj->save_record;
  ...
  
  my $obj = MyClass->fetch_one(...);
  print $obj->data('key');

B<DEPENDCIES:> Note that this type of field requires the following modules: String::Escape.

=cut

sub stringified_hash {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'interface' => {
      default => { 
	'packed_*'=>'get_set', 
	'*_pack' => 'pack', 
	'*_unpack' => 'unpack', 
	'*_readable'=>'readable',
      },
    },
    'params' => {
      hash_key => 'packed_*',
      hook => { 
	post_fetch => '*_unpack',
	pre_insert => '*_pack',
	pre_update => '*_pack',
      },
    },
    'behavior' => {
      '-init' => [ sub { 
	  require String::Escape;
	  return;
	} ],
      '-subs' => sub {
	my $m_info = shift;
	Class::MakeMethods::Standard::Hash->make(
	  -TargetClass => $m_info->{target_class},
	  'hash' => [ $m_info->{name} => { auto_init => 1 } ],
	)
      },
      'pack' => q{ 
	  my $struct_method = _ATTR_{name};
	  my %hash = $self->{$struct_method} ? %{$self->{$struct_method}} : ();
	  _SET_VALUE_{ ( ! scalar keys %hash ) ? '' :  
	    ' ' . String::Escape::hash2string(
	      map { $_ => $hash{ $_ } } sort keys %hash
	    ) . ' ' 
	  };
	},
      'unpack' => q{ 
	  my $struct_method = _ATTR_{name};
	  my $string = _GET_VALUE_;
	  $string =~ s/\A\s+|\s+\Z//g;
	  $self->$struct_method( length($string) ? String::Escape::string2hash( $string ) : {} );
	},
      'readable' => q{
	  _GET_VALUE_
	},
    },
  }
}

########################################################################

=head2 Field Type storable_hash

  use DBIx::DBO2::Fields ( storable_hash => 'data' );

This field type allows you to manipulate a hash structure for each record, which is automatically converted to and from a stringified form in the database. You can store nested data structures in the values.

A reference to the hash structure is stored in the record using the field name as the hash key, but this is not saved in the database. The text version of the data is packed into and unpacked outof a string stored under the hash key "packed_I<name>", using the Storable module.

  package MyClass;
  use DBIx::DBO2::Record '-isasubclass';
  use DBIx::DBO2::Fields ( 
    storable_hash => 'data',
    ...
  );

  package main;
  my $obj = MyClass->new;
  $obj->data( 'key' => [ 1, 2, 3 ] );
  print $obj->data('key');
  %info = $obj->data();
  $obj->save_record;
  ...
  
  my $obj = MyClass->fetch_one(...);
  print $obj->data('key');

B<DEPENDCIES:> Note that this type of field requires the following modules: Storable, MIME::Base64, Data::Dumper.

=cut

sub storable_hash {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'interface' => {
      default => { 
	'packed_*'=>'get_set', 
	'*_pack' => 'pack', 
	'*_unpack' => 'unpack',
	'*_readable'=>'readable',
      },
    },
    'params' => {
      hash_key => 'packed_*',
      hook => { 
	post_fetch => '*_unpack',
	pre_insert => '*_pack',
	pre_update => '*_pack',
      },
    },
    'behavior' => {
      '-init' => [ sub { 
	  require Storable;
	  require MIME::Base64;
	  require Data::Dumper;
	  return;
	} ],
      '-subs' => sub {
	my $m_info = shift;
	Class::MakeMethods::Standard::Hash->make(
	  -TargetClass => $m_info->{target_class},
	  'hash' => $m_info->{name},
	)
      },
      'pack' => q{ 
	  my $struct_method = _ATTR_{name};
	  my %hash = $self->{$struct_method} ? %{$self->{$struct_method}} : ();
	  _SET_VALUE_{ ! scalar(keys %hash) ? '' : 
		MIME::Base64::encode_base64( Storable::nfreeze \%hash ) }
	},
      'unpack' => q{ 
	  my $struct_method = _ATTR_{name};
	  my $string = _GET_VALUE_;
	  if ( length($string) and $string !~ m{^BQ} ) {
	    warn "Skipping mangled storable_hash $struct_method for $self $self->{id}";
	    return;
	  }
	  # warn "About to unpack storable_hash $struct_method for $self $self->{id}";
	  $self->$struct_method( length($string) ? 
	    Storable::thaw( MIME::Base64::decode_base64( $string ) ) : {} 
	  );
	},
      'readable' => q{
	  my $struct_method = _ATTR_{name};
	  my %hash = $self->$struct_method();
	  my $string = Data::Dumper->Dump( [\%hash], [ $struct_method ] );
	  $string =~ s/^\$$struct_method\s\=\s\{(.*)\}\;$/$1/s;
	  $string;
	},
    },
  }
}

########################################################################

=head2 runnable_code

A text field which is expected to contain syntactically valid Perl code.

Provides an additional helper method that executes that code, by caching it as a subroutine reference.

Optional parameters:

=over 4

=item sub_hash_key 

Name of hash key under which to store a cached subroutine. Defaults to '*_sub'.

=item sub_template

Outline for subroutine. 

=item pass_self_arg

Boolean. Determines whether a reference to the object is to be passed as an argument to the subroutine.

=back

=cut

sub runnable_code {
  {
    '-import' => { '::DBIx::DBO2::Fields:string' => '*' },
    'interface' => {
      default => { 
	'*' => 'get_set', 
	'run_*'=>'run', 
      },
    },
    'params' => {
      sub_hash_key => '*_sub',
      sub_template => q{ sub { 
	__CODE__ 
      } },
      pass_self_arg => 0,
    },
    'code_expr' => {
      _CACHED_SUB_ => '_SELF_->{ _ATTR_{sub_hash_key} }',
    },
    'behavior' => {
      'set' => q{ 
	  undef _CACHED_SUB_;
	  _SET_VALUE_{ $_[0] };
	},
      'run' => q{
	unless ( _CACHED_SUB_ ) {
	  my $code = _ATTR_{sub_template};
	  $code =~ s{\_\_CODE\_\_}{_GET_VALUE_}g;
	  local $SIG{__DIE__};
	  _CACHED_SUB_ = eval $code or
	    die "Can't eval ".(_ATTR_{name})." code: ".(_GET_VALUE_)."\n$@";
	}
	unshift @_, _SELF_ if ( _ATTR_{pass_self_arg} );
	&{_CACHED_SUB_}( @_ );
      },
    },
  }
}

########################################################################

=head1 WRAPPER FIELDS

These methods provide a field-ish interface to behavior provided by other Perl methods; they are computed on the fly, and do not correspond to SQL columns.

=head2 Field Type alias

  use DBIx::DBO2::Fields (
    alias => [ 'x', { target=>'subject' } ],
  );

This declares a method -E<gt>x() that simply calls method -E<gt>y() and passes along all of its arguments.

B<Note:> This method does not store a value, and does not correspond to an SQL column.

=cut

sub alias {
   {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'interface' => { 
      default => 'alias',
      'alias' => 'alias' 
    },
    'params' => { 'method_name' => '*' },
    'behavior' => {
      'alias' => sub { my $m_info = $_[0]; sub {
        my $target = $m_info->{'target'};
        (shift)->$target(@_) 
      }},
    },
  }
}

########################################################################

=head2 Field Type delegate

Local alias for the Universal:forward_methods method generator.

Creates a method which delegates to an object provided by another method. 

B<Note:> This method does not store a value, and does not correspond to an SQL column.

Example:

  use DBIx::DBO2::Fields
    delegate => [ 
	[ 'w' ], { target=> 'whistle' }, 
	[ 'x', 'y' ], { target=> 'xylophone' }, 
	{ name=>'z', target=>'zither', target_args=>[123], method_name=>do_zed },
      ];

Example: The above defines that method C<w> will be handled by the
calling C<w> on the object returned by C<whistle>, whilst methods C<x>
and C<y> will be handled by xylophone, and method C<z> will be handled
by calling C<do_zed> on the object returned by calling C<zither(123)>.

B<Attributes>: The following additional attributes are supported:

=over 4

=item target

I<Required>. The name of the method that will provide the object that will handle the operation.

=item target_args

Optional ref to an array of arguments to be passed to the target method.

=item method_name

The name of the method to call on the handling object. Defaults to the name of the meta-method being created.

=back

=cut

sub delegate { 'Universal:forward_methods' }

########################################################################

=head2 Field Type calculated_string

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_string {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'interface' => {
      default	    => { },
    },
    'params' => {
      calc_sub => undef,
    },
    'behavior' => {
      '-subs' => sub {
	  my $m_info = shift();
	  my $name = $m_info->{'name'};
	  ( $m_info->{calc_sub} ) ? ( $name => $m_info->{calc_sub} ) : ();
	},
    },
  }
}


########################################################################

=head2 Field Type calculated_quantity

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_quantity {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'interface' => {
      default	    => { '*_readable'=>'readable' },
    },
    'params' => {
      quantity_class => undef,
      calc_sub => undef,
    },
    'behavior' => {
      '-init' => [ sub {
	  my $m_info = shift();
	  my $qclass = $m_info->{quantity_class};
	  $qclass =~ s{::}{/}g;
	  require "$qclass.pm";
	  return;
	} ],
      'readable' => q{
	  my $method = _ATTR_{name};
	  my $qclass = _ATTR_{quantity_class};
	  $qclass->readable_value(_SELF_->$method())
	},
      '-subs' => sub {
	  my $m_info = shift();
	  my $name = $m_info->{'name'};
	  ( $m_info->{calc_sub} ) ? ( $name => $m_info->{calc_sub} ) : ();
	},
    },
  }
}


########################################################################

=head2 Field Type calculated_uspennies

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_uspennies {
  {
    '-import' => { '::DBIx::DBO2::Fields:calculated_quantity' => '*' },
    'params' => {
      quantity_class => 'Data::Quantity::Finance::Currency::USD',
    },
  }
}

########################################################################

=head2 Field Type calculated_timestamp

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_timestamp {
  {
    '-import' => { '::DBIx::DBO2::Fields:calculated_quantity' => '*' },
    'params' => {
      quantity_class => 'Data::Quantity::Time::Timestamp',
    },
  }
}

########################################################################

=head2 Field Type calculated_duration

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_duration {
  {
    '-import' => { '::DBIx::DBO2::Fields:calculated_quantity' => '*' },
    'params' => {
      quantity_class => 'Data::Quantity::Time::DurationSeconds',
    },
  }
}

########################################################################

=head2 Field Type calculated_line_items

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub calculated_line_items {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'interface' => {
      default	    => { },
    },
    'behavior' => {
      '-subs' => sub {
	  my $m_info = shift();
	  my $name = $m_info->{'name'};
	  ( $m_info->{calc_sub} ) ? ( $name => $m_info->{calc_sub} ) : ();
	},
    },
  }
}

########################################################################

=head2 Field Type filtered_line_items

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub filtered_line_items {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'line_items_method' => undef,
      'criteria' => undef,
      'related_class' => undef,
      'related_field' => undef,
    },
    'interface' => {
      default	    => { 
	'*'=>'fetch', 
	'count_*'=>'count', 
      },
    },
    'behavior' => {
      'fetch' => q{
	  my $base_method = _ATTR_{line_items_method};
	  _SELF_->$base_method( criteria => _ATTR_{criteria} );
	},
      'count' => q{
	  my $base_method = 'count_' . _ATTR_{line_items_method};
	  _SELF_->$base_method( criteria => _ATTR_{criteria} );
 	},
    },
  }
}

########################################################################

=head2 Field Type dynamic_select

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub dynamic_select {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'related_class' => undef,
      'default_criteria' => undef,
      'default_order' => undef,
      'clauses_sub' => undef,
    },
    'interface' => {
      default	    => { 
	'*'=>'fetch', 
	'count_*'=>'count', 
      },
    },
    'behavior' => {
      'fetch' => q{
	  my $clauses_sub = _ATTR_{clauses_sub};
	  my @clauses = $clauses_sub ? &$clauses_sub( _SELF_ ) : ();
	  my %clauses = ( $#clauses == 0 ) ? (criteria => @clauses) : @clauses;
	  foreach ( qw( criteria order ) ) {
	    $clauses{$_} ||= _ATTR_{"default_$_"} if ( _ATTR_{"default_$_"} );
	  }
	  my $related_class = _ATTR_REQUIRED_{related_class};
	  $related_class->fetch_records( %clauses );
	},
      'count' => q{
	  my $clauses_sub = _ATTR_{clauses_sub};
	  my @clauses = $clauses_sub ? &$clauses_sub( _SELF_ ) : ();
	  my %clauses = ( $#clauses == 0 ) ? (criteria => @clauses) : @clauses;
	  foreach ( qw( criteria order ) ) {
	    $clauses{$_} ||= _ATTR_{"default_$_"} if ( _ATTR_{"default_$_"} );
	  }
	  my $related_class = _ATTR_REQUIRED_{related_class};
	  $related_class->table->count_rows( $clauses{criteria} );
 	},
    },
  }
}

########################################################################

=head2 Field Type dynamic_fetch

B<To Do:> Documentation for this field type has not been written yet.

=cut

sub dynamic_fetch {
  {
    '-import' => { '::DBIx::DBO2::Fields:generic' => '*' },
    'params' => {
      'related_class' => undef,
      'default_criteria' => undef,
      'default_order' => undef,
      'default_limit' => 1,
      'clauses_sub' => undef,
      'related_id_method' => 'id',
    },
    'interface' => {
      default	    => { 
	'*'=>'fetch', 
	'*_readable'=>'readable',
      },
    },
    'behavior' => {
      'fetch' => q{
	  my $clauses_sub = _ATTR_{clauses_sub};
	  my @clauses = $clauses_sub ? &$clauses_sub( _SELF_ ) : ();
	  my %clauses = ( $#clauses == 0 ) ? (criteria => @clauses) : @clauses;
	  foreach ( qw( criteria order limit ) ) {
	    $clauses{$_} ||= _ATTR_{"default_$_"} if ( _ATTR_{"default_$_"} );
	  }
	  my $related_class = _ATTR_REQUIRED_{related_class};
	  $related_class->fetch_one( %clauses );
	},
      'readable' => q{
	  my $fetch_method = _ATTR_REQUIRED_{name};
	  my $foreign = _SELF_->$fetch_method() or return;
	  if ( my $display_method = _ATTR_{related_display_method} ) {
	    $foreign->$display_method();
	  } else {
	    my $related_class = _ATTR_REQUIRED_{related_class};
	    $related_class =~ s{.*::}{}g;
	    my $id_method = _ATTR_REQUIRED_{related_id_method};
	    "$related_class ID #" . $foreign->$id_method();
	  }
	},
      '-subs' => sub {
	  my $m_info = shift();
	  my $name = $m_info->{'name'};
	  
	  my $forward = $m_info->{'delegate'}; 
	  my @forward = ! defined $forward ? ()
					: ref($forward) eq 'ARRAY' ? @$forward 
						  : split ' ', $forward;
	  
	  my $access = $m_info->{'accessors'}; 
	  my @access = ! defined $access ? ()
					: ref($access) eq 'ARRAY' ? @$access 
						    : split ' ', $access;
	  
	  map({ 
	    my $fwd = $_; 
	    $fwd, sub { 
	      my $obj = (shift)->$name() 
		or Carp::croak("Can't forward $fwd because $name is empty");
	      $obj->$fwd(@_) 
	    } 
	  } @forward ),
	  map({ 
	    my $acc = $_; 
	    "$name\_$acc", sub { 
	      my $obj = (shift)->$name() 
		or return;
	      $obj->$acc(@_) 
	    }
	  } @access ),
	},
    },
  }
}

########################################################################

=head1 TO DO

=over 4 

=item *

Resolve differing approaches to setting values from human-entered formatted values. Current interface is:

=over 4 

=item - 

julian_day: I<$record>-E<gt>x( I<readable_value> ) 

=item - 

timestamp: I<$record>-E<gt>x( I<readable_value> ) 

=item - 

currency_uspennies: I<$record>-E<gt>x_readable(I<readable_value>) 

=item - 

creditcardnumber: I<$record>-E<gt>x_readable(I<readable_value>) 

=back

=back


=head1 SEE ALSO

See L<DBIx::DBO2> for an overview of this framework.

=cut

########################################################################

1;
