


package DataCube::Controller;

use strict;
use warnings;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub new_from_datacube {
    my($class,$cube) = @_;
    my $self = bless {}, ref($class) || $class;
    $self->initialize($cube);
    return $self;
}

sub initialize {
    my($self,$cube) = @_;
    my $cubes = $cube->{cube_store}->cubes;
    $self->{lattice_points} = keys %$cubes; 
    for(keys %$cubes){
        my $name        = $cubes->{$_}->{schema}->{name};
        my $field_count = $cubes->{$_}->{schema}->{field_count};
        push @{$self->{cube_stats}->{field_count}->{$field_count}}, $name;
    }
    my @field_counts   = sort {$a <=> $b} keys %{$self->{cube_stats}->{field_count}};
    my $base_cube_name = $self->{cube_stats}->{field_count}->{$field_counts[ $#field_counts ]}->[0];
    $self->{cube_stats}->{base_cube_name} = $base_cube_name;
    lattice_assembly:
    for(my $i = 0; $i < $#field_counts; ++$i){
        my $child_size = $field_counts[$i];
        my @children = @{$self->{cube_stats}->{field_count}->{$child_size}};
        child_cube:
        for my $child_cube(@children){
            my $child_fields    = $cubes->{$child_cube}->{schema}->{field_names};
            my $subset_gaurdian = DataCube::Controller::SubsetGaurdian->new;
            for(my $j = $i + 1; $j < @field_counts; ++$j){
                my $parent_size   = $field_counts[$j];
                my $parent_source = $self->{cube_stats}->{field_count}->{$parent_size};
                my $parent_count  = @$parent_source;
                parent_selection:
                for(my $r = 0; $r < $parent_count; ++$r){
                    my $parent_cube   = $parent_source->[$r];
                    my $parent_fields = $cubes->{$parent_cube}->{schema}->{field_names};
                    for(keys %$child_fields){
                        next parent_selection unless exists $parent_fields->{$_}
                    }
                    next parent_selection if $subset_gaurdian->has_observed_a_proper_subset_of($parent_fields);
                    push @{$self->{cube_stats}->{possible_parents}->{$child_cube}}, $parent_cube;
                    $subset_gaurdian->observe($parent_fields);
                    my $pcount = @{$self->{cube_stats}->{possible_parents}->{$child_cube}};
                    my $k = $j - $i;
                    next child_cube if 
                            ($pcount > 0 && $k > 1) 
                         || ($pcount > 2 && $#field_counts > 6)
                         || ($pcount > 1 && $#field_counts > 7)
                         || ($pcount > 0 && $#field_counts > 8);
                }
            }
        }
    }
    return $self;
}



package DataCube::Controller::SubsetGaurdian;

sub new {
    my($class,%opts) = @_;
    return bless {%opts}, ref($class) || $class;
}

sub observe {
    my($self,$set) = @_;
    my @set_keys = sort keys %$set;
    my $set_key  = join("\t",@set_keys);
    $self->{observed_sets}->{$set_key}->{$_} = undef for @set_keys; 
    return $self;
}

sub has_observed_a_proper_subset_of {
    my($self,$set) = @_;
    subset_observation:
    for(keys %{$self->{observed_sets}}) {
        my %observed_set = %{$self->{observed_sets}->{$_}};
        for(keys %observed_set){
            next subset_observation unless exists $set->{$_};
        }
        return 1;
    }
    return 0;
}




1;






