package Data::MuForm::Field::Button;
# ABSTRACT: Button field

use Moo;
extends 'Data::MuForm::Field';

has 'value' => ( is => 'rw', default => 'Save' );
has '+no_update'  => ( default => 1 );

sub build_form_element { 'button' }
sub build_input_type { 'button' }

sub no_fif {1}
sub fif { shift->value }

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{layout_type} = 'element';
    $args->{wrapper} = 'none';
    return $args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Button - Button field

=head1 VERSION

version 0.04

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
