use inc::Module::Install;

name('Catalyst-Model-Search');
all_from('lib/Catalyst/Model/Search.pm');

include('ExtUtils::AutoInstall');

requires 'Catalyst' => '5.62';
requires 'Class::Std';

feature 'Plucene Support',
    'Plucene'       => '1.24',
    'Plucene::Plugin::Analyzer::SnowballAnalyzer' => '1.1';
feature  'Lucene support',
    'Net::LuceneWS';

auto_install();
&WriteAll;
