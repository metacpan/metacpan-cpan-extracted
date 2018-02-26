package App::ForKids::LogicalPuzzleGenerator::Variable::Profession;

use strict;
use warnings FATAL => 'all';
use Carp;
use base 'App::ForKids::LogicalPuzzleGenerator::Variable';



=head1 NAME

App::ForKids::LogicalPuzzleGenerator::Variable::Profession

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The module is used by the App::ForKids::LogicalPuzzleGenerator.

    use App::ForKids::LogicalPuzzleGenerator;

=cut


our @professions =
(
	"wizard",
	"warrior",
	"witcher",
	"blacksmith",
	"fisherman",
	"lumberjack"
);


=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);

	# select the professions
	for my $i (0..$$this{amount_of_values}-1)
	{
		while (1)
		{
			my $value = $professions[int(rand()*@professions)];
			if (!grep {$_ eq $value } @{$$this{selected_values}})
			{
				push @{$$this{selected_values}}, $value;
				last;
			}
		}
	}
	return $this;
}

=head2 get_description

=cut

sub get_description
{
	return "Each has a different profession";
}

=head2 get_description_I

=cut

sub get_description_I
{
	my ($this, $profession) = @_;
	return sprintf("I am a %s.", $profession);
}

=head2 get_description_I_dont

=cut

sub get_description_I_dont
{
	my ($this, $profession) = @_;
	return sprintf("I am not a %s.", $profession);
}

=head2 get_description_he_does_not

=cut

sub get_description_he_does_not
{
	my ($this, $profession) = @_;
	return sprintf("is not a %s.", $profession);
}

=head2 get_description_the_one_who

=cut

sub get_description_the_one_who
{
	my ($this, $profession) = @_;
	return sprintf("The %s", $profession);
}

=head2 get_description_X

=cut

sub get_description_X
{
	my ($this, $who, $profession) = @_;
	return sprintf("%s is a %s.", $who, $profession);
}


=head2 get_description_X_does_not

=cut

sub get_description_X_does_not
{
	my ($this, $who, $profession) = @_;
	return sprintf("%s is not a %s.", $who, $profession);
}

=head2 get_description_he_likes

=cut

sub get_description_he_likes
{
	my ($this, $profession) = @_;
	return sprintf("is a %s.", $profession);
}



=head1 AUTHOR

Pawel Biernacki, C<< <pawel.f.biernacki at gmail> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-forkids-logicalpuzzlegenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ForKids-LogicalPuzzleGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=cut

1;
