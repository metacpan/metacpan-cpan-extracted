use strict;
use inc::Module::Install;

name('Acme-Shukugawa-Atom');
all_from('lib/Acme/Shukugawa/Atom.pm');
requires('Class::Accessor::Fast');
requires('Encode');
requires('File::ShareDir');
requires('Text::MeCab', '0.20007');
requires('YAML');

use_test_base;

install_share;

auto_install;
WriteAll;
