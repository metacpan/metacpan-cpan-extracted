# (X)Emacs mode: -*- cperl -*-

package CVX::Utils;

=head1 NAME

CVX::Utils - Placeholder for Package Values.

=head1 SYNOPSIS

  use PACKAGE qw( $PACKAGE $VERSION );

=head1 DESCRIPTION

This module is currently just a placeholder for package-specifics.

Called CVX:: because CVS has the wibbles when handling a directory called
CVS... :-)

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

require 5.005_62;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );
our @EXPORT_OK = qw( $PACKAGE $VERSION );

# Utility -----------------------------

use Carp               qw( croak );
use Fatal              qw( :void open sysopen close seek );

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

=head1 CLASS CONSTANTS

Z<>

=cut

use vars qw( $PACKAGE $VERSION );
$PACKAGE = 'CVSUtils';
$VERSION = '1.01';

# ----------------------------------------------------------------------------

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2001, 2002, 2003 Martyn J. Pearce.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1; # keep require happy.

__END__
