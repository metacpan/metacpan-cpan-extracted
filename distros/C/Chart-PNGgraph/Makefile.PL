# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1.1.1.2.2.2.1 2000/04/05 02:45:37 sbonds Exp $
 
#--- Distribution section ---
 
use ExtUtils::MakeMaker;
 
WriteMakefile(
		'VERSION_FROM'		=> 'lib/Chart/PNGgraph.pm',	#finds $VERSION
	      'DISTNAME'  		=> "Chart-PNGgraph",
	      'NAME'      		=> "Chart::PNGgraph",

		($] >= 5.005 ?
			('ABSTRACT'		=> 'Produces PNG graph plots',
			 'AUTHOR'		=> 'Martien Verbruggen (mgjv@comdyn.com.au)',
			) : ()
		),

		'PREREQ_PM'			=> { 
			'GD::Graph'	=> '1.20',
			'GD'		=> '1.14', 
		},
 
        'dist'    			=> {
			'COMPRESS' 		=> 'gzip -9f',
			'SUFFIX'   		=> 'gz', 
		},
 
        'clean'   	=> { 'FILES' => q(*% *.b[ac]k *.old tags) },
);

# GD has already been 'required' by the WriteMakeFile call, but it
# doesn't hurt to do it again.
require GD;

# REMOVE THE FOLLOWING CHECKS IF YOU DON'T USE Image::Magick AND YOU
# HAVE EDITED GIFgraph::Convert.
if (GD::Image->can('gif'))
{
	print "Checking for conversion of GIF to PNG\n";
	require GIFgraph::Convert;
	GIFgraph::Convert::checkImageMagick();
}

print <<END;

Please read the README. Chart::PNGgraph is now a wrapper around
GD::Graph, and requires GD::Graph and GDTextUtils to be installed. it
also requires some conversion software for use with GD < 1.20.

END
