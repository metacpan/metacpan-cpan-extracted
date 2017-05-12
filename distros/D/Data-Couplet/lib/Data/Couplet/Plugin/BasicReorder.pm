use strict;
use warnings;

package Data::Couplet::Plugin::BasicReorder;
BEGIN {
  $Data::Couplet::Plugin::BasicReorder::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::Plugin::BasicReorder::VERSION = '0.02004314';
}

# ABSTRACT: A D::C Plug-in to reorder data in your data set.

# $Id:$
use Moose::Role;
use namespace::autoclean;

with 'Data::Couplet::Role::Plugin';



sub move_up {
  my ( $self, $object, $stride ) = @_;
  return $self;
}


sub move_down {
  my ( $self, $object, $stride ) = @_;
  return $self;
}


sub swap {
  my ( $self, $key_left, $key_right ) = @_;
  return $self;
}

no Moose::Role;

1;


__END__
=pod

=head1 NAME

Data::Couplet::Plugin::BasicReorder - A D::C Plug-in to reorder data in your data set.

=head1 VERSION

version 0.02004314

=head1 SYNOPSIS

This is currently a whopping big TODO.

Patches welcome.

=head1 METHODS

=head3 ->move_up( Any $object | String $key , Int $amount ) : $self : Modifier

=head3 ->move_down( Any $object | String $key , Int $amount ) : $self : Modifier

=head3 ->swap( Any|Str $key_left, Any|Str $key_right  ) : $self : Modifier

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

