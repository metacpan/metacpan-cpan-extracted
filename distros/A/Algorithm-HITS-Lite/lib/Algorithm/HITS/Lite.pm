package Algorithm::HITS::Lite;
use Spiffy -Base;
our $VERSION = '0.04';

=head1 NAME

Algorithm::HITS::Lite - HITS algorithm implementation not requiring PDL

=head1 SYNOPSIS

    my $ah = Algorithm::HITS::Lite->new(network => $adjm);
    my ($hub,$auth) = $ah->iterate(10);

=cut

field 'network';
field nodes => -init => '$self->_collect_nodes';

=head1 APIs

=head2 new(network => $adjm)

The required parameter $adjm is the 'Adjency Matrix' presentation of
network, must be a hashref of hashref.

=head2 iterate($k)

Iterate the process for $k timesm, default to 10 if it's not given.
Return a ($hub,$auth) weight pair. Each is a hashref with
keys are the same as keys in $adjm.

=cut

sub iterate {
    my $k = shift || 10; # iter k times
    my $nodes = $self->nodes;
    my $xi = $self->_build_z(@$nodes);
    my $yi = $self->_build_z(@$nodes);
    my ($xj,$yj) = ($xi,$yi);
    for(1..$k) {
	$xj = $self->_op_T($xi,$yi);
	$yj = $self->_op_O($xj,$yi);
	$xi = $self->_normalize_xy($xj);
	$yi = $self->_normalize_xy($yj);
    }
    return($xi,$yi);
}

# Collect adjency matrix nodes.
# (All hash keys)
sub _collect_nodes {
    my $adjm = $self->network;
    my %nodes;
    for my $k1 (keys %$adjm) {
	$nodes{$k1} = 1;
	for my $k2 (keys %{$adjm->{$k1}}) {
	    $nodes{$k2} = 1;
	}
   }
    my @n = keys %nodes;
    $self->nodes(\@n);
    return [@n];
}

sub _build_z {
    my $z = {};
    $z->{$_} = 1 for(@_);
    return $z;
}

sub _normalize_xy {
    my $x = shift;
    my @vs = values %$x;
    my $sq = sqrt($self->sqsum(@vs));
    if($sq == 0) {
	for(keys %$x) {
	    $x->{$_} = 0;
	}
    } else {
	for(keys %$x) {
	    $x->{$_} /= $sq;
	}
    }
    return $x;
}


sub _op_T {
    my ($x,$y) = @_;
    my $nx;
    my $g = $self->network;
    my $nodes = $self->nodes;
    for my $h (@$nodes) {
	$nx->{$h} = 0;
	for my $p (@$nodes) {
	    $nx->{$h} += $y->{$p} if($g->{$h}->{$p});
	}
    }
    return $nx;
}

sub _op_O {
    my ($x,$y) = @_;;
    my $ny;
    my $g = $self->network;
    my $nodes = $self->nodes;
    for my $p (@$nodes) {
	$ny->{$p} = 0;
	for my $h (@$nodes) {
	    $ny->{$p} += $x->{$h} if($g->{$h}->{$p});
	}
    }
    return $ny;
}


=head2 sqsum(@list)

Internally used, return Square Sum of all numbers in @list.

=cut

sub sqsum {
    my $sum = 0;
    $sum += $_*$_ for(@_);
    return $sum;
}



=head1 SEE ALSO

L<Algorithm::HITS>, L<Algorithm::PageRank>

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
