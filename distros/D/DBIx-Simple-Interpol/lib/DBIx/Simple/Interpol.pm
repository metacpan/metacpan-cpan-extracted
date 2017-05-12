use 5.006;
use strict;
no warnings;

package DBIx::Simple::Interpol;
$DBIx::Simple::Interpol::VERSION = '1.005';
# ABSTRACT: monkey-patch DBIx::Simple to use SQL::Interpol

use Exporter::Tidy _map => {
	sql_interp => \&SQL::Interpol::sql_interp,
	sql        => \&SQL::Interpol::sql,
};

BEGIN {
	require SQL::Interpol;
	require DBIx::Simple;
	die 'Cannot find method to patch' if not DBIx::Simple->can( 'iquery' );
	*DBIx::Simple::iquery = sub {
		use warnings; # limited scope to avoid "Subroutine redefined"
		my $self = shift;
		my $p = SQL::Interpol::Parser->new;
		my $sql = $p->parse( @_ );
		return $self->query( $sql, @{ $p->bind } );
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simple::Interpol - monkey-patch DBIx::Simple to use SQL::Interpol

=head1 VERSION

version 1.005

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

This software is copyright (c) 2014 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
