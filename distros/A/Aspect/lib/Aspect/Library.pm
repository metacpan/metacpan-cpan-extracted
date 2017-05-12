package Aspect::Library;

use strict;

our $VERSION = '1.04';

1;

__END__

=pod

=head1 NAME

Aspect::Library - Base class for all reusable aspects

=head1 DESCRIPTION

B<Aspect::Library> provides a base class for all reusable aspects,
regardless of implementation.

It was created as part of the L<Aspect> namespace reorganisation. It
provides no functionality, and only acts as a method for identifying
L<Aspect> libraries.

The original first generation of libraries are implemented via the
L<Aspect::Modular> class and are deeply tied to it. For the second
generation API this lower level base class is provided to provide
a mechanism for identifying all reusable library aspects, from either
the L<Aspect::Modular> API or independently.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
