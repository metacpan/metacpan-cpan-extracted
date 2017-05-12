package Bread::Board::Declare::Meta::Role::Class;
BEGIN {
  $Bread::Board::Declare::Meta::Role::Class::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Meta::Role::Class::VERSION = '0.16';
}
use Moose::Role;
# ABSTRACT: class metarole for Bread::Board::Declare

use Bread::Board::Service;
use Class::Load qw(load_class);



sub get_all_services {
    my $self = shift;
    return map { $_->associated_service }
           grep { Moose::Util::does_role($_, 'Bread::Board::Declare::Meta::Role::Attribute::Service') }
           $self->get_all_attributes;
}

before superclasses => sub {
    my $self = shift;

    return unless @_;

    die "Multiple inheritance is not supported for Bread::Board::Declare classes"
        if @_ > 1;

    load_class($_[0]);

    return if $_[0]->isa('Bread::Board::Container');

    die "Cannot inherit from " . join(', ', @_)
      . " because Bread::Board::Declare classes must inherit"
      . " from Bread::Board::Container";
};

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Bread::Board::Declare::Meta::Role::Class - class metarole for Bread::Board::Declare

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This role adds functionality to the metaclass of L<Bread::Board::Declare>
classes.

=head1 METHODS

=head2 get_all_services

Returns all of the services that are associated with attributes in this class.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
