package AI::CBR::Case;

use warnings;
use strict;

our $DEFAULT_WEIGHT = 1;


=head1 NAME

AI::CBR::Case - case definition and representation


=head1 SYNOPSIS

Define and initialise a case.
In a productive system, you will want to encapsulate this.

    use AI::CBR::Case;
    use AI::CBR::Sim qw(sim_frac sim_eq sim_set);

    # assume we are a doctor and see a patient
    # shortcut one-time generated case
    my $case = AI::CBR::Case->new(
    	age      => { value => 30,             sim => \&sim_frac },
    	gender   => { value => 'male',         sim => \&sim_eq   },
    	job      => { value => 'programmer',   sim => \&sim_eq   },
    	symptoms => { value => [qw(headache)], sim => \&sim_set  },
    );
    
    # or case-specification with changing data
    my $patient_case = AI::CBR::Case->new(
    	age      => { sim => \&sim_frac },
    	gender   => { sim => \&sim_eq   },
    	job      => { sim => \&sim_eq   },
    	symptoms => { sim => \&sim_set  },
    );
    
    foreach my $patient (@waiting_queue) {
    	$patient_case->set_values( %$patient ); # assume $patient is a hashref with the right attributes
    	...
    }
    ...

=head1 METHODS

=head2 new

Creates a new case specification.
Pass a hash of hash references as argument.
The hash keys identify the attributes of the case,
the hash reference specifies this attribute,
with the following values:

=over 4

=item * B<sim>: a reference to the similarity function to use for this attribute

=item * B<param>: the parameter for the similarity function, if required

=item * B<weight>: the weight of the attribute in the comparison of the case. If you do not give a weight value for an attribute, the package's C<$DEFAULT_WEIGHT> will be used, which is 1 by default.

=item * B<value>: the value of the attribute, if you want to specify the complete case immediately. You can also do this later.

=back

=cut

sub new {
	my ($class, %attributes) = @_;
	
	# set default weights if unspecified
	foreach (keys %attributes) {
		$attributes{$_}->{weight} = $DEFAULT_WEIGHT unless defined $attributes{$_}->{weight};
	}
	
	my $self = \%attributes;
	bless $self, $class;
	return $self;
}


=head2 set_values

Pass a hash of attribute keys and values.
This will overwrite existing values, and can thus be used as a faster method
for generating new cases with the same specification.

=cut

sub set_values {
	my ($self, %values) = @_;
	foreach (keys %values) {
		$self->{$_}->{value} = $values{$_};
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

    perldoc AI::CBR::Case


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

1; # End of AI::CBR::Case
