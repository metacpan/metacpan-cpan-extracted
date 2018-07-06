package Data::MuForm::Field::Display;
# ABSTRACT: display only field

use Moo;
extends 'Data::MuForm::Field';


has '+no_update'  => ( default => 1 );

sub no_fif {1}
sub fif { shift->value }

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{layout_type} = 'display';
    $args->{layout} = 'span';
    $args->{no_label} = 1;
    return $args;
}

has 'html' => ( is => 'rw', predicate => 1 );

has 'render_method' => ( is => 'rw', predicate => 1 );

sub render {
    my $self = shift;

    return $self->html if $self->has_html;
    my $rargs = $self->get_render_args;
    return $self->render_method->($self, $rargs) if $self->has_render_method;
    if ( $self->form ) {
        my $form_meth = "html_" . $self->convert_full_name($self->full_name);
        if ( $self->form->can($form_meth) ) {
          return $self->form->$form_meth($rargs);
        }
    }
    return $self->next::method($rargs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Display - display only field

=head1 VERSION

version 0.05

=head1 SYNOPSIS

This class can be used for fields that are display only. It will
render the value returned by a form's 'html_<field_name>' method,
or the field's 'html' attribute.

  has_field 'explanation' => ( type => 'Display',
     html => '<p>This is an explanation...</p>' );

or in a form:

  has_field 'explanation' => ( type => 'Display' );
  sub html_explanation {
     my ( $self, $field ) = @_;
     if( $self->something ) {
        return '<p>This type of explanation...</p>';
     }
     else {
        return '<p>Another type of explanation...</p>';
     }
  }
  #----
  has_field 'username' => ( type => 'Display' );
  sub html_username {
      my ( $self, $field ) = @_;
      return '<div><b>User:&nbsp;</b>' . $field->value . '</div>';
  }

or set the name of the rendering method:

   has_field 'explanation' => ( type => 'Display', set_html => 'my_explanation' );
   sub my_explanation {
     ....
   }

or provide a 'render_method':

   has_field 'my_button' => ( type => 'Display', render_method => \&render_my_button );
   sub render_my_button {
       my $self = shift;
       ....
       return '...';
   }

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
