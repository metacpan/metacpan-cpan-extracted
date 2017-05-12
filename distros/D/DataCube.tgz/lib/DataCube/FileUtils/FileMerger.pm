


package DataCube::FileUtils::FileMerger;

use strict;
use warnings;

use File::Copy;
use Time::HiRes;
use Storable qw(nstore retrieve);

use DataCube;
use DataCube::Schema;
use DataCube::FileUtils;
use DataCube::MeasureUpdater;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub merge {
    my($self,%opts) = @_;
    
    my $schema = $opts{schema};
    my $files  = $opts{source};
    my $target = $opts{target};
    my $unlink = $opts{unlink};
    
    $files = [$files] unless ref($files);
        
    if(@$files == 1 && ! -f($target)){
        File::Copy::copy($files->[0],$target);
        return $self;
    }
    
    my $updater = DataCube::MeasureUpdater->new($schema);
    
    my $hash = {};
    if(-f($target)){
        $hash = Storable::retrieve($target);
    }
    
    for(@$files){
        my $data = Storable::retrieve($_);
        while(my($key,$val) = each %$data){
            $updater->update(
                source     => $data,
                target     => $hash,
                source_key => $key,
                target_key => $key,
            );
            delete $data->{$key};
        }
        undef $data;
    }
    
    
    my $write_time = Time::HiRes::time;
    my $temp_file  = $target . '.' . $write_time;
    Storable::nstore($hash, $temp_file);
    
    if($unlink){
        for(@$files){
            unlink($_)
                or die "DataCube::FileUtils::FileMerge(merge : unlink):\ncant unlink:\n$_\n$!\n";
        }
    }
    
    rename($temp_file, $target)
        or die "DataCube::FileUtils::FileMerger(merge):\ncant rename:\n$temp_file\nto\n$target\n$!\n";
    
    undef $hash;
    return $self;
}












1;




__DATA__

### ok this is getting too cumbersome
### need to make this easier / simpler / better delegation of duties 




sub merge_tables {
    my($self,%opts) = @_;
    
    die "DataCube::Cube::FileMerger:\nneed a valid list of source files\n"
        unless defined $opts{source};
    
    my $target  = $opts{target};
    my $sources = ref($opts{source}) ? $opts{source} : [$opts{source}];
    
    for(@$sources){
        die "DataCube::Cube::FileMerger(merge_tables):\nnot a valid source directory\n$!\n"
            unless -d($_);
    }
    
    die "DataCube::Cube::FileMerger(merge_tables):\nneed a valid target directory to merge\n$!\n"
        unless -d($opts{target});
    
    my $schema_path = "$sources->[0]/.schema";
    
    die "DataCube::Cube::FileMerger(merge_tables):\nneed a valid source schema\n$!\n"
        unless -f($schema_path);
    
    my $schema  = Storable::retrieve($schema_path);
    my $updater = DataCube::MeasureUpdater->new($schema);
    
    my $digests = {};
    for(@$sources){
        my $source_digests = Storable::retrieve("$_/.digests");
        $digests->{$_} = $source_digests->{$_} for keys %$source_digests;
    }
    if(-f("$target/.digests")){
        my $target_digests = Storable::retrieve("$target/.digests");
        $digests->{$_} = $target_digests->{$_} for keys %$target_digests;
    }
    Storable::nstore($digests,"$target/.digests");
    unless(-f("$target/.schema") && -f("$target/.config") ) {
        File::Copy::copy("$sources->[0]/.schema","$target/.schema");
        File::Copy::copy("$sources->[0]/.config","$target/.config");
    }
    
    my %files;
    for(@$sources){
        my $source = $_;
        my @files  = grep {/^[a-f0-9]+$/i} $self->dir($source);
        push @{$files{$_}}, "$source/$_" for @files;
    }
    
    for(keys %files){
        my $file  = $_;
        my @files = @{$files{$file}};
        $self->merge_files(
            source       => \@files,
            target       => $target . "/$file",
            updater      => $updater,
            unlink_after => $opts{unlink_after},
        );
    }
    if($opts{unlink_after}){
        for(@$sources){
            unlink("$_/.config");
            unlink("$_/.digests");
            unlink("$_/.schema");
            rmdir($_)
                or die "DataCube::Cube::FileMerger(merge_tables : unlink_after):\ncant unlink:\n$_\n$!\n"
        }
    }
    return $self;
}

sub merge_files {
    my($self,%opts) = @_;
    
    $opts{source} = [$opts{source}]
        unless ref($opts{source}) &&
               ref($opts{source}) =~ /^array$/i;
    
    my $updater      = $opts{updater};
    my $target_file  = $opts{target};
    my $source_files = $opts{source};
    
    if(-f($target_file)) {
        my $target_hash = Storable::retrieve($target_file);
        for(@$source_files){
            my $source_hash = Storable::retrieve($_);
            for(keys %$source_hash){
                $updater->update(
                    source     => $source_hash,
                    target     => $target_hash,
                    source_key => $_,
                    target_key => $_,
                );
            }
        }
        my $write_time = Time::HiRes::time;
        my $temp_file  = $target_file.".$write_time";
        Storable::nstore($target_hash,$temp_file);
        rename($temp_file,$target_file);
    } else {
        if(@$source_files == 1){
            if($opts{unlink_after}){
                File::Copy::move($source_files->[0],$target_file);
            } else {
                File::Copy::copy($source_files->[0],$target_file);
            }
        } else {
            my $target_hash = {};
            for(@$source_files){
                my $source_hash = Storable::retrieve($_);
                for(keys %$source_hash){
                    $updater->update(
                        source     => $source_hash,
                        target     => $target_hash,
                        source_key => $_,
                        target_key => $_,
                    );
                }
            }
            Storable::nstore($target_hash,$target_file);
        }
    }
    
    if($opts{unlink_after}){
        for(@$source_files){
            next unless -f($_);
             unlink($_)
                or die "DataCube::Cube::FileMerger(merge : unlink_after : rmdir):\n".
                       "cant remove directory:\n$_\n$!\n";
        }
    }
        
    return $self;
}




__END__





