package Algorithm::DBSCAN::Dataset;


sub new {
	my($type) = @_;
	
	my $self = {};
	$self->{points} = {};
		
	bless($self, $type);

	return($self);
}

sub AddPoint {
	my ($self, $point) = @_;
	
	my $nb_points = scalar(keys %{$self->{points}});
	$point->{visited} = 0;
	$point->{id} = $nb_points;
	if ($nb_points) {
		if ( $point->Dimensions() == $self->{points}->{0}->Dimensions() ) {
			$self->{points}->{$nb_points} = $point;
		}
		else {
			die "You can only add points with [".$self->{points}->{0}->Dimensions()."] dimensions";
		}
	}
	else {
		$self->{points}->{0} = $point;
	}
	
	return 1;
}

sub GetPointById {
	my ($self, $id) = @_;
	
	return $self->{points}->{$id};
}

sub GetPointByPublicId {
        my ($self, $point_id) = @_;

	my $point;
        foreach my $id (keys %{$self->{points}}) {
                $point = $self->{points}->{$id} if ($self->{points}->{$id}->{point_id} eq $point_id);
	}

	return $point;
}

1;