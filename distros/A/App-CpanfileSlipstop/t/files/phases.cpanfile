requires 'DateTime';
requires 'JSON::XS';

on 'develop' => sub {
    requires 'Data::Printer';
};

on 'test' => sub {
    requires 'Test::More';
};
