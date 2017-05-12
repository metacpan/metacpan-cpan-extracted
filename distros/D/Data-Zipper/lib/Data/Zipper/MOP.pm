package Data::Zipper::MOP;
BEGIN {
  $Data::Zipper::MOP::VERSION = '0.02';
}
# ABSTRACT: A zipper for MOP based objects

use warnings FATAL => 'all';
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( Object Str ArrayRef );
use MooseX::Types::Structured qw( Tuple );

with 'Data::Zipper::API' => { type => Tuple[ Str, Object ] };

sub traverse {
    my ($self, $path) = @_;
    return (
        $self->focus->$path,
        [ $path, $self->focus ],
    );
}

sub reconstruct {
    my ($self, $value, $path) = @_;
    my ($key, $object) = @$path;
    $object->meta->clone_object(
        $object,
        $key => $value
    );
}

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::Zipper::MOP - A zipper for MOP based objects

=head1 METHODS

=head2 traverse

Traverse into the object under focus, by moving into the value of an attribute
with a given name. Currently assumes the reader is the same as the name.

=head2 reconstruct

(internal)

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

