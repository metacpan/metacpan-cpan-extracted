{
    schema_class => 'TestFor::DBIx::Class::Smooth::Schema',
    fixture_sets => {
        basic => {
          Country => [
            {
                id => 1,
                name => 'Sweden',
                created_date_time => '2020-08-20 12:32:42',
            },
          ]
        }
    },
    resultsets => [
        'Author',
        'Book',
        'Country',
    ]
};
