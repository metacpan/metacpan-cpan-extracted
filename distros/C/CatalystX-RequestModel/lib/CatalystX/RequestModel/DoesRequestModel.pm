package CatalystX::RequestModel::DoesRequestModel;

use Moo::Role;
use Scalar::Util;
use CatalystX::RequestModel::Utils::BadRequest;

has ctx => (is=>'ro');
has current_namespace => (is=>'ro', predicate=>'has_current_namespace');
has current_parser => (is=>'ro', predicate=>'has_current_parser');
has catalyst_component_name => (is=>'ro');

sub namespace {
  my ($class_or_self, @data) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  if(@data) {
    @data = map { split /\./, $_ } @data;
    CatalystX::RequestModel::_add_metadata($class, 'namespace', @data);
  }

  return $class_or_self->namespace_metadata if $class_or_self->can('namespace_metadata');
}

sub content_in {
  my ($class_or_self, $ct) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  CatalystX::RequestModel::_add_metadata($class, 'content_in', $ct) if $ct;

  if($class_or_self->can('content_in_metadata')) {
    my ($ct) = $class_or_self->content_in_metadata;  # needed because this returns an array but we only want the first one
    return $ct if $ct;
  }
}

sub get_content_in {
  my $self = shift;
  my $ct = $self->content_in;
  return lc($ct) if $ct;
  return 'body';
}

sub content_type {
  my ($class_or_self, @ct) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  CatalystX::RequestModel::_add_metadata($class, 'content_type', @ct) if @ct;

  if($class_or_self->can('content_type_metadata')) {
    my (@ct) = $class_or_self->content_type_metadata;  # needed because this returns an array but we only want the first onei
    return @ct;
  }
}

sub property {
  my ($class_or_self, $attr, $data_proto, $options) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  if(defined $data_proto) {
    my $data = (ref($data_proto)||'') eq 'HASH' ? $data_proto : +{ name => $attr };
    $data->{name} = $attr unless exists($data->{name});
    CatalystX::RequestModel::_add_metadata($class, 'property_data', +{$attr => $data});
  }
}

sub properties {
  my ($class_or_self, @data) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  while(@data) {
    my $attr = shift(@data);
    my $data = (ref($data[0])||'') eq 'HASH' ? shift(@data) : +{ name => $attr };
    $data->{name} = $attr unless exists($data->{name});
    CatalystX::RequestModel::_add_metadata($class, 'property_data', +{$attr => $data});
  }

  return $class_or_self->property_data_metadata if $class_or_self->can('property_data_metadata');
}

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  return bless $args, $class;
}

## TODO handle if we are wrapping a model that already does ACCEPT_CONTEXT
sub ACCEPT_CONTEXT {
  my $self = shift;
  my $c = shift;

  my %args = (%$self, @_);  
  my %request_args = $self->parse_content_body($c, %args);
  my %init_args = (%args, %request_args, ctx=>$c);
  my $class = ref($self);

  return my $request_model = $self->build_request_model($c, $class, %init_args);
}

sub build_request_model {
  my ($self, $c, $class, %init_args) = @_;
  my $request_model = eval {
    $class->new(%init_args)
  } || do { 
    CatalystX::RequestModel::Utils::BadRequest->throw(class=>$class, error_trace=>$@);
  };

  return $request_model;
}

sub parse_content_body {
  my ($self, $c, %args) = @_;

  my @rules = $self->properties;
  my @ns = $self->get_namespace(%args);            
  my $parser_class = $self->get_content_body_parser_class($self->get_content_type($c));  
  my $parser = exists($args{current_parser}) ? 
    $args{current_parser} :
      $parser_class->new(ctx=>$c, request_model=>$self );

  $parser->{context} = $args{context} if exists $args{context}; ## TODO ulgy

  return my %request_args = $parser->parse(\@ns, \@rules);
}

sub get_content_type {
  my ($self, $c) = @_;
  my $ct = $c->req->content_type;
  return 'application/x-www-form-urlencoded' if !$ct && $c->req->method eq 'GET';
  return 'application/x-www-form-urlencoded' if $self->get_content_in eq 'query';
  return $ct;
}

sub get_namespace {
  my ($self, %args) = @_;
  return @{$args{current_namespace}} if exists($args{current_namespace});
  return grep { defined $_ } $self->namespace;
}

sub get_content_body_parser_class {
  my ($self, $content_type) = @_;
  return my $parser_class = CatalystX::RequestModel::content_body_parser_for($content_type);
}

sub get_attribute_value_for {
  my ($self, $attr) = @_;
  die "Can't get attribute value for $attr" unless $self->can($attr);
  return $self->$attr;
}

sub as_data {
  my $self = shift;
  my (@namespace, $spec);

  # separate out the namespace from data spec pattern
  foreach my $arg (@_) {
    if(ref($arg) eq 'ARRAY') {
      $spec = $arg;
    } else {
      push @namespace, $arg;
    }
  }

  # Get property info as a hash
  my %property_info = map { %$_ } $self->properties;

  # if we have a namespace, we need to descend into the data structure
  if(@namespace){
    my $value = $self;
    foreach my $ns (@namespace) {
      $value = $value->$ns;
    }
    $self = $value;
  }

  # loop over the spec and get the data
  my %return;
  foreach my $field_proto (@$spec) {
    my ($field, $sub_spec);
    if(ref($field_proto) eq 'HASH') {
      ($field, $sub_spec) = %$field_proto;
    } else {
      $field = $field_proto;
    }
    if(exists $property_info{$field}) {
      # Its a property, so process correctly
      my $meta = $property_info{$field};
      if(my $predicate = $meta->{attr_predicate}) {
        if($meta->{omit_empty}) {
          next unless $self->$predicate;  # skip empties when omit_empty=>1
        }
      }

      # get the attribute value
      my $value = $self->get_attribute_value_for($field);

      # it can be an array, an object or a plain scalar value
      if( (ref($value)||'') eq 'ARRAY') {
        my @gathered = ();
        foreach my $v (@$value) {
          if(Scalar::Util::blessed($v)) {
            my $params = $v->as_data($sub_spec);
            push @gathered, $params if keys(%$params);
          } else {
            push @gathered, $v;
          }
        }
        $return{$field} = \@gathered;
      } elsif(Scalar::Util::blessed($value) && $value->can('as_data')) { 
        my $params = $value->as_data($sub_spec);
        next unless keys(%$params);
        $return{$field} = $params;
      } else {
        $return{$field} = $value;
      }
    } else {
      # Its not a property, so just return the value.  This is to let
      # you customize the return data structure with your own non property
      # attributes or methods.
      $return{$field} = $self->get_attribute_value_for($field);
    }
  }

  return \%return;
}

sub nested_params {
  my $self = shift;
  my %return;
  foreach my $p ($self->properties) {
    my ($attr, $meta) = %$p;
    if(my $predicate = $meta->{attr_predicate}) {
      if($meta->{omit_empty}) {
        next unless $self->$predicate;  # skip empties when omit_empty=>1
      }
    }

    my $value = $self->get_attribute_value_for($attr);
    if( (ref($value)||'') eq 'ARRAY') {
      my @gathered = ();
      foreach my $v (@$value) {
        if(Scalar::Util::blessed($v)) {
          my $params = $v->nested_params;
          push @gathered, $params if keys(%$params);
        } else {
          push @gathered, $v;
        }

      }
      $return{$attr} = \@gathered;
    } elsif(Scalar::Util::blessed($value) && $value->can('nested_params')) { 
      my $params = $value->nested_params;
      next unless keys(%$params);
      $return{$attr} = $params;
    } else {
      $return{$attr} = $value;
    }
  }
  return \%return;
} 

sub get {
  my ($self, @fields) = @_;
  my $p = $self->nested_params;
  my @got = @$p{@fields};
  return @got;
}

1;

=head1 NAME

CatalystX::RequestModel::DoesRequestModel - Role to provide request model API

=head1 SYNOPSIS

Generally you will apply this role via L<CatalystX::RequestModel>

    package Example::Model::AccountRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    namespace 'person';
    content_type 'application/x-www-form-urlencoded';

    has username => (is=>'ro', property=>{always_array=>1});  
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);
    has notes => (is=>'ro', property=>+{ expand=>'JSON' });

See L<CatalystX::RequestModel> for a more general overview.

=head1 DESCRIPTION

A role that gives a L<Catalyst::Model> the ability to indicate which of its attributes should be
consider request model data, as well as additional need meta data so that we can process it
properly.

Since we need to wrap C<has> you should never apply this role manually but rather instead use
L<CatalystX::RequestModel> to apply it for you.   If you need to customize this role you will
also need to subclass L<CatalystX::RequestModel> and have that new subclass apply you custom
role.   Please ping me if you really need this since I guess we could change L<CatalystX::RequestModel>
to make it easier to supply a custom role, just let me know your use case.

=head1 METHODS

This class defines the following public API

=head2 nested_params

Returns all the attributes marked as request properties in the form of a hashref.  If any of the
properties refer to an array or indexed value, or an object, we automatically follow that to 
return all the property data below.

Attributes that are empty will be left out of the return data structure.

Easiest way to get all your data but then again you get a structure that is very tightly tied to
your request model.  

=head2 as_data

  my $data = $object->as_data(@namespace, $spec);

This method serializes the object into a data structure (hash reference) based on the provided specification.
 It allows for selective extraction of object properties and supports nested structures.

=over 4

=item @namespace

An optional list of method names to call on the object to navigate to the desired sub-object. 
Each method in the namespace should return an object or value that the next method in the namespace 
can be called on.

=item $spec

An array reference that defines which properties to include in the serialized data. Each element 
in the array can be either a string (property name) or a hash reference (property name 
and sub-specification).

=back

The method performs the following steps:

=over 4

=item 1.

Separates the namespace from the data specification pattern.

=item 2.

Retrieves property information as a hash.

=item 3.

If a namespace is provided, navigates through the object structure to the desired sub-object.

=item 4.

Iterates over the specification array and extracts the corresponding data from the object.

=back

The method handles properties that are arrays, objects, or plain scalar values. It also respects the 
`omit_empty` attribute for properties, skipping them if they are empty and `omit_empty` is set to true.

Returns a hash reference containing the serialized data.

=head3 Examples

=over 4

=item Basic Usage

  # Example 1: Converting a flat structure of incoming parameters
  # Imagine these are parameters from an HTTP request (e.g., form submission)
  my %incoming_params = (
    property1 => 'Alice',
    property2 => 'Engineer',
  );

  # Create the request model object with the incoming parameters
  my $object = My::RequestModel->new(%incoming_params);

  # Convert the request model into a simple hash reference.
  # This will only include 'property1' and 'property2' from the object.
  my $data = $object->as_data(['property1', 'property2']);

  use Data::Dumper;
  print "Flat conversion:\n", Dumper($data);

  $VAR1 = {
            'property1' => 'Alice',
            'property2' => 'Engineer'
          };

  # Example 2: Converting a nested structure
  # Here, the incoming parameters include a nested hash for address details.
  my %incoming_nested = (
    property1 => 'Alice',
    property2 => 'Engineer',
    address   => {
      street => '123 Main St',
      city   => 'Anytown',
    },
  );

  # Re-create the request model object with nested parameters.
  my $nested_object = My::RequestModel->new(%incoming_nested);

  # Convert into a hash reference.
  # The first argument 'address' directs as_data to navigate into the nested address object.
  # The spec ['street', 'city'] lists the properties to extract from that nested object.
  my $nested_data = $nested_object->as_data([
    'property1', 'property2',   # top-level properties
    {'address' => ['street', 'city'] }
  ]
  );

  print "Nested conversion:\n", Dumper($nested_data);

  $VAR1 = {
            'property1' => 'Alice',
            'property2' => 'Engineer',
            'address' => {
                           'street' => '123 Main St',
                           'city' => 'Anytown'
                         }
          };

=item Nested Structures

  my $data = $object->as_data('sub_object', [
    'property1',
    { 'nested_property' => ['sub_property1', 'sub_property2'] }
  ]);

This will navigate to the 'sub_object' within the main object and serialize 'property1' and 'nested_property', 
where 'nested_property' includes 'sub_property1' and 'sub_property2'.

=head2 get

Accepts a list of attributes that refer to request properties and returns their values.  In the case
when the attribute listed has no value, you will instead get an C<undef>.

=head1 EXCEPTIONS

This class can throw the following exceptions:

=head2 Invalid Request Content Body

If we can't create an instance of the request model we throw a L<CatalystX::RequestModel::Utils::BadRequest>.
This will get interpretated as an HTTP 400 status client error if you are using L<CatalystX::Errors>.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut

