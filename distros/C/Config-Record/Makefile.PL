# $Id: Makefile.PL,v 1.3 2006/01/27 16:25:50 dan Exp $
# -*- perl -*-

use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
	      NAME => "Config::Record",
	      VERSION_FROM => 'lib/Config/Record.pm',
	      AUTHOR => "Daniel P. Berrange (dan[at]berrange[dot]com)",
	      dist =>
	      {
	       COMPRESS => 'gzip --force --best',
	      },

	      clean =>
	      {
	       FILES => '*.bak *~',
	      },

              NO_META => 1,
	      depend => {
	        Makefile => '$(VERSION_FROM)',
		dist => 'Config-Record.spec META.yml',
	      },

	      realclean => {
	       FILES => 'Config-Record-*.tar.gz Config-Record.spec META.yml',
	      }
	     );

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
  }

__END__
