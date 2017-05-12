


package DataCube;

use 5.008008;
our $VERSION = '0.01';

use strict;
use warnings;

use Fcntl;
use URI::file;
use Digest::MD5;
use Time::HiRes;
use Data::Dumper;
use Cwd qw(getcwd);
use Storable qw(nstore);
use Scalar::Util qw(reftype);

use constant {
    read_only      => O_RDONLY,
    write_only     => O_WRONLY,
    create_write   => O_CREAT|O_WRONLY,
    vip_read_write => O_CREAT|O_WRONLY|O_EXCL,
};

use DataCube::Cube;
use DataCube::Schema;
use DataCube::FileUtils;
use DataCube::CubeStore;
use DataCube::Controller;
use DataCube::PathWalker;
use DataCube::Connection;
use DataCube::FileUtils::FileReader;

sub new {
    my($class,@opts,%opts) = @_;
    datacube_opts_collection: {
        %opts         = @opts    and last datacube_opts_collection if @_  > 2 && @_ % 2; 
        $opts{schema} = $opts[0] and last datacube_opts_collection if @_ == 2;
    }
    my $self = bless {}, ref($class) || $class;
    return $self->retrieve($opts[0]) if defined($opts[0]) && -f($opts[0]) && @opts == 1;
    return $self unless @opts;
    $self->{cube_store} = DataCube::CubeStore->new;
    schema_initialization: {
        last schema_initialization unless
                       $opts{schema}
                && ref($opts{schema})
                && ref($opts{schema}) =~ /^datacube::schema$/i;
        die "DataCube(new : schema init):\nyour schema does not contain any measures\n$!\n"
            unless $opts{schema}->{measures};
        $opts{schema}->initialize;
        $self->build_lattice_tables (
            schema => $opts{schema},
        );
    }
    $self->{updater}   = DataCube::MeasureUpdater->new($opts{schema});
    my $base_cube_name = $self->{controller}->{cube_stats}->{base_cube_name};
    $self->{meta_data}->{system}->{base_cube_name} = $base_cube_name;
    $self->{meta_data}->{system}->{base_schema} = $opts{schema};
    $self->{base_cube} = $self->{cube_store}->{cubes}->{$base_cube_name};
    return $self;
}

# change to modify:
# ------------------------------------------------------------------------------
# DataCube::insert
# DataCube::reset_measures
# DataCube::MeasureUpdater::update
# DataCube::Cube::describe
# DataCube::Cube::to_table
# Warehouse::Builder::*
# ------------------------------------------------------------------------------

sub insert {
    my($self,$data) = @_;
    my @keys;
    push @keys, $data->{$_} for @{$self->{base_cube}->{schema}->{fields}};
    my $key = join("\t",@keys);
    measure_update: 
    for(@{$self->{base_cube}->{schema}->{measures}}){
        
        if($_->[0] eq 'key_count'){
            ++$self->{base_cube}->{cube}->{$key}->{key_count};
            next measure_update;
        }
        
        my $data_key = $data->{$_->[1]};
        
        if($_->[0] eq 'count'){
            $self->{base_cube}->{cube}->{$key}->{count}->{$_->[1]}->{$data_key} = undef;
            next measure_update;
        }
        
        if($_->[0] eq 'multi_count'){
            ++$self->{base_cube}->{cube}->{$key}->{multi_count}->{$_->[1]}->{$data_key};
            next measure_update;
        }
        
        if($_->[0] eq 'sum'){
            $self->{base_cube}->{cube}->{$key}->{sum}->{$_->[1]} += $data_key;
            next measure_update;
        }
        
        if($_->[0] eq 'average'){
            $self->{base_cube}->{cube}->{$key}->{average}->{$_->[1]}->{sum_total}   += $data_key;
            ++$self->{base_cube}->{cube}->{$key}->{average}->{$_->[1]}->{observations};
            next measure_update;
        }
        
        if($_->[0] eq 'max'){
            $self->{base_cube}->{cube}->{$key}->{max}->{$_->[1]} = $data_key unless defined $self->{base_cube}->{cube}->{$key}->{max}->{$_->[1]};
            $self->{base_cube}->{cube}->{$key}->{max}->{$_->[1]} = $data_key if $data_key > $self->{base_cube}->{cube}->{$key}->{max}->{$_->[1]};
            next measure_update;
        }
        
        if($_->[0] eq 'min'){
            $self->{base_cube}->{cube}->{$key}->{min}->{$_->[1]} = $data_key unless defined $self->{base_cube}->{cube}->{$key}->{min}->{$_->[1]};
            $self->{base_cube}->{cube}->{$key}->{min}->{$_->[1]} = $data_key if $data_key < $self->{base_cube}->{cube}->{$key}->{min}->{$_->[1]};
            next measure_update;
        }
        
        if($_->[0] eq 'product'){
            $self->{base_cube}->{cube}->{$key}->{product}->{$_->[1]}  = 1 unless defined $self->{base_cube}->{cube}->{$key}->{product}->{$_->[1]};
            $self->{base_cube}->{cube}->{$key}->{product}->{$_->[1]} *= $data_key;
            next measure_update;
        }
        
    }   
    return $key;
}

sub store {
   my($self,$path) = @_;
   Storable::nstore($self,$path);
   return $self;
}

sub retrieve {
    my($self,$path) = @_;
    return $_[0] = Storable::retrieve($path);
}

sub clone {
    my($self,$clone) = @_;
    return Storable::thaw(Storable::freeze($self));
}

sub get_measures {
    my($self,$data) = @_;
    my @keys;
    my @values;
    for(@{$self->{base_cube}->{schema}->{fields}}){
        if(defined $data->{$_}){
            push @keys,   $_;
            push @values, $data->{$_}; 
        }
    }
    return unless @keys;
    my $table   = join("\t",@keys);
    my $datakey = join("\t",@values);
    return $self->cube_store->fetch($table)->data->{$datakey};   
}

sub get_measures_by_id {
    my($self,$key) = @_;
    return $self->{base_cube}->{cube}->{$key};
}

sub query_measures {
    my($self,@table) = @_;
    
    push @table, sub{1}
        unless @table
        && ref($table[$#table])
        && ref($table[$#table]) =~ /^code$/i;
    
    my $func = pop(@table);
    my $name = join("\t", sort @table);
    
    my $table = $self->cube_store->fetch($name);
    
    return unless $table;
    
    my $data  = $table->{cube};
    
    my @results;
    
    my @fields = $table->schema->fields;
    
    for(keys %$data){
        my $key = $_;
        my @key = split/\t/,$key,-1;
        my %key = map { $fields[$_] => $key[$_] } (0 .. $#fields);
        my $record =  { datakey => \%key, measures => $data->{$_} };
        push @results, $record if $func->($record);
    }
    
    return @results;
}


sub delete {
    my($self,$data) = @_;
        
    die "DataCube(delete):\n" .
        "cannot delete rows in a cube that has been rolled up\n$!\n"
        if $self->has_been_rolled_up;

    my @values;
    for(@{$self->{base_cube}->{schema}->{fields}}){
        
        die "DataCube(delete):\n" .
            "please pass a hash reference with defined entries in the base table:\n"
        unless defined $data->{$_};
    
        push @values, $data->{$_}; 
    }
    
    my $datakey = join("\t",@values);
    delete $self->{base_cube}->{cube}->{$datakey};
    return $self;
}

sub reset {
    my($self) = @_;
    for(keys %{$self->cube_store->cubes}){
        my $cube = $self->cube_store->fetch($_);
        $cube->reset;
    }
    $self->{meta_data}->{system}->{has_been_rolled_up} = 0;
    return $self;
}

sub unroll {
    my($self) = @_;
    for(keys %{$self->cube_store->cubes}){
        my $cube = $self->cube_store->fetch($_);
        $cube->reset unless $cube->schema->name eq $self->base_cube_name;
    }
    delete $self->{meta_data}->{system}->{has_been_rolled_up};
    return $self;
}


sub reset_measures {
    my($self,$data) = @_;
    
    die "DataCube(reset_measures):\n" .
        "cannot reset measures in a cube that has been rolled up\n$!\n"
        if $self->has_been_rolled_up;

    my @values;    
    for(@{$self->{base_cube}->{schema}->{fields}}){
        
        die "DataCube(reset_measures):\n" .
            "please pass a hash reference with defined entries in the base table:\n"
        unless defined $data->{$_};
        
        push @values, $data->{$_}; 
    }
    my $table = $self->base_table;
    my $key   = join("\t",@values);
    
    measure_reset: 
    for(@{$self->{base_cube}->{schema}->{measures}}){
        if($_->[0] eq 'key_count'){
            $self->{base_cube}->{cube}->{$key}->{key_count} = 0;
            next measure_reset;
        }
        if($_->[0] eq 'count'){
            $self->{base_cube}->{cube}->{$key}->{count}->{$_->[1]} = {};
            next measure_reset;
        }
        if($_->[0] eq 'multi_count'){
            $self->{base_cube}->{cube}->{$key}->{multi_count}->{$_->[1]} = {};
            next measure_reset;
        }
        if($_->[0] eq 'sum'){
            $self->{base_cube}->{cube}->{$key}->{sum}->{$_->[1]} = 0;
            next measure_reset;
        }
        if($_->[0] eq 'product'){
            $self->{base_cube}->{cube}->{$key}->{product}->{$_->[1]}  = 1;
            next measure_reset;
        }
        if($_->[0] eq 'max'){
            $self->{base_cube}->{cube}->{$key}->{max}->{$_->[1]} = undef;
            next measure_reset;
        }
        if($_->[0] eq 'min'){
            $self->{base_cube}->{cube}->{$key}->{min}->{$_->[1]} = undef;
            next measure_reset;
        }
        if($_->[0] eq 'average'){
            $self->{base_cube}->{cube}->{$key}->{average}->{$_->[1]}->{sum_total} = 0;
            $self->{base_cube}->{cube}->{$key}->{average}->{$_->[1]}->{observations} = 0;
            next measure_reset;
        }
        
    }   
    return $self;
}


sub decrement_key_count {
    my($self,$data) = @_;
    
    die "DataCube(decrement_key_count):\n" .
        "cannot decrement_key_count in a cube that has been rolled up\n$!\n"
        if $self->has_been_rolled_up;
        
    my $key = join("\t", map { $data->{$_} }  @{$self->{base_cube}->{schema}->{fields}} );
    --$self->{base_cube}->{cube}->{$key}->{key_count};
    return $self;
}

sub decrement_multi_count {
    my($self,$field,$data) = @_;
    
    die "DataCube(decrement_multi_count):\n" .
        "cannot decrement_multi_count in a cube that has been rolled up\n$!\n"
        if $self->has_been_rolled_up;
        
    my $key = join("\t", map { $data->{$_} }  @{$self->{base_cube}->{schema}->{fields}} );
    --$self->{base_cube}->{cube}->{$key}->{multi_count}->{$field}->{$data->{$field}};
    return $self;
}

sub drop_count {
    my($self,$field,$data) = @_;
    
    die "DataCube(drop_count):\n" .
        "cannot drop_count in a cube that has been rolled up\n$!\n"
        if $self->has_been_rolled_up;
        
    my $key = join("\t", map { $data->{$_} }  @{$self->{base_cube}->{schema}->{fields}} );
    delete $self->{base_cube}->{cube}->{$key}->{count}->{$field}->{$data->{$field}};
    return $self;
}

sub add_meta_data {
    my($self,%meta_data) = @_;
    $self->{meta_data}->{user_generated}->{$_} = $meta_data{$_} for keys %meta_data;
    return $self;
}


sub load_data_infile {
    my($self,$file,$line) = @_;
    my $reader = DataCube::FileUtils::FileReader->new->read($file);
    $self->insert($line) while $line = $reader->nextrow_hashref;
    return $self;
}

sub report_html {
    my($self,$dir,$target) = @_;
    return $self->report_commited_html($dir,$target) if  $dir && $target && -d($dir) && -d($target);
    mkdir($dir);
    for(keys %{$self->cube_store->cubes}){
        my $cube = $self->cube_store->fetch($_);
        $cube->report_html($dir);
    }
    return $self;
}

sub report {
    my($self,$dir,$target) = @_;
    return $self->report_commited($dir,$target) if  $dir && $target && -d($dir) && -d($target);
    mkdir($dir);
    for(keys %{$self->cube_store->cubes}){
        my $cube = $self->cube_store->fetch($_);
        $cube->report($dir);
    }
    return $self;
}

sub report_commited {
    my($self,$source,$target) = @_;
    mkdir($target);
    my $connection = DataCube::Connection->new($source);
    $connection->report($target);
    return $self;
}

sub report_html_commited {
    my($self,$source,$target) = @_;
    mkdir($target);
    my $connection = DataCube::Connection->new($source);
    $connection->report_html($target);
    return $self;
}

sub sync {
    my($self,$target) = @_;
    my $connection = DataCube::Connection->new($target);
    $connection->sync;
    return $self;
}

sub lazy_rollup {
    my($self,%opts) = @_;
    
    die "DataCube(lazy_rollup):\ncant lazy_rollup on a cube that has already been rolled up\n$!\n"
        if $self->has_been_rolled_up;
        
    $self->initialize_lazy_rollup unless $self->can_lazy_rollup;
    if($self->{lazy_rollup_list} && ! @{$self->{lazy_rollup_list}}){
        delete $self->{lazy_rollup_list};
        return;
    }
    if($self->{lazy_rollup_list}->[0] eq $self->base_cube_name) {
        shift @{$self->{lazy_rollup_list}};
        return $self->base_cube;
    }
    my $source = [split/\t/,$self->{meta_data}->{system}->{base_cube_name},-1];
    my $target = [split/\t/,shift(@{$self->{lazy_rollup_list}}),-1];
    return $self->rollup_from(
        parent => $source,
        child  => $target,
    );
}

sub initialize_lazy_rollup {
    my($self) = @_;
    my @pending = sort {$a <=> $b} keys %{$self->{controller}->{cube_stats}->{field_count}};
    for(@pending){
        push @{$self->{lazy_rollup_list}},
            sort @{$self->{controller}->{cube_stats}->{field_count}->{$_}};
    }
    return $self;
}

sub can_lazy_rollup {
    my($self) = @_;
    return $self->{lazy_rollup_list};
}

sub how_many_active_cubes {
    my($self) = @_;
    my $total = 0;
    for(keys %{$self->{cube_store}->cubes}){
        $total++ if scalar(keys(%{$self->{cube_store}->{cubes}->{$_}->{cube}}));
    }
    return $total;
}

sub rollup_from {
    my($self,%opts) = @_;
    
    $opts{child}  = [split/\t/,$opts{child} ,-1] unless ref($opts{child});
    $opts{parent} = [split/\t/,$opts{parent},-1] unless ref($opts{parent});
    
    my @parent = sort @{$opts{parent}};
    my @child  = sort @{$opts{child}};
    
    my %child = map { $_ => undef } @child;
    
    my $child_cube  = $self->{cube_store}->{cubes}->{join("\t",@child)};
    my $parent_cube = $self->{cube_store}->{cubes}->{join("\t",@parent)};
    
    die "DataCube(rollup_from):\ncould not locate child cube:@child\n"
        unless $child_cube && $child_cube->{schema};
    
    my @index_map = ();
    for(my $i = 0; $i < @parent; $i++){
        push @index_map, $i if exists $child{$parent[$i]}; 
    }
    
    die "DataCube(rollup_from):\nfound no compatible index mapping\n@parent\n@child\n"
        unless(@index_map || ($#child == 0 && $child[0] eq 'overall'));
    
    my $cube    = $child_cube->new(schema => $child_cube->{schema});
    my $updater = DataCube::MeasureUpdater->new( $cube->{schema} );
    
    my $target_data = $cube->{cube};
    my $source_data = $parent_cube->{cube};
    
    
    for(keys %$source_data){
    
        my $old_key = $_;
        my @old_key = split/\t/,$old_key,-1;
        
        local $SIG{__WARN__} = sub {
                die "DataCube(rollup_from | warnings):\n".
                    "caught a fatal exception here:\n$_[0]\n" .
                    '-' x 80 . "\n" .
                    join("\n",
                        "old_key:      $old_key",
                        'index_map:    ' . join(", ",@index_map) ,
                        "parent_cube:  $parent_cube",
                        "child_cube:   $child_cube"),"\n";
        };
        
        my $new_key = join("\t",@old_key[@index_map]);
    
    
        $updater->update (
            target     => $target_data,
            source     => $source_data,
            source_key => $old_key,
            target_key => $new_key,
        );
    }
    return $cube;
}

sub rollup {
    my($self,%opts)    = @_;
    
    die "DataCube(rollup):\ncant rollup twice!\n"
        if $self->has_been_rolled_up;
      
    my @measures       = @{$self->{meta_data}->{system}->{base_schema}->{measures}};
    my @pending_levels = sort { $b <=> $a } keys %{$self->{controller}->{cube_stats}->{field_count}};

    splice(@pending_levels, 0 ,1);
    
    for(@pending_levels){
        my $level = $_;
        my @next_cubes = @{$self->{controller}->{cube_stats}->{field_count}->{$level}};

        for(@next_cubes){
            my $next_cube_name = $_;
            
            my $possible_parents = $self->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
            
            unless($possible_parents && ref($possible_parents) =~ /^array$/i){
                die "DataCube(rollup : possible_parents):\n" .
                    "cant find possible parent list for:\nnext_cube_name:\n$next_cube_name" .
                    "\nat level:\n$level\n";
            }
            
            my @possible_parents = @$possible_parents;
             
            my $best_parent_name = $possible_parents[0];
            my $best_size        = scalar(keys %{$self->{cube_store}->{cubes}->{$possible_parents[0]}->{cube}});
            
            for(my $i = 1; $i < @possible_parents; $i++){
                my $new_size = scalar(keys %{$self->{cube_store}->{cubes}->{$possible_parents[$i]}->{cube}});
                ($best_parent_name, $best_size) = ($possible_parents[$i], $new_size) if $new_size < $best_size;
            }
            
            my $next_cube   = $self->{cube_store}->fetch($next_cube_name);
            my $best_parent = $self->{cube_store}->fetch($best_parent_name);
            
            my @best_parent_index_map = ();
            
            if($next_cube_name ne 'overall'){
                my @parent_fields = split/\t/,$best_parent_name;
                my $child_fields = $next_cube->{schema}->{field_names};
                index_map_collection:
                for(my $i = 0; $i < @parent_fields; $i++){
                    next index_map_collection unless exists $child_fields->{$parent_fields[$i]};
                    push @best_parent_index_map, $i;
                }
            }
            
            my $updater = DataCube::MeasureUpdater->new( $next_cube->{schema} );
            
            my $target_data = $next_cube->{cube};
            my $source_data = $best_parent->{cube};
            
            for(keys %$source_data){
            
                my $old_key = $_;
                my @old_key = split/\t/,$old_key,-1;
                my $new_key = join("\t",@old_key[@best_parent_index_map]);
                
                $updater->update (
                    target     => $target_data,
                    source     => $source_data,
                    source_key => $old_key,
                    target_key => $new_key,
                );
            }
        }
    }
    $self->{meta_data}->{system}->{has_been_rolled_up} = 1;
    return $self;
}

sub commit {
    my($self,$target) = @_;
    mkdir($target);
    my $cubes = $self->{cube_store}->cubes;
    $cubes->{$_}->commit($target) for keys %$cubes;
    return $self;
}

sub lazy_rc {
    my($self,$target) = @_;
	while(my $next_cube = $self->lazy_rollup){
        $next_cube->commit($target);
	}
    return $self;
}

sub build_lattice_tables {
    my($self,%opts) = @_;
    my $schema      = $opts{schema};
    $schema->check_conflicts;
    my $confine = $schema->is_confined;
    my @hierarchies = @{$schema->{hierarchies}};
    my @lattice;
    for(my $i = 0; $i < @hierarchies; $i++){
        my @hierarchy = @{$hierarchies[$i]};
        for(my $j = 0; $j < @hierarchy; $j++){
            $lattice[$i][$j] = [@hierarchy[0..$j]];
        }
    }
    
    my $path_walker = DataCube::Pathwalker->new(
        lattice => [@lattice],
    );
    
    path_walk:
    while(my $next_path = $path_walker->next_path){
        
        my $next_schema = DataCube::Schema->new;
        
        $next_schema->add_measure(@$_)          for @{$schema->{measures}};
        $next_schema->add_computed_measure(@$_) for @{$schema->{computed_measures}};
        
        for(@$next_path){
            my @path = grep{defined}@$_;
            $next_schema->add_strict_hierarchy(@path) if @path;
        }
        
        my $cube = DataCube::Cube->new(
            schema  => $next_schema,
        );
        
        $cube->{is_the_base_table} = 1 if $cube->{schema}->{name} eq $schema->{name};
        
        if($schema->{confine_to_base}){
            $self->{cube_store}->add_cube($cube) and last path_walk if $cube->{is_the_base_table};
            next path_walk;
        }
        
        if($schema->{lattice_point_names} && defined($schema->{lattice_point_names}->{$cube->{schema}->{name}}) ){
            $cube->{schema}->{lattice_point_name} =
                $schema->{lattice_point_names}->{$cube->{schema}->{name}};
        }
        
        if(defined $confine){
            next path_walk if $confine ne $cube->{schema}->{name};
            $self->{cube_store}->add_cube($cube) and last path_walk
                if $confine eq $cube->{schema}->{name};
        }
       
        if( $schema->{lattice_point_filters} ){
            my @fields  = split/\t/,$cube->{schema}->{name};
            my @filters = @{ $schema->{lattice_point_filters} };
            for( @filters ){
                next unless ref( $_ ) && ref( $_ ) eq 'CODE';
                next path_walk if $_->( @fields ) && ! $cube->{is_the_base_table};
            }
        }        
 
        if( $schema->{asserted_lattice_points} && ref($schema->{asserted_lattice_points}) ){
            $self->{cube_store}->add_cube($cube)
                if exists
                    $schema->{asserted_lattice_points}->{$cube->{schema}->{name}}   ||
                    $cube->{schema}->{name} eq $schema->{name};
        } else {
            $self->{cube_store}->add_cube($cube)
                unless exists
                    $schema->{suppressed_lattice_points}->{$cube->{schema}->{name}} &&
                    $cube->{schema}->{name} ne $schema->{name};
        }
        
    }
    $self->{controller} = DataCube::Controller->new_from_datacube($self);
    return $self;

}

sub merge_with {
    my($self,@data_cubes) = @_;
    my $base_cube_name = $self->{meta_data}->{system}->{base_cube_name};
    my $base_schema    = $self->{cube_store}->fetch($base_cube_name)->{schema};
    my $self_cubes     = $self->{cube_store}->cubes;
    
    for(@data_cubes){
        my $data_cube    = $_;
        my $parity_check = $data_cube->has_been_rolled_up + $self->has_been_rolled_up;
        
        die "DataCube(merge_with):\ncant merge a cube which has been rolled up with one that has not\n" if $parity_check % 2;
        my $new_cubes = $data_cube->{cube_store}->cubes;
        
        for(keys %$self_cubes){ die "DataCube(merge_with : self_cubes):\ncube name mismatch:\n$_\n$!\n" unless defined $new_cubes->{$_} }
        for(keys %$new_cubes) { die "DataCube(merge_with : new_cubes):\ncube name mismatch:\n$_\n$!\n"  unless defined $self_cubes->{$_}}
        
        for(keys %$self_cubes){
            $self_cubes->{$_}->merge_with( $new_cubes->{$_} );
        }
    }
    
    return $self;
}

sub isa_copy_of {
    my($self,$cube) = @_;
    my @queue = ($self,$cube);
    equality_check:
    while(1){
        last equality_check unless @queue;
        my($source,$target) = splice(@queue,0,2);
        return if (ref($source) && !ref($target)) || (!ref($source) && ref($target));
        next equality_check unless defined($source) && defined($target);
        if(!ref($source) && !ref($target)){
            return unless $source eq $target;
            next equality_check;
        }
        if(reftype($source) =~ /^array$/i && reftype($target) =~ /^array$/i){
            return unless @$source == @$target;
            push @queue, ($source->[$_],$target->[$_]) for (0..$#$source);
            next equality_check;
        }
        if(reftype($source) =~ /^hash$/i && reftype($target) =~ /^hash$/i){
            return unless keys %$source == keys %$target;
            push @queue, ($source->{$_},$target->{$_}) for keys %$source;
            next equality_check;
        }
    }
    return 1;
}

sub has_been_rolled_up {
    my($self) = @_;
    return $self->{meta_data}->{system}->{has_been_rolled_up} || 0;
}

sub rollup_by_level {
    my($self,%opts) = @_;
    $self->initialize_rollup_by_level unless $self->can_rollup_by_level;
    unless($self->{level_rollup_state}->{pending_levels}){
        delete $self->{level_rollup_state};
        return;
    }   
    my $cube_name = $self->{level_rollup_state}->{current_cube};
    my $parents   = $self->{controller}->{cube_stats}->{possible_parents}->{$cube_name};
    unless($parents) {  
        $self->nominate_next_level_cube;
        return $self->{base_cube};
    } 
    if(my $last_name = $self->{level_rollup_state}->{current_cleanup}){
        unless($self->{level_rollup_state}->{parent_ref_count}->{$last_name}){
            delete $self->{cube_store}->{cubes}->{$last_name}->{cube};
            $self->{cube_store}->{cubes}->{$last_name}->{cube} = {}; 
        }
    }
    my $parent = $self->{level_rollup_state}->{possible_parents}->{$cube_name};
    $self->{cube_store}->{cubes}->{$cube_name} =
    $self->rollup_from(
        parent => $parent,
        child  => $cube_name,
    );
    $self->{level_rollup_state}->{parent_ref_count}->{$parent}--;
    my $cleanup =
                 0 >= $self->{level_rollup_state}->{parent_ref_count}->{$parent}
        && $parent ne $self->{meta_data}->{system}->{base_cube_name};
    if($cleanup){
        delete $self->{level_rollup_state}->{parent_ref_count}->{$parent};
        delete $self->{cube_store}->{cubes}->{$parent}->{cube};
        $self->{cube_store}->{cubes}->{$parent}->{cube} = {};
    }
    $self->nominate_next_level_cube;
    $self->{level_rollup_state}->{current_cleanup} = $cube_name;
    return $self->{cube_store}->fetch($cube_name);
}

sub nominate_next_level_cube {
    my($self) = @_;
    my $current_level = $self->{level_rollup_state}->{current_level};
    my @current_level = @{$self->{level_rollup_state}->{pending_levels}->{$current_level}};
    
    unless(@current_level){
        delete $self->{level_rollup_state}->{pending_levels}->{$current_level};
        my @pending_levels = sort {$b <=> $a} keys %{$self->{level_rollup_state}->{pending_levels}};
        unless(@pending_levels){
            delete $self->{level_rollup_state}->{pending_levels};
            return $self; 
        }
        my $child = shift(@{$self->{level_rollup_state}->{pending_levels}->{$pending_levels[0]}});
        $self->{level_rollup_state}->{current_cube}   = $child;
        $self->{level_rollup_state}->{current_parent} = $self->{level_rollup_state}->{possible_parents}->{$child};
        $self->{level_rollup_state}->{current_level}  = $pending_levels[0];
            
    } else {
        my $child = shift(@{$self->{level_rollup_state}->{pending_levels}->{$current_level}});
        $self->{level_rollup_state}->{current_cube}   = $child;
        $self->{level_rollup_state}->{current_parent} = $self->{level_rollup_state}->{possible_parents}->{$child};
    }
    return $self;
}

sub initialize_rollup_by_level {
    my($self) = @_;
    my $possible = $self->{controller}->{cube_stats}->{possible_parents}; 
    for(keys %$possible){
        my($child,@parents) = ($_,@{$possible->{$_}});
        $self->{level_rollup_state}->{possible_parents}->{$child} = $parents[0];
        $self->{level_rollup_state}->{parent_ref_count}->{$parents[0]}++;
    }
    for(keys %{$self->{controller}->{cube_stats}->{field_count}}){
        my $level = $_;
        my @cubes = @{$self->{controller}->{cube_stats}->{field_count}->{$level}};
        $self->{level_rollup_state}->{pending_levels}->{$level} = [@cubes];
    }
    my @pending_levels = sort {$b <=> $a} keys %{$self->{level_rollup_state}->{pending_levels}};
    $self->{level_rollup_state}->{current_cube}  = shift(@{$self->{level_rollup_state}->{pending_levels}->{$pending_levels[0]}});
    $self->{level_rollup_state}->{current_level} = $pending_levels[0];
    return $self;
}

sub can_rollup_by_level {
    my($self) = @_;
    return $self->{level_rollup_state};
}



# user help funtions

sub describe {
    my($self) = @_;
    my $cubes = $self->{cube_store}->cubes;
    for(sort { length($a) <=> length($b) || $a cmp $b} keys %$cubes){
        $cubes->{$_}->describe($self);
    }
}

sub get_base_cube_name {
    my($self) = @_;
    return $self->{controller}->{cube_stats}->{base_cube_name};
}

sub base_cube_name {
    my($self) = @_;
    return $self->{controller}->{cube_stats}->{base_cube_name};
}

sub cube_store {
    my($self) = @_;
    return $self->{cube_store};    
}

sub cube_list {
    my($self) = @_;
    $self->cube_store->cube_names;
}

sub cube_names {
    my($self) = @_;
    $self->cube_store->cube_names;
}

sub cubes {
    my($self) = @_;
    my @names     = $self->cube_store->cube_names;
    my $cube_hash = $self->cube_store->cubes; 
    return map { $cube_hash->{$_} } @names;
}

sub table_store {
    my($self) = @_;
    return $self->{cube_store};    
}

sub base_cube {
    my($self) = @_;
    return $self->{base_cube};    
}

sub base_table {
    my($self) = @_;
    return $self->{base_cube};    
}

sub schema {
    my($self) = @_;
    return $self->{meta_data}->{system}->{base_schema};
}

sub tables {
    my($self) = @_;
    return sort keys %{ $self->table_store->tables };
}

sub table_count {
    my($self) = @_;
    return scalar( keys %{ $self->cube_store->cubes } )
}

sub dmp {
    use Data::Dumper;
    print Dumper( \@_ );
}




1;






__DATA__




__END__





=head1 NAME

DataCube - An Object Oriented Perl Module for Data Mining, Data Warehousing, and creating OLAP cubes.

=head1 SYNOPSIS

  
  use strict;
  use warnings;
  
  use DataCube;
  use DataCube::Schema;
  
  
  
  # first, make yourself a schema
  
  my $schema = DataCube::Schema->new;
  
  $schema->add_dimension('country');
  $schema->add_dimension('product');
  $schema->add_dimension('salesperson');
  
  $schema->add_hierarchy('year','quarter','month','day');
  
  $schema->add_measure('sum','units_sold');
  $schema->add_measure('sum','dollar_volume');
  $schema->add_measure('average','price_per_unit');
  
  
  
  # make a cube from a schema
  
  my $cube = DataCube->new($schema);
  
  
  
  # get your hands on some data

  my @data = example_sales_data();
  
  
  
  # insert your data into the cube, one hashref at a time
  
  for(my $i = 0; $i < @data; $i++){  
    
    my $date  = $data[$i][0];
    
    my($month,$day,$year) = split/\//,$date;
    
    my $quarter = $month > 0 && $month < 4  ? 'Q1' :
                  $month > 3 && $month < 7  ? 'Q2' :
                  $month > 6 && $month < 10 ? 'Q3' :
                  $month > 9 && $month < 13 ? 'Q4' : '';
    
    my %data = ();
    
    $data{year}           = $year;
    $data{quarter}        = $quarter;
    $data{month}          = sprintf("%02d",$month);
    $data{day}            = sprintf("%02d",$day);
    $data{country}        = $data[$i][1];
    $data{salesperson}    = $data[$i][2];
    $data{product}        = $data[$i][3];
    $data{units_sold}     = $data[$i][4];
    $data{price_per_unit} = $data[$i][5];
    $data{dollar_volume}  = $data[$i][6];
    
    $cube->insert(\%data);
    
  }
  
  # generate all the rollups
  
  $cube->rollup;
  
  
  # make all your reports
  
  my $target = '/home/david/data_warehouse/reports/sales_data';
  
  $cube->report($target);
  
  
  # alternatively, save your work to disk for later 
  
  my $cube_store = '/home/david/data_warehouse/cubes/sales_cube';
  
  $cube->commit($cube_store);
  
  
  # congratulations, you now have a data warehouse 
  
  
  sub example_sales_data {
    my $data = '
        Date         Country   SalesPerson     Product     Units   Unit_Cost       Total
        3/15/2005         US       Sorvino      Pencil        56        2.99      167.44
        3/7/2006          US       Sorvino      Binder         7       19.99      139.93
        8/24/2006         US       Sorvino        Desk         3      275.00      825.00
        9/27/2006         US       Sorvino         Pen        76        1.99      151.24
        5/22/2005         US      Thompson      Pencil        32        1.99       63.68
        10/14/2006        US      Thompson      Binder        57       19.99     1139.43
        4/18/2005         US       Andrews      Pencil        75        1.99      149.25
        4/10/2006         US       Andrews      Pencil        66        1.99      131.34
        10/31/2006        US       Andrews      Pencil       114        1.29      147.06
        12/21/2006        US       Andrews      Binder        28        4.99      139.72
        2/26/2005         CA          Gill         Pen        51       19.99     1019.49
        1/15/2006         CA          Gill      Binder        46        8.99      413.54
        5/14/2006         CA          Gill      Pencil        94        1.29      121.26
        5/31/2006         CA          Gill      Binder       102        8.99      916.98
        9/10/2006         CA          Gill      Pencil        98        1.29      126.42
        2/9/2005          UK       Jardine      Pencil       125        4.99      623.75
        5/5/2005          UK       Jardine      Pencil        90        4.99      449.10
        3/24/2006         UK       Jardine      PenSet        76        4.99      379.24
        11/17/2006        UK       Jardine      Binder        39        4.99      194.61
        12/4/2006         UK       Jardine      Binder        94       19.99     1879.06
        1/23/2005         US        Kivell      Binder        50       19.99      999.50
        11/25/2005        US        Kivell      PenSet        96        4.99      479.04
        6/17/2006         US        Kivell        Desk         5      125.00      625.00
        8/7/2006          US        Kivell      PenSet        42       23.95     1005.90
        6/25/2005         UK        Morgan      Pencil        90        4.99      449.10
        10/5/2005         UK        Morgan      Binder        28        8.99      251.72
        7/21/2006         UK        Morgan      PenSet        55       12.49      686.95
        9/1/2005          US         Smith        Desk         2      125.00      250.00
        12/12/2005        US         Smith      Pencil        67        1.29       86.43
        2/1/2006          US         Smith      Binder        87       15.00     1305.00
        7/12/2005         US        Howard      Binder        29        1.99       57.71
        4/27/2006         US        Howard         Pen        96        4.99      479.04
        1/6/2005          CA         Jones      Pencil        95        1.99      189.05
        4/1/2005          CA         Jones      Binder        76        4.99      379.24
        6/8/2005          CA         Jones      Binder        60        8.99      539.40
        8/15/2005         US         Jones      Pencil        35        4.99      174.65
        9/18/2005         US         Jones      PenSet        16       15.99      255.84
        10/22/2005        US         Jones         Pen        64        8.99      575.36
        2/18/2006         CA         Jones      Binder         4        4.99       19.96
        7/4/2006          CA         Jones      PenSet        61        4.99      304.39
        7/29/2005         UK         Hogan      Binder        81       19.99     1619.19
        11/8/2005         UK         Hogan         Pen        12       19.99      239.88
        12/29/2005        UK         Hogan      PenSet        74       15.99     1183.26
    ';
    
        my @data = map { [ grep { /\S/ } split/\s+/] } grep { /\S/ } split/\n+/,$data;
        shift @data;
        return @data;
    }




=head1 DESCRIPTION


This module provides a pure perl, object oriented, embeddable data cubing engine.
It is self contained and ready to use in data mining and data warehousing applications.



=head1 OBJECT METHODS

This module provides several methods to create, store, modify and access DataCubes.




=head2 Core Methods

=over 2

These methods expose the core DataCube API.
They are presented in the order in which you will probably want to use them.

All examples below follow the example from the new method.

=back

=head3 new

=over 3

The new constructor should be used with a schema like so:

  use DataCube;
  use DataCube::Schema;
  
  my $schema = DataCube::Schema->new;
  
  $schema->add_dimension('foo');
  $schema->add_dimension('bar');
  
  $schema->add_hierarchy('goo','gaz','waka_waka');
  
  $schema->add_measure('count');
  $schema->add_measure('count','stuff');
  $schema->add_measure('average','blah_blah_blah');
  
  my $cube = DataCube->new($schema);


=back


=head3 insert

=over 3

Now that you have a data cube, insert your data, one hashref at a time:

  foreach $row (@in_some_data_set) {  
    
    my %data = ();
    
    $data{foo}             = $row[0];
    $data{bar}             = $row[1];
    $data{goo}             = $row[2];
    $data{gaz}             = $row[3];
    $data{stuff}           = $row[4];
    $data{waka_waka}       = $row[5];
    $data{blah_blah_blah}  = $row[6];
    
    $cube->insert(\%data);
    
  }

The insert method returns a unique identifier of the inserted record.

Notice that each field from the schema is present and populated by name at insertion time.

DataCube will *not* under any circumstances perform sanity checks for you, ever. 

=back

=head3 load_data_infile

=over 3

The load_data_infile method will batch insert the contents of an entire text file into a cube;

    $cube->load_data_infile( $file );

The file format is simple:

    1. tab delimited fields
    2. new line delimited records
    3. column names at the top.  the column names must be the same as from your schema.

Example:

Let's I have a file called 'revenue.tsv' which looks like this:

    country   product    year    revenue
    us        pens       2009    1856.45
    us        pencils    2008   20495.90
    
    [ ... ]

Then I can load it into a cube as follows:

    my $schema = DataCube::Schema->new;
    
    $schema->add_dimension('year');
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    
    $schema->add_measure('sum','revenue');
    
    my $cube = DataCube->new( $schema );
    
    $cube->load_data_infile('revenue.tsv');
    
Note: it's ok if your text file contains more columns than your schema.


=back


=head3 rollup

=over 3

The rollup method will perform all the aggregations along all the dimensions and measures specified in your schema.

It will happen in memory and very quickly.

This method explodes if the cube has already been rolled up when called.

=back


=head3 lazy_rollup

=over 3

The lazy_rollup method will perform all the aggregations along all the dimensions and measures specified in your schema, iteratively, as opposed to all at once.

An example use case:


  my $target = '/media/Raptor/reports';
  
  while(my $next_cube = $cube->lazy_rollup) {
      $next_cube->report($target);
  }


The advantage is that far less ram is used and the time it takes to generate the rollups is increased only slightly.

=back



=head3 commit

=over 3

The commit method  saves your work to disk.
It will create its own directory tree and will store files using its own internal logic.

Emmited files are binary, not human readable, and should not be modified by anything but DataCube.

  my $target = 'path/to/some/folder/that/exists'';
  
  $cube->commit($target);

If the commit target exists, it will be updated in place and will reflect all commits to date. 


=back


=head3 sync

=over 3

The sync method uses the binary files in a commit target to create flat text file reports.

  $cube->sync($target);

Flat text files will be located alongside their binary files with the name '.report';
In our example, 16 rollup tables will have been created and commited to disk.  They will have 32 letter hex names:

  my $target = 'path/to/some/folder/that/exists';
  
  $cube->commit($target);

  #  suppose you now have a folder called
  # 'path/to/some/folder/that/exists/882e5cd3dd0a5a69ea992891621c6715'
  
  #  you can now call sync:
  
  $cube->sync($target);

  #  to create a flat text file report at this location:
  # 'path/to/some/folder/that/exists/882e5cd3dd0a5a69ea992891621c6715/.report'


Before the call to sync is made, the contents of the .report file may not exist or may exist but may not be current.  Be careful.

=back


=head3 report

=over 3

The report method creates flat text file reports, in the specified location.

  $cube->report($target);

Flat text files will be located in the $target directory, with human readable names.

If two directories are passed to the report method, then flat text file reports with be generated from a prior commit target like so:

  my $commit_target = 'data_warehouse/cubes/my_cube';
  my $report_target = 'data_warehouse/reports/my_reports';
  
  $cube->commit($commit_target);
  $cube->report($commit_target, $report_target);

Now, the $report_target directory will contain reports which represent the cumulative work in the $commit_target


=back


=head3 report_html

=over 3

The report_html method is the same as the report method but produces html reports instead of flat text files.  See 'report';




=back

=head2 Access Methods

=over 2

These methods provide basic read / write access to the internal contents of the cube.

=back

=head3 reset

=over 3

The reset method resets the internal state of the cube :

    $cube->reset;

This is equivalent to

    $cube = Datacube->new( $cube->schema );

In other words, the reset method empties the data from all the cubes internal tables.

=back


=head3 unroll

=over 3

The unroll method reverts the cube to its pre-rollup state and has no effect on unrolled cubes:

    $cube->unroll;

It is implemented as follows:

    sub unroll {
        
        my($self) = @_;
        
        for(keys %{$self->cube_store->cubes}){
            
            my $table = $self->cube_store->fetch($_);
            
            $table->reset unless $table->schema->name eq $self->base_cube_name;
            
        }
        
        delete $self->{meta_data}->{system}->{has_been_rolled_up};
        
        return $self;
    }

=back



=head3 reset_measures

=over 3

The reset_measures method allows you to reset all measure values associated with a specific tuple, to their default values.
Sums are set to 0, products to 1, internal count distinct hashes are reset to {}, etc. 

An example:

   use YAML;
   sub dump_yaml { print YAML::Dump \@_ }
 
   my %data = (
        year        => '2005',
        quarter     => 'Q1',
        month       => '03',
        day         => '15',
        country     => 'US',
        salesperson => 'Sorvino',
        product     => 'Pencil',
    );


    dump_yaml($cube->get_measures(\%data));

    $cube->reset_measures(\%data);

    dump_yaml($cube->get_measures(\%data));

    # --------------------------------------------------------------------------
    # prints
    # --------------------------------------------------------------------------
    # average:
    #   price_per_unit:
    #     observations: 1
    #     sum_total: 2.99
    # sum:
    #   dollar_volume: 167.44
    #   units_sold: 56
    #
    #
    # average:
    #   price_per_unit:
    #     observations: 0
    #     sum_total: 0
    # sum:
    #   dollar_volume: 0
    #   units_sold: 0
    # --------------------------------------------------------------------------


This method explodes if the cube has already been rolled up when called.


=back


=head3 delete

=over 3

The delete method removes the index and measures associated with a specific tuple.

An example:

    my %data = (
        year        => '2005',
        quarter     => 'Q1',
        month       => '03',
        day         => '15',
        country     => 'US',             
        salesperson => 'Sorvino',
        product     => 'Pencil',
    );
    
    $cube->delete(\%data);
    
    # base table no longer contains 'US 15  03  Pencil  Q1  Sorvino 2005'

This method explodes if the cube has already been rolled up when called.


=back




=head3 decrement_key_count

=over 3

The decrement_key_count method decreases the unqualified 'count' measure associated with a dimension instance by 1.  

An example:

    $cube->decrement_key_count(\%data);

This method explodes if the cube has already been rolled up when called.


=back


=head3 drop_count / decrement_multi_count

=over 3

These methods modify the contents of ('count','field') and ('multi_count','field') measures.

An example:

    $cube->drop_count('users',\%data);
    
    $cube->decrement_multi_count('field',\%data);

This warrants a small example:

    use strict;
    use warnings;
        
    use DataCube;
    use DataCube::Schema;
        
    my $schema = DataCube::Schema->new;
    
    $schema->add_dimension('year');
    $schema->add_dimension('country');
    
    $schema->add_measure('count','product');
    $schema->add_measure('multi_count','salesperson');
    
    my $cube = DataCube->new($schema);
    
    $cube->load_data_infile('sales.tsv');
    
    my %data = (
        year        => '2006',
        country     => 'US',
        product     => 'Pencil',
        salesperson => 'Andrews',
    );
    
    my $filter = sub {
        my($data) = @_;
        return 1
            if $data->{datakey}->{year}        eq '2006'
            && $data->{datakey}->{country}     eq 'US'
    };
    
    my @query = ('country','year',$filter);
    
    dmp($cube->query_measures( @query ));
    
    $cube->drop_count('product',\%data);
    
    dmp($cube->query_measures(  @query ));
        
    $cube->decrement_multi_count('salesperson',\%data);
    
    dmp($cube->query_measures(  @query ));

    sub dmp {
        use Data::Dumper;
        print Dumper \@_;
    }

This prints the following (without the comments):

    # first, here is the original row in the base table
    # --------------------------------------------------------------------------------
    
    $VAR1 = [
              {
                'datakey' => {
                               'country' => 'US',
                               'year' => '2006'
                             },
                'measures' => {
                                'count' => {
                                             'product' => {
                                                            'Pen' => undef,
                                                            'Desk' => undef,
                                                            'PenSet' => undef,
                                                            'Pencil' => undef,
                                                            'Binder' => undef
                                                          }
                                           },
                                'multi_count' => {
                                                   'salesperson' => {
                                                                      'Howard' => 1,
                                                                      'Sorvino' => 3,
                                                                      'Smith' => 1,
                                                                      'Andrews' => 3,
                                                                      'Kivell' => 2,
                                                                      'Thompson' => 1
                                                                    }
                                                 }
                              }
              }
            ];
    
    # after 'drop_count'
    # note that Pencils is now removed from the count of distinct products
    # --------------------------------------------------------------------------------
    
    $VAR1 = [
              {
                'datakey' => {
                               'country' => 'US',
                               'year' => '2006'
                             },
                'measures' => {
                                'count' => {
                                             'product' => {
                                                            'Pen' => undef,
                                                            'Desk' => undef,
                                                            'PenSet' => undef,
                                                            'Binder' => undef
                                                          }
                                           },
                                'multi_count' => {
                                                   'salesperson' => {
                                                                      'Howard' => 1,
                                                                      'Sorvino' => 3,
                                                                      'Smith' => 1,
                                                                      'Andrews' => 3,
                                                                      'Kivell' => 2,
                                                                      'Thompson' => 1
                                                                    }
                                                 }
                              }
              }
            ];
    
    # after 'decrement_multi_count'
    # note that Andrews has made one fewer sale for 'US  2006'
    # --------------------------------------------------------------------------------
    
    $VAR1 = [
              {
                'datakey' => {
                               'country' => 'US',
                               'year' => '2006'
                             },
                'measures' => {
                                'count' => {
                                             'product' => {
                                                            'Pen' => undef,
                                                            'Desk' => undef,
                                                            'PenSet' => undef,
                                                            'Binder' => undef
                                                          }
                                           },
                                'multi_count' => {
                                                   'salesperson' => {
                                                                      'Howard' => 1,
                                                                      'Sorvino' => 3,
                                                                      'Smith' => 1,
                                                                      'Andrews' => 2,
                                                                      'Kivell' => 2,
                                                                      'Thompson' => 1
                                                                    }
                                                 }
                              }
              }
            ];
    
    # get it?
    # --------------------------------------------------------------------------------


Granted, these methods are technical and should be used with great caution.

These methods explode if the cube has already been rolled up when called.


=back





=head2 Convenience Methods

=over 2

These methods provide wrappers around slightly complicated operations.
They are meant to be sugary and save you development time.

=back


=head3 lazy_rc

=over 3

The lazy_rc method uses an iterative rollup algorithm to rollup and commit the cube.
It will be more memory efficient and slightly slower than first calling rollup and then calling commit.

   my $target = '/some/folder';
   
   $cube->insert( a bunch of data *see above* );
   
   $cube->lazy_rc($target);

lazy_rc will generally use twice as much virtual memory as your perl process did right after inserting a bunch of data
(as opposed to n times where n is the number of internal lattice points (ie different rollups)).


=back

=head3 store / retrieve

=over 3

The store and retrieve methods provide ways to store your cube to a single file on disk and slurp it back in later.

Example:

    $cube->store('sales.cube');
    
    # then at the beginning of some other script:
    
    my $cube = DataCube->new->retrieve('sales.cube');
    
    # which is equivalent to
    # ------------------------------------------------
    # $cube = DataCube->new;
    # $cube->retrieve('sales.cube');
    
The new constructor can also take this file path instead of a schema object:

    $cube->store('sales.cube');
    
    my $clone = DataCube->new('sales.cube');

which brings us to:

=back


=head3 clone

=over 3

The clone methods provides a deep copy of a data cube.

Example:

    my $clone = $cube->clone;
    
    # now anything done to $clone does not affect $cube

=back





=head2 Examination Methods

=over 2

These methods help you peek inside your cube.

=back

=head3 describe

=over 3

Its like mysql describe but for data cubes.  Kewl huh.

Produces text output.  Try it:

  use DataCube;
  use DataCube::Schema;
  
  my $schema = DataCube::Schema->new;
  
  $schema->add_dimension('foo');
  $schema->add_dimension('bar');
  
  $schema->add_hierarchy('goo','gaz','waka_waka');
  
  $schema->add_measure('count');
  $schema->add_measure('count','stuff');
  $schema->add_measure('average','blah_blah_blah');
  
  my $cube = DataCube->new($schema);
  
  $cube->describe;

=back

=head3 get_measures

=over 3

The get_measures method provides real-time access to the cube.

Consider the example in the synopsis section:

  [...]
  
  $cube->rollup;
  
  my %data = (
    country     => 'US',
    salesperson => 'Sorvino'
  );
  
  my $measures = $cube->get_measures(\%data);

This will query the 'country', 'salesperson' table for the instance
'US, Sorvino' and will return a hashref of the measures and their values.

You can query the cube's base table at insertion time like so:

  my %data = ( ... );
  
  $cube->insert(\%data);
  
  my $measures = $cube->get_measures(\%data);

For a richer query interface, see query_measures or DataCube::Query;
For information about measures, see DataCube::Schema;

=back

=head3 get_measures_by_id

=over 3

The get_measures_by_id method fetches measures associated with a unique record identifier from the base table.

    my $record_id = $cube->insert(\%data);
    
    my $measures = $cube->get_measures_by_id( $record_id );
    
    # same as $cube->get_measures(\%data);

Note: This method only works on the base table.


=back


=head3 query_measures

=over 3

The query_measures method provides real-time search for data cubes.

Consider the example in the synopsis section:

    [...]
    
    $cube->rollup;
    
    my $filter = sub {
        my($data) = @_;
        
        my $datakey  = $data->{datakey};
        my $measures = $data->{measures};
        
        return 1 if
               $datakey->{country} =~ /^(us|ca)$/i
            or $measures->{sum}->{units_sold}    > 200
            or $measures->{sum}->{dollar_volume} > 2500
    };
    
    my @results = $cube->query_measures('country','salesperson', $filter);

This will query the 'country', 'salesperson' table in a case
insensitive fashion for all rows where any of the following conditions apply:

    1. the country is 'us' or 'ca'
    2. more than 200 units have been sold
    2. more than 2500 dollars in revenue have been generated

Results will be returned as an array of hash references, in the same format
expected by the $filter callback above.


=back


=head2 Status Methods

=over 2

These methods provide infomation about the state of the cube.

=back

=head3 has_been_rolled_up

=over 3

This method will return true if the cube has been rolled up,  0 otherwise.

Note: lazy_rc does not set the has_been_rolled_up flag to true.


=back


=head1 IMPORTANT 

There are 4 rules for DataCube that must never be broken.

    1.  Your data may not contain tab character(s)
    2.  You may not have a dimension called 'overall'  
    3.  All named entries from your schema must exist and be defined at insertion time
    4.  Do not use double underscores in the names of dimensions, hierarchies or measure fields.

Example:

    use DataCube;
    use DataCube::Schema;
  
    my $schema = DataCube::Schema->new;
  
    $schema->add_dimension('foo');
    $schema->add_dimension('bar');
  
    $schema->add_measure('count');
  
  
    # breaks rule 1
    # ---------------------------
    
    $cube->insert({
        foo => 12,
        bar => "\tsome_text",
    });


    # breaks rule 3
    # ---------------------------
    
    $cube->insert({
        bar => "some_text",
    });


Incidentally, DataCube will not check these for you, ever, so consider yourself warned.




=head1 EXPORT

This module does not export anything.  It is object oriented.



=head1 NOTES

=head2 ACID Compliance

=over 2

The DataCube API provides operations that guarantee reliable transactions.  Please see the blackbear cookbook for details.

=back





=head1 SEE ALSO



Wikipedia on OLAP Cubes:

http://en.wikipedia.org/wiki/OLAP_cube


Other Data Cubing Engines:

=begin html
<a href="http://www.asterdata.com/">http://www.asterdata.com/</a><br/>
<a href="http://www.oracle.com/technology/obe/olap_cube/buildicubes.htm">http://www.oracle.com/technology/obe/olap_cube/buildicubes.htm</a><br/>
<a href="http://www.microsoft.com/sqlserver/2005/en/us/business-intelligence.aspx">http://www.microsoft.com/sqlserver/2005/en/us/business-intelligence.aspx</a><br/>

=end html

=head1 AUTHOR

David Williams, E<lt>david@namimedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-Now by David Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut








