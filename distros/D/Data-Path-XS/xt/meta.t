use strict;
use warnings;
use Test::More;

eval { require Test::CPAN::Meta; 1 }
    or plan skip_all => 'Test::CPAN::Meta required';
eval { require Test::CPAN::Meta::JSON; 1 }
    or plan skip_all => 'Test::CPAN::Meta::JSON required';

Test::CPAN::Meta::meta_yaml_ok();
Test::CPAN::Meta::JSON::meta_json_ok();
