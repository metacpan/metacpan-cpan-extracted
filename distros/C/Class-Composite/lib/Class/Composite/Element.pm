=head1 NAME

Class::Composite::Element - Element of a Collection::Container

=head1 SYNOPSIS

  use Class::Composite::Element;
  use Class::Composite::Container;
  my $element = Class::Composite::Element->new();
  my $collection = Class::Composite::Container->new();
  $collection->addElement( $elem );

=head1 DESCRIPTION

Used to differenciate elements from containers within a collection

=head1 INHERITANCE

Class::Composite

=head1 INTERFACE

None

=cut
package Class::Composite::Element;

use strict;
use warnings::register;

use base qw ( Class::Composite );

our $VERSION = 0.1;



1;

__END__

=head1 SEE ALSO

Class::Composite, Class::Composite::Container

=head1 AUTHOR

"Pierre Denis" <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2002, Fotango Ltd. All rights reserved.

This is free software. This software
may be modified and/or distributed under the same terms as Perl
itself.

=cut
