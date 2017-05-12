package Books::Result::BookGenre;

use DBIx::Class::Candy;

table 'book_genre';

column 'book_id' => {
  data_type      => 'int',
  is_foreign_key => 1,
};

column 'genre_id' => {
  data_type      => 'int',
  is_foreign_key => 1,
};

primary_key 'book_id', 'genre_id';

belongs_to 'book' => ( 'Books::Result::Book', 'book_id' );
belongs_to 'genre' => ( 'Books::Result::Genre', 'genre_id' );

1;
