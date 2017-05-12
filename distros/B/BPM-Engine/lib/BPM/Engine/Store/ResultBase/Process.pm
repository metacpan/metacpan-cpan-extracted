package BPM::Engine::Store::ResultBase::Process;
BEGIN {
    $BPM::Engine::Store::ResultBase::Process::VERSION   = '0.01';
    $BPM::Engine::Store::ResultBase::Process::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

sub new_instance {
    my ($self, $attrs) = @_;
    $attrs ||= {};
    
    my $guard = $self->result_source->schema->txn_scope_guard;    

    my $process_instance = $self->add_to_instances($attrs);
    
    if(my $package = $self->package) {
        $process_instance->create_attributes('container', $package->data_fields)
            if $package->data_fields;
        }
    $process_instance->create_attributes('fields', $self->data_fields)
        if $self->data_fields;
    $process_instance->create_attributes('params', $self->formal_params)
        if $self->formal_params;
    
    $guard->commit;
    
    return $process_instance;
    }

sub start_activities {
    my $self = shift;
    #my @v = $self->graph->source_vertices();
    #return [ map($self->activities->find($_), @v)  ];
    my @start = grep { $_->is_start_activity } $self->activities->all;
    return \@start;
    }

sub start_activity {
    my $self = shift;
    my $start = $self->start_activities;
    die('Multiple start activities detected') unless scalar @{$start} == 1;
    return $start->[0];
    }

sub mark_back_edges {
    my $self = shift;
    
    my $g = $self->graph;
    return unless $g->is_cyclic;
    
    $g = $g->copy_graph;
    #warn "Graph: ", $g->stringify(), "\n";
    my @v = sort $g->vertices();
    my @sources = $g->source_vertices();
    my $start = $sources[0]; # $self->start_activity->id;
    
    # find and remove all cycles
    while( my @cyc = $g->find_a_cycle() ) {
        my $apsp = $g->APSP_Floyd_Warshall();
        my %dist = map { $_ => $apsp->path_length($start, $_) } @cyc;
        my $far = (sort { $dist{$a} <=> $dist{$b} } keys %dist )[-1];
        #warn "Farthest vertex is $far";
        CYC: for my $v(@cyc) {
            next if $v eq $far;
            next unless $g->has_edge($far,$v);
            
            $self->transitions({ from_activity_id => $far, to_activity_id => $v })
                ->first->update({ is_back_edge => 1 });
            
            # Remove edge (${far}->$v)
            $g->delete_edge($far,$v);
            $g->add_edge($v,$far);
            #warn "Graph is now: " . $g->stringify();
            last CYC;
            }
        
        }
    }

no Moose::Role;

1;
__END__