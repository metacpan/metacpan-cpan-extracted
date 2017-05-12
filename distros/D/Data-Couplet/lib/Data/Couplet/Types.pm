use strict;
use warnings;

package Data::Couplet::Types;
BEGIN {
  $Data::Couplet::Types::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::Types::VERSION = '0.02004314';
}

# ABSTRACT: Various type-constraints for working with D::C and Moose

use MooseX::Types::Moose qw( :all );
use MooseX::Types -declare => [
  qw(
    DataCouplet
    DataCoupletImpl
    DataCoupletPlugin
    )
];


class_type DataCouplet, { class => 'Data::Couplet' };

coerce DataCouplet, from ArrayRef, via {
  require Data::Couplet;
  return Data::Couplet->new( @{$_} );
};

coerce DataCouplet, from HashRef, via {
  require Data::Couplet;
  return Data::Couplet->new( %{$_} );
};


class_type DataCoupletImpl, { class => 'Data::Couplet::Private' };


role_type DataCoupletPlugin, { role => 'Data::Couplet::Role::Plugin' };

1;


__END__
=pod

=head1 NAME

Data::Couplet::Types - Various type-constraints for working with D::C and Moose

=head1 VERSION

version 0.02004314

=head1 EXPORTED TYPES

=head2 DataCouplet

All children of Data::Couplet.

=head3 COERCIONS

=head4 ArrayRef

Will behave as if somebody had done

  Data::Couplet->new( @{ $arrayref });

=head4 HashRef

As for ArrayRef, but don't try thinking it will retain order.

=head2 DataCoupletImpl

Anything that implements something like Data::Couplet.

That is, any descendant of Data::Couplet::Private

All DataCouplet instances should also be DataCoupletImpl instances.

=head2 DataCoupletPlugin

Plugins

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

