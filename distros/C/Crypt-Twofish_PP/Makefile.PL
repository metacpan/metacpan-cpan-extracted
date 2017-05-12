#! /usr/local/bin/perl -w

# vim: tabstop=4
# $Id: Makefile.PL,v 1.3 2003/11/27 15:25:14 guido Exp $

# Makefile generator for Crypt-Twofish_PP.
# Copyright (C) 2002-2003 Guido Flohr <guido@imperia.net>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms and conditions as Perl itsels (see the Artistic
# license included).

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME		    => 'Crypt-Twofish_PP',
	VERSION_FROM	=> 'lib/Crypt/Twofish_PP.pm',
    ($] >= 5.005 ?
		(ABSTRACT	=> 'Pure Perl implementation of Twofish',
	 	 AUTHOR		=> 'Guido Flohr <guido@imperia.net>',
		 ) : (),
	),
	PL_FILES        => {},
	PREREQ_PM	=> { 'Locale::TextDomain' => 0 },
);

sub MY::postamble {
	return <<'EOF';
all :: lib/Crypt/Twofish_PP.pm README

README: lib/Crypt/Twofish_PP.pm
	$(PERL) -e 'use Pod::Text; pod2text "$<"' >$@
EOF
}

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
