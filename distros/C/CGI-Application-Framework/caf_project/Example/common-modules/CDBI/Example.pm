# ////////////////////
# //////////////////// Beginning of CDBI::Example class, based on Class::DBI
# //////////////////// and Class::DBI::mysql. This class has to provide
# //////////////////// enough info for database connections to be made, along
# //////////////////// with whatever other method overrides, utility methods,
# //////////////////// etc. might be needed or desired by the classes that
# //////////////////// are based on CDBI::Example
# ////////////////////

package CDBI::Example;

use base qw( CGI::Application::Framework::CDBI );

use strict;
use warnings;


1; # gotta end a .pm file with a 1, or risk being ostracized...
