use warnings;
use inc::Module::Install 0.91;

all_from 'lib/Class/Discover.pm';

requires 'File::Find::Rule';
requires 'File::Find::Rule::Perl' => '1.07';
requires 'PPI';
requires 'File::Temp';
requires 'ExtUtils::MM_Unix';
requires 'Path::Class';

test_requires 'Test::More';
test_requires 'Test::Differences';


auto_install();
WriteAll();


WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Class/DISCOVER.pm > README'
  },
);
