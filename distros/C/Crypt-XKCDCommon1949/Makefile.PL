use inc::Module::Install;

name           'Crypt-XKCDCommon1949';
all_from       'lib/Crypt/XKCDCommon1949.pm';

test_requires  'Test::More'       => 0;

recommends     'Crypt::Diceware'     => 0.002;
recommends     'Crypt::XkcdPassword' => 0;
recommends     'Acme::MetaSyntactic' => 1.007;

license 'perl';
githubmeta;
author_tests('xt');
readme_from    'lib/Crypt/XKCDCommon1949.pm';

WriteAll;
