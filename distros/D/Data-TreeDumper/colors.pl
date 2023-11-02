#! /usr/bin/perl 

use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;

our $s ;
do "./s" ;

$Data::TreeDumper::Useascii = 1 ;

print DumpTree($s, 'Unaltered data structure') ;

#-------------------------------------------------------------------------------
# Tree Coloring example
#-------------------------------------------------------------------------------

use Term::ANSIColor qw(:constants) ;

my @colors = map
		{
		Term::ANSIColor::color($_) ;
		}
		(
		  'red'
		, 'green'
		, 'yellow'
		, 'blue'
		, 'magenta'
		, 'cyan'
		) ;

#-------------------------------------------------------------------------------
# level coloring
#-------------------------------------------------------------------------------

sub ColorLevels
{
my $level   = shift ;
my $index   = $level % @colors ;

return($colors[$index], '') ;
}

print Data::TreeDumper::DumpTree($s, "Level coloring using a sub", COLOR_LEVELS => \&ColorLevels, NUMBER_LEVELS => 2) ;

print Term::ANSIColor::color('reset') ;

sub ColorLevelsGlyphs
{
my $level   = shift ;
my $index   = $level % @colors ;

return($colors[$index], Term::ANSIColor::color('reset')) ;
}

print Data::TreeDumper::DumpTree($s, "Level glyph coloring using a sub", COLOR_LEVELS => \&ColorLevelsGlyphs) ;

print Data::TreeDumper::DumpTree($s, "Level coloring using an array", COLOR_LEVELS => [\@colors, '']) ;
print Term::ANSIColor::color('reset') ;

print Data::TreeDumper::DumpTree($s, "Level glyph coloring using an array", COLOR_LEVELS => [\@colors, Term::ANSIColor::color('reset')]) ;

#-------------------------------------------------------------------------------
# label coloring
#-------------------------------------------------------------------------------

sub ColorLabel
{
my ($tree, $level, $path, $nodes_to_display, $setup) = @_ ;

if('HASH' eq ref $tree)
	{
	my @keys_to_dump ;
	
	for my $key_name (keys %$tree)
		{
		my $index = ord(substr($key_name, 0, 1)) % @colors ;
		my $reset_color = $setup->{__ANSI_COLOR_RESET} || Term::ANSIColor::color('reset') ;
		
		$key_name = 
			[
			  $key_name
			, $colors[$index] . $key_name . $reset_color
			] ;
			
		push @keys_to_dump, $key_name ;
		}
		
	return ('HASH', undef, @keys_to_dump) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print Data::TreeDumper::DumpTree($s, "Colored labels (using a filter)", FILTER => \&ColorLabel) ;

#allowing for a tree color

print $colors[3] ;
print Data::TreeDumper::DumpTree($s, "Colored tree and labels", FILTER => \&ColorLabel, __ANSI_COLOR_RESET => $colors[3]) ;
print Term::ANSIColor::color('reset') ;

