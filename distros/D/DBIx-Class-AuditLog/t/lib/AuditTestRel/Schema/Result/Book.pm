package AuditTestRel::Schema::Result::Book;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('AuditLog');

__PACKAGE__->table('book');

__PACKAGE__->add_columns(
	"id",
	{
		data_type => "integer",
		extra => { unsigned => 1 },
		is_auto_increment => 1,
		is_nullable => 0,
	},
	"title_id",
	{
		data_type => "integer",
		extra => { unsigned => 1 },
		is_nullable => 0,
	},
	"isbn",
	{ data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "title",
   "AuditTestRel::Schema::Result::Title",
   { "id" => "title_id" },
);

__PACKAGE__->has_many(
  "bookauthors",
   "AuditTestRel::Schema::Result::BookAuthor",
   'book_id'
);


__PACKAGE__->many_to_many(
	'authors', 'bookauthors', 'author'
);

1;

