use inc::Module::Install 0.91;

name     'Catalyst-Action-Serialize-SimpleExcel';
all_from 'lib/Catalyst/Action/Serialize/SimpleExcel.pm';
author   'Rafael Kitover <rkitover@cpan.org>';
license  'perl';

requires 'Catalyst::Controller::REST';
requires 'Spreadsheet::WriteExcel';
requires 'parent';
requires 'namespace::clean';

test_requires 'Test::More';
test_requires 'Spreadsheet::ParseExcel';
test_requires 'Test::Deep';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Action/Serialize/SimpleExcel.pm > README");
}

realclean_files 'README';

auto_provides;
auto_install;

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Action-Serialize-SimpleExcel/1.000/trunk/';

WriteAll;
