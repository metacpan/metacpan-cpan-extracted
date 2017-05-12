package Acme::BloodType;

use warnings;
use strict;

=head1 NAME

Acme::BloodType - For those obsessed with celebrities' blood types

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Allows you to model people with different blood-types and see what would
happen if they had a kid. Alpha version handles ABO only for now.

  use Acme::BloodType;

  # Hooray for gene sequencers
  $mary = Acme::BloodType->new({ genotype => "AA" });
  $bill = Acme::BloodType->new({ phenotype => "O" });

  $baby = $mary->cross($bill);

  print "It's a ", $baby->get_bloodtype, "!\n";

=cut

my $alleles = [ "O", "A", "B" ];
my $phenotypes = [ "O", "A", "B", "AB" ];

my $geno_pheno = {
	"OO" => "O",
	"OA" => "A", "AO" => "A", "AA" => "A",
	"OB" => "B", "BO" => "B", "BB" => "B",
	"AB" => "AB", "BA" => "AB"
};

=head1 METHODS

=head2 Acme::BloodType->new(\%specifier)

Create an Acme::Bloodtype object representing a person. You may specify
genotype, phenotype (in which case a genotype is chosen at random), or nothing,
in which case it's all random. Probabilities don't (yet) model real-world
distributions.

=cut

sub new {
	my ($class, $init) = @_;

	my $self = {};

	if (defined $init && defined $init->{'genotype'}) {
		return undef unless $geno_pheno->{ $init->{'genotype'} };
		$self->{'genotype'} = $init->{'genotype'};
	} elsif (defined $init && defined $init->{'phenotype'}) {
		my @possible = grep { $geno_pheno->{$_} eq $init->{'phenotype'} } keys %$geno_pheno;
		return undef unless @possible;
		$self->{'genotype'} = $possible[rand @possible];
	} else {
		my @possible = keys %$geno_pheno;
		$self->{'genotype'} = $possible[rand @possible];
	}

	return bless $self, $class;
}

=head2 $bt->get_bloodtype

Get the bloodtype (phenotype) of this person. Returns "A", "B", "AB", or "O".

=cut

sub get_bloodtype {
	my ($self) = @_;

	return $geno_pheno->{ $self->{'genotype'} };
}

=head2 $bt->get_genotype

Get the genotype of this person. Returns a string of two characters, which
may be "A", "B", or "O".

=cut

sub get_genotype {
	my ($self) = @_;
	return $self->{'genotype'};
}

=head2 $bt1->cross($bt2)

"Mate" one person with the other, producing a result chosen randomly in the
style of Mendel.

=cut

sub cross {
	my ($self, $other) = @_;

	die "Uh?" unless $other->isa(__PACKAGE__);

	my $from_self = substr $self->get_genotype, int rand 2, 1;
	my $from_other = substr $other->get_genotype, int rand 2, 1;

	return __PACKAGE__->new({ genotype => $from_self . $from_other });
}

=head1 AUTHOR

Andrew Rodland, C<< <ARODLAND at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-bloodtype at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-BloodType>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::BloodType

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-BloodType>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-BloodType>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-BloodType>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-BloodType>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Andrew Rodland, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::BloodType
