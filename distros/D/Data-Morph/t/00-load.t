use Test::More;
use warnings;
use strict;

BEGIN
{
    use_ok('Data::Morph');
    use_ok('Data::Morph::Role::Backend');
    use_ok('Data::Morph::Backend::Raw');
    use_ok('Data::Morph::Backend::Object');
    use_ok('Data::Morph::Backend::DBIC');
}

done_testing();
