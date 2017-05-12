package Data::MuForm::Renderer::Base;
# ABSTRACT: Renderer

use Moo;
use List::Util ('any');
use Scalar::Util ('weaken');


has 'form' => ( is => 'ro', weak_ref => 1 );

has 'localizer' => ( is => 'ro' );

has 'standard_layout' => ( is => 'rw', default => 'lbl_ele_err' );

has 'cb_layout' => ( is => 'rw', default => 'cbwrlr' );

has 'rdgo_layout' => ( is => 'rw', default => 'labels_right' );

has 'cbgo_layout' => ( is => 'rw', default => 'labels_right' );

has 'display_layout' => ( is => 'rw', default => 'span' );

has 'field_wrapper' => ( is => 'rw', default => 'simple' );

has 'wrapper_tag' => ( is => 'rw', default => 'div' );

has 'error_tag' => ( is => 'rw', default => 'span' );

has 'error_class' => ( is => 'rw', default => 'error_message' );

has 'render_element_errors' => ( is => 'rw', default => 0 );

has 'is_html5' => ( is => 'rw', default => 0 );

sub BUILD {
    my $self = shift;
    if ( $self->form ) {
        weaken($self->{localizer});
    }
}

sub render_hook {
    my $self = shift;
    return $self->form->render_hook($self, @_);
}


sub localize {
   my ( $self, @message ) = @_;
   return $self->localizer->loc_($message[0]);
}

#==============================
#  Forms
#==============================

sub render_form {
    my ($self, $rargs, $fields ) = @_;

    my $out = '';
    $out .= $self->render_start($rargs);
    $out .= $self->render_form_errors($rargs);

    foreach my $field ( @$fields ) {
        $out .= $field->render;
    }

    $out .= $self->render_end($rargs);
    return $out;
}

sub render_start {
    my ($self, $rargs ) = @_;

    my $name = $rargs->{name};
    my $method = $rargs->{method};
    my $out = qq{<form };
    $out .= qq{id="$name" };
    $out .= process_attrs($rargs->{form_attr}, ['id','name']);
    $out .= q{>};
}

sub render_end {
    my ($self, $rargs ) = @_;

   return q{</form>};
}

sub render_form_errors {
    my ( $self, $rargs ) = @_;
    my $out = '';
    if ( scalar @{$rargs->{form_errors}} ) {
      $out .= q{<div class="form_errors>};
      my $error_tag = $rargs->{error_tag} || $self->error_tag;
      my $error_class = $rargs->{error_class} || $self->error_class;
      foreach my $error ( @{$rargs->{form_errors}} ) {
        $out .= qq{\n<$error_tag class="$error_class">$error</$error_tag>};
      }
      $out .= q{</div>};
    }
    return $out;
}

#==============================
#  Fields
#==============================

sub render_field {
  my ( $self, $rargs ) = @_;

  $rargs->{rendering} = 'field';
  $self->render_hook($rargs);

  my $layout_type = $rargs->{layout_type};

  my $out;
  if ( $layout_type eq 'checkbox' ) {
     $out = $self->render_layout_checkbox($rargs);
  }
  elsif ( $layout_type eq 'checkboxgroup' ) {
     $out = $self->render_layout_checkboxgroup($rargs);
  }
  elsif ( $layout_type eq 'radiogroup' ) {
     $out = $self->render_layout_radiogroup($rargs);
  }
  elsif ( $layout_type eq 'element' ) { # submit, reset, hidden
     $out = $self->render_element($rargs);
  }
  elsif ( $layout_type eq 'list' ) { # list
     $out = $self->render_layout_list($rargs);
  }
  elsif ( $layout_type eq 'display' ) {
     $out = $self->render_layout_display($rargs);
  }
  else {  # $layout_type eq 'standard'
     $out = $self->render_layout_standard($rargs);
  }

  return $self->wrap_field($rargs, $out);
}

sub wrap_field {
  my ( $self, $rargs, $rendered ) = @_;

  # wrap the field
  my $wrapper = $rargs->{wrapper} || $self->field_wrapper;
  return $rendered if $wrapper eq 'none';
  my $wrapper_meth = $self->can("wrapper_$wrapper") || die "wrapper method '$wrapper' not found";
  my $out = $wrapper_meth->($self, $rargs, $rendered);
  return $out;
}

sub render_compound {
    my ( $self, $rargs, $fields ) = @_;

    my $out = '';
    if ( $rargs->{is_instance} ) {
        add_to_class($rargs, 'wrapper_attr', 'repinst');
    }
    $out .= $self->render_label($rargs);
    foreach my $field ( @$fields ) {
        $out .= $field->render;
    }
    $out = $self->wrap_field($rargs, $out);
    return $out;
}

sub render_repeatable {
    my ( $self, $rargs, $fields ) = @_;
    my $out = '';
    $out .= $self->render_label($rargs);

    foreach my $field ( @$fields ) {
        $out .= $field->render;
    }
    $out = $self->wrap_field($rargs, $out);
    return $out;
}

#==============================
#  Utility methods
#==============================


sub add_to_class {
  my ( $href, $attr_key, $class ) = @_;

  return unless defined $class;
  if ( exists $href->{$attr_key}{class} && ref $href->{$attr_key}{class} ne 'ARRAY' ) {
     my @classes = split(' ', $href->{$attr_key}{class});
     $href->{$attr_key}{class} = \@classes;
  }
  if ( $class && ref $class eq 'ARRAY' ) {
     push @{$href->{$attr_key}{class}}, @$class;
  }
  else {
      push @{$href->{$attr_key}{class}}, $class;
  }
}


sub process_attrs {
    my ($attrs, $skip) = @_;

    $skip ||= [];
    my @use_attrs;
    my %skip;
    @skip{@$skip} = ();
    for my $attr ( sort keys %$attrs ) {
        next if exists $skip{$attr};
        next if $attr eq 'rendering';
        my $value = '';
        if( defined $attrs->{$attr} ) {
            if( ref $attrs->{$attr} eq 'ARRAY' ) {
                # we don't want class="" if no classes specified
                next unless scalar @{$attrs->{$attr}};
                $value = join (' ', @{$attrs->{$attr}} );
            }
            else {
                $value = $attrs->{$attr};
            }
        }
        push @use_attrs, sprintf( '%s="%s"', $attr, $value );
    }
    my $out = join( ' ', @use_attrs );
    return $out;
}

#==============================
#  Field form elements
#==============================


sub render_input {
  my ( $self, $rargs ) = @_;

  my $input_type = $rargs->{input_type};
  if ( $self->is_html5 && $rargs->{html5_input_type} ) {
    $input_type = $rargs->{html5_input_type};
  }
  # checkboxes are special
  return $self->render_checkbox($rargs) if $input_type eq 'checkbox';

  my $name = $rargs->{name};
  my $id = $rargs->{id};
  my $fif = html_filter($rargs->{fif});

  my $out = qq{\n<input type="$input_type" };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{value="$fif" };
  add_to_class( $rargs, 'element_attr', 'error' ) if @{$rargs->{errors}};
  $out .= process_attrs($rargs->{element_attr});
  $out .= "/>";
  return $out;
}


sub render_select {
  my ( $self, $rargs ) = @_;

  my $id = $rargs->{id};
  my $name = $rargs->{name};
  my $size = $rargs->{size};

  # beginning of select
  my $out = qq{\n<select };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{multiple="multiple" } if $rargs->{multiple};
  $out .= qq{size="$size" } if $size;
  add_to_class( $rargs, 'element_attr', 'error' ) if @{$rargs->{errors}};
  $out .= process_attrs($rargs->{element_attr});
  $out .= ">";

  # render empty_select
  if ( exists $rargs->{empty_select} ) {
    my $label = $self->localize($rargs->{empty_select});
    $out .= qq{\n<option value="">$label</option>};
  }

  # render options
  my $options = $rargs->{options};
  foreach my $option ( @$options ) {
      if ( my $label = $option->{group} ) {
          $label = $self->localize( $label );
          $out .= qq{\n<optgroup label="$label">};
          foreach my $group_opt ( @{ $option->{options} } ) {
              $out .= $self->render_select_option($rargs, $group_opt);
          }
          $out .= qq{\n</optgroup>};
      }
      else {
         $out .= $self->render_select_option($rargs, $option);
      }
  }

  # end of select
  $out .= "\n</select>\n";
  return $out;
}

sub render_select_option {
    my ( $self, $rargs, $option ) = @_;

    # prepare for selected attribute
    my $value = $option->{value};
    my $multiple = $rargs->{multiple};
    my $fif = $rargs->{fif} || [];
    my %fif_lookup;
    @fif_lookup{@$fif} = () if $multiple;

    my $label = $self->localize($option->{label});
    my $out = '';
    $out .= qq{\n<option };
    my $attrs = $option;
    $attrs = {%$attrs, %{$option->{attributes}}} if exists $option->{attributes};
    $out .= process_attrs($attrs, ['label', 'order']);
    if ( defined $fif && ( ($multiple && exists $fif_lookup{$value}) || ( $fif eq $value ) ) ) {
        $out .= q{selected="selected" };
    }
    $out .= qq{>$label</option>};
    return $out;
}



sub render_textarea {
  my ( $self, $rargs ) = @_;

  my $name = $rargs->{name};
  my $id = $rargs->{id};
  my $fif = html_filter($rargs->{fif});

  my $out = "\n<textarea ";
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  add_to_class( $rargs, 'element_attr', 'error' ) if @{$rargs->{errors}};
  $out .= process_attrs($rargs->{element_attr});
  $out .= ">$fif</textarea>";
  return $out;
}


sub render_element {
  my ( $self, $rargs ) = @_;

  my $do_errors = delete $rargs->{do_errors};
  $rargs->{rendering} = 'element';
  $self->render_hook($rargs);
  my $form_element = $rargs->{form_element};
  my $meth = "render_$form_element";
  my $out = $self->$meth($rargs);
  # this enables doing field.render_element without having to
  # render the errors for each field.
  if ( $self->render_element_errors && $do_errors ) {
    $out .= $self->render_errors($rargs);
  }
  return $out;
}


sub render_label {
  my ( $self, $rargs, $left_of_label, $right_of_label ) = @_;

  return '' if $rargs->{no_label};
  return '' if $rargs->{is_contains};
  return '' if $rargs->{wrapper} && $rargs->{wrapper} eq 'fieldset'; # this is kludgy :(
  $rargs->{rendering} = 'label';
  $self->render_hook($rargs);
  $right_of_label ||= '';
  $left_of_label ||= '';

  my $id = $rargs->{id};
  my $label = $rargs->{display_label} || $self->localize($rargs->{label});
  my $out = qq{\n<label };
  $out .= qq{for="$id"};
  $out .= process_attrs($rargs->{label_attr});
  $out .= qq{>};
  $out .= qq{$left_of_label$label$right_of_label};
  $out .= qq{</label>};
  return $out
}


sub render_errors {
  my ( $self, $rargs ) = @_;

  $rargs->{rendering} = 'errors';
  $self->render_hook($rargs);
  my $errors = $rargs->{errors} || [];
  my $out = '';
  my $error_tag = $rargs->{error_tag} || $self->error_tag;
  my $error_class = $rargs->{error_class} || $self->error_class;
  foreach my $error (@$errors) {
    $out .= qq{\n<$error_tag class="$error_class">$error</$error_tag>};
  }
  return $out;
}

sub html_filter {
    my $string = shift;
    return '' if (!defined $string);
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    return $string;
}

sub render_option {
    my ( $self, $rargs, $option ) = @_;
    my $out = '';
    if ( $rargs->{layout_type} eq 'standard' ) {
        $out .= $self->render_select_option($rargs, $option);
    }
    elsif ( $rargs->{layout_type} eq 'checkboxgroup' ) {
        $out .= $self->render_checkbox_option($rargs, $option);
    }
    elsif ( $rargs->{layout_type} eq 'radiogroup' ) {
        $out .= $self->render_radio_option($rargs, $option);
    }
    return $out;
}

#==============================
#  Radio, Radiogroup
#==============================

sub render_layout_radiogroup {
  my ( $self, $rargs ) = @_;

  my $rdgo_layout = $rargs->{rdgo_layout} || $self->rdgo_layout;
  my $rdgo_layout_meth = $self->can("rdgo_layout_$rdgo_layout") or die "Radio layout '$rdgo_layout' not found";

  my $out = $self->render_label($rargs);
  # render options
  my $options = $rargs->{options};
  foreach my $option ( @$options ) {
    $out .= $rdgo_layout_meth->($self, $rargs, $option);
  }
  # TODO - is this the best place for error messages for radiogroups?
  $out .= $self->render_errors($rargs);
  return $out;
}

sub render_radio_option {
    my ( $self, $rargs, $option ) = @_;

    my $name = $rargs->{name};
    my $order = $option->{order};
    my $out = qq{<input type="radio" };
    $out .= qq{name="$name" };
    $out .= qq{id="$name$order" } unless $option->{id};
    my $attrs = $option;
    $attrs = {%$attrs, %{$option->{attributes}}} if exists $option->{attributes};
    $out .= process_attrs($attrs, ['label', 'order']);
    if ( $rargs->{fif} eq $option->{value} ) {
        $out .= qq{checked="checked" };
    }
    $out .= q{/>};
}

sub rdgo_layout_labels_left {
    my ( $self, $rargs, $option ) = @_;
    my $rd_element = $self->render_radio_option($rargs, $option);
    my $rd = $self->render_radio_label($rargs, $option, '', $rd_element);
    my $out = $self->element_wrapper($rargs, $rd);
    return $out;
}

sub rdgo_layout_labels_right {
    my ( $self, $rargs, $option ) = @_;
    my $rd_element = $self->render_radio_option($rargs, $option);
    my $rd = $self->render_radio_label($rargs, $option, $rd_element, '');
    my $out = $self->element_wrapper($rargs, $rd);
    return $out;
}

sub render_radio_label {
  my ( $self, $rargs, $option, $left_of_label, $right_of_label ) = @_;

  $right_of_label ||= '';
  $left_of_label ||= '';
  my $label = $self->localize($option->{label});

  my $attrs = { class => ['radio'] };
  $attrs->{for} = $option->{id} ? $option->{id} : $rargs->{name} . $option->{order};
# add_to_class( $attrs, $rargs->{radio_label_class} );

  my $out = qq{\n<label };
  $out.= process_attrs($attrs);
  $out .= q{>};
  $out .= qq{$left_of_label $label $right_of_label};
  $out .= qq{</label>};
}

#==============================
#  Checkboxes
#==============================

sub render_layout_checkbox {
    my ( $self, $rargs) = @_;

  my $cb_element = $self->render_checkbox($rargs);
  my $cb_layout = $rargs->{cb_layout} || $self->cb_layout;
  my $meth = $self->can("cb_layout_$cb_layout") || die "Checkbox layout '$cb_layout' not found";
  my $out = '';
  $out = $meth->($self, $rargs, $cb_element);
  $out .= $self->render_errors($rargs);

  return $out;

}


sub render_checkbox {
  my ( $self, $rargs ) = @_;

  my $name = $rargs->{name};
  my $id = $rargs->{name};
  my $checkbox_value = $rargs->{checkbox_value};
  my $fif = html_filter($rargs->{fif});

  my $out = qq{<input };
  $out .= qq{type="checkbox" };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{value="$checkbox_value" };
  $out .= qq{checked="checked" } if $fif eq $checkbox_value;
  add_to_class( $rargs, 'element_attr', 'error' ) if @{$rargs->{errors}};
  $out .= process_attrs($rargs->{element_attr});
  $out .= "/>";
  return $out;
}

sub render_checkbox_option {
  my ( $self, $rargs, $option ) = @_;

  # prepare for checked attribute
  my $multiple = $rargs->{multiple};
  my $fif = $rargs->{fif} || [];
  my %fif_lookup;
  @fif_lookup{@$fif} = () if $multiple;


  my $name = $rargs->{name};
  my $value = $option->{value};
  my $order = $option->{order};
  my $out = qq{<input };
  $out .= qq{type="checkbox" };
  $out .= qq{name="$name" };
  $out .= qq{id="$name$order" } unless $option->{id};
  if ( defined $fif && ( ($multiple && exists $fif_lookup{$value}) || ( $fif eq $value ) ) ) {
      $out .= q{checked="checked" };
  }
  my $attrs = $option;
  $attrs = {%$attrs, %{$option->{attributes}}} if exists $option->{attributes};
  $out .= process_attrs($attrs, ['label', 'order']);
  $out .= "/>";
  return $out;
}

sub render_layout_checkboxgroup {
  my ( $self, $rargs ) = @_;

  my $out = $self->render_label($rargs);
  my $cbgo_layout = $rargs->{cbgo_layout} || $self->cbgo_layout;
  my $cbgo_layout_meth = $self->can("cbgo_layout_$cbgo_layout")
     || die "Checkbox group option layout '$cbgo_layout' not found";;
  # render options
  my $options = $rargs->{options};
  foreach my $option ( @$options ) {
      $out .= $cbgo_layout_meth->($self, $rargs, $option);
  }
  # TODO - is this the best place for error messages?
  $out .= $self->render_errors($rargs);
  return $out;
}

sub cbgo_layout_labels_right {
  my ( $self, $rargs, $option ) = @_;

  my $cb_element = $self->render_checkbox_option($rargs, $option);
  my $cb = $self->render_checkbox_label($rargs, $option, $cb_element, '');
  my $out .= $self->element_wrapper($rargs, $cb);
  return $out;
}

sub cbgo_layout_labels_left {
  my ( $self, $rargs, $option ) = @_;
  my $cb_element = $self->render_checkbox_option($rargs, $option);
  my $cb = $self->render_checkbox_label($rargs, $option, '', $cb_element);
  my $out .= $self->element_wrapper($rargs, $cb);
  return $out;
}

sub render_checkbox_label {
  my ( $self, $rargs, $option, $left_of_label, $right_of_label ) = @_;

  $right_of_label ||= '';
  $left_of_label ||= '';
  my $label = $self->localize($option->{label});

  my $attrs = { class => ['checkbox'] };
  $attrs->{for} = $option->{id} ? $option->{id} : $rargs->{name} . $option->{order};
# add_to_class( $attrs, $rargs->{checkbox_label_class} );

  my $out = qq{\n<label };
  $out.= process_attrs($attrs);
  $out .= q{>};
  $out .= qq{$left_of_label $label $right_of_label};
  $out .= qq{</label>};
}


sub cb_layout_cbwrll {
  my ( $self, $rargs, $cb_element ) = @_;

  my $out = $self->render_label($rargs, '', $cb_element);
  return $out

}


sub cb_layout_cbwrlr {
  my ( $self, $rargs, $cb_element ) = @_;

  my $out = $self->render_label($rargs, $cb_element, '' );
  return $out;
}


sub cb_layout_cbnowrll {
  my ( $self, $rargs, $cb_element ) = @_;

  my $out = $self->render_label($rargs);
  $out .= $cb_element;
  return $out;
}

sub cb_layout_cb2l {
  my ( $self, $rargs, $cb_element ) = @_;

  my $out = $self->render_label($rargs);

  my $id = $rargs->{id};
  my $option_label = $self->localize($rargs->{option_label}) || '';
  $out .= qq{\n<label for="$id">$cb_element$option_label</label>};
  return $out;
}

#==============================
#  Layouts
#==============================

sub render_layout_standard {
  my ( $self, $rargs ) = @_;

  # render the field layout
  my $layout = $rargs->{layout} || $self->standard_layout;
  my $layout_meth = $self->can("layout_$layout");
  die "layout method '$layout' not found" unless $layout_meth;
  my $out = '';
  $out .= $layout_meth->($self, $rargs);
  return $out;
}

sub layout_lbl_ele_err {
    my ( $self, $rargs ) = @_;

    my $out = '';
    $out .= $self->render_label($rargs);
    $out .= $self->render_element($rargs);
    $out .= $self->render_errors($rargs);
    return $out;
}

sub layout_lbl_wrele_err {
    my ( $self, $rargs ) = @_;

    my $out = '';
    $out .= $self->render_label($rargs);
    my $ele .= $self->render_element($rargs);
    $out .= $self->element_wrapper($rargs, $ele);
    $out .= $self->render_errors($rargs);
    return $out;
}

sub layout_no_label {
    my ( $self, $rargs ) = @_;
    my $out = '';
    $out .= $self->render_element($rargs);
    $out .= $self->render_errors($rargs);
    return $out;
}

#==============================
#  Wrappers
#==============================

sub wrapper_simple {
    my ( $self, $rargs, $rendered ) = @_;

    my $tag = $rargs->{wrapper_attr}{tag} || $self->wrapper_tag;
    my $out = qq{\n<$tag };
    $out .= process_attrs($rargs->{wrapper_attr}, ['tag']);
    $out .= qq{>};
    $out .= $rendered;
    $out .= qq{\n</$tag>};
    return $out;
}

sub wrapper_fieldset {
    my ( $self, $rargs, $rendered ) = @_;

    my $id = $rargs->{id} if ($rargs->{is_compound});
    my $label = $self->localize($rargs->{label});
    my $out = qq{\n<fieldset };
    $out .= qq{id="$id" } if $id;
    $out .= process_attrs($rargs->{wrapper_attr});
    $out .= qq{>};
    $out .= qq{<legend class="label">$label</legend>};
    $out .= $rendered;
    $out .= qq{\n</fieldset>};
    return $out;
}

sub element_wrapper {
    my ( $self, $rargs, $rendered ) = @_;
    my $out = qq{\n<div };
    $out .= process_attrs($rargs->{element_wrapper_attr});
    $out .= qq{>$rendered</div>};
    return $out;
}

sub render_layout_list {
    my ( $self, $rargs ) = @_;

    my $fif = $rargs->{fif} || [];
    my $size = $rargs->{size};
    $size ||= (scalar @{$fif} || 0) + ($rargs->{num_extra} || 0);
    $size ||= 2;
    my $out = $self->render_label($rargs);
    my $index = 0;
    while ( $size ) {
       my $value = shift @$fif;
       $value = defined $value ? $value : '';
       my $element = $self->render_input({%$rargs, fif => $value, id => $rargs->{id} . $index++ });
       $out .= $self->element_wrapper($rargs, $element);
       $size--;
    }
    return $out;
}

sub render_layout_display {
  my ( $self, $rargs ) = @_;

  # render the field layout
  my $layout = $rargs->{layout} || $self->display_layout;
  my $layout_meth = $self->can("layout_$layout");
  die "layout method '$layout' not found" unless $layout_meth;
  my $out = '';
  $out .= $layout_meth->($self, $rargs);
  return $out;
}

sub layout_span {
  my ( $self, $rargs ) = @_;

    my $out= '<span';
    $out .= ' id="' . $rargs->{id} . '"';
    $out .= process_attrs($rargs->{element_attr});
    $out .= '>';
    $out .= $rargs->{fif};
    $out .= '</span>';
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Renderer::Base - Renderer

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Base functionality for renderers, including rendering standard form controls.

You can use this base renderer if it does everything that you need. The
various attributes can be set in a form class:

  sub build_renderer_args { { error_tag => 'label' } }

In many cases you might want to create your own custom renderer class which inherits
from this one. In it you can set the various standard defaults for your
rendering, and override some of the methods, like 'render_errors'. You can
also create custom layouts using the layout sub naming convention so they can
be found.

There is a 'render_hook' which can be used to customize things like classes and
attributes. It is called on every 'render_field', 'render_element', 'render_errors',
and 'render_label' call. The hook can be used in a custom renderer or in the form class,
whichever is most appropriate.

This base renderer is supplied as a library of useful routines. You could replace it
entirely if you want, as long you implement the methods that are used in the form
and field classes.

The rendering is always done using a 'render_args' hashref of the pieces of the form
and field that are needed for rendering. Instead of having lots of rendering attributes
in the fields, with additional rendering pieces and settings in other attributes (like
the 'tags' hashref in FormHandler, most of the rendering settings are passed along
as keys in the render_args hashref.

The 'render_args' can be defined in a field definition:

  has_field 'foo' => ( type => 'Text', render_args => { element => { class => ['abc', 'def'] }} );
  or
  has_field 'foo' => ( type => 'Text', 'ra.ea.class' => ['abc', 'def'] );

Or passed in on a render call:

  $field->render({ 'ea.class' => 'abc' });

If you have custom rendering code that depends on some new flag, you
can just start using a new render_args hashref key in your custom code
without having to do anything special to get it there. You have to set it somewhere
of course, either in the field definition or passed in on the rendering calls.

For a particular field, the field class will supply a 'base_render_args', which is
merged with the 'render_args' from the field definition, which is merged with
the 'render_args' from the actual rendering call.

One of the main goals of this particular rendering iteration has been to make
it easy and seamless to limit rendering to only the field elements, so that all
of the complicated divs and classes that are necessary for recent 'responsive'
CSS frameworks can be done in the templates under the control of the frontend
programmers.

  [% form.field('foo').render_element({ class => 'mb10 tye', placeholder => 'Type...'}) %]

Or render the element, the errors and the labels, and do all of the other formatting
in the template:

   [% field = form.field('foo') %]
   <div class="sm tx10">
      [% field.render_label({ class="cxx" }) %]
      <div class="xxx">
        [% field.render_element({ class => 'mb10 tye', placeholder => 'Type...'}) %]
      </div>
      <div class="field-errors">[% field.render_errors %]</div>
   </div>

Another goal has been to make it possible to render a form automatically
and have it just work.

  [% form.render %]

=head2 Renderer attributes

In a form class:

  sub build_renderer_args { { error_tag => 'label', cb_layout => 'cbwrll' } }

In a Renderer subclass:

  has '+error_tag' => ( default => 'label' );
  has '+cb_layout' => ( default => 'cbwrll' );

=over 4

=item standard_layout

For normal inputs and select fields.

Provided:

  lbl_ele_err    - label, element, error
  lbl_wrele_err  - label, wrapped element, error

Create new layouts starting with 'layout_<name>'.

=item cb_layout

Default checkbox layout. Create new checkbox layouts with methods starting
with 'cb_layout_<name>'.

Provided:

   cbwrll - checkbox, wrapped, label left
   cbwrlr - checkbox, wrapped, label right
   cbnowrll - checkbox, not wrapped, label left
   cb2l   - checkbox, 2 labels

=item rdgo_layout

Default radiogroup option layout

Provided:

   labels_left
   labels_right

Supply more with 'rdgo_layout_<name>'.

=item cbgo_layout

Default checkbox group option layout

Provided:

   labels_left
   labels_right

Supply more with 'cbgo_layout_<name>'.

=item display_layout

Default 'display' field layout.

Provided:

    span

Provide more options with 'layout_<name>'.

=item field_wrapper

Default field wrapper. Supply more with 'wrapper_<name>'.

Provided:

   simple
   fieldset

=item wrapper_tag

Default wrapper tag. Default: 'div'.

=item error_tag

Default error tag.

=item error_class

The default class added to the rendered errors.

=item render_element_errors

This is for when you are just doing 'render_element', but want to also render
the errors, without having to do a separate call. It's off by default.

=item is_html5

Render using the html5_input_type for the field (if one exists). Currently
the following fields have an html5_input_type: Currency (number), Date (date),
Email (email), Integer (number), URL (url). You can set the html5_input_type
in the field definition.

=back

=head1 NAME

Data::MuForm::Renderer::Base

=head1 Layouts

The 'standard' layouts are for all fields that don't have another layout type.
This includes text fields, selects, and textareas. Create a new layout with 'layout_<layout-name'.
Included layouts are 'lbl_ele_err' and 'no_label'. The default is 'lbl_ele_err', which renders
a label, the form control, and then error messages.

The 'radiogroup' layouts are for radiogroups, which is a 'Select' field layout type.
Create a new layout with 'rd_layout_<layout name>'.
Radiogroup option layouts are named 'rdgo_layout_<layout name>'. The provided layouts
are 'right_label' and 'left_label'.

Checkbox layout methods are named 'cb_layout_<layout name>'. The provided layouts are
'cbwrll' - checkbox wrapped, label left, 'cbwrlr' - checkbox wrapped, label right,
'cb2l' - checkbox with two labels, 'cbnowrll' - checkbox unwrapped, label left.

The checkbox group layouts are another 'Select' field layout type.
Checkbox group options layouts are named 'cbgo_layout_<layout name>'.

=head1 Form and Field methods

In the field:

    render (render_field, render_compound or render_repeatable in the renderer)
    render_element (for standard single elements)
    render_label
    render_errors

In the Select field:

    render_option (for select, radio group and checkbox group)

In the form:

    render (render_form in the renderer)
    render_start
    render_end
    render_errors (render_form_errors in the renderer)

=head2 add_to_class

Utility class used to add to the 'class' key of an attribute hashref,
handling arrayref/not-arrayref, etc. Used to add 'error' and 'required'
classes.

=head2 process_attrs

Takes a hashref of key-value pairs to be rendered into HTML attributes.
Second param ($skip) is keys to skip in the hashref.

All 'values' are html filtered.

=head2 render_input

=head2 render_select

=head2 render_textarea

=head2 render_element

=head2 render_label

=head2 render_errors

=head2 render_checkbox

=head2 cbwrll

Checkbox, wrapped, label left

   <label class="checkbox" for="option1"><input id="option1" name="option1" type="checkbox" value="1" /> Option1 </label>

=head2 cbwrlr

Checkbox wrapped, label right

=head2 cbnowrll

Checkbox not wrapped, label left

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
