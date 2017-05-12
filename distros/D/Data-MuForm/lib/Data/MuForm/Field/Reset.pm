package Data::MuForm::Field::Reset;
# ABSTRACT: reset field

use Moo;
extends 'Data::MuForm::Field';


has 'value' => ( is => 'rw', default => 'Reset' );
has '+no_update'  => ( default => 1 );

sub build_input_type { 'reset' }

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

Data::MuForm::Field::Reset - reset field

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Use this field to declare a reset field in your form.

   has_field 'reset' => ( type => 'Reset', value => 'Restore' );

Uses the 'reset' widget.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
