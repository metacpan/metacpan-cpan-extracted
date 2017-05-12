# $Id: Makefile.PL,v 1.9 2001/05/22 18:36:47 thomas Exp $
package Apache::DnsZone;

use ExtUtils::MakeMaker;
use Apache::src ();

require 5.005;

WriteMakefile(
	      'NAME' => __PACKAGE__,
	      'VERSION_FROM' => 'lib/Apache/DnsZone.pm', 
	      'INC' => Apache::src->new->inc,
	      'PREREQ_PM' => {
		  'Apache::AuthCookie' => 0,
		  'Apache::AuthTicket' => 0,
		  'Apache::Request' => 0.3103,
		  'mod_perl' => 1.24,
		  'Net::DNS' => 0.12,
		  'DBI' => 1.13,
		  'Email::Valid' => 0,
		  'CGI::FastTemplate' => 1.09,
		  'MLDBM' => 0,
                  'GDBM_File' => 0,
	      },
              'clean' => { 'FILES' => '*.xs*, lang/DnsZoneLang' }
);


sub MY::postamble {
    my $postamble = <<'END';
language: 
	cd lang && perl langdbm.pl
END
    $postamble;
}

