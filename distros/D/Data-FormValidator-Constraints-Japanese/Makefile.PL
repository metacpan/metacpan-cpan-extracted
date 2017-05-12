#!perl
use strict;
use inc::Module::Install;

name 'Data-FormValidator-Constraints-Japanese';
all_from 'lib/Data/FormValidator/Constraints/Japanese.pm';
requires 'Data::FormValidator';
requires 'Encode';
requires 'Encode::Detect';
requires 'Mail::Address::MobileJp';

auto_install;
WriteAll;
