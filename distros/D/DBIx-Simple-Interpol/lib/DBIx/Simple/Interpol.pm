use 5.006; use strict; use warnings;

package DBIx::Simple::Interpol;

our $VERSION = '1.007';

use SQL::Interpol ();
use DBIx::Simple ();

sub import {
	shift;
	my $prelude = sprintf qq'package %s;\n#line %d "%s"\n', ( caller )[0,2,1];
	my $sub = eval qq{ sub { $prelude SQL::Interpol->import(\@_) } };
	&$sub;
}

sub iquery {
	my $self = shift;
	my $p = SQL::Interpol::Parser->new;
	my $sql = $p->parse( @_ );
	$self->query( $sql, @{ $p->bind } );
}

die 'Cannot find method to patch' if not DBIx::Simple->can( 'iquery' );

do { no warnings 'redefine'; *DBIx::Simple::iquery = \&iquery };

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simple::Interpol - monkey-patch DBIx::Simple to use SQL::Interpol

=head1 SYNOPSIS

  use DBIx::Simple::Interpol;
  # ...
  my $rows = $db->iquery( '
      SELECT title
      FROM threads
      WHERE date >', \$x, '
      AND subject IN', \@subjects, '
  ' )->arrays;

=head1 DESCRIPTION

The recommended way to use L<SQL::Interpol> is via its L<DBIx::Simple>
integration, which provides an excellent alternative to plain DBI access.

Ordinarily, the C<iquery> method in L<DBIx::Simple> integrates L<SQL::Interp>.
But by loading this module instead (or after) L<DBIx::Simple>, the C<iquery>
method will be patched to use L<SQL::Interpol> instead.

This is all there is to this module.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
