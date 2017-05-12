package Bread::Board::Declare::Meta::Role::Attribute;
BEGIN {
  $Bread::Board::Declare::Meta::Role::Attribute::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Meta::Role::Attribute::VERSION = '0.16';
}
use Moose::Role;
# ABSTRACT: base attribute metarole for Bread::Board::Declare

use Moose::Util 'does_role', 'find_meta';

use Bread::Board::Declare::Meta::Role::Attribute::Container;
use Bread::Board::Declare::Meta::Role::Attribute::Service;


has service => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

# this is kinda gross, but it's the only way to hook in at the right place
# at the moment, it seems
around interpolate_class => sub {
    my $orig = shift;
    my $class = shift;
    my ($options) = @_;

    # we only want to do this on the final recursive call
    return $class->$orig(@_)
        if $options->{metaclass};

    return $class->$orig(@_)
        if exists $options->{service} && !$options->{service};

    my ($new_class, @traits) = $class->$orig(@_);

    return wantarray ? ($new_class, @traits) : $new_class
        if does_role($new_class, 'Bread::Board::Declare::Meta::Role::Attribute::Service')
        || does_role($new_class, 'Bread::Board::Declare::Meta::Role::Attribute::Container');

    my $parent = @traits
        ? (find_meta($new_class)->superclasses)[0]
        : $new_class;
    push @{ $options->{traits} }, 'Bread::Board::Declare::Meta::Role::Attribute::Service';

    return $parent->interpolate_class($options);
};

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Bread::Board::Declare::Meta::Role::Attribute - base attribute metarole for Bread::Board::Declare

=head1 VERSION

version 0.16

=head1 ATTRIBUTES

=head2 service

Whether or not to create a service for this attribute. Defaults to true.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
