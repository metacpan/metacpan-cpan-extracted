package Data::MuForm::Field::Textarea;
# ABSTRACT: textarea input

use Moo;
extends 'Data::MuForm::Field::Text';
use Types::Standard -types;

sub build_form_element { 'textarea' }

has 'cols'    => ( is => 'rw', default => 40 );
has 'rows'    => ( is => 'rw', default => 5 );

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{element_attr}->{cols} = $self->cols if $self->cols;
    $args->{element_attr}->{rows} = $self->rows if $self->rows;
    return $args;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Textarea - textarea input

=head1 VERSION

version 0.04

=head1 Summary

For HTML textarea

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
