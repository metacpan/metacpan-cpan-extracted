#!/usr/bin/perl
package My::Constant::Module;
use base qw(Exporter);
use blib;
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

use Constant::Generate
	[qw(MOO COW)],
	-tag => "some_constants",
	-type => "int",
	-export => 1,
	-export_tags => 1,
	-start_at => 32;
	
package My::User::Module;
use strict;
use warnings;
BEGIN {
	My::Constant::Module->import(qw(:some_constants));
}
my ($animal,$noise) = (COW,MOO);
printf("%s is known to make lots of %s noises\n",
	some_constants_to_str($animal), some_constants_to_str($noise));
