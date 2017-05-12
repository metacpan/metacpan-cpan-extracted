#!perl
# $Id: 01_write.pl 315 2008-12-17 21:09:23Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
require DBI;
require DBD::PO; DBD::PO->init(':plural');

# for test examples only
our ($PATH_P, $TABLE_2P, $PATH_M, $TABLE_2M);
() = eval 'use Test::DBD::PO::Defaults qw($PATH_P $TABLE_2P $PATH_M $TABLE_2M)'; ## no critic (StringyEval InterpolationOfMetachars)

my $path_p  = $PATH_P
              || q{./LocaleData/de/LC_MESSAGES};
my $table_p = $TABLE_2P
              || 'table_plural.po';
my $path_m  = $PATH_M
              || q{./LocaleData/de/LC_MESSAGES};
my $table_m = $TABLE_2M
              || 'table_plural.mo';

system "D:/build/gettext/bin/msgfmt.exe $path_p/$table_p -o $path_m/$table_m";