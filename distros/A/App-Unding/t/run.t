use Test::Script 1.10 tests => 4;

use File::Copy;

copy ('bin/unding', 'bin/unding.test');

script_compiles('bin/unding.test');

my $pw = "test\n";

script_runs(['bin/unding.test', 't/secret.txt'], { stdin => \$pw }, 'encrypt');
script_runs(['bin/unding.test'],                 { stdin => \$pw }, 'decrypt');
script_stdout_is("Hello World!\n",                                  'compare');

unlink 'bin/unding.test';
