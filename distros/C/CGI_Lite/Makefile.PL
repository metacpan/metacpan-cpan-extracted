use ExtUtils::MakeMaker;
require 5.002;

$VERSION = "1.8";

print "\nWelcome to the installation of CGI_Lite $VERSION...\n\n";

WriteMakefile (
                 NAME      =>   "CGI_Lite",
                 DISTNAME  =>   "CGI_Lite",
                 MAN3PODS  =>   ' ',  
                 VERSION   =>   "$VERSION",
                 'dist'    =>   {
				    COMPRESS => 'gzip -9f', 
				    SUFFIX   => 'gz'
           			}
              );

print <<End_of_Text;

Now do the following to install CGI_Lite $VERSION:

    % make 
    % make install

End_of_Text
