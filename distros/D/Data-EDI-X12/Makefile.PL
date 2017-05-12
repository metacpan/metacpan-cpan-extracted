use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'Data-EDI-X12';
all_from 'lib/Data/EDI/X12.pm';
license 'perl';

requires 'YAML';

WriteAll();
