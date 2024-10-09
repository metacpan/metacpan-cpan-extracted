#
# (c) 1999 Morgan Stanley Dean Witter and Co.
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Makefile.PL,v 1.1 1999/11/23 17:01:33 desimr $
#
use ExtUtils::MakeMaker;

print <<"LegalMumboJumbo";

This software is is licensed as open source code and is subject to the
terms and conditions of a license agreement that is set forth in the
included LICENSE file.  

If you have read the license agreement and accept its terms and
conditions, answer "yes" to continue with the installation.  If you
have not read the license agreement or do not accept its terms and
conditions, answer "no" and fire up your favorite text editor....

LegalMumboJumbo
    
my $answer = prompt("Did you read the LICENSE file and agree to its terms and conditions? [y] ");
exit 1 if $answer =~ /^n/i;

open(YES,">.LICENSE.ACCEPTED") || 
  die "Unable to write .LICENSE.ACCEPTED: $!\n";
close(YES) ||
  die "Unable to close .LICENSE.ACCEPTED: $!\n";

print "\n";

WriteMakefile(NAME   	=> 'Date::Business',
	      VERSION_FROM 	=> 'Business.pm',
				PREREQ_PM     => {
					'Time::Local'   => 0,
					'POSIX'         => 0,
				},
);

