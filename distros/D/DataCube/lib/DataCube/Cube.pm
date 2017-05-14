


package DataCube::Cube;

use strict;
use warnings;
use Storable;
use Digest::MD5;
use Time::HiRes;
use Data::Dumper;
use Cwd qw(getcwd);

use DataCube::MeasureUpdater;

use DataCube::Cube::Style;
use DataCube::Cube::Style::HTML;
use DataCube::Cube::Style::HTML::CSS;


sub new {
    my($class,%opts) = @_;
    $opts{cube} ||= {};
    my $self = bless {%opts}, ref($class) || $class;
    $self->{schema}->initialize if $self->{schema};
    return $self;
}

sub is_empty {
    my($self) = @_;
    return 0 if $self->is_non_empty;
    return 1;
}

sub is_non_empty {
    my($self) = @_;
    return 1 if scalar(keys %{$self->{cube}});
    return 0;
}

sub merge_with {
    my($self,$cube) = @_;
    
    return $self unless $cube->is_non_empty;
    
    my $schema    = $self->{schema};
    my $cube_data = $cube->{cube};
    my $self_data = $self->{cube};
    
    my $updater = DataCube::MeasureUpdater->new($self->{schema});
    
    for(keys %{$cube->{cube}}){
        $updater->update(
            source     => $cube_data,
            target     => $self_data,
            source_key => $_,
            target_key => $_,    
        );
    }
    return $self;
}

sub commit {
    my($self,%opts);
    
    commit_opts:{
        ($self)               = @_ and last commit_opts if @_ == 1;
        ($self,%opts)         = @_ and last commit_opts if @_ % 2 && @_ > 2;
        ($self,$opts{target}) = @_ and last commit_opts;   
    }
    
    $opts{target} ||= getcwd;
    $opts{prefix} ||= 3;
    
    my $digest = $self->{schema}->{name_digest};
    my $target = $opts{target} . "/$digest";
    
    my $schema;
    my $config;
    my $digests;
    my $digester = Digest::MD5->new;
    
    unless(-d( $target )){
        mkdir($target)
            or die "DataCube::Cube(commit):\ncant make directory: $target\n$!\n";
        $schema = $self->{schema};
        for(keys %{$self->{cube}}){
            my $digest = $digester->add($_)->hexdigest;
            $digests->{$_} = {
                digest => $digest,
                prefix => substr($digest,0,$opts{prefix})
            };
        }
        Storable::nstore(\%opts,  "$target/.config.working");
        Storable::nstore($schema, "$target/.schema.working");
        Storable::nstore($digests,"$target/.digests.working");
        rename("$target/.config.working",  "$target/.config")  or die "DataCube::Cube(commit):\ncant rename config file:\n$target/.config.working \nto\n$target/.config \n$!\n";
        rename("$target/.schema.working",  "$target/.schema")  or die "DataCube::Cube(commit):\ncant rename config file:\n$target/.schema.working \nto\n$target/.schema \n$!\n";
        rename("$target/.digests.working", "$target/.digests") or die "DataCube::Cube(commit):\ncant rename config file:\n$target/.digests.working\nto\n$target/.digests\n$!\n";
    } else {
        $config  = Storable::retrieve("$target/.config");
        $schema  = Storable::retrieve("$target/.schema");
        $digests = Storable::retrieve("$target/.digests");
    }
    
    my $updater = DataCube::MeasureUpdater->new($schema);
    
    my $prefices;
    my $digests_changed = 0;
    
    for(keys %{$self->{cube}}){
        if($digests->{$_}){
            my $prefix = $digests->{$_}->{prefix};
            $prefices->{$prefix}->{$digests->{$_}->{digest}} = $_;
        } else {
            my $digest = $digester->add($_)->hexdigest;
            my $prefix = substr($digest,0,$config->{prefix});
            $digests->{$_} = {
                digest => $digest,
                prefix => $prefix,
            };
            $prefices->{$prefix}->{$digest} = $_;
            $digests_changed = 1;
        }
    }
    
    if($digests_changed){
        Storable::nstore($digests,"$target/.digests.working");
        rename("$target/.digests.working", "$target/.digests")
            or die "DataCube::Cube(commit):\ncant rename config file:\n$target/.digests.working\nto\n$target/.digests\n$!\n";
    }
    
    for(keys %$prefices){
        my $cube_hunk;
        $cube_hunk->{$_} = $self->{cube}->{$_} for values %{$prefices->{$_}};
        my $target_file  = $target . "/$_";
        if(-f($target_file)){
            my $existing_hunk = Storable::retrieve($target_file);
            for(keys %$cube_hunk){
                $updater->update(
                    source     => $cube_hunk,
                    target     => $existing_hunk,
                    source_key => $_,
                    target_key => $_,
                );
            }
            Storable::nstore($existing_hunk, $target_file . '.working');
            rename("$target_file.working", "$target_file")
                or die "DataCube::Cube(commit):\ncant rename target file:\n$target_file.working\nto\n$target_file\n$!\n";
        } else {
            Storable::nstore($cube_hunk, $target_file . '.working');
            rename("$target_file.working", "$target_file")
                or die "DataCube::Cube(commit):\ncant rename target file:\n$target_file.working\nto\n$target_file\n$!\n";
        }
    }
    return $self;
}

sub report {
    my($self,$dir,%opts);
    purge_opts:{
        ($self)             = @_ and last purge_opts if @_ == 1;
        ($self,%opts)       = @_ and last purge_opts if @_ % 2 && @_ > 2;
        ($self,$opts{dir})  = @_ and last purge_opts;   
    }
    $dir = $opts{dir} || getcwd;
    local $| = 1;
    my $name = $self->{schema}->{name};
   (my $file_name = $name) =~ s/\t+/__/g;
    $file_name = $self->schema->safe_file_name;
    my @sorted_measures = @{$self->{schema}->{measures}};
    my @computed_measures = @{$self->{schema}->{computed_measures}};
    for(@sorted_measures){ $_->[2] = 'count' if $_->[0] eq 'key_count' }
    @sorted_measures = sort {$a->[2] cmp $b->[2]}  @sorted_measures;
    open(my $F, '>' , $dir . '/' . $file_name.'.dat')
        or die "cant open purge file:\n$dir/$file_name.dat\n$!\n";
    print $F join("\n", map { join("\t",@$_) } @{$self->to_table});
    close $F;
    return $self;
}


sub describe {
    my($self,$cube) = @_;
    my $schema = $self->{schema};

    my $name = $schema->{name};
    my $meas = $schema->{measures};
    my $hier = $schema->{hierarchies};
    my $dige = $schema->{name_digest};
    my $base = $cube->get_base_cube_name;
    
    my(@dims,@hiers);
    my @meas = @$meas;
    
    for(@$hier){
        if(@$_ == 1){
            push @dims,  $_
        } else {
            push @hiers, $_
        }
    }
    
    @dims  = map { $_->[0]          } @dims;
    @hiers = map { join (", ", @$_) } @hiers;
    
    for(@meas){
        if($_->[0] eq 'key_count'){
            $_->[1] = '';
            $_->[0] = 'count';
        }
    }    
    
    print "\n table:  $dige", $name eq $base ? " (base table)\n" : "\n";
    print '-' x 80 ,"\n\n";
    
    for(sort { length($a->[0]) <=> length($b->[0]) || $a->[0] cmp $b->[0] || length($a->[1]) <=> length($b->[1])} @meas){
        my $additive       = 'additive';
        my $measure_string = '';
        if($_->[0] eq 'count' && $_->[1] eq ''){
            $measure_string = 'count of occurances';
        } elsif($_->[0] eq 'average') {
            $measure_string = "average $_->[1]";
            $additive = 'non-' . $additive;
        } else {
            if(defined($_->[1]) && length($_->[1]) && ($_->[0] eq 'count' || $_->[0] eq 'multi_count')){
                $additive = 'non-' . $additive;
            }
            $measure_string = "$_->[0] of $_->[1]";
        }
        printf "\tmeasure:    %-30s (%s)\n",$measure_string,$additive;
    }
    print "\n";
    
    for(sort { length($a) <=> length($b) || $a cmp $b } @dims){
        print "\tdimension:  $_\n";
    }
    print "\n" if @dims;
    
    for(sort { length($a) <=> length($b) || $a cmp $b } @hiers){
        print "\thierarchy:  $_\n";
    }
    print "\n" if @hiers;
    
    my $print_name = $schema->{lattice_point_name} || $name;
    $print_name =~ s/\t/__/g;
    printf "\treport:     %-50s\n\n",$print_name; 
    return $self;
}

sub report_html {
    my($self,$dir,%opts);
    purge_opts:{
        ($self)             = @_ and last purge_opts if @_ == 1;
        ($self,%opts)       = @_ and last purge_opts if @_ % 2 && @_ > 2;
        ($self,$opts{dir})  = @_ and last purge_opts;   
    }
    $dir = $opts{dir} || getcwd;
    local $| = 1;
    my $file_name = $self->schema->safe_file_name;
    open(my $F, '>' , $dir . '/' . $file_name.'.html')
        or die "cant open purge file:\n$dir/$file_name.html\n$!\n";
    my $driver =  DataCube::Cube::Style::HTML->new;
    print $F $driver->html($self);
    close $F;
    return $self;
}

sub to_table {
    my($self) = @_;
    my $table = [];
    my $schema = $self->schema;
    
    my $name = $self->{schema}->{name}; 
   (my $alias = $name) =~ s/\t+/__/g;
    $alias = $self->{schema}->{lattice_point_name} if defined($self->{schema}->{lattice_point_name});
    my @sorted_measures = $schema->measures;
    my @computed_measures = @{$self->{schema}->{computed_measures}};
    for(@sorted_measures){
        $_->[2] = 'count' if $_->[0] eq 'key_count'
    }
    @sorted_measures = sort {$a->[2] cmp $b->[2]}  @sorted_measures;
    
    my $data   = $self->{cube};
    my @keys   = sort keys %$data;
    my @fields = $schema->field_names;
    
    push @$table, [@fields, map { $_->[2] } @sorted_measures];
    
    for(my $i = 0; $i < @keys; ++$i){
        
        my $k   = $i + 1;
        my $key = $keys[$i];
        my @key = split/\t/,$key,-1;
        
        @key = ('') if ! @key && $self->schema->field_count == 1;
        
        die "DataCube::Cube(to_table | alignment):\nthere is a data alignment problem here:\n\n\t" .
             join("\t\n",@fields) . "\n" . '-' x 40 . "\n\t" . join("\t\n",@key)
        unless $#key == $#fields;
        
        for(my $j = 0; $j < @fields; ++$j){
            $table->[$k][$j] = $key[$j];
        }
        
        measure_loop:
        for(my $n = 0; $n < @sorted_measures; ++$n){
            
            my $j    = $n + @fields;
            
            my $node = $sorted_measures[$n];
            
            measure_collect: {
                if($node->[0] eq 'key_count'){
                    $table->[$k][$j] = $self->{cube}->{$key}->{key_count};
                    last measure_collect;
                }
                if($node->[0] eq 'count'){
                    $table->[$k][$j] = scalar(keys %{$self->{cube}->{$key}->{count}->{$node->[1]}});
                    last measure_collect;
                }
                if($node->[0] eq 'multi_count'){
                    $table->[$k][$j] = scalar(keys %{$self->{cube}->{$key}->{multi_count}->{$node->[1]}});
                    last measure_collect;
                }
                if($node->[0] eq 'sum'){
                    $table->[$k][$j] = $self->{cube}->{$key}->{sum}->{$node->[1]};
                    last measure_collect;
                }
                if($node->[0] eq 'min'){
                    $table->[$k][$j] = $self->{cube}->{$key}->{min}->{$node->[1]};
                    last measure_collect;
                }
                if($node->[0] eq 'max'){
                    $table->[$k][$j] = $self->{cube}->{$key}->{max}->{$node->[1]};
                    last measure_collect;
                }
                if($node->[0] eq 'average'){
                    $table->[$k][$j] = $self->{cube}->{$key}->{average}->{$node->[1]}->{sum_total} / $self->{cube}->{$key}->{average}->{$node->[1]}->{observations};
                    last measure_collect;
                }
            }
        }
    }
    return wantarray ? @$table : $table;
}

sub tsv_data {
    my( $self ) = @_;
    my @measures = $self->schema->measures; 
    for(@measures){ $_->[2] = 'count' if $_->[0] eq 'key_count' }
    @measures  = sort { $a->[2] cmp $b->[2] }  @measures;
    my $data   = $self->{cube};
    my @keys   = keys %$data;
    my @results;
    for my $key( @keys ){
        my @measure_values = $self->get_measure_values( $key, \@measures );
        push @results, join("\t", $key, join("\t", @measure_values));
    }
    return @results;
}

sub get_measure_values {
    my( $self, $key, $measures ) = @_;
    my @measures = @$measures;
    my @results;
    for( @measures ){      
        if($_->[0] eq 'key_count'){
            push @results, $self->{cube}->{$key}->{key_count};
            next;
        }
        if($_->[0] eq 'count'){
            push @results, scalar(keys %{$self->{cube}->{$key}->{count}->{$_->[1]}});
            next;
        }
        if($_->[0] eq 'multi_count'){
            push @results, scalar(keys %{$self->{cube}->{$key}->{multi_count}->{$_->[1]}});
            next;
        }
        if($_->[0] eq 'sum'){
            push @results, $self->{cube}->{$key}->{sum}->{$_->[1]};
            next;
        }
        if($_->[0] eq 'min'){
            push @results, $self->{cube}->{$key}->{min}->{$_->[1]};
            next;
        }
        if($_->[0] eq 'max'){
            push @results, $self->{cube}->{$key}->{max}->{$_->[1]};
            next;
        }
        if($_->[0] eq 'average'){
            push @results, $self->{cube}->{$key}->{average}->{$_->[1]}->{sum_total} / 
                           $self->{cube}->{$key}->{average}->{$_->[1]}->{observations};
            next;
        }
    }
    return @results;
}

sub cube {
    my($self) = @_;
    return $self->{cube}
}

sub data {
    my($self) = @_;
    return $self->{cube}
}

sub name {
    my($self) = @_;
    return $self->{schema}->{name};
}

sub schema {
    my($self) = @_;
    return $self->{schema};
}

sub reset {
    my($self) = @_;
    $self->{cube} = {};
    return $self;
}

sub has_field {
    my($self,$field) = @_;
    my $fields = $self->schema->field_names;
    return 1 if exists $fields->{$field};
    return 0;
}

sub is_the_base_table {
    my($self) = @_;
    return 1 if $self->{is_the_base_table};
    return 0;
}




1;





__DATA__



__END__











