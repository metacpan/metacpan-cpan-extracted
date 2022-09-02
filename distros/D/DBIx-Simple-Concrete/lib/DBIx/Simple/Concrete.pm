use 5.006; use strict; use warnings;

package DBIx::Simple::Concrete;

our $VERSION = '1.007';

use DBIx::Simple ();
use SQL::Concrete ();

sub import {
	shift;
	my $prelude = sprintf qq'package %s;\n#line %d "%s"\n', ( caller )[0,2,1];
	my $sub = eval qq{ sub { $prelude SQL::Concrete->import(\@_) } };
	&$sub;
}

sub cquery { shift->query( SQL::Concrete::Renderer->new->render( @_ ) ) }

die 'Too late to patch DBIx::Simple' if DBIx::Simple->can( 'cquery' );

*DBIx::Simple::cquery = \&cquery;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simple::Concrete - monkey-patch DBIx::Simple to use SQL::Concrete

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

This software is copyright (c) 2022 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
