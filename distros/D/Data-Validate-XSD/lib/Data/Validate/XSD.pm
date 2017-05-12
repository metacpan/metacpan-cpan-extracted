package Data::Validate::XSD;

use strict;

=head1 NAME

Data::Validate::XSD - Validate complex structures by definition

=head1 SYNOPSIS

  use Data::Validate::XSD;

  my $validator = Data::Validate::XSD->new( \%definition );

  $errors = $validator->validate( \%data );

  warn Dumper($errors) if $errors;

=head1 DESCRIPTION
  
  Based on xsd and xml validation, this is an attempt to provide those functions
  without either xml or the hidous errors given out by modules like XPath.

  The idea behind the error reporting is that the errors can reflect the structure
  of the original structure replacing each variable with an error code and message.
  It is possible to work out a one dimention error reporting scheme too which I may
  work on next.

=head1 INVITATION

  If you find an example where the W3C definitions and this module differ then
  please email the author and a new version with fixes can be released.

  If you find there is a certain type that your always using then let me know
  I can consider adding the type to the default set and make the module more useful.

=head1 EXAMPLES

=head2 Definitions

  A definition is a hash containing information like an xml node containing children.

  An example definition for registering a user on a website:


$def = {
    root => [
      { name => 'input', type => 'newuser' },
      { name => 'foo',   type => 'string'  },
    ],

    simpleTypes => [
      confirm  => { base => 'id',   match => '/input/password' },
      rname    => { base => 'name', minLength => 1 },
      password => { base => 'id',   minLength => 6 },
    ],

    complexTypes => {
      newuser => [
        { name => 'username',     type => 'token'                                 },
        { name => 'password',     type => 'password'                              },
        { name => 'confirm',      type => 'confirm'                               },
        { name => 'firstName',    type => 'rname'                                 },
        { name => 'familyName',   type => 'name',  minOccurs => 0                 },
        { name => 'nickName',     type => 'name',  minOccurs => 0                 },
        { name => 'emailAddress', type => 'email', minOccurs => 1, maxOccurs => 3 },
    [
      { name => 'aim',    type => 'index'  },
      { name => 'msn',    type => 'email'  },
      { name => 'jabber', type => 'email'  },
      { name => 'irc',    type => 'string' },
    ]
      ],
    },
};


=head2 Data

And this is an example of the data that would validate against it:


$data = {
    input => {
      username     => 'abcdef',
      password     => '1234567',
      confirm      => '1234567',
      firstName    => 'test',
      familyName   => 'user',
      nickName     => 'foobar',
      emailAddress => [ 'foo@bar.com', 'some@other.or', 'great@nice.con' ],
      msn          => 'foo@msn.com',
    },
    foo => 'extra content',
};


We are asking for a username, a password typed twice, some real names, a nick name,
between 1 and 3 email addresses and at least one instant message account, foo is an
extra string of information to show that the level is arbitary. bellow the definition
and all options are explained.

=head2 Results

The first result you get is a structure the second is a boolean, the boolean explains the total stuctures pass or fail status.

The structure that is returned is almost a mirror structure of the input:

$errors = {
    input => {
       username     => 0,
       password     => 0,
       confirm      => 0,
       firstName    => 0,
       familyName   => 0,
       nickName     => 0,
       emailAddress => 0,
    }
},

=head1 DETAILED DEFINITION

=head2 Definition Root

  root         - The very first level of all structures, it should contain the first
                 level complex type (see below). The data by default is a hash since
                 all xml have at least one level of xml tags names.

  import       - A list of file names, local to perl that should be loaded to include
                 further and shared simple and complex types. Supported formats are
                 "perl code", xml and yml.

  simpleTypes  - A hash reference containing each simple definition which tests a
                 scalar type (see below for format of each definition)
                

  complexTypes - A hash reference containing each complex definition which tests a
                 structure (see below for definition).


=head2 Simple Types

  A simple type is a definition which will validate data directly, it will never validate
  arrays, hashes or any future wacky structural types. In perl parlance it will only validate
  SCALAR types. These options should match the w3c simple types definition:

  base           - The name of another simple type to first test the value against.
  fixed          - The value should match this exactly.
  pattern        - Should be a regular expresion reference which matchs the value i.e qr/\w/
  minLength      - The minimum length of a string value.
  maxLength      - The maximum length of a string value.
  match          - An XPath link to another data node it should match.
  notMatch       - An XPath link to another data node it should NOT match.
  enumeration    - An array reference of possible values of which value should be one.
  custom         - Should contain a CODE reference which will be called upon to validate the value.
  minInclusive   - The minimum value of a number value inclusive, i.e greater than or eq to (>=).
  maxInclusive   - The maximum value of a number value inclusive, i.e less than of eq to (<=).
  minExclusive   - The minimum value of a number value exlusive, i.e more than (>).
  maxExclusive   - The maximum value of a number value exlusive, i.e less than (<).
  fractionDigits - The maximum number of digits on a fractional number.

=head2 Complex Types

  A complex type is a definition which will validate a hash reference, the very first structure,
  'root' is a complex definition and follows the same syntax as all complex types. each complex
  type is a list of data which should all occur in the hash, when a list entry is a hash; it
  equates to one named entry in the hash data and has the following options:

  name      - Required name of the entry in the hash data.
  minOccurs - The minimum number of the named that this data should have in it.
  maxOccurs - The maximum number of the named that this data should have in it.
  type      - The type definition which validates the contents of the data.

  Where the list entry is an array, it will toggle the combine mode and allow further list entries
  With in it; this allows for parts of the sturcture to be optional only if different parts of the
  stucture exist.

=head1 INBUILT TYPES

  By default these types are available to all definitions as base types.

    string           - /^.*$/
    integer          - /^[\-]{0,1}\d+$/
    index            - /^\d+$/
    double           - /^[0-9\-\.]*$/
    token            - /^\w+$/
    boolean          - /^1|0|true|false$/
    email            - /^.+@.+\..+$/
    date             - /^\d\d\d\d-\d\d-\d\d$/ + datetime
    'time'           - /^\d\d:\d\d$/ + datetime
    datetime         - /^(\d\d\d\d-\d\d-\d\d)?[T ]?(\d\d:\d\d)?$/ + valid_date method
    percentage       - minInclusive == 0 + maxInclusive == 100 + double

=cut

use Carp;
use Scalar::Util qw/looks_like_number/;
use Date::Parse qw/str2time/;
our $VERSION = "1.05";

# Error codes
my $NOERROR             = 0x00;
my $INVALID_TYPE        = 0x01;
my $INVALID_PATTERN     = 0x02;
my $INVALID_MINLENGTH   = 0x03;
my $INVALID_MAXLENGTH   = 0x04;
my $INVALID_MATCH       = 0x05;
my $INVALID_VALUE       = 0x06;
my $INVALID_NODE        = 0x07;
my $INVALID_ENUMERATION = 0x08;
my $INVALID_MIN_RANGE   = 0x09;
my $INVALID_MAX_RANGE   = 0x0A;
my $INVALID_NUMBER      = 0x0B;
my $INVALID_COMPLEX     = 0x0C;
my $INVALID_EXIST       = 0x0D;
my $INVALID_MIN_OCCURS  = 0x0E;
my $INVALID_MAX_OCCURS  = 0x0F;
my $INVALID_CUSTOM      = 0x10;
my $CRITICAL            = 0x11;

my @errors = (
  0,
  'Invalid Node Type',
  'Invalid Pattern: Regex Pattern failed',
  'Invalid MinLength: Not enough nodes present',
  'Invalid MaxLength: Too many nodes present',
  'Invalid Match: Node to Node match failed',
  'Invalid Value, Fixed string did not match',
  'Invalid Node: Required data does not exist for this node',
  'Invalid Enum: Data not equal to any values supplied',
  'Invalid Number: Less than allowable range',
  'Invalid Number: Greater than allowable range',
  'Invalid Number: Data is not a real number',
  'Invalid Complex Type: Failed to validate Complex Type',
  'Invalid Exists: Data didn\'t exist, and should.',
  'Invalid Occurs: Minium number of occurances not met',
  'Invalid Occurs: Maxium number of occurances exceeded',
  'Invalid Custom Filter: Method returned false',
  'Critical Problem:',
);

my %complex_types = ();

my %simple_types = (
    string     => { pattern => qr/.*/ },
    integer    => { pattern => qr/[\-]{0,1}\d+/ },
    'index'    => { pattern => qr/\d+/ },
    double     => { pattern => qr/[0-9\-\.]*/ },
    token      => { base    => 'string', pattern => qr/\w+/ },
    boolean    => { pattern => qr/1|0|true|false/ },
    email      => { pattern => qr/.+@.+\..+/ },
    date       => { pattern => qr/\d\d\d\d-\d\d-\d\d/, base => 'datetime' },
    'time'     => { pattern => qr/\d\d:\d\d/,          base => 'datetime' },
    datetime   => { pattern => qr/(\d\d\d\d-\d\d-\d\d)?[T ]?(\d\d:\d\d)?/, custom => sub { _test_datetime(@_) } },
    percentage => { base => 'double', minInclusive => 0, maxInclusive => 100 },
  );

=head1 METHODS

=head2 $class->new( $definition )

 Create a new validation object, debug will cause
 All error codes to be replaced by error strings.

=cut
sub new {
  my ($class, $definition) = @_;

  my $self = bless { strict => 1 }, $class;

  $self->setDefinition( $definition );

  return $self;
}

=head2 $class->newFromFile( $path, $filename, $debug )

  Create a new definition from a dumped perl file.

=cut
sub newFromFile {
  my ($class, $filename, @a) = @_;

  if(-f $filename) {
    my $definition = $class->_load_file( $filename, 1 );
    return $class->new( $definition, @a );
  }
  croak("Validation Error: Could not find Validate Configuration '$filename'");
}

=head2 I<$validator>->validate( $data )

  Validate a set of data against this validator.
  Returns an $errors structure or 0 if there were no errors.

=cut
sub validate {
  my ($self, $data) = @_;
  my $def = $self->{'definition'};

  if(defined($def->{'root'}) and defined($data)) {
    return $self->_validate_elements( definition => $def->{'root'}, data => $data );
  } else {
    croak("VAL Error: No root document definition") if not defined($def->{'root'});
    croak("VAL Error: No data provided")            if not defined($data);
  }
}

=head2 I<$validator>->validateFile( $filename )

  Validate a file against this validator.

=cut
sub validateFile {
  my ($self, $filename, @a) = @_;

  if(-f $filename) {
    my $data = $self->_load_file( $filename );
    return $self->validate( $data, @a );
  }
  croak("Validation Error: Could not find data to validate: '$filename'");
  
}

=head2 I<$validator>->setStrict( $bool )

  Should missing data be considered an error.

=cut
sub setStrict {
  my ($self, $bool) = @_;
  $self->{'strict'} = $bool;
}

=head2 I<$validator>->setDefinition( $definition )

  Set the validators definition, will load it (used internally too)

=cut
sub setDefinition {
  my ($self, $definition) = @_;
  $self->{'definition'} = $self->_load_definition( $definition );
}

=head2 I<$validator>->getErrorString( $error_code )

  Return a human readable string for each error code.

=cut
sub getErrorString {
  my ($self, $e) = @_;
  if($e>0 and $e<=$#errors) {
    return $errors[$e];
  }
  return 'Invalid error code';
}

=head1 INTERNAL METHODS

  Only read on if you are interesting in knowing some extra stuff about
  the internals of this module.

=head2 I<$validator>->_load_definition( $definition )

  Internal method for loading a definition into the validator

=cut
sub _load_definition
{
  my ($self, $definition) = @_;

  $definition->{'simpleTypes'} = { %simple_types, %{$definition->{'simpleTypes'} || {}} };
  $definition->{'complexTypes'} = { %complex_types, %{$definition->{'complexTypes'} || {}} };

  if(defined($definition->{'include'})) {
    if(ref($definition->{'include'}) eq "ARRAY") {
      foreach my $include (@{$definition->{'include'}}) {

        my $def = ref($include) ? $self->_load_definition( $include ) : $self->_load_definition_from_file( $include );
        
        if(defined($def->{'simpleTypes'})) {
          $self->_push_hash($definition->{'simpleTypes'}, $def->{'simpleTypes'});
        }

        if(defined($def->{'complexTypes'})) {
          $self->_push_hash($definition->{'complexTypes'}, $def->{'complexTypes'});
        }
      }
    } else {
      croak("Validator Error: include format needs to be an Array []");
    }
  }
  return $definition;
}

=head2 I<$validator>->_load_definition_from_file( $filename )

  Internal method for loading a definition from a file

=cut
sub _load_definition_from_file {
  my ($self, $filename) = @_;
  my $definition = $self->_load_file( $filename );
  return $self->_load_definition( $definition );
}

=head2 I<$validator>->_validate_elements( %p )

  Internal method for validating a list of elements;
  p: definition, data, mode

=cut
sub _validate_elements
{
  my ($self, %p) = @_;

  my $definition  = $p{'definition'};
  my $data        = $p{'data'};
  my $errors      = {};

  # This should be AND or OR and controls the logic flow of the data varify
  my $mode = $p{'mode'} || 'AND';
  
  if(not UNIVERSAL::isa($definition, 'ARRAY')) {
    croak("definition is not in the correct format: expected array");
  }

  foreach my $element (@{$definition}) {

    # Element data check
    if(UNIVERSAL::isa($element, 'HASH')) {
      
      my $name = $element->{'name'};

      # Skip element if it's not defined
      next if(not $name);

      $element->{'minOccurs'} = 1 if not defined($element->{'minOccurs'});
      $element->{'maxOccurs'} = 1 if not defined($element->{'maxOccurs'});
      $element->{'type'} = 'string' if not defined($element->{'type'});

      my $terrors = $self->_validate_element(
        definition => $element,
        data       => $data->{$name},
        name       => $name,
      );
      
      # Fill Errors with required results.
      $errors->{$name} = $terrors if $terrors;

    } elsif(UNIVERSAL::isa($element, 'ARRAY')) {


      my $subr = {};
      $subr = $self->_validate_elements(
        definition => $element,
        data       => $data,
        mode       => $mode eq 'OR' ? 'AND' : 'OR',
      );

      map { $errors->{$_} = $subr->{$_} } keys(%{$subr}) if $subr and ref($subr);
    } else {
      carp "This is a complex type, but it doesn't look like one: $element";
    }
  }

  if($mode eq 'OR') {
    # Only invalidate parent if all elements have errored
    foreach (%{$errors}) {
      return 0 if not $errors->{$_};
    }
    return $errors;
  }

  return %{$errors} ? $errors : 0;
}

=head2 I<$validator>->_validate_element( %p )

  Internal method for validating a single element
  p: data, definition, mode

=cut
sub _validate_element {
  my ($self, %p) = @_;

  my $definition = $p{'definition'};
  my $data       = $p{'data'};
  my $name       = $p{'name'};

  my @results;
  my $proped = 0;

  if(ref($data) ne "ARRAY" and defined($data)) {
     $proped = 1;
     $data = [$data];
  }

  # minOccurs checking
  if($definition->{'minOccurs'} >= 1) {
    if(defined($data)) {
      if($definition->{'minOccurs'} > @{$data}) {
        return $INVALID_MIN_OCCURS;
      }
    } else {
      return $INVALID_EXIST;
    }
  }

  if(defined($data)) {

    # maxOccurs Checking
    if($definition->{'maxOccurs'} ne 'unbounded') {
      if($definition->{'maxOccurs'} < @{$data}) {
        return $INVALID_MAX_OCCURS;
      }
    }
    
    foreach my $element (@{$data}) {
      # fixed and default checking
      if(defined($definition->{'fixed'})) {
        if(ref($element) ne "" or ($element and $element ne $definition->{'fixed'})) {
          push @results, $INVALID_VALUE;
          next;
        }
      }

      if(defined($definition->{'default'})) {
        $element = $definition->{'default'} if not defined($element);
      }

      my %po;
      foreach ('minLength', 'maxLength') {
        $po{$_} = $definition->{$_} if defined($definition->{$_});
      }

      # Element type checking
      my ($result, $te) = $self->_validate_type(
        type => $definition->{'type'},
        data => $element,
        %po, #Passable Options
      );

      push @results, $result if $result;
    }
  }

  if(@results > 0) {
    return ($proped ? $results[0] : \@results);
  }
  return 0;
}

=head2 I<$validator>->_validate_type( %p )

  Internal method for validating a single data type

=cut
sub _validate_type {
  my ($self, %p) = @_;

  my $data       = delete($p{'data'});
  my $type       = delete($p{'type'});
  my $definition = $self->{'definition'};
  my %pdef       = %p;

  if(defined($definition->{'simpleTypes'}->{$type})) {

    my $typedef = { %{$definition->{'simpleTypes'}->{$type}}, %pdef };

    # Base type check
    if(defined($typedef->{'base'})) {
      my $err = $self->_validate_type(
        type => $typedef->{'base'},
        data => $data,
      );
      return $err if $err;
    }

    # Pattern type check
    if(defined($typedef->{'pattern'}) and ref($typedef->{'pattern'}) eq 'REGEX') {
      if($data !~ $typedef->{'pattern'}) {
        return $INVALID_PATTERN;
      }
    }

  # Custom method check
  if(defined($typedef->{'custom'})) {
    my $method = $typedef->{'custom'};

    if(ref($method) ne 'CODE' or not $method->($data, $typedef)) {
      return $INVALID_CUSTOM;
    }
  }

    # Length checks
    if(defined($typedef->{'maxLength'})) {
      if(length($data) > $typedef->{'maxLength'}) {
        return $INVALID_MAXLENGTH;
      }
    }

    if(defined($typedef->{'minLength'})) {
      if(length($data) < $typedef->{'minLength'}) {
        return $INVALID_MINLENGTH;
      }
    }

    # Match another node
    if(defined($typedef->{'match'}) or defined($typedef->{'notMatch'})) {
      my $path   = $typedef->{'match'} || $typedef->{'notMatch'};
      my $result = $self->_find_value( path => $path, data => $data );
      if( ($data ne $result and $typedef->{'match'})
       or ($data eq $result and $typedef->{'notMatch'})) {
        return $INVALID_MATCH;
      }
    }

    if(defined($typedef->{'enumeration'})) {
      if(ref($typedef->{'enumeration'}) ne 'ARRAY') {
        croak("Validator Error: Enumberation not of the correct type");
      }
      my $found = 0;
      foreach (@{$typedef->{'enumeration'}}) {
        $found = 1 if $_ eq $data;
      }
      return $INVALID_ENUMERATION if not $found;
    }

    if(looks_like_number($data)) {
      return $INVALID_MIN_RANGE if defined($typedef->{'minInclusive'}) and $data < $typedef->{'minInclusive'};
      return $INVALID_MAX_RANGE if defined($typedef->{'maxInclusive'}) and $data > $typedef->{'maxInclusive'};
      return $INVALID_MIN_RANGE if defined($typedef->{'minExclusive'}) and $data <= $typedef->{'minExclusive'};
      return $INVALID_MAX_RANGE if defined($typedef->{'maxExclusive'}) and $data >= $typedef->{'maxExclusive'};

#     return $INVALID_FRACTION if defined($typedef->{'fractionDigits'}) and $data !~ /\.(\d{})$/;

    } elsif(defined($typedef->{'minInclusive'}) or defined($typedef->{'maxInclusive'}) or
      defined($typedef->{'minExclusive'}) or defined($typedef->{'maxExclusive'}) or
      defined($typedef->{'fractionDigits'})) {
      return $INVALID_NUMBER;
    }

  } elsif(defined($definition->{'complexTypes'}->{$type})) {
    my $typedef = $definition->{'complexTypes'}->{$type};
    if(ref($data) eq "HASH") {
      return $self->_validate_elements( definition => $typedef, data => $data );
    } else {
      return $INVALID_COMPLEX;
    }
  } else {
    croak("Validator Error: Can not find type definition '$type'");
    return $CRITICAL;
  }
  
  return $NOERROR;
}

=head2 I<$validator>->_find_value( %p )

  Internal method for finding a value match (basic xpath)

=cut
sub _find_value
{
  my ($self, %p) = @_;
  # Remove root path, and stop localisation
  if($p{'path'} =~ s/^\///){ $p{'data'} = $self->{'data'}; }

  my @paths = split('/', $p{'path'});
  my $data  = $p{'data'};

  foreach my $path (@paths) {
    if(UNIVERSAL::isa($data, 'HASH')) {
      if(defined($data->{$path})) {
        $data = $data->{$path};
      } else {
        carp "Validator Error: Can't find nodes for '$p{'path'}' in _find_value\n" if $self->{'debug'};
      }
    } else {
      carp "Validator Error: Can't find nodes for '$p{'path'}' in _find_value\n" if $self->{'debug'};
    }
  }
  return $data;
}

=head2 I<$validator>->_push_hash( $dest, $source )

  Internal method for copying a hash to another

=cut
sub _push_hash
{
  my($self, $dest, $source) = @_;

  foreach my $key (keys(%{$source})) {
    if(not $dest->{$key}) {
      $dest->{$key} = $source->{$key};
    }
  }
  return $dest;
}

=head2 I<$validator>->_load_file( $file )

  Internal method for loading a file, must be valid perl syntax.
  Yep that's right, be bloody careful when loading from files.

=cut
sub _load_file {
  my ($self, $filename, $def) = @_;
  open( VALIDATE, $filename );
    my $content = join('', <VALIDATE>);
  close( VALIDATE );
  
  my $data;
  if($content =~ /^<\?xml/) {
    # XML File
    eval("use Data::Validate::XSD::ParseXML");
	croak("Did you forget to install XML::SAX? ($@)") if $@;
	my $parser = Data::Validate::XSD::ParseXML->new( $content );
	if($def and $content =~ /XMLSchema/) {
		$data = $parser->definition();
	} else {
		$data = $parser->data();
	}
  } else {
    $data = eval('{ '.$content.' }');
    croak("Validator Error! $@") if $@;
  }
  return $data;
}

=head2 $validate->_test_datetime( $typedef )

  Test a date time range is a valid date.

=cut
sub _test_datetime {
  my ($data, $typedef) = @_;
  if($data) {
    my $epoch = str2time( $data );
    if($epoch) {
      return 1;
    }
  }
  return undef;
}

=head1 KNOWN BUGS

 * XML and YML suport not added yet.
 * Fraction Didgets test doesn't work yet.

=head1 AUTHOR

 Copyright, Martin Owens 2007-2008, Affero General Public License (AGPL)

 http://www.fsf.org/licensing/licenses/agpl-3.0.html

=cut
1;
