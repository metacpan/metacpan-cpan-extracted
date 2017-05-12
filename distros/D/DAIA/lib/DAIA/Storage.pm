use strict;
use warnings;
package DAIA::Storage;
#ABSTRACT: Information about the place where an item is stored
our $VERSION = '0.43'; #VERSION

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://purl.org/ontology/daia/Storage' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DAIA::Storage - Information about the place where an item is stored

=head1 VERSION

version 0.43

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Storage is a subclass of.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
