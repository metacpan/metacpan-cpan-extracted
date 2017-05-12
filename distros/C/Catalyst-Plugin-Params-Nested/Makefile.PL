use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Params-Nested';
all_from 'lib/Catalyst/Plugin/Params/Nested.pm';
license 'perl';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Params/Nested.pm > README")
        and die $!;
}

requires 'Catalyst'         => '5.49';
test_requires 'Test::MockObject' => '1.01';
requires 'CGI::Expand'      => '1.06';
requires 'MRO::Compat';

resources 'repository' => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Params-Nested';

WriteAll();

