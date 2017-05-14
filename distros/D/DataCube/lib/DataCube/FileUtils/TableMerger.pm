


package DataCube::FileUtils::TableMerger;

use strict;
use warnings;

use File::Copy;
use Time::HiRes;
use Storable qw(nstore retrieve);

use DataCube;
use DataCube::Schema;
use DataCube::FileUtils;
use DataCube::MeasureUpdater;
use DataCube::FileUtils::FileMerger;

my $utils = DataCube::FileUtils->new;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub merge {
    my($self,%opts) = @_;
    
    $opts{source} = [$opts{source}] unless ref($opts{source});
    my $schema    = Storable::retrieve("$opts{source}->[0]/.schema");
    
    $self->merge_auxillary_files(%opts);
    
    my %files;
    for(@{$opts{source}}){
        my $source = $_;
        my @files  = grep {/^[a-f0-9]+$/i} $utils->dir($source);
        push @{$files{$_}}, "$source/$_" for @files;
    }
    
    for(keys %files){
        my $file_merger = DataCube::FileUtils::FileMerger->new;
        $file_merger->merge(
            source  => $files{$_},
            target  => $opts{target} . "/$_",
            schema  => $schema,
            unlink  => $opts{unlink},
        );
    }
    
    return $self;
}


sub merge_auxillary_files {
    my($self,%opts) = @_;
    
    my $digests = {};
    for(@{$opts{source}}){
        my $source_digests = Storable::retrieve("$_/.digests");
        $digests->{$_} = $source_digests->{$_} for keys %$source_digests;
    }
    Storable::nstore($digests,"$opts{target}/.digests");
    
    File::Copy::copy("$opts{source}->[0]/.schema","$opts{target}/.schema")
        unless -f("$opts{target}/.schema");
    
    File::Copy::copy("$opts{source}->[0]/.config","$opts{target}/.config")
        unless -f("$opts{target}/.config");
    
    return $self;
}






1;




__DATA__



__END__





