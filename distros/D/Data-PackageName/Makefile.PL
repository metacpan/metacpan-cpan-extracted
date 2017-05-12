#!/usr/bin/env perl
use warnings;
use strict;

use inc::Module::Install;

name            q{Data-PackageName};
license         q{perl};
author          q{Robert 'phaylon' Sedlacek <rs@474.at>};
all_from        q{lib/Data/PackageName.pm};

build_requires  q{Test::More},                  '0.62';
build_requires  q{FindBin},                     0;

requires        q{Moose},                       0;
requires        q{Scalar::Util},                0;
requires        q{Path::Class::Dir},            0;
requires        q{Path::Class::File},           0;
requires        q{Class::Inspector},            0;
requires        q{namespace::clean},            '0.04';

WriteAll;

