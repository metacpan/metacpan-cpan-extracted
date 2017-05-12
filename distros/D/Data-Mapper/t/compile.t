use strict;
use Test::More;

BEGIN {
    use_ok 'Data::Mapper';
    use_ok 'Data::Mapper::Class';
    use_ok 'Data::Mapper::Data';
    use_ok 'Data::Mapper::Schema';
    use_ok 'Data::Mapper::Adapter';
    use_ok 'Data::Mapper::Adapter::DBI';
}

done_testing;
