package Biblio::Zotero::DB::Schema::Result::StoredItem;
$Biblio::Zotero::DB::Schema::Result::StoredItem::VERSION = '0.004';
# TODO: document

use strict;
use warnings;
use base qw/Biblio::Zotero::DB::Schema::Result::Item/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('storedItems');
__PACKAGE__->result_source_instance->is_virtual(1);

# NOTE: SQL
__PACKAGE__->result_source_instance->view_definition(
	q[
	SELECT * FROM items me
		WHERE ( itemid NOT IN ( SELECT me.itemid FROM deletedItems me ) )
	]
);
# the above view_definition is the same as:
# ----------------------------------------
# my $deleted = $schema->resultset('DeletedItem')
# 	->get_column('itemid')
# 	->as_query
# $schema
# 	->resultset('Item')
# 	->search( { itemid => { 'not in' => $deleted } })
# 	->as_query

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::StoredItem

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
