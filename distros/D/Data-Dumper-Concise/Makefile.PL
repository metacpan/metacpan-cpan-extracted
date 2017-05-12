use 5.006;
use inc::Module::Install 0.91;
use strict;
use warnings FATAL => 'all';

resources 'repository' => 'git://git.shadowcat.co.uk/p5sagit/Data-Dumper-Concise';
resources 'homepage' => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Data-Dumper-Concise.git;a=summary';

all_from 'lib/Data/Dumper/Concise.pm';

WriteAll;
