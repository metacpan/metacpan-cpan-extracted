# $Id: Makefile.PL,v 1.10 2008/06/03 17:25:25 cmungall Exp $

use ExtUtils::MakeMaker;
require 5.005;
#use Config;

%packages =
  (
   'Tk'                       => '0.0/Tk/tree viewer/stag-view.pl',
   'GD'                       => '1.3/Graphical Drawing Toolkit/drawing trees/stag-drawtree.pl',
   'XML::LibXSLT'             => '0.0/XSLT/XSLT Transformations/Data::Stag::XSLTHandler',
   'JSON'          => '0.0/JSON parser and writer/Writing JSON/Data::Stag::JSONWriter',
   'Storable'          => '0.0/storage of data structures/storing stag trees/Data::Stag::StagDB',
   'MLDBM'          => '0.0/multilevel hash store/indexing stag nodes/Data::Stag::StagDB',
   'Graph::Directed'          => '0.0/Generic Graph data stucture and algorithms/transforming stag trees to graphs/Data::Stag::GraphHandler',
   'XML::Parser::PerlSAX'  => '0.0/SAX Handler/parsing XML/Data::Stag::XMLParser', 
   'IO::String'         => '0.0/String handling/parsing strings containing stag data/Data::Stag',

  );


sub check_package {
    my ($name,$str) = @_;
    my ($ver,$desc,$expl,$module) = split( /\// , $str);
    if( !eval "require($name)") {
	print "External Module $name, $desc,\n is not installed on this computer.\n  $module in Data::Stag needs it for $expl\n\n";
	return 1;
    }

    return 0;
}
$error = 0;
print "\n";
foreach $name ( keys %packages ) {
    if( &check_package($name,$packages{$name}) == 1 ) {
	$error = 1;
    }
}
if( $error == 1 ) {
    print <<QQ_ERROR_QQ;

Information:

   There are some external packages and perl modules, listed above, which 
   stag uses. This only effects the functionality which is listed above:
   the rest of stag will work fine, which includes nearly all of the
   core functionality.

   Enjoy the rest of stag, which you can use after going 'make install'

QQ_ERROR_QQ
}

eval {
    require "IO/String.pm";
};
if ($@) {
    print <<FAIL;

** Missing vital module: IO::String **

This module is required by Data::Stag. Please install this module from CPAN

FAIL
}

WriteMakefile(
	      'NAME'         => "Data",
	      'DISTNAME'         => "Data-Stag",
	      'ABSTRACT'     => 'Structured Tags',
	      'AUTHOR'       => 'Chris Mungall <cjm AT fruitfly DOT org>',
	      'VERSION_FROM' => "Data/Stag.pm",
	      'PREREQ_PM'    => {
                                 'IO::String'=>0,
				},
	      'EXE_FILES'    => [
                                 qw(
				    scripts/stag-autoschema.pl
				    scripts/stag-db.pl
				    scripts/stag-diff.pl
				    scripts/stag-drawtree.pl
				    scripts/stag-filter.pl
				    scripts/stag-findsubtree.pl
				    scripts/stag-flatten.pl
				    scripts/stag-grep.pl
				    scripts/stag-handle.pl
				    scripts/stag-itext2simple.pl
				    scripts/stag-itext2sxpr.pl
				    scripts/stag-itext2xml.pl
				    scripts/stag-join.pl
				    scripts/stag-merge.pl
				    scripts/stag-mogrify.pl
				    scripts/stag-parse.pl
				    scripts/stag-query.pl
				    scripts/stag-splitter.pl
				    scripts/stag-view.pl
				    scripts/stag-xml2itext.pl
				    scripts/stag-itext2simple.pl
                                   )
				],
	      'dist'         => { 
				 'SUFFIX'       => ".gz",
				 'DIST_DEFAULT' => 'all tardist',
				 'COMPRESS'     => "gzip -9f" 
				},
	      clean => {
			FILES => 'Data-Stag-$(VERSION).tar.gz',
		       },
	     );

