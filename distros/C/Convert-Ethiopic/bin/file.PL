#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic::File;

# use diagnostics;

main:
{

	open ( FILE, "t/Hello.sera" );

	my $f = new Convert::Ethiopic::File ( \*FILE );

	print $f->toString;

	close (FILE);

}
