package Data::MuForm::Field::Hidden;
# ABSTRACT: hidden field

use Moo;
extends 'Data::MuForm::Field::Text';

sub build_input_type { 'hidden' }


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

Data::MuForm::Field::Hidden - hidden field

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is a 'convenience' text field that uses the 'hidden' type.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
