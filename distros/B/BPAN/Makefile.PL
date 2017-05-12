use inc::Module::Install;

name            'BPAN';
all_from        'lib/BPAN.pm';

install_script  'bpan';

WriteAll;
