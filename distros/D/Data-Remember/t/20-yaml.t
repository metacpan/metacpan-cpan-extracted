use strict;
use warnings;

use YAML::Syck;
BEGIN { YAML::Syck::DumpFile('t/test.yml', {}); }

use Test::More;
use Data::Remember YAML => file => 't/test.yml';

require 't/test-brain.pl';

unlink 't/test.yml';
