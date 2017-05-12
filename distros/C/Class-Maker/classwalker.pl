# Author: Murat Uenalan (muenalan@cpan.org)
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
# Note: This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

use lib( '.' );

use IO::Extended ':all';

use Class::Maker qw(classes);

println "\nUsage: $0 package [ ModuleName ] .. i.e. Web::Object" unless @ARGV;

my $what = shift if @ARGV > 1 ;

$what |= 'main::';

map { eval "require $_" } @ARGV;

my @all = classes( $what );

foreach( @all )
{
	my ( $cls, $href_cls ) = @{ %{ $_ } };

	if( $cls )
	{
		printfln "\n%-30s", $cls;

		printfln "isa => %s", join( ', ', @{ $href_cls->{isa} } ) || '' if $href_cls->{isa};

		printfln "methods => %s", join( ', ', @{ $href_cls->{methods} } ) || '' if $href_cls->{methods};
	}
}

	use Text::Flowchart;

	my $flowchart = Text::Flowchart->new( width => 100 ); #, pad => ".", debug => 1 );

	my $counter;

	my @boxes;

	my $cls = 'Oh shit';

	foreach( @all )
	{
		my ( $cls, $href_cls ) = each %$_;

		if( $cls )
		{
			#push @boxes, $flowchart->box( x_coord => 0 + $counter, y_coord => 0 + $counter, width => 30, string => $cls );

			#$flowchart->relate( [ $boxes[-1], "right"] => [ $boxes[-2], "left"] ) if @boxes > 1;

			push @boxes, $flowchart->box( x_coord => 1, y_coord => 0 + $counter, width => (length $cls) + 4, string => $cls );

			$counter += $boxes[-1][7];

			#printfln "isa => %s", join( ', ', @{ $href_cls->{isa} } ) || '' if $href_cls->{isa};

			#printfln "methods => %s", join( ', ', @{ $href_cls->{methods} } ) || '' if $href_cls->{methods};
		}
	}

=head1

	$flowchart->relate(
		[$example_box, "right"] => [$example_box2, "left"],
		reason => "Y"
	);

	$flowchart->relate(
		[$example_box, "right", -1] => [$example_box3, "left"],
		reason => "N"
	);

=cut
    $flowchart->draw();
