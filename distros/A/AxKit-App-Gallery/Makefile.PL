# $Id: Makefile.PL,v 1.9 2004/02/26 17:45:10 nik Exp $

use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'AxKit::App::Gallery',
#    'VERSION_FROM' => 'lib/AxKit/App/Gallery.pm', # finds $VERSION
	      'VERSION'	=> '0.5',
	      'PREREQ_PM' => {
			      AxKit => 1.62,
			      Data::Page => 0.15,
			      XML::LibXSLT => 1.53,
			      XML::LibXML => 1.52,
			      Imager => 0.41,
			      URI => 1.23,
			      Image::Info => 1.08,
			      RDF::Core => 0.30,
			     },
	     );

if(eval { require XML::LibXML }) {
  if (XML::LibXML->VERSION > '1.52' and XML::LibXML->VERSION < '1.57') {
    die <<"REASON";

***** ERROR *****

Your XML::LibXML version is between 1.53 and 1.56.  These versions have bugs
which mean they do not work will with AxKit and AxKit::App::Gallery.

Please downgrade to version 1.52 or upgrade to 1.57, which is known to be
stable.

REASON
  }
}

if (eval { require Image::Info } and eval { require IO::String }) {
  if (Image::Info->VERSION == '1.12' and IO::String->VERSION == '1.02') {
    die <<"REASON";

***** ERROR *****

Your Image::Info version is 1.12, and your IO::String version is 1.02.

There is a known bug in the interaction between these two modules that
causes Image::Info to core dump when processing some images.  You should
either upgrade Image::Info to 1.13 or greater, or IO::String to 1.03 or
greater.

REASON
  }
}
