use Test::Script 1.10 tests => 3;
use File::Copy;

copy ('bin/unding', 'bin/unding.test');

my $pw_repeat = "test\ntest\n";
my $pw        = "test\n";

script_runs(['bin/unding.test', 'xt/secret.txt'], { stdin => \$pw_repeat }, 'encrypt');
script_runs(['bin/unding.test'],                  { stdin => \$pw },        'decrypt');
script_stdout_is("Hello World!\n",                                          'compare');

unlink 'bin/unding.test';
