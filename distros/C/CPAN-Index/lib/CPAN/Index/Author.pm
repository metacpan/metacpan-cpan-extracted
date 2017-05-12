package CPAN::Index::Author;

use strict;
use base 'DBIx::Class';
use Email::Address ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_components('Core');

__PACKAGE__->table('author');

__PACKAGE__->add_columns(
	id => {
		data_type         => 'varchar',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	name => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	email => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	);

__PACKAGE__->set_primary_key('id');

sub address {
	Email::Address->new( $_[0]->name => $_[0]->email );
}

1;

__END__

=pod

=head1 NAME

CPAN::Index::Author - An object representing a CPAN author

=head1 DESCRIPTION

B<CPAN::Index::Author> object represent CPAN authors in the index.

=head1 METHODS

=head2 id

The C<id> accessor returns the author's CPAN id.

This is a capitalized string. For example, the author's CPAN id is "ADAMK".

=head2 name

The C<name> accessor returns the full name of the CPAN author

=head2 email

The C<email> accessor returns the email address of the CPAN author

=head2 address

The C<address> method returns the email address of the CPAN author, but as
a full name-inclusive L<Email::Address> object.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Index>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

C<load_authors> based on L<Parse::CPAN::Authors> by Leon Brocard E<lt>acme@cpan.orgE<gt>

=head1 SEE ALSO

L<CPAN::Index>, L<Parse::CPAN::Authors>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
