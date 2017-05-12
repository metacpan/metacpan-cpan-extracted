use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Unicode';
all_from 'lib/Catalyst/Plugin/Unicode.pm';

author 'Christian Hansen <ch@ngmedia.com>';
author 'Marcus Ramberg <mramberg@pcan.org>';
author 'Jonathan Rockway <jrockway@cpan.org>';
author 'Tomas Doran <bobtfish@bobtfish.net>';

requires 'Catalyst::Runtime' => '5.70';
requires 'MRO::Compat' => '0.10';

test_requires 'Test::More';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'IO::Scalar';
test_requires 'ok';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Unicode/';

WriteAll;
