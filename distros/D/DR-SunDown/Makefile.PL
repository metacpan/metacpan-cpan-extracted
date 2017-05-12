use inc::Module::Install;

use_ppport 3.19;
# cc_warnings;
cc_src_paths 'sundown/src', 'sundown/html', 'xs';
cc_include_paths 'sundown/src', 'sundown/html';

name            'DR-SunDown';
abstract_from   'lib/DR/SunDown.pm';
version_from    'lib/DR/SunDown.pm';
author          'Dmitry E. Oboukhov <unera@debian.org>';
license         'perl';

WriteAll;
