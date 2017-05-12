package Books::Result::Author;

use DBIx::Class::Candy;

table 'author';

column 'id' => {
    data_type => 'int',
    is_auto_increment => 1,
};

column 'name' => {
    data_type => 'varchar',
    size      => 256,
};

primary_key 'id';

has_many 'addresses' => ( 'Books::Result::Address', 'author_id' );

1;
