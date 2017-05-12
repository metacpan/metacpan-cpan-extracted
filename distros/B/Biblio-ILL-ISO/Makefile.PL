use 5.6.0;
use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Find;

find( \&filecheck, "." );

sub filecheck {
    unlink if /~$/;  # Remove any emacs backup files
    die "Aborting: Swapfile $_ found" if /\.swp$/;
}

&WriteMakefile(
	'NAME'		=> 'Biblio::ILL::ISO',
	'DISTNAME'	=> 'Biblio-ILL-ISO',
	'VERSION_FROM'	=> 'lib/Biblio/ILL/ISO/ISO.pm', # finds $VERSION
	'ABSTRACT_FROM' => 'lib/Biblio/ILL/ISO/ISO.pm',
	'PMLIBDIRS'	=> [ qw( lib/ ) ],
	'AUTHOR'	=> 'David Christensen <DChristensenSPAMLESS@westman.wave.ca>',
	'PREREQ_PM'	=> {
			   'Test::More' => 0,
			   'Convert::ASN1' => 0,
			   },
	'EXE_FILES'	=> [ qw( pl/messages/01.request.read.pm
				 pl/messages/01.request.write.pm
				 pl/messages/02.forward-notification.read.pm
				 pl/messages/02.forward-notification.write.pm
				 pl/messages/03.shipped.read.pm
				 pl/messages/03.shipped.write.pm
				 pl/messages/04.answer.read.pm
				 pl/messages/04.answer.write.pm
				 pl/messages/05.conditional-reply.read.pm
				 pl/messages/05.conditional-reply.write.pm
				 pl/messages/06.cancel.read.pm
				 pl/messages/06.cancel.write.pm
				 pl/messages/07.cancel-reply.read.pm
				 pl/messages/07.cancel-reply.write.pm
				 pl/messages/08.received.read.pm
				 pl/messages/08.received.write.pm
				 pl/messages/09.recall.read.pm
				 pl/messages/09.recall.write.pm
				 pl/messages/10.returned.read.pm
				 pl/messages/10.returned.write.pm
				 pl/messages/11.checked-in.read.pm
				 pl/messages/11.checked-in.write.pm
				 pl/messages/12.overdue.read.pm
				 pl/messages/12.overdue.write.pm
				 pl/messages/13.renew.read.pm
				 pl/messages/13.renew.write.pm
				 pl/messages/14.renew-answer.read.pm
				 pl/messages/14.renew-answer.write.pm
				 pl/messages/15.lost.read.pm
				 pl/messages/15.lost.write.pm
				 pl/messages/16.damaged.read.pm
				 pl/messages/16.damaged.write.pm
				 pl/messages/17.message.read.pm
				 pl/messages/17.message.write.pm
				 pl/messages/18.status-query.read.pm
				 pl/messages/18.status-query.write.pm
				 pl/messages/19.status-or-error-report.read.pm
				 pl/messages/19.status-or-error-report.write.pm
				 pl/messages/20.expired.read.pm
				 pl/messages/20.expired.write.pm
				 pl/ISOtypetest.pm 
				 pl/ISO-t-dumper.pm
				 pl/ISO-msg-t-dumper.pm
				 ) 
			     ],
	'dist'		=> {
			   COMPRESS => 'gzip -9f',
			   SUFFIX => 'gz',
			   },
	'depend'	=> {
			   Makefile => '$(VERSION_FROM)'
			   },
);
