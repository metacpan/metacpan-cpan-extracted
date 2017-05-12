package Algorithm::SocialNetwork;
use Spiffy -Base;
use Quantum::Superpositions;
our $VERSION = '0.07';

field graph => {},
    -init => 'Graph->new()';

### negative value doesn't make sense for Bc
### Un-normlized result.
sub BetweenessCentrality {
    my @V  = $self->graph->vertices;
    my %CB; @CB{@V}=map{0}@V;
    for my $s (@V) {
        my (@S,$P,%sigma,%d,@Q);
        $P->{$_} = [] for (@V);
        @sigma{@V} = map{0}@V; $sigma{$s} = 1;
        @d{@V} = map{-1}@V; $d{$s} = 0;
        push @Q,$s;
        while(@Q) {
            my $v = shift @Q;
            push @S,$v;
            for my $w ($self->graph->neighbors($v)) {
                if($d{$w} < 0) {
                    push @Q,$w;
                    $d{$w} = $d{$v} + 1;
                }
                if($d{$w} == $d{$v} + 1) {
                    $sigma{$w} += $sigma{$v};
                    push @{$P->{$w}},$v;
                }
            }
        }
        my %rho; $rho{$_} = 0 for(@V);
        while(@S) {
            my $w = pop @S;
            for my $v (@{$P->{$w}}) {
                $rho{$v} += ($sigma{$v}/$sigma{$w})*(1+$rho{$w});
            }
            $CB{$w} += $rho{$w} unless $w eq $s;
        }
    }
    return @_? @CB{@_} : \%CB;
}

sub ClusteringCoefficient {
    my $vertex = shift;
    my @kv = $self->graph->neighbors($vertex);
    return unless @kv > 1;
    my $edges = $self->edges(@kv);
    return ($edges / ( @kv * (@kv - 1)));
}

sub WeightedClusteringCoefficient {
    my $vertex = shift;
    my @kv = $self->graph->neighbors($vertex);
    return unless @kv > 1;
    my $weight = 0;
    for($self->edges(@kv)) {
        $weight += $self->graph->get_edge_weight(@$_) || 1;
    }
    return ($weight / ( @kv * (@kv - 1)));
}

sub ClosenessCentrality {
    my $vertex = shift;
    my $sp = $self->graph->SPT_Dijkstra(first_root => $vertex);
    my $s = 0;
    for($self->graph->vertices) {
        $s += $sp->path_length($vertex,$_) || 0;
    }
    return 1/$s;
}

*DistanceCentrality = \&ClosenessCentrality;

sub GraphCentrality {
    my $vertex = shift;
    my $sp = $self->graph->SPT_Dijkstra(first_root => $vertex);
    my $s = -1;
    for(map { $sp->path_length($vertex,$_) || 0 }
            $self->graph->vertices) {
        $s = $_ if $_ > $s;
    }
    return 1/$s;
}

### edges between given nodes.
sub edges {
    my @nodes = @_;
    my @edges = grep {
        all(@$_) eq any(@nodes)
    } $self->graph->edges;
    return @edges;
}
