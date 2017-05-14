


package DataCube::FileUtils::CubeMerger;

use strict;
use warnings;

use DataCube::FileUtils;
use DataCube::FileUtils::TableMerger;

my $utils = DataCube::FileUtils->new;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub merge {
    my($self,%opts) = @_;
    my $source = $opts{source};
    my $target = $opts{target};
    my $unlink = $opts{unlink} || 0;
    die "DataCube::FileUtils::CubeMerger(merge | opts):\nneed a source and target directory to merge:\n$!"
        unless -d($source) && -d($target);
    my @tables = grep { /^[a-f0-9]{32}$/i } $utils->dir($source);
    for(@tables){
        die "DataCube::FileUtils::CubeMerger(merge | tables):\n".
            "found missaligned tables in source and target\n$source/$_\n$target/$_\n$!"
        unless -d("$target/$_");
    }
    my $table_merger = DataCube::FileUtils::TableMerger->new;
    for(@tables){
        $table_merger->merge (
            source => $source,
            target => $target,
            unlink => $unlink,
        );
    }    
    return $self;
}







1;




__DATA__



__END__





