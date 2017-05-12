package Books::Result::Book;

use DBIx::Class::Candy;

table 'book';

column 'id' => {
    data_type => 'int',
    is_auto_increment => 1,
};

column 'title' => {
    data_type => 'varchar',
    size      => 1000,
};

column 'author_id' => {
    data_type      => 'int',
    is_foreign_key => 1,
    is_nullable    => 1,
};

primary_key 'id';

has_many 'book_genres' => ( 'Books::Result::BookGenre', 'book_id' );
many_to_many 'genres' => ( 'book_genres', 'genre' );
belongs_to 'author' => ( 'Books::Result::Author', 'author_id' );

1;
