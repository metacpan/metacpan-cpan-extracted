package Data::MuForm::Field::Submit;
# ABSTRACT: Submit field

use Moo;
extends 'Data::MuForm::Field';

has 'value' => ( is => 'rw', default => 'Save' );
has '+no_update'  => ( default => 1 );

sub build_input_type { 'submit' }

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

Data::MuForm::Field::Submit - Submit field

=head1 VERSION

version 0.05

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
