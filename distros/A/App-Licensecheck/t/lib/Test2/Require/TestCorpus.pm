package Test2::Require::TestCorpus;

use strict;
use warnings;

use Test2::Require::Module qw(File::BaseDir);

use File::BaseDir qw(data_dirs);

use Carp qw/confess/;

use base 'Test2::Require';

sub skip
{
	my $class = shift;
	my ($var) = @_;
	confess 'no test corpus variable specified' unless $var;
	return undef if data_dirs("tests/$var");
	return
		"This test only runs if test corpus is available at the path \${XDG_DATA_DIRS} + tests/$var/";
}

1;
