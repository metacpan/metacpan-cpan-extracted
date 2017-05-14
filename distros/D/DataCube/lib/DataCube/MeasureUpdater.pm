


package DataCube::MeasureUpdater;


use strict;
use warnings;


sub new {
    my($class,@opts,%opts) = @_;
    
    updater_opts:{
        %opts         = @opts    and last updater_opts if @_  > 2 && @_ % 2; 
        $opts{schema} = $opts[0] and last updater_opts if @_ == 2;
    }
    
    my $schema = $opts{schema};
    
    die   "DataCube::MeasureUpdater(new):\nmust pass a DataCube::Schema object to new\n$!\n"
    unless $schema && ref($schema) && ref($schema) =~ /^datacube::schema$/i;
    
    my $self = bless {}, ref($class) || $class;
    $self->{measures} = $schema->{measures};
    return $self;
}


sub update {
    my($self,%opts) = @_;

    my $source     = $opts{source};
    my $target     = $opts{target};
    my $source_key = $opts{source_key};
    my $target_key = $opts{target_key};

    #local $SIG{__WARN__} = sub {
    #    die '-' x 80 . "\n" .
    #        "DataCube::MeasureUpdater(update | warnings):\n".
    #        "caught a fatal exception here:\n$_[0]\n" . '-' x 80 . "\n" .
    #        join("\n", "source_key:   $source_key", "target_key:   $target_key") . '-' x 80 . "\n";
    #};

    update:
    for(@{$self->{measures}}) {
        
        if($_->[0] eq 'key_count'){
            
            next update unless exists $source->{$source_key}->{key_count};
            
            $target->{$target_key}->{key_count} +=
            $source->{$source_key}->{key_count};
            
            next update;
        }
        
        my $measure_field = $_->[1];
        
        if($_->[0] eq 'count'){
            next update unless exists $source->{$source_key}->{count}->{$measure_field};
            
            $target->{$target_key}->{count}->{$measure_field} = {}
                unless $target->{$target_key}->{count}->{$measure_field};
            
            my $target_area = $target->{$target_key}->{count}->{$measure_field};
            my $source_area = $source->{$source_key}->{count}->{$measure_field};
            
            $target_area->{$_} = undef for keys %$source_area;
            
            next update;
        }
          
        if($_->[0] eq 'multi_count'){
            next update unless exists $source->{$source_key}->{multi_count}->{$measure_field};
            
            $target->{$target_key}->{multi_count}->{$measure_field} = {}
                unless $target->{$target_key}->{multi_count}->{$measure_field};
            
            my $target_area = $target->{$target_key}->{multi_count}->{$measure_field};
            my $source_area = $source->{$source_key}->{multi_count}->{$measure_field};
            
            $target_area->{$_} += $source_area->{$_} for keys %$source_area;
            
            next update;
        }
        
        if($_->[0] eq 'sum'){
            next update unless exists $source->{$source_key}->{sum}->{$measure_field};
            
            $target->{$target_key}->{sum}->{$measure_field} +=
            $source->{$source_key}->{sum}->{$measure_field};
            
            next update;
        }

        if($_->[0] eq 'min'){
            next update unless defined $source->{$source_key}->{min}->{$measure_field};
            
            $target->{$target_key}->{min}->{$measure_field} =
            $source->{$source_key}->{min}->{$measure_field}
                if !defined $target->{$target_key}->{min}->{$measure_field}
                            || $target->{$target_key}->{min}->{$measure_field}
                             > $source->{$source_key}->{min}->{$measure_field};
            
            next update;
        }
        
        if($_->[0] eq 'max'){
            next update unless defined $source->{$source_key}->{max}->{$measure_field};
            
            $target->{$target_key}->{max}->{$measure_field} =
            $source->{$source_key}->{max}->{$measure_field}
                if !defined $target->{$target_key}->{max}->{$measure_field}
                            || $target->{$target_key}->{max}->{$measure_field} 
                             < $source->{$source_key}->{max}->{$measure_field};
            
            next update;
        }
        
        if($_->[0] eq 'product'){
            next update unless exists $source->{$source_key}->{product}->{$measure_field};
            
            $target->{$target_key}->{product}->{$measure_field} = 1
            unless defined $target->{$target_key}->{product}->{$measure_field};
            
            $target->{$target_key}->{product}->{$measure_field} *=
            $source->{$source_key}->{product}->{$measure_field};
            
            next update;
        }
        
        if($_->[0] eq 'average'){
            next update unless exists $source->{$source_key}->{average}->{$measure_field}->{sum_total};
                
            $target->{$target_key}->{average}->{$measure_field}->{sum_total}    += 
            $source->{$source_key}->{average}->{$measure_field}->{sum_total};
            
            $target->{$target_key}->{average}->{$measure_field}->{observations} += 
            $source->{$source_key}->{average}->{$measure_field}->{observations};
            
            next update;
        }
        
    }

    return $self;
}








1;