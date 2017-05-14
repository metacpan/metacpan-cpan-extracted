#! /usr/bin/perl -W

use strict;
use warnings;

use lib '/home/mica_environment/program_modules/perl';
require Carrot;

require Carrot::Productivity::Text::Placeholder::Templague::Directory_Listing;
my $listing = Carrot::Productivity::Text::Placeholder::Templague::Directory_Listing->constructor(
	'[=counter=]. [=file_name_full=] [=file_mode_rwx=]');
my $rows = $listing->generate('/');

print join(TXT_LINE_BREAK, map(${$_}, @$rows)), TXT_LINE_BREAK;

exit(PDX_EXIT_SUCCESS);
