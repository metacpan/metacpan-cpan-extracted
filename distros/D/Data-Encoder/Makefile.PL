use inc::Module::Install;
name 'Data-Encoder';
all_from 'lib/Data/Encoder.pm';

recommends 'JSON';
recommends 'YAML';
recommends 'Data::MessagePack';

test_requires 'Test::More', 0.96;
test_requires 'Test::Requires';

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

auto_include();
auto_set_repository();

WriteAll;
