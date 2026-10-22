use strict;
use warnings;
use Test::More;

eval { require Test::CPAN::Meta; 1 }
    or plan skip_all => 'Test::CPAN::Meta required';
eval { require Test::CPAN::Meta::JSON; 1 }
    or plan skip_all => 'Test::CPAN::Meta::JSON required';

plan tests => 4;
Test::CPAN::Meta::meta_spec_ok(-f 'META.yml' ? 'META.yml' : 'MYMETA.yml');
Test::CPAN::Meta::JSON::meta_spec_ok(-f 'META.json' ? 'META.json' : 'MYMETA.json');
