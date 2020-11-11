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
            {
                id => 2,
                name => 'Denmark',
                created_date_time => '2020-09-13 13:34:43',
            }
          ],
          Publisher => [
            {
                id => 1,
                name => 'The Iceland Publisher',
            },
          ],
        }
    },
    resultsets => [qw/
        Author
        Book
        Country
        Publisher
    /]
};
