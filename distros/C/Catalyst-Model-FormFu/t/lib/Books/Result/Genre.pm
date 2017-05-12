package Books::Result::Genre;

use DBIx::Class::Candy;

table 'genre';

column 'id' => {
    data_type         => 'int',
    is_auto_increment => 1,
};

column 'name' => {
    data_type => 'varchar',
    size      => 256,
};

column 'fiction' => {
    data_type => 'boolean',
};

primary_key 'id';

has_many 'book_genres' => ( 'Books::Result::BookGenre', 'genre_id' );
many_to_many 'books' => ( 'book_genres', 'book' );

1;
