use inc::Module::Install;

name            'CPAN2RT';
author          'Ruslan Zakirov <ruz@bestpractical.com>';
license         'perl';
all_from        'lib/CPAN2RT.pm';

install_script  'bin/cpan2rt';

requires        'Email::Address';
requires        'List::Compare';
requires        'List::MoreUtils';
requires        'CPAN::DistnameInfo' => '0.07'; # for .tar.bz2
requires        'LWP::UserAgent';
requires        'HTTP::Date';
requires        'File::Spec';
requires        'XML::SAX';

auto_install();
WriteAll();
