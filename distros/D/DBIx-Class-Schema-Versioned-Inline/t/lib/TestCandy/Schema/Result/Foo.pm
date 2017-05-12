package TestCandy::Schema::Result::Foo;
use TestCandy::Schema::Candy;

till '0.003';

primary_column foos_id => { data_type => 'integer', is_auto_increment => 1 };

column age => {
    data_type   => "integer",
    is_nullable => 1,
    since       => '0.002',
};

column height => {
    data_type   => "integer",
    is_nullable => 1,
    till        => '0.002',
};

column width => {
    data_type     => "integer",
    is_nullable   => 0,
    default_value => 1,
    since         => '0.002',
    renamed_from  => 'height',
};

1;
