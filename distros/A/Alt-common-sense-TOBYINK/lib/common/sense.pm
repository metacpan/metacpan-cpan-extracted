use 5.006;
use strict;
use warnings;
use utf8;

package #
	common::sense;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '3.73';

sub import
{
	# utf8
	'utf8'->import;
	
	# strict
	'strict'->import( qw(vars subs) );
	
	# feature
	if ($] >= 5.010)
	{
		require feature;
		'feature'->import( qw(say state switch) );
		'feature'->import( qw(unicode_strings) ) if $] >= 5.012;
		if ($] >= 5.016)
		{
			'feature'->import( qw(current_sub fc evalbytes) );
			'feature'->unimport( qw(array_base) );
		}
	}
	
	# warnings
	'warnings'->unimport;
	'warnings'->import(
		qw(
			FATAL closed threads internal debugging pack
			portable prototype inplace io pipe unpack malloc
			glob digit printf layer
			reserved taint closure semicolon
		)
	);
	'warnings'->unimport( qw(exec newline unopened) );
}

1;
