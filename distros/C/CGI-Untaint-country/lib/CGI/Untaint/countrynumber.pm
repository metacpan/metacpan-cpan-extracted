package CGI::Untaint::countrynumber;
use warnings;
use strict;
use base 'CGI::Untaint::country';
sub _codeset { Locale::Constants::LOCALE_CODE_NUMERIC }

1;
