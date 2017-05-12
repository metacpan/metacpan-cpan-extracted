package Acme::CPANAuthors::Australian;

use 5.008;
use strict;
use warnings;
use utf8;

BEGIN {
	$Acme::CPANAuthors::Australian::AUTHORITY = 'cpan:TOBYINK';
	$Acme::CPANAuthors::Australian::VERSION   = '0.002';
}

use Acme::CPANAuthors::Register (
	'ADAMC' => 'Adam Clarke',
	'ANNELI' => 'Amelia Cuss',
	'ANTHONY' => 'Anthony Thyssen',
	'BDGREGG' => 'Brendan Gregg',
	'BENL' => 'Benjamin Low',
	'BJKUIT' => 'Benjamin Kuit',
	'BKRAMER' => 'Ben Kramer',
	'BMORGAN' => 'Bruce Morgan',
	'BQUINN' => 'Brendan Quinn',
	'CCHITTLE' => 'Chris Chittleborough',
	'CEBJYRE' => 'Glenn Fowler',
	'CMLH' => 'Christian Heinrich',
	'CMYERS' => 'Chris Myers',
	'CORLETTK' => 'Keith Corlett',
	'DAP' => 'Deborah Pickett',
	'DAVIDB' => 'David Baxter',
	'DEL' => 'Del Elson',
	'DJZORT' => 'Dean Hamstead',
	'EAYNG' => 'Eric Young',
	'FOOBARD' => 'Gustaf Bjorksten',
	'FRANKC' => 'Frank Carnovale',
	'GARYAJ' => 'Gary Ashton-Jones',
	'GAVIN' => 'Gavin McDonald',
	'GAVINC' => 'Gavin Carr',
	'GJRUSSEL' => 'Geoff Russell',
	'GOSSAMER' => 'Ricky Buchanan',
	'HONEYMAN' => 'Bryn Honeyman',
	'IANB' => 'Ian Boreham',
	'IVANWILLS' => 'Ivan Wills',
	'IWADE' => 'Iain Wade',
	'IXA' => 'Infoxchange Australia',
	'JEFFERY' => 'Jeffery Candiloro',
	'JEPRICE' => 'Jeremy Price',
	'JMORRIS' => 'James Morris',
	'KIELSTR' => 'Kiel R Stirling',
	'LECSTOR' => 'Jason Galea',
	'LEIF' => 'Leif Eriksen',
	'LTP' => 'Luke Poskitt',
	'MAGORACH' => 'Peter Brown',
	'MAKIS' => 'Makis Marmaridis',
	'MARAL' => 'Peter Marelas',
	'MARKNG' => 'Mark Ng',
	'MARKPF' => 'Mark Pfeiffer',
	'MARKPRIOR' => 'Mark Prior',
	'MATTK' => 'Matt Koscica',
	'MDBGRIZ' => 'Matthew Braid',
	'MJHARR' => 'Mathew John Harrison',
	'MRG' => 'Matthew Green',
	'MWALKER' => 'Matthew Walker',
	'NGLEDHILL' => 'Nicholas Gledhill',
	'NSHARROCK' => 'Noel Sharrock',
	'PGMART' => 'Peter G. Martin',
	'PJB' => 'Peter Billam',
	'PJF' => 'Paul Jamieson Fenwick',
	'RIK' => 'Rik Harris',
	'RKS' => 'Russell Standish',
	'ROHANPM' => 'Rohan McGovern',
	'RSAVAGE' => 'Ron Savage',
	'SCOTT' => 'Scott Penrose',
	'SDOWIDEIT' => 'Sven Dowideit',
	'SDT' => 'Stephen Thirlwall',
	'SHOLDEN' => 'Sam Holden',
	'SIMRAN' => 'simran',
	'STEVENL' => 'Steven Lee',
	'STHOMAS' => 'Steve Thomas',
	'TOBYINK' => 'Toby Inkster',
	'TONYC' => 'Tony Cook',
	'UNISOLVE' => 'Simon Taylor',
	'VENTRAIP' => 'VentraIP Wholesale',
	'VOICET' => 'Ben Kramer',
	'WAYLAND' => 'Tim Nelson',
	'XANNI' => 'Andrew Pam',
);

q(AU);

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::CPANAuthors::Australian - we are Australian CPAN authors

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Acme::CPANAuthors;
 
 my $authors = Acme::CPANAuthors->new('Australian');
 my $count   = $authors->count;
 
 print "Count of Australian CPAN authors: $count\n";

=head1 DESCRIPTION

This class provides a hash of Australian CPAN authors' PAUSE ID and name
to be used with the L<Acme::CPANAuthors> module.

This module was created simply because nobody had written it and uploaded
it to CPAN before me :)

=head1 MAINTENANCE

If you are an Australian CPAN author not listed here, please send me your
ID/name via RT so I can always keep this module up to date. If there's a
mistake and you're listed here but are not Australian (or just don't want
to be listed), sorry for the inconvenience: please contact me and I'll
remove the entry right away.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-CPANAuthors-Australian>.

=head1 SEE ALSO

L<Acme::CPANAuthors>.

Not to be confused with:
L<Acme::CPANAuthors::Austrian>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=for the record, I am a dual citizen.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
