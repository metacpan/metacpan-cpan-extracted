package Biblio::Zotero::DB::Library;
$Biblio::Zotero::DB::Library::VERSION = '0.004';
use strict;
use warnings;
use Moo;
use Biblio::Zotero::DB::Library::Trash;
use Biblio::Zotero::DB::Library::Unfiled;

has _db => ( is => 'ro', weak_ref => 1 );

sub collections {
	my $self = shift;
	$self->_db->schema->resultset('Collection');
}

has name => ( is => 'ro', default => sub { 'My Library' } );

sub items {
	my $self = shift;
	my $schema = $self->_db->schema;
	$schema->resultset('StoredItem')
		->with_item_attachment_resultset('StoredItemAttachment')
		->_toplevel_items;
}

sub trash {
	my $self = shift;
	Biblio::Zotero::DB::Library::Trash->new( _db => $self->_db );
}

sub unfiled {
	my $self = shift;
	Biblio::Zotero::DB::Library::Unfiled->new( _db => $self->_db );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Library

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 name

TODO

=head1 METHODS

=head2 collections

TODO

Biblio::Zotero::DB::Schema::Result::Collection

=head2 items

TODO

=head2 trash

TODO

=head2 unfiled

TODO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
