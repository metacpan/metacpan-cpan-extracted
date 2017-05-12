use inc::Module::Install;

name 'Catalyst-View-FillInForm';
all_from 'lib/Catalyst/View/FillInForm.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::View::TT';
requires 'HTML::FillInForm';

test_requires 'Catalyst::Action::RenderView';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::More';

resources repository => '';

if (-e 'inc/.author') {
  build_requires 'Test::Pod' => 1.14;
  build_requires 'Test::Pod::Coverage' => 1.04;

}

WriteAll();
