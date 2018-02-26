package App::ForKids::LogicalPuzzleGenerator::Variable;

use strict;
use warnings FATAL => 'all';
use Carp;


=head1 NAME

App::ForKids::LogicalPuzzleGenerator - The great new App::ForKids::LogicalPuzzleGenerator!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::ForKids::LogicalPuzzleGenerator::Variable;

    my $foo = App::ForKids::LogicalPuzzleGenerator::Variable->new(amount_of_values=>3);
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut


sub new
{
	my $class = shift;
	my $this = { @_ };
	bless $this, $class;
	return $this;
}

1;
