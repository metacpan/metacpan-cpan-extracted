
package Business::BR;

use 5;
use strict;
use warnings;

#require Exporter;
#our @ISA = qw(Exporter);
#our %EXPORT_TAGS = ( 'all' => [ qw() ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw();

our $VERSION = '0.0022';

1;

__END__

=head1 NAME

Business::BR - Root for namespace of Brazilian business-related modules

=head1 SYNOPSIS

  use Business::BR; # does nothing, it is just a placeholder

=head1 DESCRIPTION

This module is meant to provide a root for the namespace C<Business::BR>.
It is meant as a placeholder to reserve and explain how the
namespace can be used.

To see actual code, take a look at C<Business::BR::*> modules

  http://search.cpan.org/search?query=Business%3A%3ABR&mode=module

=head1 SEE ALSO

The namespace has been chosen based on similar modules
for other countries, like Business::FR::SSN which tests
the French "Numéro de Sécurité Sociale", the 
C<Business::AU::*> L<http://search.cpan.org/search?query=Business%3A%3AAU&mode=module> 
and 
C<Business::CN::*> L<http://search.cpan.org/search?query=Business%3A%3ACN&mode=module>
modules.

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
