package Bread::Board::Declare::Literal;
BEGIN {
  $Bread::Board::Declare::Literal::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Literal::VERSION = '0.16';
}
use Moose;
# ABSTRACT: subclass of Bread::Board::Literal for Bread::Board::Declare


extends 'Bread::Board::Literal';
with 'Bread::Board::Declare::Role::Service';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Bread::Board::Declare::Literal - subclass of Bread::Board::Literal for Bread::Board::Declare

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is a custom subclass of L<Bread::Board::Literal> which does the
L<Bread::Board::Declare::Role::Service> role. See those two modules for more
details.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
