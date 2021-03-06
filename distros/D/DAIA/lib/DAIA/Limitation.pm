use strict;
use warnings;
package DAIA::Limitation;
#ABSTRACT: Information about specific limitations of availability
our $VERSION = '0.43'; #VERSION

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DAIA::Limitation - Information about specific limitations of availability

=head1 VERSION

version 0.43

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Limitation is a subclass of.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
