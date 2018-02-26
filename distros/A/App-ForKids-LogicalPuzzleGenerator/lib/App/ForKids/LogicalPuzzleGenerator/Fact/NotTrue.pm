package App::ForKids::LogicalPuzzleGenerator::Fact::NotTrue;

use strict;
use warnings FATAL => 'all';
use Carp;
use App::ForKids::LogicalPuzzleGenerator::Fact;
use base 'App::ForKids::LogicalPuzzleGenerator::Fact';


=head1 NAME

App::ForKids::LogicalPuzzleGenerator::Fact::NotTrue

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

The module is used by the App::ForKids::LogicalPuzzleGenerator.

    use App::ForKids::LogicalPuzzleGenerator;

=head1 SUBROUTINES/METHODS

=head2 new

=cut


sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);
	$$this{value} = 0;
	return $this;
}


=head1 AUTHOR

Pawel Biernacki, C<< <pawel.f.biernacki at gmail> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-forkids-logicalpuzzlegenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ForKids-LogicalPuzzleGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=cut

1;
