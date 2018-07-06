package Data::MuForm::Field::Checkbox;
# ABSTRACT: Checkbox field
use Moo;
extends 'Data::MuForm::Field';


has 'size' => ( is => 'rw', default => 0 );

has 'checkbox_value' => ( is => 'rw', default => 1 );
has '+input_without_param' => ( default => 0 );
#has 'option_label'         => ( is => 'rw' );
#has 'option_wrapper'       => ( is => 'rw' );

sub build_input_type { 'checkbox' }

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{checkbox_value} = $self->checkbox_value;
    $args->{layout_type} = 'checkbox';
    return $args;
}


sub validate {
    my $self = shift;

    $self->add_error($self->get_message('required'), field_label => $self->loc_label) if( $self->required && !$self->value );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Checkbox - Checkbox field

=head1 VERSION

version 0.05

=head1 DESCRIPTION

Render args:
  option_label
  option_wrapper

=head1 NAME

Data::MuForm::Field::Checkbox

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
