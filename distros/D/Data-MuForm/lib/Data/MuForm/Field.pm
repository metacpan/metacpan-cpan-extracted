package Data::MuForm::Field;
# ABSTRACT: Base field package
use Moo;
use Types::Standard -types;
use Try::Tiny;
use Scalar::Util ('blessed', 'weaken');
use Data::Clone ('data_clone');
use Data::MuForm::Localizer;
use Data::MuForm::Merge ('merge');
with 'Data::MuForm::Common';

has 'name' => ( is => 'rw', required => 1 );
has 'id' => ( is => 'rw', lazy => 1, builder => 'build_id' );
sub build_id {
   my $self = shift;
   if ( my $meth = $self->get_method('build_id') ) {
       return $meth->($self, @_);
   }
   elsif ( $self->form && $self->form->can('build_field_id') ) {
       return $self->form->build_field_id($self);
   }
   return $self->prefixed_name;
}
has 'prefixed_name' => ( is => 'rw', lazy => 1, builder => 'build_prefixed_name');
sub build_prefixed_name {
    my $self = shift;
    my $prefix = ( $self->form && $self->form->field_prefix ) ? $self->field_prefix. "." : '';
    return $prefix . $self->full_name;
}
has 'form' => ( is => 'rw', weak_ref => 1, predicate => 'has_form' );
has 'type' => ( is => 'ro', required => 1, default => 'Text' );
has 'default' => ( is => 'rw' );
has 'input' => ( is => 'rw', predicate => 'has_input', clearer => 'clear_input' );
has 'input_without_param' => ( is => 'rw', predicate => 'has_input_without_param' );
has 'value' => ( is => 'rw', predicate => 'has_value', clearer => 'clear_value' );
has 'init_value' => ( is => 'rw', predicate => 'has_init_value', clearer => 'clear_init_value' );
has 'no_value_if_empty' => ( is => 'rw' );
has 'input_param' => ( is => 'rw' );
has 'filled_from' => ( is => 'rw', clearer => 'clear_filled_from' );
has 'password' => ( is => 'rw', default => 0 );
has 'accessor' => ( is => 'rw', lazy => 1, builder => 'build_accessor' );
sub build_accessor {
    my $self     = shift;
    my $accessor = $self->name;
    $accessor =~ s/^(.*)\.//g if ( $accessor =~ /\./ );
    return $accessor;
}
has 'custom' => ( is => 'rw' );
has 'parent' => ( is  => 'rw',   predicate => 'has_parent', weak_ref => 1 );
has 'source' => ( is => 'rw' );
has 'errors' => ( is => 'rw', isa => ArrayRef, default => sub {[]} );
sub has_errors { my $self = shift; return scalar @{$self->errors}; }
sub all_errors { my $self = shift; return @{$self->errors}; }
sub clear_errors { $_[0]->{errors} = [] }
sub clear_error_fields { }

# this is a permanent setting of active
has 'active' => ( is => 'rw', default => 1 );
# this is a temporary active set on the process call, cleared on clear_data
has '_active' => ( is => 'rw', predicate => '_has_active', clearer => '_clear_active' );
sub clear_inactive { $_[0]->active(1) }
sub inactive { return ( shift->active ? 0 : 1 ) }
sub is_active {
    my $self = shift;
    return $self->_active if $self->_has_active;
    return $self->active;
}
sub multiple { }
sub is_inactive { ! $_[0]->is_active }
has 'disabled' => ( is => 'rw', default => 0 );
has 'no_update' => ( is => 'rw', default => 0 );
has 'writeonly' => ( is => 'rw', default => 0 );
has 'is_contains' => ( is => 'rw' );
has 'apply' => ( is => 'rw', default => sub {[]} ); # for field defnitions
sub has_apply { return scalar @{$_[0]->{apply}} }
has 'base_apply' => ( is => 'rw', builder => 'build_base_apply' ); # for field classes
sub build_base_apply {[]}
sub has_base_apply { return scalar @{$_[0]->{base_apply}} }
has 'trim' => ( is => 'rw', default => sub { *default_trim } );
sub default_trim {
    my $value = shift;
    return unless defined $value;
    my @values = ref $value eq 'ARRAY' ? @$value : ($value);
    for (@values) {
        next if ref $_ or !defined;
        s/^\s+//;
        s/\s+$//;
    }
    return ref $value eq 'ARRAY' ? \@values : $values[0];
}
sub has_fields { } # compound fields will override
has 'methods' => ( is => 'rw', isa => HashRef, builder => 'build_methods', trigger => 1 );
sub build_methods {{}}
sub _trigger_methods {
    my ( $self, $new_methods ) = @_;
    my $base_methods = $self->build_methods;
    my $methods = merge($new_methods, $base_methods);
    $self->{methods} = $methods;

}
sub get_method {
   my ( $self, $meth_name ) = @_;
   return  $self->{methods}->{$meth_name};
}

has 'validate_when_empty' => ( is => 'rw' );
has 'not_nullable' => ( is => 'rw' );
sub is_repeatable {}
sub is_compound {}
sub is_form {0}
sub no_fif {0}

around BUILDARGS => sub {
  my ( $orig, $class, %field_attr ) = @_;

  munge_field_attr(\%field_attr);

  return $class->$orig(%field_attr);
};


sub BUILD {
    my $self = shift;

    if ( $self->form ) {
        # To avoid memory cycles it needs to be weakened when
        # it's set through a form.
        weaken($self->{localizer});
        weaken($self->{renderer});
    }
    else {
        # Vivify. This would generally only happen in a standalone field, in tests.
        $self->localizer;
        $self->renderer;
    }

    $self->_install_methods;
}

sub _install_methods {
    my $self = shift;

    if ( $self->form ) {
        my $suffix = $self->convert_full_name($self->full_name);
        foreach my $prefix ( 'validate', 'default' ) {
            next if exists $self->methods->{$prefix};
            my $meth_name = "${prefix}_$suffix";
            if ( my $meth = $self->form->can($meth_name) ) {
                my $wrap_sub = sub {
                    my $self = shift;
                    return $self->form->$meth($self);
                };
                $self->{methods}->{$prefix} = $wrap_sub;
            }
        }
    }
}


sub fif {
    my $self = shift;
    return unless $self->is_active;
    return '' if $self->password;
    return $self->input if $self->has_input;
    if ( $self->has_value ) {
      my $value = $self->value;
      $value = $self->transform_value_to_fif->($self, $value) if $self->has_transform_value_to_fif;
      return $value;
    }
    return '';
}


sub full_name {
    my $field = shift;

    my $name = $field->name;
    my $parent_name;
    # field should always have a parent unless it's a standalone field test
    if ( $field->parent ) {
        $parent_name = $field->parent->full_name;
    }
    return $name unless defined $parent_name && length $parent_name;
    return $parent_name . '.' . $name;
}

sub full_accessor {
    my $field = shift;

    my $parent = $field->parent;
    if( $field->is_contains ) {
        return '' unless $parent;
        return $parent->full_accessor;
    }
    my $accessor = $field->accessor;
    my $parent_accessor;
    if ( $parent ) {
        $parent_accessor = $parent->full_accessor;
    }
    return $accessor unless defined $parent_accessor && length $parent_accessor;
    return $parent_accessor . '.' . $accessor;
}


#====================
# Localization
#====================

sub localize {
   my ( $self, @message ) = @_;
   return $self->localizer->loc_($message[0]);
}

has 'language' => ( is => 'rw', lazy => 1, builder => 'build_language' );
sub build_language { 'en' }
has 'localizer' => (
    is => 'rw', lazy => 1, builder => 'build_localizer',
);
sub build_localizer {
    my $self = shift;
    return Data::MuForm::Localizer->new(
      language => $self->language,
    );
}

#====================
# Rendering
#====================
has 'label' => ( is => 'rw', lazy => 1, builder => 'build_label' );
sub build_label {
    my $self = shift;
    if ( my $meth = $self->get_method('build_label' ) ) {
        return $meth->($self);
    }
    my $label = $self->name;
    $label =~ s/_/ /g;
    $label = ucfirst($label);
    return $label;
}
sub loc_label {
    my $self = shift;
    return $self->localize($self->label);
}
has 'form_element' => ( is => 'rw', lazy => 1, builder => 'build_form_element' );
sub build_form_element { 'input' }
has 'input_type' => ( is => 'rw', lazy => 1, builder => 'build_input_type' );
sub build_input_type { 'text' }

# could have everything in one big "pass to the renderer" hash?
has 'layout' => ( is => 'rw' );
has 'layout_group' => ( is => 'rw' );
has 'order' => ( is => 'rw', default => 0 );
has 'html5_input_type' => ( is => 'rw', predicate => 'has_html5_input_type' );

sub base_render_args {
  my $self = shift;
  my $args = {
    name => $self->prefixed_name,
    field_name => $self->name,
    type => $self->type,
    form_element => $self->form_element,
    input_type => $self->input_type,
    id => $self->id,
    label => $self->loc_label,
    required => $self->required,
    errors => $self->errors || [],
    fif => $self->fif,
    layout_type => 'standard',
    is_contains => $self->is_contains,
  };
  $args->{html5_input_type} = $self->html5_input_type if $self->has_html5_input_type;
  return $args;
}

has 'render_args' => ( is => 'rw', lazy => 1, isa => HashRef, builder => 'build_render_args' );
sub build_render_args {{}}
# this is really just here for testing fields. If you want to test a custom
# renderer in a field, pass it in.
has 'renderer' => (
  is => 'rw', lazy => 1,
  builder => 'build_renderer',
);
sub build_renderer {
  my $self = shift;
  require Data::MuForm::Renderer::Base;
  return Data::MuForm::Renderer::Base->new( localizer => $self->localizer );
}

sub get_render_args {
  my ( $self, %args ) = @_;
  my $render_args = merge( $self->render_args, $self->base_render_args );
  $render_args = merge( \%args, $render_args );
  return $render_args;
}

sub render {
  my ( $self, $rargs ) = @_;
  munge_render_field_attr($rargs);
  my $render_args = $self->get_render_args(%$rargs);
  return $self->renderer->render_field($render_args);
}

sub render_element {
  my ( $self, $rargs ) = @_;
  my $args = { element_attr => $rargs };
  my $do_errors = delete $rargs->{do_errors};
  $args->{do_errors} = defined $do_errors ? $do_errors : 1;
  my $render_args = $self->get_render_args(%$args);
  return $self->renderer->render_element($render_args);
}

sub render_errors {
  my ( $self, $rargs ) = @_;
  my $render_args = $self->get_render_args( error_attr => $rargs );
  return $self->renderer->render_errors($render_args);
}

sub render_label {
  my ( $self, $rargs, @args ) = @_;
  my $render_args = $self->get_render_args( label_attr => $rargs );
  $self->form->render_hook($render_args) if $self->form;
  return $self->renderer->render_label($render_args, @args);
}


#===================
#  Errors
#===================

# handles message with and without variables
sub add_error {
    my ( $self, @message ) = @_;
    my $out;
    if ( $message[0] !~ /{/ ) {
        $out = $self->localizer->loc_($message[0]);
    }
    else {
        $out = $self->localizer->loc_x(@message);
    }
    return $self->push_error($out);
}

sub add_error_px {
    my ( $self, @message ) = @_;
    my $out = $self->localizer->loc_px(@message);
    return $self->push_error($out);;
}

sub add_error_nx {
    my ( $self, @message ) = @_;
    my $out = $self->localizer->loc_nx(@message);
    return $self->push_error($out);
}

sub add_error_npx {
    my ( $self, @message ) = @_;
    my $out = $self->localizer->loc_npx(@message);
    return $self->push_error($out);;
}



sub push_error {
    my $self = shift;
    push @{$self->{errors}}, @_;
    if ( $self->parent ) {
        $self->parent->propagate_error($self);
    }
}

sub clear { shift->clear_data }

#===================
#  Transforms
#===================

# these are all coderefs
has 'transform_param_to_input' => ( is => 'rw', predicate => 'has_transform_param_to_input' );
has 'transform_input_to_value' => ( is => 'rw', predicate => 'has_transform_input_to_value' );
has 'transform_default_to_value' => ( is => 'rw', predicate => 'has_transform_default_to_value' );
has 'transform_value_after_validate' => ( is => 'rw', predicate => 'has_transform_value_after_validate' );
has 'transform_value_to_fif' => ( is => 'rw', predicate => 'has_transform_value_to_fif' );

#====================================================================
# Validation
#====================================================================

has 'required' => ( is => 'rw', default => 0 );
has 'required_when' => ( is => 'rw', isa => HashRef, predicate => 'has_required_when' );
has 'unique' => ( is => 'rw', predicate => 'has_unique' );
sub validated { !$_[0]->has_errors && $_[0]->has_input }
sub normalize_input { } # intended for field classes, to make sure input is in correct form, mostly multiple or not

sub input_defined {
    my ($self) = @_;
    return unless $self->has_input;
    return has_some_value( $self->input );
}

sub has_some_value {
    my $x = shift;

    return unless defined $x;
    return $x =~ /\S/ if !ref $x;
    if ( ref $x eq 'ARRAY' ) {
        for my $elem (@$x) {
            return 1 if has_some_value($elem);
        }
        return 0;
    }
    if ( ref $x eq 'HASH' ) {
        for my $key ( keys %$x ) {
            return 1 if has_some_value( $x->{$key} );
        }
        return 0;
    }
    return 1 if blessed($x);    # true if blessed, otherwise false
    return 1 if ref( $x );
    return;
}



sub base_validate { }
sub validate {1}

sub field_validate {
    my $self = shift;

    return if ( $self->has_fields && $self->skip_fields_without_input && ! $self->has_input );

    $self->normalize_input;

    my $continue_validation = 1;
    if ( ( $self->required ||
         ( $self->has_required_when && $self->match_when($self->required_when) ) ) &&
         ( ! $self->has_input || ! $self->input_defined )) {
        $self->add_error( $self->get_message('required'), field_label => $self->label );
        if( $self->has_input ) {
            $self->not_nullable ? $self->value($self->input) : $self->value(undef);
        }

        $continue_validation = 0;
    }
    elsif ( $self->is_repeatable ) { }
    elsif ( !$self->has_input ) {
        $continue_validation = 0;
    }
    elsif ( !$self->input_defined ) {
        if ( $self->not_nullable ) {
            $self->value($self->input);
            # handles the case where a compound field value needs to have empty subfields
            $continue_validation = 0 unless $self->is_compound;
        }
        elsif ( $self->no_value_if_empty || $self->is_contains ) {
            $continue_validation = 0;
        }
        else {
            $self->value(undef);
            $continue_validation = 0;
        }
    }
    return if ( !$continue_validation && !$self->validate_when_empty );


    if ( $self->has_fields ) {
        $self->fields_validate;
    }
    else {
        my $input = $self->input;
        $input = $self->transform_input_to_value->($self, $input) if $self->has_transform_input_to_value;
        $self->value($input);
    }

    $self->value( $self->trim->($self->value) ) if $self->trim;

    $self->validate($self->value);  # this is field class validation. Do it before the other validations.

    $self->apply_actions;  # this could be either from the field definitions or from a custom field

    # this is validate_<field name> or methods->{validate => ...} validation
    if ( my $meth = $self->get_method('validate') ) {
        $meth->($self);
    }

    if ( $self->has_transform_value_after_validate ) {
        my $value = $self->value;
        $value = $self->transform_value_after_validate->($self, $value);
        $self->value($value);
    }

    return ! $self->has_errors;
}

sub transform_and_set_input {
  my ( $self, $input ) = @_;
  $input = $self->transform_param_to_input->($self, $input) if $self->has_transform_param_to_input;
  $self->input($input);
}


sub apply_actions {
    my $self = shift;

    my $error_message;
    local $SIG{__WARN__} = sub {
        my $error = shift;
        $error_message = $error;
        return 1;
    };

    my $is_type = sub {
        my $class = blessed shift or return;
        return $class eq 'MooseX::Types::TypeDecorator' || $class->isa('Type::Tiny');
    };

    my @actions;
    push @actions, @{ $self->base_apply }, @{ $self->apply };
    for my $action ( @actions ) {
        $error_message = undef;
        # the first time through value == input
        my $value     = $self->value;
        my $new_value = $value;
        # Moose constraints
        if ( !ref $action || $is_type->($action) ) {
            $action = { type => $action };
        }
        if ( my $when = $action->{when} ) {
            next unless $self->match_when($when);
        }
        if ( exists $action->{type} ) {
            my $tobj;
            if ( $is_type->($action->{type}) ) {
                $tobj = $action->{type};
            }
            else {
                my $type = $action->{type};
                $tobj = Moose::Util::TypeConstraints::find_type_constraint($type) or
                    die "Cannot find type constraint $type";
            }
            if ( $tobj->has_coercion && $tobj->validate($value) ) {
                eval { $new_value = $tobj->coerce($value) };
                if ($@) {
                    if ( $tobj->has_message ) {
                        $error_message = $tobj->message->($value);
                    }
                    else {
                        $error_message = $@;
                    }
                }
                else {
                    $self->value($new_value);
                }

            }
            $error_message ||= $tobj->validate($new_value);
        }
        # now maybe: http://search.cpan.org/~rgarcia/perl-5.10.0/pod/perlsyn.pod#Smart_matching_in_detail
        # actions in a hashref
        elsif ( ref $action->{check} eq 'CODE' ) {
            if ( !$action->{check}->($value, $self) ) {
                $error_message = $self->get_message('wrong_value');
            }
        }
        elsif ( ref $action->{check} eq 'Regexp' ) {
            if ( $value !~ $action->{check} ) {
                $error_message = [$self->get_message('no_match'), 'value', $value];
            }
        }
        elsif ( ref $action->{check} eq 'ARRAY' ) {
            if ( !grep { $value eq $_ } @{ $action->{check} } ) {
                $error_message = [$self->get_message('not_allowed'), 'value', $value];
            }
        }
        elsif ( ref $action->{transform} eq 'CODE' ) {
            $new_value = eval {
                no warnings 'all';
                $action->{transform}->($value, $self);
            };
            if ($@) {
                $error_message = $@ || $self->get_message('error_occurred');
            }
            else {
                $self->value($new_value);
            }
        }
        if ( defined $error_message ) {
            my @message = ref $error_message eq 'ARRAY' ? @$error_message : ($error_message);
            if ( defined $action->{message} ) {
                my $act_msg = $action->{message};
                if ( ref $act_msg eq 'CODE' ) {
                    $act_msg = $act_msg->($value, $self, $error_message);
                }
                if ( ref $act_msg eq 'ARRAY' ) {
                    @message = @{$act_msg};
                }
                elsif ( ref \$act_msg eq 'SCALAR' ) {
                    @message = ($act_msg);
                }
            }
            $self->add_error(@message);
        }
    }
}

sub match_when {
    my ( $self, $when ) = @_;

    my $matched = 0;
    foreach my $key ( keys %$when ) {
        my $check_against = $when->{$key};
        my $from_form = ( $key =~ /^\+/ );
        $key =~ s/^\+//;
        my $field = $from_form ? $self->form->field($key) : $self->parent->subfield( $key );
        unless ( $field ) {
            warn "field '$key' not found processing 'when' for '" . $self->full_name . "'";
            next;
        }
        my $field_fif = defined $field->fif ? $field->fif : '';
        if ( ref $check_against eq 'CODE' ) {
            $matched++
                if $check_against->($field_fif, $self);
        }
        elsif ( ref $check_against eq 'ARRAY' ) {
            foreach my $value ( @$check_against ) {
                $matched++ if ( $value eq $field_fif );
            }
        }
        elsif ( $check_against eq $field_fif ) {
            $matched++;
        }
        else {
            $matched = 0;
            last;
        }
    }
    return $matched;
}

#====================================================================
# Filling
#====================================================================

sub fill_from_params {
    my ( $self, $input, $exists ) = @_;

    $self->filled_from('params');
    if ( $exists ) {
        $self->transform_and_set_input($input);
    }
    elsif ( $self->disabled ) {
    }
    elsif ( $self->has_input_without_param ) {
        $self->transform_and_set_input($self->input_without_param);
    }
    return;
}

sub fill_from_object {
    my ( $self, $value ) = @_;

    $self->filled_from('object');
    $self->value($value);

    if ( $self->form ) {
        $self->form->init_value( $self, $value );
    }
    else {
        $self->init_value($value);
        #$result->_set_value($value);
    }
    $self->value(undef) if $self->writeonly;

    return;
}

sub fill_from_fields {
    my ( $self ) = @_;

    if ( my @values = $self->get_default_value ) {
        if ( $self->has_transform_default_to_value ) {
            @values = $self->transform_default_to_value->($self, @values);
        }
        my $value = @values > 1 ? \@values : shift @values;
        if ( defined $value ) {
            $self->init_value($value);
            $self->value($value);
        }
    }
    return;
}


sub clear_data {
    my $self = shift;
    $self->clear_input;
    $self->clear_value;
    $self->clear_errors;
    $self->_clear_active;
    $self->clear_filled_from;
}

sub get_default_value {
    my $self = shift;
    if ( my $meth = $self->get_method('default') ) {
        return $meth->($self);
    }
    elsif ( defined $self->default ) {
        return $self->default;
    }
    return;
}


#====================================================================
# Messages
#====================================================================

has 'messages' => ( is => 'rw', isa => HashRef, default => sub {{}} );
sub _get_field_message { my ($self, $msg) = @_; return $self->{messages}->{$msg}; }
sub _has_field_message { my ($self, $msg) = @_; exists $self->{messages}->{$msg}; }
sub set_message { my ($self, $msg, $value) = @_; $self->{messages}->{$msg} = $value; }


our $class_messages = {
    'field_invalid'   => 'field is invalid',
    'range_too_low'   => 'Value must be greater than or equal to [_1]',
    'range_too_high'  => 'Value must be less than or equal to [_1]',
    'range_incorrect' => 'Value must be between {start} and {end}',
    'wrong_value'     => 'Wrong value',
    'no_match'        => '[_1] does not match',
    'not_allowed'     => '[_1] not allowed',
    'error_occurred'  => 'error occurred',
    'required'        => "'{field_label}' field is required",
    'unique'          => 'Duplicate value for [_1]',   # this is used in the DBIC model
};

sub get_class_messages  {
    my $self = shift;
    my $messages = { %$class_messages };
    return $messages;
}

sub get_message {
    my ( $self, $msg ) = @_;

    # first look in messages set on individual field
    return $self->_get_field_message($msg)
       if $self->_has_field_message($msg);
    # then look at form messages
    return $self->form->_get_form_message($msg)
       if $self->has_form && $self->form->_has_form_message($msg);
    # then look for messages up through inherited field classes
    return $self->get_class_messages->{$msg};
}
sub all_messages {
    my $self = shift;
    my $form_messages = $self->has_form ? $self->form->messages : {};
    my $field_messages = $self->messages || {};
    my $lclass_messages = $self->my_class_messages || {};
    return {%{$lclass_messages}, %{$form_messages}, %{$field_messages}};
}

sub clone {
    my $self = shift;
    return data_clone($self);
}

sub get_result {
    my $self = shift;
    my $result = {
        name => $self->name,
        full_name => $self->full_name,
        id => $self->id,
        label => $self->label,
        render_args => $self->render_args,
        fif => $self->fif,
    };
    $result->{errors} = $self->errors if $self->has_errors;
    return $result;
}

sub convert_full_name {
    my ( $self, $full_name ) = @_;
    $full_name =~ s/\.\d+\./_/g;
    $full_name =~ s/\./_/g;
    return $full_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field - Base field package

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Instances of Field subclasses are generally built by L<Data::MuForm>
from 'has_field' declarations or the field_list.

   has_field 'my_field' => ( type => 'Integer' );
   field_list => [
      my_field => { type => 'Integer' }
   ]

Fields can also be added with add_field:

    $form->add_field( name => 'my_field', type => 'Integer' );

You can create custom field classes:

    package MyApp::Field::MyText;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm::Field::Text';

    has 'my_attribute' => ( is => 'rw' );

    sub validate { <perform validation> }

    1;

=head1 DESCRIPTION

This is the base class for form fields. The 'type' of a field class
is used in the MuForm field_list or has_field to identify which field class to
load from the 'field_namespace' (or directly, when prefixed with '+').
If the type is not specified, it defaults to Text.

See L<Data::MuForm::Manual::Fields> for a list of the fields and brief
descriptions of their structure.

=head1 NAME

Data::MuForm::Field

=head1 ATTRIBUTES

=head2 Names, types, accessor

=over

=item name

The name of the field. Used in the HTML form. Often a db accessor.
The only required attribute.

=item type

The class or type of the field. The 'type' of L<Data::MuForm::Field::Currency>
is 'Currency'.

=item id

The id to use when rendering. This can come from a number of different places.

  1) field definition
  2) field 'build_id' method
  3) form 'build_field_id' method
  4) field prefixed_name

=item accessor

If the name of your field is different than your database accessor, use
this attribute to provide the accessor.

=item full_name

The name of the field with all parents:

   'event.start_date.month'

=item full_accessor

The field accessor with all parents.

=item prefixed_name

The full_name plus the prefix provided in 'field_prefix'. Useful for multiple
forms on the same page.

=item input_param

By default we expect an input parameter based on the field name.  This allows
you to look for a different input parameter.

=back

=head2 Field data

=over

=item active, inactive, is_active, is_inactive

Determines which fields will be processed and rendered.

Can be changed on a process call, and cleared afterward:

    $form->process( active => [ 'foo', 'bar' ], params => $params );

You can use the is_inactive and is_active methods to check whether this particular
field is active. May be necessary to use in templates if you're changing the
active/inactive of some fields.

   if( $form->field('foo')->is_active ) { ... }

=item input

The input string from the parameters passed in. This is not usually set by
the user.

=item value

The value as it would come from or go into the database, after being
acted on by transforms and validation code. Used to construct the
C<< $form->values >> hash. Before validation is performed, the input is
copied to the 'value', and validation and constraints should act on 'value'.
After validation, C<< $form->value >> will get a hashref of the values.

See also L<Data::MuForm::Manual::Transforms>.

=item fif

Values used to fill in the form. Read only.

   [% form.field('title').fif %]

=item init_value

Initial value populated by fill_from_object. You can tell if a field
has changed by comparing 'init_value' and 'value'. You wouldn't normally
change this.

=item input_without_param

Input for this field if there is no param. Set by default for Checkbox,
and Select, since an unchecked checkbox or unselected pulldown
does not return a parameter.

=back

=head2 Form, parent, etc

=over

=item form

A reference to the containing form.

=item parent

A reference to the parent of this field. Compound fields are the
parents for the fields they contain.

=item localizer

Set from the form when fields are created.

=item renderer

Set from the form when fields are created.

=back

=head2 Errors

=over

=item errors

Returns the error list (arrayref) for the field. Also provides
'all_errors', 'num_errors', 'has_errors', 'push_error' and 'clear_errors'.
Use 'add_error' to add an error to the array if you
want to localize the error message, or 'push_error' to skip
the localization.

=item add_error

Add an error to the list of errors. Error message will be localized
using 'localize' method, and the Localizer (default is
Data::MuForm::Localizer, which use a gettext style .po file).

    return $field->add_error( 'bad data' ) if $bad;

=item push_error

Adds an error to the list of errors without localization.

=item error_fields

The form and Compound fields will have an array of errors from the subfields.

=back

=head2 methods

A 'methods' hashref allows setting various coderefs, 'build_id', 'build_label',
'build_options', 'validate', 'default'.

   methods => { build_id => \&my_build_id } - coderef for constructing the id
   methods => { build_label => \&my_build_label } - coderef for constructing the label

=over

=item build_id

A coderef to build the field's id. If one doesn't exist, will use a form 'build_field_id'
method. Fallback is to use the field's full name.

=item build_label

=item build_options

=item validate

=item default

=back

=head2 render_args

The 'render_args' hashref contains keys which are used in rendering, with shortcuts
for easier specification in a field definition.

   element_attr         - ea
   label_attr           - la
   wrapper_attr         - wa
   error_attr           - era
   element_wrapper_attr - ewa

   has_field 'foo' => ( render_args => { element_attr => { readonly => 1, my_attr => 'abc' }} );
   has_field 'foo' => ( 'ra.ea' => { readonly => 1, my_attr => 'abc' } );
   has_field 'foo' => ( 'ra'.wa.class' => ['mb10', 'wr66'] );

Note the the 'name', 'id', and 'value' of fields is set by field attributes. Though
it is possible to override the id in render_args, it then won't be available for
other code such as 'errors_by_id'. There is some behavior associated with the 'disabled'
flag too.

   label       - Text label for this field. Defaults to ucfirst field name.
   id          - Used in 'id="<id>"' in HTML
   disabled    - Boolean to set field disabled

The order attribute may be used to set the order in which fields are rendered.

   order       - Used for sorting errors and fields. Built automatically,
                 but may also be explicitly set. Auto sequence is by 5: 5, 10, 15, etc

=head2 Flags

=over

=item password

Prevents the entered value from being displayed in the form

=item writeonly

The initial value is not taken from the database

=item no_update

Do not include this field in C<< $form->values >>, and so it won't be updated in the database.

=item not_nullable

Fields that contain 'empty' values such as '' are changed to undef in the validation process.
If this flag is set, the value is not changed to undef. If your database column requires
an empty string instead of a null value (such as a NOT NULL column), set this attribute.

    has_field 'description' => (
        type => 'TextArea',
        not_nullable => 1,
    );

This attribute is also used when you want an empty array to stay an empty array and not
be set to undef.

It's also used when you have a compound field and you want the 'value' returned
to contain subfields with undef, instead of the whole field to be undef.

=back

=head2 Defaults

See also the documentation on L<Data::MuForm::Manual::Defaults>.

=over

=item default method

Note: do *not* set defaults by setting the 'checked' or 'selected' attributes
in options. The code will be unaware that defaults have been set.

  has_field 'foo' => (  methods => { default => \&my_default } );
  sub my_default { }
  OR
  has_field 'foo';
  sub default_foo { }

Supply a coderef (which will be a method on the field).
If not specified and a form method with a name of
C<< default_<field_name> >> exists, it will be used.

=item default

Provide an initial value in the field declaration:

  has_field 'bax' => ( default => 'Default bax' );

=back

=head1 Constraints and Validations

See also L<Data::MuForm::Manual::Validation>.

=head2 Constraints set in attributes

=over

=item required

Flag indicating whether this field must have a value

=item unique

For DB field - check for uniqueness. Action is performed by
the DB model.

=item apply

Use the 'apply' keyword to specify an ArrayRef of constraints and coercions to
be executed on the field at field_validate time.

   has_field 'test' => (
      apply => [ TinyType,
                 { check => sub {...}, message => { } },
                 { transform => sub { ... lc(shift) ... } }
               ],
   );

=back

=head2 messages

    has_field 'foo' => ( messages => { required => '...', unique => '...' } );
    or
    has_field 'foo' => ( 'msg.required' => '...' );

Set messages created by MuForm by setting in the 'messages'
hashref or with the 'msg.<msg_name>' shortcut. Some field subclasses have additional
settable messages.

required:  Error message text added to errors if required field is not present.
The default is "Field <field label> is required".

=head2 Transforms

There are a number of methods to provide finely tuned transformation of the
input or value.

See also L<Data::MuForm::Manual::Transforms>.

=over 4

=item transform_input_to_value

In FH was 'inflate_method'.

Transforms the string that was submitted in params (and copied to 'input') when
it's stored in the 'value' attribute during validation.

=item transform_value_to_fif

In FH was 'deflate_method'.

When you get 'fif' for the field and the 'value' is used (as opposed to input)
transforms the value to a string suitable for filling in a form field.

=item transform_default_to_value

In FH was inflate_default_method.

Transform the 'default' provided by an 'model' or 'init_values' or 'default' when it's stored
in the 'value'.

=item transform_value_after_validate

In FH was 'deflate_value_method';

Transform the value after validation has been performs, in order to return
a different form in C<< $form->value >>.

=item transform_param_to_input

Transform the param when it's stored in 'input'. Will change what the user sees
in a re-presented form.

=item trim

A transform to trim the field. The default 'trim' sub
strips beginning and trailing spaces.
Set this attribute to null to skip trimming, or supply a different
sub.

  trim => sub {
      my $string = shift;
      <do something>
      return $string;
  }

Trimming is performed before any other defined actions.

=back

=head1 Processing and validating the field

See also L<Data::MuForm::Manual::Validation>.

=head2 Validate method

   has_field 'foo' => ( methods => { validate => \&foo_validation } );
   sub foo_validation { }
   OR
   has_field 'foo';
   sub validate_foo { }

Supply a coderef (which will be a method on the field).
If not specified and a form method with a name of
C<< validate_<field_name> >> exists, it will be used instead.

Periods in field names will be replaced by underscores, so that the field
'addresses.city' will use the 'validate_addresses_city' method for validation.

=head2 apply actions

Use Type::Tiny types;

   use Types::Standard ('PosInteger');
   has_field 'foo' => ( apply => [ PosInteger ] );

=head2 validate

This field method can be used in addition to or instead of 'apply' actions
in custom field classes.
It should validate the field data and set error messages on
errors with C<< $field->add_error >>.

    sub validate {
        my $field = shift;
        my $value = $field->value;
        return $field->add_error( ... ) if ( ... );
    }

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
