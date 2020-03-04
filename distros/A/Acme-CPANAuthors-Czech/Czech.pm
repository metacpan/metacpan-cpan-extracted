package Acme::CPANAuthors::Czech;

use strict;
use utf8;
use warnings;

our $VERSION = 0.25;

# Modules.
use Acme::CPANAuthors::Register(
	'CHOROBA' => 'E. Choroba',
	'DANIELR' => 'Roman Daniel',
	'DANPEDER' => 'Daniel Peder',
	'DOUGLISH' => 'Dalibor Hořínek',
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
	'MILSO' => 'Milan Šorm',
	'MJFO' => 'Michal Jurosz',
	'PAJAS' => 'Petr Pajas',
	'PASKY' => 'Petr Baudiš',
	'PEK' => 'Petr Kletečka',
	'POPEL' => 'Martin Popel',
	'PSME' => 'Petr Šmejkal',
	'RUR' => 'Rudolf Rosa',
	'RVASICEK' => 'Roman Vašíček',
	'SEIDLJAN' => 'Jan Seidl',
	'SKIM' => 'Michal Josef Špaček',
	'SMRZ' => 'Otakar Smrž',
	'STRAKA' => 'Milan Straka',
	'TKR' => 'Tomáš Kraut',
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
 # Count of Czech CPAN authors: 38

=head1 EXAMPLE2

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
 #     [0]  "CHOROBA",
 #     [1]  "DANIELR",
 #     [2]  "DANPEDER",
 #     [3]  "DOUGLISH",
 #     [4]  "HIHIK",
 #     [5]  "HOLCAPEK",
 #     [6]  "HPA",
 #     [7]  "JANPAZ",
 #     [8]  "JANPOM",
 #     [9]  "JENDA",
 #     [10] "JIRA",
 #     [11] "JSPICAK",
 #     [12] "KLE",
 #     [13] "KOLCON",
 #     [14] "MAJLIS",
 #     [15] "MICHALS",
 #     [16] "MILSO",
 #     [17] "MJFO",
 #     [18] "PAJAS",
 #     [19] "PASKY",
 #     [20] "PEK",
 #     [21] "POPEL",
 #     [22] "PSME",
 #     [23] "RUR",
 #     [24] "RVASICEK",
 #     [25] "SEIDLJAN",
 #     [26] "SKIM",
 #     [27] "SMRZ",
 #     [28] "STRAKA",
 #     [29] "TKR",
 #     [30] "TRIPIE",
 #     [31] "TYNOVSKY",
 #     [32] "VARISD",
 #     [33] "VASEKD",
 #     [34] "YENYA",
 #     [35] "ZABA",
 #     [36] "ZEMAN",
 #     [37] "ZOUL"
 # ]

=head1 DEPENDENCIES

L<Acme::CPANAuthors>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Acme-CPANAuthors-Czech>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.25

=cut
