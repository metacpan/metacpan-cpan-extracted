# This component is private and unsupported: it is deliberately undocumented
# and excluded from the CPAN index (see dist.ini).  It remains only for
# existing code that already depends on it and may be removed at any time.

package DBIx::Class::Valiant::Result::HTML::FormFields;

use base 'DBIx::Class';

use warnings;
use strict;

## TODO add cache=>1 for simple memory caching of the resultset

__PACKAGE__->mk_classdata( __select_options_rs_for => {} );
__PACKAGE__->mk_classdata( __checkbox_rs_for => {} );
__PACKAGE__->mk_classdata( __radio_button_rs_for => {} );
__PACKAGE__->mk_classdata( __radio_buttons_for => {} );
__PACKAGE__->mk_classdata( __field_attribute_for => {} );

__PACKAGE__->mk_classdata( __tags_by_column => {} );
__PACKAGE__->mk_classdata( __columns_by_tag => {} );

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    my $tag_info = exists $info->{tag}
      ? $info->{tag}
      : exists $info->{tags}
        ? $info->{tags}
        : undef;

    return unless $tag_info;

    my @tags = (ref($tag_info)||'') eq 'ARRAY'
      ? @{$tag_info}
      : ($tag_info);

    $self->__tags_by_column->{$column} = \@tags;
    
    foreach my $tag (@tags) {
      push @{$self->__columns_by_tag->{$tag}}, $column;
    }
}

sub tags_by_column {
  my ($self, $column) = @_;
  return @{$self->__tags_by_column->{$column}||[]};
}

sub columns_by_tag {
  my ($self, $tag) = @_;
  return @{$self->__columns_by_tag->{$tag}||[]};
}

sub add_select_options_rs_for {
  my ($class, $column, $code) = @_;
  $class->__select_options_rs_for->{$column} = $code;
}

sub select_options_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__select_options_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('option_value');
    my ($label_method) = $class->columns_by_tag('option_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub select_options_for {
  my ($self, $column, %options) = @_;
  my ($rs, $label_method, $value_method) = $self->select_options_rs_for($column, %options);
  my @options = map {[ $_->$label_method, $_->$value_method ]} $rs->all;
  return \@options;
}

sub add_checkbox_rs_for {
  my ($class, $column, $code) = @_;
  $class->__checkbox_rs_for->{$column} = $code;
}

sub checkbox_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__checkbox_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('checkbox_value');
    my ($label_method) = $class->columns_by_tag('checkbox_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub checkboxes_for {
  my ($self, $column, %options) = @_;
  my ($rs, $label_method, $value_method) = $self->checkbox_rs_for($column, %options);
  my @options = map {[ $_->$label_method, $_->$value_method ]} $rs->all;
  return \@options;
}

sub add_radio_button_rs_for {
  my ($class, $column, $code) = @_;
  $class->__radio_button_rs_for->{$column} = $code;
}

sub radio_button_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__radio_button_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('radio_value');
    my ($label_method) = $class->columns_by_tag('radio_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub add_radio_buttons_for {
  my ($class, $column, $code) = @_;
  $class->__radio_buttons_for->{$column} = $code;
}
sub radio_buttons_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__radio_buttons_for->{$column};
  my @buttons = $code->($self, %options);
  return @buttons;
}

# $class->add_form_field_for($column);
# $class->add_form_field_for($column, \&code);
# $class->add_form_field_for($column, \%options);
# $class->add_form_field_for($column, \%options, \&code);

sub add_form_field_for {
  my ($class, $column) = (shift(@_), shift(@_));
  my $options = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $code = (ref($_[0])||'') eq 'CODE' ? shift(@_) : sub { $class->_auto_read_attribute_for_html($column) };

  $class->__field_attribute_for->{$column} = [$code, $options];
}

# __PACKAGE__->add_form_field_for(
#   'user',
#   sub ($self) { $self->user},
#   { label=>..., type=>..., context=>'admin' } );

# add 'context' to this so that you can have different forms for same
# TODO maybe need to add way to wrap getting label and errors...

sub has_form_fields {
  my ($self) = @_;
  return scalar keys %{$self->__field_attribute_for};
}

sub has_form_field {
  my ($self, $column) = @_;
  return exists $self->__field_attribute_for->{$column};
}

sub read_form_field_for {
  my ($self, $column) = @_;
  die "Can't find a form field for column '$column'" unless $self->has_form_field($column);
  return $self->_read_form_field_for($column);
}

sub _read_form_field_for {
  my ($self, $column) = @_;
  my ($code, $options) = @{$self->__field_attribute_for->{$column}};
  return $code->($self, $column);
}


sub read_attribute_for_html {
  my ($self, $attribute) = @_;
  die "'attribute' is required argument" unless defined $attribute;

  # If at least one form field is defined for this class, that means the
  # author wanted fine grained control over the form fields so we'll use that
  # and only that.  Otherwise we'll fall back to the auto reading method

  if($self->has_form_fields) {
    return $self->_read_form_field_for($attribute) if $self->has_form_field($attribute);
  } else {
    return $self->_auto_read_attribute_for_html($attribute);
  }
}

sub _auto_read_attribute_for_html {
  my ($self, $attribute) = @_;

  # Handle special case for 'delete' attribute and 'add' attribute
  return $self->is_marked_for_deletion if $attribute eq '_delete';
  return 1 if $attribute eq '_add';

  # First fallback to the normal DBIC way of getting a column value
  return $self->get_column($attribute) if $self->result_source->has_column($attribute);

  # Second just look for a method that matches the attribute name
  return $self->$attribute if $self->can($attribute); 

  # Permit getting the value of a relationship if it's a single relationship
  if($self->has_relationship($attribute)) {
    my $rel_data = $self->relationship_info($attribute);
    my $rel_type = $rel_data->{attrs}{accessor};
    return $self->$attribute if($rel_type eq 'single');
  }

  # If we can't find a value just return because the formhandler will decide
  # if this is an error or not
  return bless +{}, 'Valiant::BadAttribute';
}

1;

