#!/usr/bin/perl -w
#
# $Id$
#

use strict;
use warnings;
use Module::Build;

# accomodate with CPAN autoinstall
shift(@ARGV) if $ARGV[0] && $ARGV[0] eq 'Build';    

Module::Build->new(
	module_name        => 'Acme::Brainfuck',
	license            => 'unrestricted',
	dist_version_from  => 'lib/Acme/Brainfuck.pm',
	dist_author        => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
	requires           => { },
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;
