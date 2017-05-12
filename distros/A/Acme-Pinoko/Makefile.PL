use inc::Module::Install;

all_from    'lib/Acme/Pinoko.pm';
readme_from 'lib/Acme/Pinoko.pm';

requires 'Carp';
requires 'Module::Load' => '0.22';
requires 'Data::Recursive::Encode';
requires 'Lingua::JA::Regular::Unicode' => '0.09';
requires 'Lingua::JA::Halfwidth::Katakana';
test_requires 'Test::More' => 0.98;
test_requires 'Test::Base';
test_requires 'Test::Fatal';
test_requires 'Test::Requires';

# どっちかがあればOK
#requires 'Text::MeCab' => '0.20013';
#requires 'Text::KyTea' => '0.42';

tests 't/*.t';
author_tests 'xt';

no_index directory => 'benchmark';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Acme-Pinoko',
    bugtracker => 'https://github.com/pawa-/Acme-Pinoko/issues',
);

WriteAll;
