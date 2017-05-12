package Data::MuForm::Model::Object;
# ABSTRACT: stub for Object model

use Moo::Role;

sub update_model {
    my $self = shift;

    my $model = $self->model;
    return unless $model;
    foreach my $field ( $self->sorted_fields ) {
        my $name = $field->name;
        next unless $model->can($name);
        $model->$name( $field->value );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Model::Object - stub for Object model

=head1 VERSION

version 0.04

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
