use strict;
use warnings;

use YAML::Syck;
BEGIN { YAML::Syck::DumpFile('t/test.yml', {}); }

use Test::More tests => 2;

use Data::Remember YAML => file => 't/test.yml';

remember foo => 1;
remember bar => 2;
remember baz => 3;

brain->dump;

my $test_data = YAML::Syck::LoadFile('t/test.yml');
is_deeply($test_data, { foo => 1, bar => 2, baz => 3});

brain->dump('t/test2.yml');

my $test2_data = YAML::Syck::LoadFile('t/test.yml');
is_deeply($test2_data, { foo => 1, bar => 2, baz => 3});

unlink $_ for (qw( t/test.yml t/test2.yml ));
