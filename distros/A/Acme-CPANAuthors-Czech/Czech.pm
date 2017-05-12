package Acme::CPANAuthors::Czech;

# Pragmas.
use strict;
use utf8;
use warnings;

# Version.
our $VERSION = 0.22;

# Modules.
use Acme::CPANAuthors::Register(
	'CHOROBA' => 'E. Choroba',
	'DANIELR' => 'Roman Daniel',
	'DANPEDER' => 'Daniel Peder',
	'DOUGLISH' => 'Dalibor Hořínek',
	'HIHIK' => 'Jiří Václavík',
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
	'SKIM' => 'Michal Špaček',
	'SMRZ' => 'Otakar Smrž',
	'STRAKA' => 'Milan Straka',
	'TKR' => 'Tomáš Kraut',
	'TRIPIE' => 'Tomáš Stýblo',
	'TYNOVSKY' => 'Miroslav Týnovský',
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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Acme::CPANAuthors;

 # Create object.
 my $authors = Acme::CPANAuthors->new('Czech');

 # Get number of Czech CPAN authors.
 my $count = $authors->count;

 # Print out.
 print "Count of Czech CPAN authors: $count\n";

 # Output:
 # Count of Czech CPAN authors: 36

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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
 #     [5]  "HPA",
 #     [6]  "JANPAZ",
 #     [7]  "JANPOM",
 #     [8]  "JENDA",
 #     [9]  "JIRA",
 #     [10] "JSPICAK",
 #     [11] "KLE",
 #     [12] "KOLCON",
 #     [13] "MAJLIS",
 #     [14] "MICHALS",
 #     [15] "MILSO",
 #     [16] "MJFO",
 #     [17] "PAJAS",
 #     [18] "PASKY",
 #     [19] "PEK",
 #     [20] "POPEL",
 #     [21] "PSME",
 #     [22] "RUR",
 #     [23] "RVASICEK",
 #     [24] "SEIDLJAN",
 #     [25] "SKIM",
 #     [26] "SMRZ",
 #     [27] "STRAKA",
 #     [28] "TKR",
 #     [29] "TRIPIE",
 #     [30] "TYNOVSKY",
 #     [31] "VASEKD",
 #     [32] "YENYA",
 #     [33] "ZABA",
 #     [34] "ZEMAN",
 #     [35] "ZOUL"
 # ]

=head1 DEPENDENCIES

L<Acme::CPANAuthors>.

=head1 REPOSITORY

L<https://github.com/tupinek/Acme-CPANAuthors-Czech>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2016 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.22

=cut
