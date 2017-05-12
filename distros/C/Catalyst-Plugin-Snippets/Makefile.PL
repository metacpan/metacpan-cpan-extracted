use strict;
use inc::Module::Install 0.91;
use Module::Install::ReadmeFromPod;

license 'perl';
name    'Catalyst-Plugin-Snippets';
all_from 'lib/Catalyst/Plugin/Snippets.pm';
requires 'Catalyst' => '5.80';

requires 'MRO::Compat';
requires 'Test::MockObject';
test_requires 'Test::MockObject';
recommends    'JSON::Syck';
readme_from 'lib/Catalyst/Plugin/Snippets.pm';
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Snippets';
WriteAll;

