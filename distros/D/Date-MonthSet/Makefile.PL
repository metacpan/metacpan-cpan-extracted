#!/usr/bin/perl -w

use warnings;
use strict;

use inc::Module::Install;

name			'Date-MonthSet';
author			'Mike Eldridge <diz@cpan.org>';
license			'perl';

build_requires	'Test::More'		=> '0.42';
build_requires	'Test::Pod'			=> 0;

version_from	'lib/Date/MonthSet.pm';

auto_install;

WriteAll;
