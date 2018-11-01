use lib '.';

use inc::Module::Install;

name           'Build-PPK';
version_from   'lib/Build/PPK.pm';
author         'Alexandra Hrefna Hilmisdóttir <xan@cpan.org>';
repository     'https://github.com/xantronix/Build-PPK';
abstract       'Generate self-contained Perl scripts';
license        'perl';
requires       'Filesys::POSIX' => '0.009';
requires       'File::ShareDir' => '1.00';

install_share  'share';
install_script 'bin/ppk';
install_script 'bin/ppk-deptool';

WriteAll;
