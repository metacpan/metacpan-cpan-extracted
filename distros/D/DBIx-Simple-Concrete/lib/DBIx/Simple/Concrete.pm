use 5.006;
use strict;
no warnings;

package DBIx::Simple::Concrete;
$DBIx::Simple::Concrete::VERSION = '1.001';
# ABSTRACT: monkey-patch DBIx::Simple to use SQL::Concrete

BEGIN {
	require SQL::Concrete;
	require DBIx::Simple;
	require Import::Into;
	die 'Too late to patch DBIx::Simple' if DBIx::Simple->can( 'cquery' );
	*DBIx::Simple::cquery = sub {
		use warnings; # limited scope to avoid "Subroutine redefined"
		my $self = shift;
		return $self->query( SQL::Concrete::Renderer->new->render( @_ ) );
	};
}

sub import { shift; SQL::Concrete->import::into( scalar caller, @_ ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simple::Concrete - monkey-patch DBIx::Simple to use SQL::Concrete

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use DBIx::Simple::Concrete;
 # ...
 my $rows = $db->cquery( '
     SELECT title
     FROM threads
     WHERE date >', \$date, '
     AND', { subject => \@subjects }, '
 ' )->arrays;

=head1 DESCRIPTION

The recommended way to use L<SQL::Concrete> is via its L<DBIx::Simple>
integration, which provides an excellent alternative to plain DBI access.

But by loading this module instead (or after) L<DBIx::Simple>, a C<cquery>
method will be added to it which integrates L<SQL::Concrete> just the same
way as its built-in C<iquery> method integrates L<SQL::Interp>.

This is all there is to this module.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
