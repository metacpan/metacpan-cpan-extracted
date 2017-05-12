package Data::MuForm::Field::PrimaryKey;
# ABSTRACT: primary key field

use Moo;
extends 'Data::MuForm::Field';
use Types::Standard -types;


has 'is_primary_key' => ( isa => Bool, is => 'ro', default => '1' );
has '+no_value_if_empty' => ( default => 1 );

sub BUILD {
    my $self = shift;
    if ( $self->has_parent ) {
        if ( $self->parent->has_primary_key ) {
            push @{ $self->parent->primary_key }, $self;
        }
        else {
            $self->parent->primary_key( [ $self ] );
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::PrimaryKey - primary key field

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This field is for providing the primary key for Repeatable fields:

   has_field 'addresses' => ( type => 'Repeatable' );
   has_field 'addresses.address_id' => ( type => 'PrimaryKey' );

Do not use this field to hold the primary key of the form's main db object (model).
That primary key is in the 'model_id' attribute.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
