package Acme::CPANAuthors::Czech;

use strict;
use utf8;
use warnings;

our $VERSION = 0.32;

# Modules.
use Acme::CPANAuthors::Register(
	'ATG' => 'Ondřej Vostal',
	'BULB' => 'Jan Hudec',
	'CHOROBA' => 'E. Choroba',
	'CONTYK' => 'Petr Šabata',
	'DANIELR' => 'Roman Daniel',
	'DANPEDER' => 'Daniel Peder',
	'DOUGLISH' => 'Dalibor Hořínek',
	'DPOKORNY' => 'Dan Pokorny',
	'HIHIK' => 'Jiří Václavík',
	'HOLCAPEK' => 'Jan Holčapek',
	'HPA' => 'Petr Vraník',
	'JANPAZ' => 'Jan Pazdziora',
	'JANPOM' => 'Jan Pomikálek',
	'JENDA' => 'Jan Krynický',
	'JIRA' => 'Jiří Pavlovský',
	'JSPICAK' => 'Jakub Špičák',
	'KLE' => 'Petr Kletečka',
	'KOLCON' => 'Luboš Kolouch',
	'MAJLIS' => 'Martin Majlis',
	'MICHALS' => 'Michal Sedlák',
	'MIK' => 'Karel Miko',
	'MILSO' => 'Milan Šorm',
	'MJFO' => 'Michal Jurosz',
	'PAJAS' => 'Petr Pajas',
	'PAJOUT' => 'Jan Poslušný',
	'PASKY' => 'Petr Baudiš',
	'PCIMPRICH' => 'Petr Cimprich',
	'PEK' => 'Petr Kletečka',
	'PETRIS' => 'Petr Malát',
	'PKUBANEK' => 'Petr Kubánek',
	'POPEL' => 'Martin Popel',
	'PSME' => 'Petr Šmejkal',
	'RADIUSCZ' => 'Radek Šiman',
	'RUR' => 'Rudolf Rosa',
	'RVASICEK' => 'Roman Vašíček',
	'SARFY' => 'Martin Šárfy',
	'SEIDLJAN' => 'Jan Seidl',
	'SKIM' => 'Michal Josef Špaček',
	'SMRZ' => 'Otakar Smrž',
	'STRAKA' => 'Milan Straka',
	'TKR' => 'Tomáš Kraut',
	'TPODER' => 'Tomáš Podermański',
	'TRIPIE' => 'Tomáš Stýblo',
	'TYNOVSKY' => 'Miroslav Týnovský',
	'VARISD' => 'Dušan Variš',
	'VASEKD' => 'Václav Dovrtěl',
	'YENYA' => 'Jan "Yenya" Kasprzak',
	'ZABA' => 'Zdeněk Žabokrtský',
	'ZEMAN' => 'Dan Zeman',
	'ZOUL' => 'Tomáš Znamenáček',
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Acme::CPANAuthors::Czech - We are Czech CPAN authors.

=head1 SYNOPSIS

 use Acme::CPANAuthors;

 my $authors = Acme::CPANAuthors->new('Czech');
 my $url = $authors->avatar_url('TRIPIE');
 my $number = $authors->count;
 my @distors = $authors->distributions('JANPAZ');
 my @ids = $authors->id;
 my $kwalitee = $authors->kwalitee('RUS');
 my $name = $authors->name('CHOROBA');

=head1 DESCRIPTION
 
See documentation for L<Acme::CPANAuthors> for more details.

=head1 EXAMPLE1

=for comment filename=count_of_czech_cpan_authors.pl

 use strict;
 use warnings;

 use Acme::CPANAuthors;

 # Create object.
 my $authors = Acme::CPANAuthors->new('Czech');

 # Get number of Czech CPAN authors.
 my $count = $authors->count;

 # Print out.
 print "Count of Czech CPAN authors: $count\n";

 # Output:
 # Count of Czech CPAN authors: 50

=head1 EXAMPLE2

=for comment filename=list_of_czech_cpan_author_nicks.pl

 use strict;
 use warnings;

 use Acme::CPANAuthors;
 use Data::Printer;

 # Create object.
 my $authors = Acme::CPANAuthors->new('Czech');

 # Get all ids.
 my @ids = $authors->id;

 # Print out.
 p @ids;

 # Output:
 # [
 #     [0]  "ATG",
 #     [1]  "BULB",
 #     [2]  "CHOROBA",
 #     [3]  "CONTYK",
 #     [4]  "DANIELR",
 #     [5]  "DANPEDER",
 #     [6]  "DOUGLISH",
 #     [7]  "DPOKORNY",
 #     [8]  "HIHIK",
 #     [9]  "HOLCAPEK",
 #     [10] "HPA",
 #     [11] "JANPAZ",
 #     [12] "JANPOM",
 #     [13] "JENDA",
 #     [14] "JIRA",
 #     [15] "JSPICAK",
 #     [16] "KLE",
 #     [17] "KOLCON",
 #     [18] "MAJLIS",
 #     [19] "MICHALS",
 #     [20] "MILSO",
 #     [21] "MIK",
 #     [22] "MJFO",
 #     [23] "PAJAS",
 #     [24] "PAJOUT",
 #     [25] "PASKY",
 #     [26] "PCIMPRICH",
 #     [27] "PEK",
 #     [28] "PETRIS",
 #     [29] "PKUBANEK",
 #     [30] "POPEL",
 #     [31] "PSME",
 #     [32] "RADIUSCZ"
 #     [33] "RUR",
 #     [34] "RVASICEK",
 #     [35] "SARFY",
 #     [36] "SEIDLJAN",
 #     [37] "SKIM",
 #     [38] "SMRZ",
 #     [39] "STRAKA",
 #     [40] "TKR",
 #     [41] "TPODER",
 #     [42] "TRIPIE",
 #     [43] "TYNOVSKY",
 #     [44] "VARISD",
 #     [45] "VASEKD",
 #     [46] "YENYA",
 #     [47] "ZABA",
 #     [48] "ZEMAN",
 #     [49] "ZOUL"
 # ]

=head1 DEPENDENCIES

L<Acme::CPANAuthors>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Acme-CPANAuthors-Czech>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.32

=cut
