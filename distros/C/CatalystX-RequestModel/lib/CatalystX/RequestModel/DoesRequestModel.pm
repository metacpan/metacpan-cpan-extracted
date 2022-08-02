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
  my ($class_or_self, $ct) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  CatalystX::RequestModel::_add_metadata($class, 'content_type', $ct) if $ct;

  if($class_or_self->can('content_type_metadata')) {
    my ($ct) = $class_or_self->content_type_metadata;  # needed because this returns an array but we only want the first one
    return $ct;
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
  return $self->$attr;
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

