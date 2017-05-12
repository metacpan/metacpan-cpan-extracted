use 5.008001; use strict; use warnings; # use utf8; (currently breaks Module::Install)

use inc::Module::Install;

name 'Alt-Acme-Math-XS-ModuleInstall';
abstract 'Math is HARD (faster!)';
author 'Ingy döt Net <ingy@cpan.org>';
version '0.0.6';
perl_version '5.8.1';
license 'perl';
inline module => 'Acme::Math::XS';
no_index directory => 'lib/Acme';

WriteAll;
