package Data::MuForm::Field::Repeatable::Instance;
# ABSTRACT: used internally by repeatable fields

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Field::Compound';


sub BUILD {
    my $self = shift;
}

has '+no_value_if_empty' => ( default => 1 );

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{no_label} = 1;
    $args->{is_instance} = 1;
    return $args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Repeatable::Instance - used internally by repeatable fields

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This is a simple container class to hold an instance of a Repeatable field.
It will have a name like '0', '1'... Users should not need to use this class.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
