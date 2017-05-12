


package DataCube::FileSplitter;

use lib '..';

use strict;
use warnings;

use Fcntl;
use URI::file;
use Digest::MD5;
use Time::HiRes;
use Data::Dumper;
use Cwd qw(getcwd);
use Storable qw(nstore retrieve);

use DataCube;
use DataCube::Schema;
use DataCube::MeasureUpdater;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub split {
    my($self,@opts,%opts) = @_;
    
    split_opts:{
        %opts       = @opts    and last split_opts if @_  > 2 && @_ % 2; 
        $opts{file} = $opts[0] and last split_opts if @_ == 2;
    }
    
    my $path = $opts{file};
    my $pref = $opts{prefix} || 2;
    
    $path =~ /^((?:.*?[\/\\])?)([^\/\\]+?)$/;
    my($dir,$file) = ($1,$2);
    $file =~ s/\..{1,4}$//i;
    
    mkdir($dir.$file)
        or die "DataCube::FileSplitter(split):\ncant make directory:\n$dir$file\nfrom path:$path\n$!\n";
    
    my $digester       = Digest::MD5->new;
    my $data_cube      = Storable::retrieve($path);
    my $base_cube_name = $data_cube->{meta_data}->{system}->{base_cube_name} || $data_cube->{meta_data}->{system}->{base_cube};
    
    my $cubes = $data_cube->{cube_store}->cubes;
    
    for(keys %$cubes){
        my $cube_name = $_;
        my $cube_data = $data_cube->{cube_store}->fetch($cube_name);
        my $name_dige = $cube_data->{schema}->{name_digest};
        my $cube_hash = $cube_data->{cube};
        my $cube_targ = $dir.$file.'/'.$name_dige;
        mkdir($cube_targ)
            or die "DataCube::FileSplitter(split):\ncant make directory:\n".
                   "$cube_targ\nfrom cube named\n$cube_name\n$name_dige\n$!\n";
        
        nstore($cube_data->{schema}, $cube_targ."/.schema");
        
        my %prefices;
        
        for(keys %$cube_hash){        
            my $digest = $digester->add($_)->hexdigest;
            my $prefix = substr($digest, 0 , $pref);
            $prefices{$prefix}->{$digest} = $_;
        }

        for(keys %prefices){
            my $cube_hunk;
            my @cube_keys  = values %{$prefices{$_}};
            $cube_hunk->{$_} = $cube_hash->{$_} for @cube_keys;
            nstore($cube_hunk, $cube_targ . "/$_");
        }
    }

    return $self;
}

sub merge_all {
    my($self,$dir) = @_;
    my @dir        = grep {$_ !~ /^merge$/ } $self->dir($dir);
    my $merge_dir  = "$dir/merge";
    unless(-d($merge_dir)){
        mkdir($merge_dir) or die "DataCube::FileSplitter(merge_all):\ncant make directory:$merge_dir\n$!\n"
    }
    
}

sub merge {
    my($self,%opts) = @_;
    
    my $target       = $opts{target};
    my $source_files = $opts{source_files};
    
    my $schema;
    my $sources;

    unless(-d($target)){
        mkdir($target) or die "DataCube::FileSplitter(merge : mkdir):\ncant make target directory:\n$target\n$!\n";
    }

    base_check:{
        my $first = $source_files->[0];
        my @first = grep{/^[a-f0-9]+$/i}$self->dir($first);
        for(@first){
            my $name = $_;
            for(@$source_files){
                die "DataCube::FileSplitter(merge : base_check):\nmissing cube named:\n$name\nin merge source:\n$_"
                    unless (-d("$_/$name"))
            }
        }
    }
    my $i = 0;  
    for(@$source_files){
        my $dir = $_;
        my @cube_dirs = $self->dir($dir);
        for(@cube_dirs){
            my $cube_dir = $_;
            if($i == 0){
                my $schema = Storable::retrieve("$dir/$cube_dir/.schema");
                $sources->{$cube_dir}->{schema}  = $schema;
                $sources->{$cube_dir}->{updater} = DataCube::MeasureUpdater->new($schema);
            }
            my @data_files = grep{$_ ne '.schema'}$self->dir("$dir/$cube_dir");
            for(@data_files){
                my $prefix = $_;
                push @ { $sources->{$cube_dir}->{parts}->{$prefix} }, "$dir/$cube_dir/$prefix";
            }
        }
        $i++;
    }
  
    
    for(keys %$sources){
        unless(-d("$target/$_")){
            mkdir("$target/$_") or die
                "DataCube::FileSplitter(merge : mkdir):\ncant make target directory:\n$target/$_\n$!\n";
        }
        my $cube_name = $_;
        my %parts = %{$sources->{$cube_name}->{parts}};
        for(sort keys %parts){
            my $prefix = $_;
            $self->merge_files(
                files   => $sources->{$cube_name}->{parts}->{$prefix},
                target  => $target . "/$cube_name/$prefix",
                updater => $sources->{$cube_name}->{updater},
            );
        }
    }
    return $self;
}

sub merge_files {
    
    my($self,%opts) = @_;
    
    my $files   = $opts{files};
    my $target  = $opts{target};
    my $updater = $opts{updater};
    
    
    if( -f($target) ) {
        unshift @$files, $target;
    }
    
    my $big_hunk = {};
    
    for(@$files){
        
        my $small_hunk = Storable::retrieve($_);
        
        unless (ref($small_hunk)){
            die "DataCube::FileSplitter(merge_files):\nStorable returned a non-ref\n$!"
        }
        
        for(keys %$small_hunk){
            $updater->update(
                target     => $big_hunk,
                source     => $small_hunk,
                source_key => $_,
                target_key => $_,    
            );
        }
        
    }
   
    Storable::nstore($big_hunk,$target);
   
    return $self;
}

sub dir {
    my($self,$path) = @_;
    opendir(my $D, $path) or die "DataCube::FileSplitter(dir):\ncant open directory:$path\n$!\n";
    grep {/[^\.]/} readdir($D);
}











1;






__END__


### from before the creation of DataCube::MeasureUpdater
### ----------------------------------------------------------------------------

            merge_file_measure_update:
            
            for(@{$schema->{measures}}) {
                
                if($_->[0] eq 'key_count'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{key_count};
                    $big_hunk->{$key}->{key_count} += $small_hunk->{$key}->{key_count};
                    next merge_file_measure_update;
                }
                
                if($_->[0] eq 'count'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{count}->{$_->[1]}->{workspace};
                    my $count_field_name = $_->[1];
                    $big_hunk->{$key}->{count}->{$count_field_name}->{workspace}->{$_} = undef
                        for keys %{$small_hunk->{$key}->{count}->{$count_field_name}->{workspace}};
                    next merge_file_measure_update;
                }
                  
                if($_->[0] eq 'multi_count'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{multi_count}->{$_->[1]}->{workspace};
                    my $multi_count_field_name = $_->[1];
                    $big_hunk->{$key}->{multi_count}->{$multi_count_field_name}->{workspace}->{$_} += 
                        $small_hunk->{$key}->{multi_count}->{$multi_count_field_name}->{workspace}->{$_}
                            for keys %{$small_hunk->{$key}->{multi_count}->{$multi_count_field_name}->{workspace}};
                    next merge_file_measure_update;
                }
                
                if($_->[0] eq 'sum'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{sum}->{$_->[1]};
                    $big_hunk->{$key}->{sum}->{$_->[1]} += $small_hunk->{$key}->{sum}->{$_->[1]};
                    next merge_file_measure_update;
                }
                
                if($_->[0] eq 'product'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{product}->{$_->[1]};
                    $big_hunk->{$key}->{product}->{$_->[1]} *= $small_hunk->{$key}->{product}->{$_->[1]};
                    next merge_file_measure_update;
                }
                
                if($_->[0] eq 'average'){
                    next merge_file_measure_update unless exists $small_hunk->{$key}->{average}->{$_->[1]}->{workspace}->{sum_total};
                    $big_hunk->{$key}->{average}->{$_->[1]}->{workspace}->{sum_total} += 
                        $small_hunk->{$key}->{average}->{$_->[1]}->{workspace}->{sum_total};
                    $big_hunk->{$key}->{average}->{$_->[1]}->{workspace}->{observations} += 
                        $small_hunk->{$key}->{average}->{$_->[1]}->{workspace}->{observations};
                    next merge_file_measure_update;
                }
            }
            
        }
        