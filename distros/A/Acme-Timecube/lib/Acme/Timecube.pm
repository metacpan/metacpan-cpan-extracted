package Acme::Timecube;

use HTML::TreeBuilder;
use LWP::UserAgent;

use strict;
use warnings;

our $VERSION = '0.01';
our @METHODS = (['debate', 'discourse', 'discussion', 'dissertation', 'essay', 
		'exposition', 'lecture', 'preach', 'sermon', 'speech', 'treatise'],
		[10, 8, 4, 18, 25, 7, 22, 1, 13, 9, 30]);

{
	no strict 'refs';
	my $c = -1;	

	foreach my $m (@{$METHODS[0]}) {
		*{ __PACKAGE__.'::'.$m } = sub {
			for ( 1 .. $METHODS[1][$c++] ) { $_[0]->__truth }
		}
	}
}

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{ua} = LWP::UserAgent->new;
	$self->{wisdom} = HTML::TreeBuilder->new_from_content( $self->{ua}->get( 'http://www.timecube.com' )->decoded_content );
	$self->{wisdom} or die "Couldn't fetch wisdom...\n";
	@{ $self->{verses} } = $self->{wisdom}->find_by_tag_name( 'p' );
	return $self
}

sub __truth {
	print @{ $_[0]->{verses} }[ int rand scalar @{ $_[0]->{verses} } ]->as_trimmed_text( extra_chars => '\xA0' )."\n"
}

=head1 NAME

Acme::Timecube - Installs 4 corner cubic wisdom.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Acme::Timecube;

    my $tc = Acme::Timecube->new();

    # Preach cubic wisdom
    $tc->preach;

    # Deliver a discourse on 4 corner day logic
    $tc->discourse;

    # A lecture on why you are a stupid educated fool
    $tc->lecture;

=head1 METHODS

=head2 new

Creates a new L<Acme::Timecube> object.

=head2 debate, discourse, discussion, dissertation, essay, exposition, lecture, preach, sermon, speech, treatise

Deliver a debate, discourse, discussion, dissertation, essay, exposition, lecture, preach, 
sermon, speech or treatise on Timecube philosophy and science.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

None.  Acme::Timecube is free from your stupid, academic 1 day bugs.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Timecube

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Timecube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Timecube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Timecube>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Timecube/>

=back

=head1 ACKNOWLEDGEMENTS

Gene Ray - mad props

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
