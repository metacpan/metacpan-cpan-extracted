package Biblio::SICI::Role::RecursiveLink;
{
  $Biblio::SICI::Role::RecursiveLink::VERSION = '0.04';
}

# ABSTRACT: Role to provide a "link" to the parent Biblio::SICI

use strict;
use warnings;

use Moo::Role;
use Sub::Quote;


has '_sici' => (
	is       => 'ro',
	required => 1,
	isa      => quote_sub(q{ my ($val) = @_; die unless ( $val->isa('Biblio::SICI') ) }),
	weak     => 1,
);


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI::Role::RecursiveLink - Role to provide a "link" to the parent Biblio::SICI

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A role that provides an attribute used to provide internal access 
to the parent C<Biblio::SICI> object from the three segment classes.

B<For internal use only!>

=head1 ATTRIBUTES

=over 4

=item _sici

Weak ref to the parent object.

=back

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
