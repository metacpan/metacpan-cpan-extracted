package AI::CBR::Case::Compound;

use warnings;
use strict;

our $DEFAULT_WEIGHT = 1;


=head1 NAME

AI::CBR::Case::Compound - compound case definition and representation


=head1 SYNOPSIS

Define and initialise a compound (or object-oriented) case.
This is a case consisting of multiple object definitions related in some way.
In a productive system, you will want to encapsulate this.

    use AI::CBR::Case::Compound;
    use AI::CBR::Sim qw(sim_eq sim_dist);

    # assume we sell travels with flight and hotel
    # shortcut one-time generated case
    my $case = AI::CBR::Case::Compound->new(
    	# flight object
    	{
			flight_start  => { value => 'FRA', sim => \&sim_eq },
			flight_target => { value => 'LIS', sim => \&sim_eq },
			price         => { value => 300,   sim => \&sim_dist, param => 200 },
		},
		# hotel object
		{
			stars => { value => 3,  sim => \&sim_dist, param => 2 },
			rate  => { value => 60, sim => \&sim_dist, param => 200 },		
		},
    );

    ...

=head1 METHODS

=head2 new

Creates a new compound case specification.
Pass a list of hash references as argument.
Each hash reference is the same specification as passed to L<AI::CBR::Case>.

=cut

sub new {
	my ($class, @definitions) = @_;
	
	# set default weights if unspecified
	foreach my $attributes (@definitions) {
		foreach (keys %$attributes) {
			$attributes->{$_}->{weight} = $DEFAULT_WEIGHT unless defined $attributes->{$_}->{weight};
		}
	}
	
	my $self = \@definitions;
	bless $self, $class;
	return $self;
}


=head2 set_values

Pass a flat hash of attribute keys and values.
This will overwrite existing values, and can thus be used as a faster method
for generating new cases with the same specification.
Notice that keys in the different specifications of the compound object may not have the same name!

=cut

sub set_values {
	my ($self, %values) = @_;
	foreach my $spec (@$self) {
		foreach (keys %$spec) {
			$spec->{$_}->{value} = $values{$_};
		}
	}
}


=head1 SEE ALSO

See L<AI::CBR> for an overview of the framework.


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-cbr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-CBR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::CBR::Case::Compound


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-CBR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AI-CBR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AI-CBR>

=item * Search CPAN

L<http://search.cpan.org/dist/AI-CBR>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AI::CBR::Case::Compound
