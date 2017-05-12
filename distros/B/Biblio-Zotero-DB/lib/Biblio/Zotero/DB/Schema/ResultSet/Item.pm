package Biblio::Zotero::DB::Schema::ResultSet::Item;
$Biblio::Zotero::DB::Schema::ResultSet::Item::VERSION = '0.004';
use strict;
use warnings;
use Moo;

extends 'DBIx::Class::ResultSet';

has _attachment_itemtypeid => ( is => 'ro', default => sub {
	my $self = shift;
	my $attachment_itemtypeid = $self->result_source->schema
		->resultset('ItemType')
		->search({ 'typename' => 'attachment' })
		->single->itemtypeid;
});

has _note_itemtypeid => ( is => 'ro', default => sub {
	my $self = shift;
	my $attachment_itemtypeid = $self->result_source->schema
		->resultset('ItemType')
		->search({ 'typename' => 'note' })
		->single->itemtypeid;
});

has _item_attachment_resultset => ( is => 'rw', default => sub { 'ItemAttachment' } );

# pass the args as is to the parent --- new() takes no params for the current object
sub BUILDARGS { shift; { }; }
sub FOREIGNBUILDARGS { shift; @_; }

sub with_item_attachment_resultset {
	my ($self, $resultset) = @_;
	my $self_clone = $self->search({});
	$self_clone->_item_attachment_resultset($resultset);
	$self_clone;
}

sub search_by_field {
	my ($self, $field_queries) = @_;

	my $schema = $self->result_source->schema;
	my $subqueries;

	while (my ($key, $value) = each %$field_queries) {
		push @$subqueries,
			$schema->resultset('ItemData')->search(
			{
				'fieldid.fieldname' => $key,
				'valueid.value' => $value,
			},
			{
				prefetch => [ 'fieldid', 'valueid' ],
			}
			)->get_column('itemid')->as_query;
	}

	return $self->search_rs(
		{
			-and => [ map {
					{ 'me.itemid' => { '-in' => $_ } }
				} @$subqueries
			],
		},
		{
			prefetch => { 'item_datas' => [ 'fieldid', 'valueid' ] },
		},
	);
}

sub items_with_attachments_of_mimetypes {
	my ($self, @mimetypes) = @_;
	return unless @mimetypes;
	my $subquery = $self->_attachment_subquery({ mimetype => [ -or => @mimetypes ] });

	return $self->search_rs(
		{ 'me.itemid' => { '-in' => $subquery } },
		{
			prefetch => { 'item_datas' => [ 'fieldid', 'valueid' ] },
		},
	);
}

sub items_with_pdf_attachments {
	my ($self) = @_;
	$self->items_with_attachments_of_mimetypes('application/pdf');
}

sub _attachment_subquery {
	my ($self, $search_query) = @_;
	my $schema = $self->result_source->schema;
	my $subquery = $schema->resultset($self->_item_attachment_resultset)
		->search(
			$search_query,
			{ '+columns' =>
				{ outputitemid =>
					\do { "IFNULL(me.sourceitemid, me.itemid)" } },
			}
		)->get_column('outputitemid')->as_query;
}

sub _toplevel_items {
	my $self = shift;
	my $subquery = $self->_attachment_subquery({});
	return $self->search_rs(
		{ -or => [
				{ 'me.itemid' => { '-in' => $subquery } },
				{ 'itemtypeid' => { 'not in', [$self->_attachment_itemtypeid, $self->_note_itemtypeid] } },
			]
		},
		{
			prefetch => { 'item_datas' => [ 'fieldid', 'valueid' ] },
		},
	);
}

sub _trash_items {
	my $self = shift;
	my $schema = $self->result_source->schema;
	# an item is in the trash if either the item itself is in deletedItems.itemid
	my $deleted = $schema->resultset('DeletedItem')
		->get_column('itemid')->as_query;

	# or if it has an attachment that is in deletedItems
	my $deletedAttachment = $schema->resultset('ItemAttachment')
		->search( { 'itemid' => { -in => $deleted } })
		->get_column('sourceitemid')->as_query;

	# or if it has an attachment that is in deletedItems
	my $deletedNote = $schema->resultset('ItemNote')
		->search({ 'itemid' => { -in => $deleted } })
		->get_column('sourceitemid')->as_query;

	my $attached = $schema->resultset('ItemAttachment')
		->search( { 'sourceitemid' => { '!=' => undef } })
		->get_column('itemid')->as_query;

	my $noted = $schema->resultset('ItemNote')
		->search( { 'sourceitemid' => { '!=' => undef } })
		->get_column('itemid')->as_query;

	$schema->resultset('Item')->search(
		{
			-or => [
				{ 'me.itemid' => { -in => $deleted } },
				{ 'me.itemid' => { -in => $deletedAttachment } },
				{ 'me.itemid' => { -in => $deletedNote } },
			]
		},
	)->search(
		{
			-and => [
				{ 'me.itemid' => { 'not in' => $attached } },
				{ 'me.itemid' => { 'not in' => $noted } }
			]
		},
		{
			prefetch => { 'item_datas' => [ 'fieldid', 'valueid' ] },
		},
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::ResultSet::Item

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
