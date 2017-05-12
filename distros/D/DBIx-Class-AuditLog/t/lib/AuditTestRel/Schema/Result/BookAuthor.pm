package AuditTestRel::Schema::Result::BookAuthor;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('AuditLog');

__PACKAGE__->table('bookauthor');

__PACKAGE__->add_columns(
	"book_id",
	{
		data_type => "integer",
		extra => { unsigned => 1 },
		is_nullable => 0,
	},
	"author_id",
	{
		data_type => "integer",
		extra => { unsigned => 1 },
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key("book_id","author_id");

__PACKAGE__->belongs_to(
  "book",
   "AuditTestRel::Schema::Result::Book",
   { "id" => "book_id" },
);

__PACKAGE__->belongs_to(
  "author",
   "AuditTestRel::Schema::Result::Person",
   { "id" => "author_id" },
);

1;


