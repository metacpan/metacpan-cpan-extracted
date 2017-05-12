use utf8;
package Biblio::Zotero::DB::Schema;
$Biblio::Zotero::DB::Schema::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UlX+tV+7vyST2GUwO/11dw

# NOTE: extended DBIC schema below

use Moo;
use Path::Class;
use Path::Class::URI;

extends 'DBIx::Class::Schema';


has zotero_storage_directory => ( is => 'rw' );

around connection => sub {
	my ( $inner, $self, $dsn, $username, $pass, $attr ) = ( shift, @_ );

	$self->zotero_storage_directory(dir(
		delete $attr->{zotero_storage_directory}
	)->absolute) if(exists $attr->{zotero_storage_directory});

	$attr->{ReadOnly} = 1; # force to be readonly
  $attr->{sqlite_unicode} = 1; # strings are UTF-8
  # there are no SQL_BLOB types in the schema, so this should be fine

	$inner->(@_);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  $schema = Biblio::Zotero::DB::Schema->connect(
    'dbi:SQLite:dbname='.'/path/to/profile/zotero.sqlite',
    '', '',
    { zotero_storage_directory => '/path/to/profile/storage' },
  );

=head1 ATTRIBUTES

=head2 zotero_storage_directory

a string the storage directory for attachments associated with the database.
This is optional and can be set by using the connection attribute
C<zotero_storage_directory>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
