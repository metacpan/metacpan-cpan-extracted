use inc::Module::Install;

name     '<tmpl_var distro>';
all_from '<tmpl_var main_pm_file>';
author   '<tmpl_var author>';

build_requires 'CGI::Application'              => 4.04;
build_requires 'File::Find'                    => 0;
build_requires 'HTML::Template'                => 0;
build_requires 'Pod::Coverage'                 => 0.18;
build_requires 'Pod::Usage'                    => 0;
build_requires 'Test::More'                    => 0;
build_requires 'Test::Pod'                     => 1.22;
build_requires 'Test::Pod::Coverage'           => 1.08;
build_requires 'Test::WWW::Mechanize::CGIApp'  => 0;
requires       'CGI::Application'              => 4.04;
requires       'File::Find'                    => 0;
requires       'HTML::Template'                => 0;
auto_install;
sign 1;

WriteAll;

