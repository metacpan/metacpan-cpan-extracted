package CPAN::Index::Package;

use strict;
use base 'DBIx::Class';
use version ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_components('Core');

__PACKAGE__->table('package');

__PACKAGE__->add_columns(
	name => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	version => {
		accessor          => 'version_string',
		data_type         => 'varchar',
		size              => 32,
		is_nullable       => 1,
		is_auto_increment => 0,
		default_value     => '',
		},
	path => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	);

__PACKAGE__->set_primary_key('name');

sub version {
	my $self  = shift;
	my $value = $self->version_string(@_);
	defined($value) ? version->new($value) : undef;
}

1;

__END__

=pod

=head1 NAME

CPAN::Index::Package - An object representing a CPAN package

=head1 DESCRIPTION

B<CPAN::Index::Package> object represent CPAN packages in the index.

=head1 METHODS

=head2 name

The C<name> accessor returns the package namespace.

This is a valid Perl package name, such as "Foo::Bar".

=head2 version

The C<version> accessor returns the current version of the package.

Returns a L<version> object, or C<undef> if the package is unversioned.

=head2 path

The C<path> accessor returns the package's location, as a path relative
to the CPAN author root.

That is, a string in the form "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz".

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Index>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<CPAN::Index>, L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
