use 5.00503;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'CGI::pWiki',
    'ABSTRACT'     => 'Perl Wiki Environment',
    'AUTHOR'       => 'kraehe@copyleft.de',
    'VERSION_FROM' => 'pWiki.pm',
    'EXE_FILES'    => [ 'pWiki.cgi' ],
#   'PL_FILES'     => { 'Bootstrap.PL' => 'blib/lib/CGI/pWiki/DB.pm' }
    'dist'         => { 'COMPRESS' => 'gzip -v -f -9', 'SUFFIX' => 'gz' }
);
