#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'Dancer-Template-Caml';

version_from 'lib/Dancer/Template/Caml.pm';
author 'Viacheslav Tykhanovskyi <vti@cpan.org>';
abstract 'Text::Caml for Dancer';
license 'artistic_2';
perl_version '5.008007';

requires 'Carp'       => 0;
requires 'File::Spec' => 0;

requires 'Text::Caml' => 0.009005;
requires 'Dancer'     => 1.3072;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

no_index directory => 't';

resources
  bugtracker => 'http://github.com/vti/dancer-template-caml/issues',
  repository => 'http://github.com/vti/dancer-template-caml/',
  license    => 'http://dev.perl.org/licenses/';

auto_install;

WriteAll;
