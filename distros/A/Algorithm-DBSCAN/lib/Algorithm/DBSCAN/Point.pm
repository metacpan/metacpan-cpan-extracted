package Algorithm::DBSCAN::Point;
use Data::Dumper;

sub new {
	my($type, $point_id, @coordinates) = @_;
	
	my $self = {};
	
	$self->{cluster_id} = 0;
	$self->{point_id} = $point_id;
	$self->{coordinates} = \@coordinates;
	
	bless($self, $type);

	return($self);
}

sub Distance {
	my ($self, $point) = @_;
	
	my $distance;
	
	my $i = 0;
	foreach my $c (@{$self->{coordinates}}) {
		$distance += ($c - $point->{coordinates}->[$i]) * ($c - $point->{coordinates}->[$i]);
		$i++;
	}
	
	return $distance;
}

sub Dimensions {
	my ($self) = @_;
	
	return scalar(@{$self->{coordinates}});
}

1;