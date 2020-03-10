package Acme::CPANAuthors::Slovak;

use strict;
use utf8;
use warnings;

our $VERSION = 0.27;

# Modules.
use Acme::CPANAuthors::Register(
	'BARNEY' => 'Branislav Zahradník',
	'JKUTEJ' => 'Jozef Kutej',
	'PALI' => 'Pavol Rohár',
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Acme::CPANAuthors::Slovak - We are Slovak CPAN authors.

=head1 SYNOPSIS

 use Acme::CPANAuthors;

 my $authors = Acme::CPANAuthors->new('Slovak');
 my $url = $authors->avatar_url('PALI');
 my $number = $authors->count;
 my @distors = $authors->distributions('JKUTEJ');
 my @ids = $authors->id;
 my $kwalitee = $authors->kwalitee('BARNEY');
 my $name = $authors->name('PALI');

=head1 DESCRIPTION
 
See documentation for L<Acme::CPANAuthors> for more details.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Acme::CPANAuthors;

 # Create object.
 my $authors = Acme::CPANAuthors->new('Slovak);

 # Get number of Slovak CPAN authors.
 my $count = $authors->count;

 # Print out.
 print "Count of Slovak CPAN authors: $count\n";

 # Output:
 # Count of Slovak CPAN authors: 3

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Acme::CPANAuthors;
 use Data::Printer;

 # Create object.
 my $authors = Acme::CPANAuthors->new('Slovak');

 # Get all ids.
 my @ids = $authors->id;

 # Print out.
 p @ids;

 # Output:
 # [
 #     [0]  "BARNEY",
 #     [1]  "JKUTEJ",
 #     [2]  "PALI",
 # ]

=head1 DEPENDENCIES

L<Acme::CPANAuthors>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Acme-CPANAuthors-Slovak>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
