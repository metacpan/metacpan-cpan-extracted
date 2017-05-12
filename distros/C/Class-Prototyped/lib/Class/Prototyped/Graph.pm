# Graph an object structure using GraphViz.
use Class::Prototyped;
use GraphViz;
use IO::File;

package Class::Prototyped::Mirror;
$Class::Prototyped::Mirror::VERSION = '1.13';

my %graphOpts = (
	R => 1,        # H or V orientation
	i => 'png',    # output format
	u => 0,        # output image map?
	s => 1,        # what kind of image map?
);

sub graphOptions {
	shift if ref( $_[0] );
	%graphOpts = ( %graphOpts, @_ );
}

# look familiar?
sub visitAllParents {
	my $mirror   = shift;
	my $sub      = shift;
	my $userData = shift;
	my $stack    = shift || [];
	my $seen     = shift || {};

	push ( @$stack, $mirror );
	$sub->( $parentMirror, $userData, $stack );
	foreach my $parent ( $mirror->parents ) {
		next unless UNIVERSAL::can( $parent, 'reflect' );
		my $parentMirror = $parent->reflect;
		$parentMirror->visitAllParents( $sub, $userData, $stack, $seen );
	}
	pop (@$stack);
}

sub _graphOneObject {
	my $mirror   = shift;
	my $data     = shift;
	my $g        = $data->[0];
	my $slotName = $data->[1];
	my $stack    = shift;

	my $name = $stack->[-1]->getSlot($slotName);
	$g->add_node($name);

	my $fromName;

	if ( @$stack >= 2 ) {
		$fromName = $stack->[-2]->getSlot($slotName);
		$g->add_edge( $fromName, $name );
	}
}

sub graph {
	shift if UNIVERSAL::isa( $_[0], 'Class::Prototyped::Mirror' );
	my $slotName = shift;

	my $outfile = 'graph.png';
	my $g = GraphViz->new( rankdir => $graphOpts{R} || 0 );

	foreach my $obj (@_) {
		my $mirror = $obj->reflect;
		$mirror->visitAllParents( \&_graphOneObject, [ $g, $slotName ] );
	}

	my $output = IO::File->new( $outfile, 'w' )
	  or die "can't open $outfile: $!\n";
	$output->print( eval "\$g->as_$graphOpts{i}()" );
	$output->close();

	if ( $graphOpts{u} ) {
		STDOUT->print( exists( $graphOpts{s} ) ? $g->as_imap : $g->as_ismap() );
	}
}

1;
