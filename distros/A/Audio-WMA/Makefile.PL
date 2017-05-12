# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use inc::Module::Install;

name('Audio-WMA');
license('perl');
perl_version('5.005');
all_from('WMA.pm');

auto_install();
WriteAll();
