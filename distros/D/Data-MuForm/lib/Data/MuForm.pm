package Data::MuForm;
# ABSTRACT: Data validator and form processor

use Moo;
use Data::MuForm::Meta;

with 'Data::MuForm::Model';
with 'Data::MuForm::Fields';
with 'Data::MuForm::Common';

use Types::Standard -types;
use Class::Load ('load_optional_class');
use Data::Clone ('data_clone');
use Data::MuForm::Params;
use Data::MuForm::Localizer;
use MooX::Aliases;
use Data::MuForm::Merge ('merge');

our $VERSION = '0.04';


has 'name' => ( is => 'ro', builder => 'build_name');
sub build_name {
    my $self = shift;
    my $class = ref $self;
    my  ( $name ) = ( $class =~ /.*::(.*)$/ );
    $name ||= $class;
    return $name;
}
has 'id' => ( is => 'ro', lazy => 1, builder => 'build_id' );
sub build_id { $_[0]->name }
has 'submitted' => ( is => 'rw', default => undef );  # three values: 0, 1, undef
has 'processed' => ( is => 'rw', default => 0 );
#has 'no_init_process' => ( is => 'rw', default => 0 );

has 'ran_validation' => ( is => 'rw', default => 0 );
has '_params' => ( is => 'rw', isa => HashRef, default => sub {{}}, alias => 'data' );
sub clear_params { $_[0]->{_params} = {} }
sub has_params { my $self = shift; return scalar keys %{$self->{_params}}; }
sub params {
    my ( $self, $params ) = @_;
    if ( $params ) {
        $params = $self->munge_params($params);
        $self->{_params} = $params;
    }
    return $self->{_params};
}
has 'field_prefix' => ( is => 'rw' );

has 'form_meta_fields' => ( is => 'rw', isa => ArrayRef, default => sub {[]} );
has 'index' => ( is => 'rw', isa => HashRef, default => sub {{}} );
sub add_to_index { my ( $self, $field_name, $field ) = @_; $self->{index}->{$field_name} = $field; }
sub form { shift }
sub is_form {1}
sub parent { }
has 'ctx' => ( is => 'rw', weak_ref => 1 );
# init_values can be a blessed object or a hashref
has 'init_values' => ( is => 'rw', alias => 'init_object' );
sub clear_init_values { $_[0]->{init_values} = undef }
sub has_init_values {
    my $self = shift;
    my $init_obj = $self->init_values;
    return 0 unless defined $init_obj;
    return 0 if ref $init_obj eq 'HASH' and ! scalar keys %$init_obj;
    return 1;
}
has 'fill_from_object_source' => ( is => 'rw', );
has 'active' => ( is => 'rw', clearer => 'clear_active', predicate => 'has_active' );
has 'inactive' => ( is => 'rw', clearer => 'clear_inactive', predicate => 'has_inactive' );
sub full_name { '' }
sub full_accessor { '' }
sub fif { shift->fields_fif(@_) }

has '_repeatable_fields' => (
    is => 'rw',
    default => sub {[]},
);
sub add_repeatable_field {
  my ( $self, $field ) = @_;
  push @{$self->_repeatable_fields}, $field;
}
sub has_repeatable_fields {
  my ( $self, $field ) = @_;
  return scalar @{$self->_repeatable_fields};
}
sub all_repeatable_fields {
  my $self = shift;
  return @{$self->_repeatable_fields};
}

#========= Rendering ==========
has 'http_method'   => ( is  => 'ro', default => 'post' );
has 'action' => ( is => 'rw' );
has 'enctype' => ( is => 'rw' );
has 'renderer_class' => ( is => 'ro', builder => 'build_renderer_class' );
sub build_renderer_class { 'Data::MuForm::Renderer::Base' }
has 'renderer' => ( is => 'rw', lazy => 1, builder => 'build_renderer' );
sub build_renderer {
    my $self = shift;
    my $renderer_class = load_optional_class($self->renderer_class) ? $self->renderer_class : 'Data::MuForm::Renderer::Base';
    my $renderer = $renderer_class->new(
        localizer => $self->localizer,
        form => $self->form,
        %{$self->renderer_args},
    );
    return $renderer;
}
has 'renderer_args' => ( is => 'ro', isa => HashRef, builder => 'build_renderer_args' );
sub build_renderer_args {{}}
has 'render_args' => ( is => 'rw', lazy => 1, isa => HashRef, builder => 'build_render_args' );
sub build_render_args {{}}
sub base_render_args {
  my $self = shift;
  my $args = {
    name => $self->name,
    id => $self->name,
    form_errors => $self->form_errors || [],
    form_attr => {
      method => $self->http_method,
    }
  };
  $args->{form_attr}->{action} = $self->action if $self->action;
  $args->{form_attr}->{enctype} = $self->enctype if $self->enctype;
  return $args;
}


#========= Errors ==========
has 'form_errors' => ( is => 'rw', isa => ArrayRef, default => sub {[]} );
sub clear_form_errors { $_[0]->{form_errors} = []; }
sub all_form_errors { return @{$_[0]->form_errors}; }
sub has_form_errors { scalar @{$_[0]->form_errors} }
sub num_form_errors { scalar @{$_[0]->form_errors} }
sub push_form_error { push @{$_[0]->form_errors}, $_[1] }
sub add_form_error {
    my ( $self, @message ) = @_;
    my $out;
    if ( $message[0] !~ /{/ ) {
        $out = $self->localizer->loc_($message[0]);
    }
    else {
        $out = $self->localizer->loc_x(@message);
    }
    return $self->push_form_error($out);
}

sub has_errors {
    my $self = shift;
    return $self->has_error_fields || $self->has_form_errors;
}
sub num_errors {
    my $self = shift;
    return $self->num_error_fields + $self->num_form_errors;
}
sub get_errors { shift->errors }

sub all_errors {
    my $self         = shift;
    my @errors = $self->all_form_errors;
    push @errors,  map { $_->all_errors } $self->all_error_fields;
    return @errors;
}
sub errors { [$_[0]->all_errors] }

sub errors_by_id {
    my $self = shift;
    my %errors;
    $errors{$_->id} = [$_->all_errors] for $self->all_error_fields;
    return \%errors;
}

sub errors_by_name {
    my $self = shift;
    my %errors;
    $errors{$_->prefixed_name} = [$_->all_errors] for $self->all_error_fields;
    return \%errors;
}

#========= Localization ==========

has 'language' => ( is => 'rw', builder => 'build_language' );
sub build_language { 'en' }
has 'localizer' => ( is => 'rw', lazy => 1, builder => 'build_localizer' );
sub build_localizer {
    my $self = shift;
    return Data::MuForm::Localizer->new(
      language => $self->language,
    );
}

#========= Messages ==========
has 'messages' => ( is => 'rw', isa => HashRef, builder => 'build_messages' );
sub build_messages {{}}
sub _get_form_message { my ($self, $msgname) = @_; return $self->messages->{$msgname}; }
sub _has_form_message { my ($self, $msgname) = @_; return exists $self->messages->{$msgname}; }
sub set_message { my ( $self, $msgname, $msg) = @_; $self->messages->{$msgname} = $msg; }
my $class_messages = {};
sub get_class_messages  {
    return $class_messages;
}
sub get_message {
    my ( $self, $msg ) = @_;
    return $self->_get_form_message($msg) if $self->_has_form_message($msg);
    return $self->get_class_messages->{$msg};
}
sub all_messages {
    my $self = shift;
    return { %{$self->get_class_messages}, %{$self->messages} };
}


#========= Methods ==========
sub BUILD {
    my $self = shift;

    # instantiate
    $self->localizer;
    $self->renderer;
    $self->build_fields;
    $self->after_build_fields;
    # put various defaults into fields. Should this happen?
    # it will be re-done on the first process call
    $self->fill_values;
}

sub process {
    my $self = shift;

    $self->clear if $self->processed;
    $self->setup(@_);
    $self->after_setup;
    $self->validate_form if $self->submitted;

    $self->update_model       if ( $self->validated );
    $self->after_update_model if ( $self->validated );

    $self->processed(1);
    return $self->validated;
}

sub check {
    my $self = shift;
    $self->clear if $self->processed;
    $self->setup(@_);
    $self->after_setup;
    $self->validate_form if $self->submitted;
    $self->processed(1);
    return $self->check_result;
}

sub check_result {
    my $self = shift;
    return $self->validated;
}

sub clear {
    my $self = shift;
    $self->clear_params;
    $self->clear_filled_from;
    $self->submitted(undef);
    $self->model(undef);
    $self->clear_init_values;
    $self->fill_from_object_source(undef);
    $self->ctx(undef);
    $self->processed(0);
    $self->ran_validation(0);

    # this will recursively clear field data
    $self->clear_data;
    $self->clear_form_errors;
    $self->clear_error_fields;
}


sub setup {
    my ( $self, @args ) = @_;

    if ( @args == 1 ) {
        $self->params( $args[0] );
    }
    elsif ( @args > 1 ) {
        my $hashref = {@args};
        while ( my ( $key, $value ) = each %{$hashref} ) {
            warn "invalid attribute '$key' passed to setup_form"
                unless $self->can($key);
            $self->$key($value);
        }
    }
    # set_active
    $self->set_active;

    # customization hook
    $self->in_setup;

    # set the submitted flag
    $self->submitted(1) if ( $self->has_params && ! defined $self->submitted );

    # fill the 'value' attributes from model, init_values or fields
    $self->fill_values;

    # fill in the input attribute
    my $params = data_clone( $self->params );
    if ( $self->submitted ) {
        $self->fill_from_params($params, 1 );
        # if the params submitted don't match fields, it shouldn't count as 'submitted'
        if ( ! scalar keys %{$self->input} ) {
            $self->submitted(0);
        }
    }

}

sub fill_values {
    my $self = shift;

    # these fill the 'value' attributes
    if ( $self->model && $self->use_model_for_defaults ) {
      $self->fill_from_object_source('model');
      $self->fill_from_object($self->model);
    }
    elsif ( $self->init_values ) {
        $self->fill_from_object_source('init_values');
        $self->fill_from_object($self->init_values );
    }
    elsif ( !$self->submitted ) {
        # no initial object. empty form must be initialized
        $self->fill_from_fields;
    }
}

sub in_setup { }
sub after_setup { }
sub after_build_fields { }

sub update_model {
    my $self = shift;
}


sub munge_params {
    my ( $self, $params, $attr ) = @_;

    my $_fix_params = Data::MuForm::Params->new;
    my $new_params = $_fix_params->expand_hash($params);
    if ( $self->field_prefix ) {
        $new_params = $new_params->{ $self->field_prefix };
    }
    $new_params = {} if !defined $new_params;
    return $new_params;
}

sub set_active {
    my $self = shift;
    if( $self->has_active ) {
        foreach my $fname (@{$self->active}) {
            my $field = $self->field($fname);
            if ( $field ) {
                $field->_active(1);
            }
            else {
                warn "field $fname not found to set active";
            }
        }
        $self->clear_active;
    }
    if( $self->has_inactive ) {
        foreach my $fname (@{$self->inactive}) {
            my $field = $self->field($fname);
            if ( $field ) {
                $field->_active(0);
            }
            else {
                warn "field $fname not found to set inactive";
            }
        }
        $self->clear_inactive;
    }
}

#====================================================================
# Validation
#====================================================================

sub validate_form {
    my $self = shift;

    $self->fields_validate;
    $self->validate;       # hook
    $self->validate_model; # hook
    $self->fields_set_value;
    $self->submitted(undef);
    $self->ran_validation(1);
}

# hook for child forms
sub validate { }

# hook for model validation
sub validate_model { }

sub validated { my $self = shift; return $self->ran_validation && ! $self->has_error_fields; }

sub get_default_value { }

sub transform_and_set_input {
    my ($self, $input) = @_;
    $self->input($input);
}

sub get_result {
    my $self = shift;
    my $result = {
        method => $self->http_method,
        action => $self->action,
        name   => $self->name,
        id     => $self->id,
        submitted => $self->submitted,
        validated => $self->validated,
    };
    $result->{form_errors} = $self->form_errors if $self->has_form_errors;
    $result->{errors} = $self->errors if $self->has_errors;
    return $result;
}

sub results { shift->fields_get_results }

sub add_field {
    my ( $self, %field_attr ) = @_;
    my $field = $self->_make_field( \%field_attr );
    # make it the last field.
    unless ( exists $field_attr{order} ) {
      my $order = $field->parent->_get_highest_field_order;
      $field->order($order + 5);
    }
    return $field;
}

sub after_update_model {
    my $self = shift;
    # This an attempt to reload the repeatable
    # relationships after the database is updated, so that we get the
    # primary keys of the repeatable elements. Otherwise, if a form
    # is re-presented, repeatable elements without primary keys may
    # be created again. There is no reliable way to connect up
    # existing repeatable elements with their db-created primary keys.
    if ( $self->has_repeatable_fields && $self->model ) {
        foreach my $field ( $self->all_repeatable_fields ) {
            next unless $field->is_active;
            # Check to see if there are any repeatable subfields with
            # null primary keys, so we can skip reloading for the case
            # where all repeatables have primary keys.
            my $needs_reload = 0;
            foreach my $sub_field ( $field->all_fields ) {
                if ( $sub_field->is_compound && $sub_field->has_primary_key ) {
                    foreach my $pk_field ( @{ $sub_field->primary_key } ) {
                        $needs_reload++ unless $pk_field->fif;
                    }
                    last if $needs_reload;
                }
            }
            next unless $needs_reload;
            my @names = split( /\./, $field->full_name );
            my $rep_model = $self->find_sub_obj( $self->model, \@names );
            # $rep_model is a single row or an array of rows or undef
            # If we found a database model for the repeatable, initialize
            # with 'fill_from_object'
            if ( ref $rep_model ) {
                my $parent = $field->parent;
                $field->init_state;
                $field->fill_from_object( $rep_model );
            }
        }
    }
}

# model for render_hook in forms to modify render_args for rendering
sub render_hook {
    my ( $self, $renderer, $rargs ) = @_;
}

sub get_render_args {
  my ( $self, %args ) = @_;
  my $render_args = merge( $self->base_render_args, $self->render_args );
  $render_args = merge( $render_args, \%args );
  return $render_args;
}

sub render {
  my ( $self, $rargs ) = @_;
  my $render_args = $self->get_render_args(%$rargs, rendering => 'form');
  return $self->renderer->render_form($render_args, $self->sorted_fields);
}

sub render_start {
  my ( $self, $rargs ) = @_;
  my $render_args = $self->get_render_args( form_attr => $rargs, rendering => 'form_start');
  return $self->renderer->render_start($render_args);
}

sub render_end {
  my ( $self, $rargs ) = @_;
  # is there any need for attributes on a form end tag? never seen any...
  my $render_args = $self->get_render_args(rendering => 'form_end');
  return $self->renderer->render_end($render_args);
}

sub render_errors {
  my ( $self, $rargs ) = @_;
  # we're not doing 'form_error_attr'. only processing 'error_tag' and 'error_class'
  my $render_args = $self->get_render_args( %$rargs, rendering => 'form_errors');
  return $self->renderer->render_form_errors($render_args);
}

# just for top level fields
sub render_hidden_fields {
  my $self = shift;
  foreach my $field ( $self->all_sorted_fields ) {
    if ( $field->type eq 'Hidden' && $field->has_value ) {
      $field->render_element;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm - Data validator and form processor

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Moo conversion of HTML::FormHandler, with more emphasis on data
validation and a new way of rendering. The core behavior is basically
the same as FormHandler, but some names have been changed, some
functionality removed, some added. It will be necessary to change
your forms to convert to MuForm, but it shouldn't be difficult.

See the manual at L<Data::MuForm::Manual>, and in particular
L<Data::MuForm::Manual::FormHandlerDiff> if you're already using
FormHandler.

    my $validator = MyApp::Form::Test->new;
    $validator->check( data => $params );
                    or
    my $form = MyApp::Form::User->new;
    $form->process( model => $row, params => $params );
    my $rendered_form = $form->render;
    if( $form->validated ) {
        # perform validated form actions
    }
    else {
        # perform non-validated actions
    }

An example of a custom form class:

    package MyApp::Form::User;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'name' => ( type => 'Text' );
    has_field 'age' => ( type => 'Integer', apply => [ MinimumAge ] );
    has_field 'hobbies' => ( type => 'Multiple' );
    has_field 'address' => ( type => 'Compound' );
    has_field 'address.city' => ( type => 'Text' );
    has_field 'address.state' => ( type => 'Select' );
    has_field 'email' => ( type => 'Email' );

A dynamic form - one that does not use a custom form class - may be
created using the 'field_list' attribute to set fields:

    my $validator = Data::MuForm->new(
        name => 'login_form',
        field_list => [
            'username' => {
                type  => 'Text',
                apply => [ { check => qr/^[0-9a-z]*\z/,
                   message => 'Contains invalid characters' } ],
            },
            'password' => { apply => [ Password ] },
        ],
    );

=head1 DESCRIPTION

This documentation is mainly of Data::MuForm class attributes and methods.
For general-purpose documentation see L<Data::MuForm::Manual>.

=head1 NAME

Data::MuForm

=head1 ATTRIBUTES and METHODS

=head2 Creating a form with 'new'

The new constructor takes name/value pairs:

    MyForm->new( action => $action );

No attributes are required on new. Normally you would pass in persistent
attributes on 'new' (such as 'schema') and request/process related attributes on 'process'.

The form's fields will be built from the form definitions on new.

The 'field_list' is passed in on 'new' because fields are build at construction time.
It can also be a method in the form class.

   field_list  - an array of field definitions

=head2 process & check

Data to be validated/processed:

   data     $validator->check( data => {} );
   params   $form->process( params => {} );

The 'init_values' hashref can be passed in, but can also be set in the form class:

   init_values - a hashref or object to provide initial values

Passed in on process with a DBIC model MuForm class:

   model     - database row object

See the model class for more information about 'model', 'model_id',
'model_class', and 'schema' (for the DBIC model).
L<Data::MuForm::Model::DBIC>.

=head2 Processing

=head3 check

Use the 'check' method to perform validation on your data:

    my $result = $validator->check( data => { ... } );

The 'result' returned from 'check' is $form->validated, but you can
override the 'check_result' method in the form to return data in
whatever format you wish.

=head3 process

Call the 'process' method on your form to perform validation and
update. A database form must have either a model (row object) or
a schema, model_id (row primary key), and model_class (usually set in the form).
A non-database form requires only parameters.

   $form->process( model => $book, params => $c->req->parameters );
   $form->process( model_id => $model_id,
       schema => $schema, params => $c->req->parameters );
   $form->process( params => $c->req->parameters );

This process method returns the 'validated' flag (C<< $form->validated >>).
If it is a database form and the form validates, the database row
will be updated.

After the form has been processed, you can get a parameter hashref suitable
for using to fill in the form from C<< $form->fif >>.
A hash of inflated values (that would be used to update the database for
a database form) can be retrieved with C<< $form->value >>.

If you don't want to update the database, you can use the 'check' method instead.

=head3 params

Parameters are passed in when you call 'process'.
HFH gets data to validate and store in the database from the params hash.
If the params hash is empty, no validation is done, so it is not necessary
to check for POST before calling C<< $form->process >>. (Although see
the 'posted' option for complications.)

Params can either be in the form of CGI/HTTP style params:

   {
      user_name => "Joe Smith",
      occupation => "Programmer",
      'addresses.0.street' => "999 Main Street",
      'addresses.0.city' => "Podunk",
      'addresses.0.country' => "UT",
      'addresses.0.address_id' => "1",
      'addresses.1.street' => "333 Valencia Street",
      'addresses.1.city' => "San Francisco",
      'addresses.1.country' => "UT",
      'addresses.1.address_id' => "2",
   }

or as structured data in the form of hashes and lists:

   {
      addresses => [
         {
            city => 'Middle City',
            country => 'GK',
            address_id => 1,
            street => '101 Main St',
         },
         {
            city => 'DownTown',
            country => 'UT',
            address_id => 2,
            street => '99 Elm St',
         },
      ],
      'occupation' => 'management',
      'user_name' => 'jdoe',
   }

CGI style parameters will be converted to hashes and lists for HFH to
operate on.

=head3 submitted

Note that MuForm by default uses empty params as a signal that the
form has not actually been submitted, and so will not attempt to validate
a form with empty params. Most of the time this works OK, but if you
have a small form with only the controls that do not return a post
parameter if unselected (checkboxes and select lists), then the form
will not be validated if everything is unselected. For this case you
can either add a hidden field as an 'indicator', or use the 'submitted' flag:

   $form->process( submitted => ($c->req->method eq 'POST'), params => ... );

The 'submitted' flag also works to prevent validation from being performed
if there are extra params in the params hash and it is not a 'POST' request.

=head2 Getting data out

=head3 fif  (fill in form)

If you don't use MuForm rendering and want to fill your form values in
using some other method (such as with HTML::FillInForm or using a template)
this returns a hash of values that are equivalent to params which you may
use to fill in your form.

The fif value for a 'title' field in a TT form:

   [% form.fif.title %]

Or you can use the 'fif' method on individual fields:

   [% form.field('title').fif %]

If you use MuForm to render your forms or field you probably won't use
these methods.

=head3 value

Returns a hashref of all field values. Useful for non-database forms, or if
you want to update the database yourself. The 'fif' method returns
a hashref with the field names for the keys and the field's 'fif' for the
values; 'value' returns a hashref with the field accessors for the keys, and the
field's 'value' (possibly inflated) for the values.

Forms containing arrays to be processed with L<Data::MuForm::Field::Repeatable>
will have parameters with dots and numbers, like 'addresses.0.city', while the
values hash will transform the fields with numbers to arrays.

=head2 Accessing and setting up fields

Fields are declared with a number of attributes which are defined in
L<Data::MuForm::Field>. If you want additional attributes you can
define your own field classes (or apply a role to a field class - see
L<Data::MuForm::Manual::Cookbook>). The field 'type' (used in field
definitions) is the short class name of the field class, used when
searching the 'field_namespace' for the field class.

=head3 has_field

The most common way of declaring fields is the 'has_field' syntax.
Using the 'has_field' syntax sugar requires C< use Data::MuForm::Meta; >.
See L<Data::MuForm::Manual::Intro>

   use Moo;
   use Data::MuForm::Meta;
   has_field 'field_name' => ( type => 'FieldClass', .... );

=head3 field_list

A 'field_list' is an array of field definitions which can be used as an
alternative to 'has_field' in small, dynamic forms to create fields.

    field_list => [
       field_one => {
          type => 'Text',
          required => 1
       },
       field_two => 'Text,
    ]

The field_list array takes elements which are either a field_name key
pointing to a 'type' string or a field_name key pointing to a
hashref of field attributes. You can also provide an array of
hashref elements with the name as an additional attribute.
The field list can be set inside a form class, when you want to
add fields to the form depending on some other state, although
you can also create all the fields and set some of them inactive.

   sub field_list {
      my $self = shift;
      my $fields = $self->schema->resultset('SomeTable')->
                          search({user_id => $self->user_id, .... });
      my @field_list;
      while ( my $field = $fields->next )
      {
         < create field list >
      }
      return \@field_list;
   }

=head2 add_field

You can add an additional field with $form->add_field.

    my $order = $form->field('foo')->order + 1;
    $form->add_field(
       name => 'my_cb',
       type => 'Checkbox',
       order => $order,
    );

It will be ordered as the last field unless you set the 'order'
attribute. Form fields are automatically ordered by 5 (i.e. 5, 10, 15, etc).

=head3 active/inactive

A field can be marked 'inactive' and set to active at process time
by specifying the field name in the 'active' array:

   has_field 'foo' => ( type => 'Text', inactive => 1 );
   ...
   my $form = MyApp::Form->new;
   $form->process( active => ['foo'] );

Or a field can be a normal active field and set to inactive at process
time:

   has_field 'bar';
   ...
   my $form = MyApp::Form->new;
   $form->process( inactive => ['foo'] );

Fields specified as active/inactive on 'process' will have the flag
flag cleared when the form is cleared (on the next process/check call).

The 'sorted_fields' method returns only active fields, sorted according to the
'order' attribute. The 'fields' method returns all fields.

   foreach my $field ( $self->all_sorted_fields ) { ... }

You can test whether a field is active by using the field 'is_active' and 'is_inactive'
methods.

=head3 field_namespace

Use to look for field during form construction. If a field is not found
with the field_namespace (or Data::MuForm/Data::MuFormX),
the 'type' must start with a '+' and be the complete package name.

=head3 fields

The array of fields, objects of L<Data::MuForm::Field> or its subclasses.
A compound field will itself have an array of fields,
so this is a tree structure.

=head3 sorted_fields

Returns those fields from the fields array which are currently active, ordered
by the 'order' attribute. This is the method that returns the fields that are
looped through when rendering.

=head3 field($name), subfield($name)

'field' is the method that is usually called to access a field:

    my $title = $form->field('title')->value;
    [% f = form.field('title') %]

    my $city = $form->field('addresses.0.city')->value;

Since fields are searched for using the form as a base, if you want to find
a sub field in a compound field method, the 'subfield' method may be more
useful, since you can search starting at the current field. The 'chained'
method also works:

    -- in a compound field --
    $self->field('media.caption'); # fails
    $self->field('media')->field('caption'); # works
    $self->subfield('media.caption'); # works

=head3 build_field_id

Create a 'build_field_id' sub in the form class to use a common method for
constructing field ids.

    sub build_field_id {
       my ( $self, $field ) = @_;
       return $field->name . '_' . $self->id;
    }

=head2 Constraints and validation

Most validation is performed on a per-field basis, and there are a number
of different places in which validation can be performed.

See also L<Data::MuForm::Manual::Validation>.

=head3 Class validation for individual fields

You can define a method in your class to perform validation on a field.
This method is the equivalent of the field class validate method except it is
in the validator/form class, so you might use this
validation method if you don't want to create a field subclass.

It has access to the form ($self) and the field.
This method is called after the field class 'validate' method, and is not
called if the value for the field is empty ('', undef). (If you want an
error message when the field is empty, use the 'required' flag and message
or the form 'validate' method.)
The name of this method can be set with 'set_validate' on the field. The
default is 'validate_' plus the field name:

   sub validate_testfield { my ( $self, $field ) = @_; ... }

If the field name has dots they should be replaced with underscores.

Note that you can also provide a coderef which will be a method on the field:

   has_field 'foo' => ( methods => { validate => \&validate_foo } );

=head3 validate

This is a form method that is useful for cross checking values after they have
been saved as their final validated value, and for performing more complex
dependency validation. It is called after all other field validation is done,
and whether or not validation has succeeded, so it has access to the
post-validation values of all the fields.

This is the best place to do validation checks that depend on the values of
more than one field.

=head2 Accessing errors

Also see L<Data::MuForm::Manual::Errors>.

Set an error in a field with C<< $field->add_error('some error string'); >>.
Set a form error not tied to a specific field with
C<< $self->add_form_error('another error string'); >>.
The 'add_error' and 'add_form_error' methods call localization. If you
want to skip localization for a particular error, you can use 'push_error'
or 'push_form_errors' instead.

  has_errors - returns true or false
  error_fields - returns list of fields with errors
  errors - returns array of error messages for the entire form
  num_errors - number of errors in form

Each field has an array of error messages. (errors, has_errors, num_errors,
clear_errors)

  $form->field('title')->errors;

Compound fields also have an array of error_fields.

=head2 Clear form state

The clear method is called at the beginning of 'process' if the form
object is reused, such as when it is persistent,
or in tests.  If you add other attributes to your form that are set on
each request, you may need to either clear those yourself or ensure that
they are always set on each process call.

=head2 Miscellaneous attributes

=head3 name

The form's name.  Useful for multiple forms. Used for the form element 'id'.
When 'field_prefix' is set it is used to construct the field 'id'
and 'name'.  The default is derived from the form class name.

=head3 init_values

An 'init_values' object or hashref  may be used instead of the 'model' to pre-populate the values
in the form. This can be useful when populating a form from default values
stored in a similar but different object than the one the form is creating.
It can be set in a variety of ways:

   my $form = MyApp::Form->new( init_values => { .... } );
   $form->process( init_values => {...}, ... );
   has '+init_values' => ( default => sub { { .... } } );
   sub init_values { my $self = shift; .... }

The method version is useful if the organization of data in your form does
not map to an existing or database object in an automatic way, and you need
to create a different type of object for initialization. (You might also
want to do 'update_model' yourself.)

You can use both a 'model' and an 'init_values' hashref
when some of the fields in your form come from the database and some
are process or environment type flags that are not in the database.

=head3 ctx

Place to store application context for your use in your form's methods.

=head2 Localizer

The form has a 'localizer' object which is shared with form fields.
Uses gettext style .po files with names parameters, and is implemented
with internal code borrowed from L<Locale::TextDomain::OO>.

=head2 Flags

=head3 validated, is_valid

Flag that indicates if form has been validated. You might want to use
this flag if you're doing something in between process and returning,
such as setting a stash key. ('is_valid' is a synonym for this flag)

   $form->process( ... );
   $c->stash->{...} = ...;
   return unless $form->validated;

=head3 ran_validation

Flag to indicate that validation has been run. This flag will be
false when the form is initially loaded and displayed, since
validation is not run until MuForm has params to validate.

=head3 field_prefix

String to be used as a prefix for field ids and names
in an HTML form. Useful for multiple forms
on the same HTML page. The prefix is stripped off of the fields
before creating the internal field name, and added back in when
returning a parameter hash from the 'fif' method. For example,
the field name in the HTML form could be "book.borrower", and
the field name in the MuForm form (and the database column)
would be just "borrower".

   has '+name' => ( default => 'book' );
   has '+field_prefix' => ( default => 'book' );

Also see the Field attribute "prefixed_name", a convenience function which
will return the field_prefix + "." + field full_name

=head2 setup

This is where args passed to 'process' are set, and the form is
filled by params, object, or fields.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
