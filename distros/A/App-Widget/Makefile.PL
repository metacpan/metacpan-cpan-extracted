
######################################################################
## File: $Id: Makefile.PL 14126 2010-06-09 20:57:38Z spadkins $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @programs = (
    "cgi-bin/app-button",
);

%opts = (
    'NAME'        => 'App-Widget',
    'DISTNAME'    => 'App-Widget',
    'VERSION'     => '0.968',
    'EXE_FILES'   => [ @programs ],
    'PREREQ_PM'   => { # I haven't yet determined what the minimum versions should be
                       'Compress::Zlib'           => 0,  # for compressed serialization and browser responses
                       'Data::Dumper'             => 0,  # used for debugging
                       'Date::Parse'              => 0,  # date support
                       'Date::Format'             => 0,  # date support
                       'Exception::Class'         => 0,  # allows exception hierarchies
                       'Class::Data::Inheritable' => 0,  # [prereq for Exception::Class]
                       'Devel::StackTrace'        => 0,  # [prereq for Exception::Class]
                       'MIME::Base64'             => "2.1", # used for turning binary (serialized?) data into text (Sessions)
                       'Storable'                 => 0,  # used for serialization everywhere
                     },
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(MOD_INSTALL) cgi-bin "\$(PREFIX)/cgi-bin/App"
	@\$(MOD_INSTALL) htdocs  "\$(PREFIX)/htdocs/App"

EOF
}

