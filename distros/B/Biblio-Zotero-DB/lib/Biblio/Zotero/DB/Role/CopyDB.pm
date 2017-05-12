package Biblio::Zotero::DB::Role::CopyDB;
# ABSTRACT: A role to copy the database to a temporary file.
$Biblio::Zotero::DB::Role::CopyDB::VERSION = '0.004';
use strict;
use warnings;
use Moo::Role;

use File::Temp;
use File::Copy;
use Path::Class;

has db_file_temp => ( is => 'rw', builder => 1, lazy => 1, clearer => 1);

sub _build_db_file_temp {
	return File::Temp->new();
}

around schema => sub {
	my $orig = shift;
	my $self = $_[0];

	my $orig_db_file = $self->db_file;
	my $copy_db_file = "@{[$self->db_file_temp]}";
		# for L<File::Temp>, this will call ->filename on it

	copy($orig_db_file, $copy_db_file) or die "could not copy $orig_db_file to $copy_db_file";

	$self->db_file($copy_db_file); # swap the copy in
	my $ret = $orig->(@_); # get the schema
	$self->db_file($orig_db_file); # restore the original
	$ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Role::CopyDB - A role to copy the database to a temporary file.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Biblio::Zotero::DB;
  use Moo::Role;

  $db = Biblio::Zotero::DB->new();
  Moo::Role->apply_roles_to_object($db, 'Biblio::Zotero::DB::Role::CopyDB');
  $db->schema; # this will use a copy of the database file

=head1 DESCRIPTION

It is likely to that you might have Zotero open while using
L<Biblio::Zotero::DB>. This causes problems as the database file will be locked
as long as Zotero is running. To get around that, applying this role will
create a copy whenever the C<L<schema|Biblio::Zotero::DB/schema>> attribute of L<Biblio::Zotero::DB> is
built.

=head1 ATTRIBUTES

=head2 db_file_temp

A string that is used to determine where to store the copy of the
L<database file|Biblio::Zotero::DB/db_file>. By default, this is built as a
L<File::Temp>.

=over 4

=item * This must be a writable file or retrieving the
C<L<schema|Biblio::Zotero::DB/schema>> will C<die>.

=item * This can be cleared using the method C<clear_db_file_temp>.

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
