


package DataCube::FileUtils;

use strict;
use warnings;

use Fcntl;
use DataCube;
use DataCube::Schema;
use DataCube::MeasureUpdater;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub dir {
    my($self,$path) = @_;
    opendir(my $D, $path) or die "DataCube::FileUtils(dir):\ncant open directory:$path\n$!\n";
    grep {/[^\.]/} readdir($D);
}

sub unlink_recursive {
    my($self,$d) = @_;
    if(-d($d)){
        my @d = $self->dir($d);
        $self->unlink_recursive("$d/$_") for @d;
        rmdir($d) or die "DataCube::FileUtils(unlink_recursive | rmdir):\ncant rmdir $d\n$!\n";
    } elsif( -f($d) ) {
        unlink($d)
            or die "DataCube::FileUtils(unlink_recursive | unlink):\ncant unlink $d\n$!\n";
    }
    return $self
}


sub ensure_directory {
    my($self,$dir) = @_;
    return if -d($dir);
    my @dir = ();
    my $tmp = $dir;
    parent_tree:
    while($tmp =~ /[\\\/]/){
        $tmp =~ /^(.*?)[\\\/]([^\\\/]+)$/;
        $tmp = $1;    
        unshift @dir, $2;
        last parent_tree if -d($tmp);
    }
    mkdir($tmp);
    for(@dir){
       $tmp .= '/' . $_;
       mkdir($tmp)
        or die "DataCube::FileUtils(ensure_directory):\n".
               "could not ensure directory:\n$dir:\nfailed at:\n$tmp\n$!\n";
    }
    return $self;
}

sub contents {
    my($self,$path) = @_;
    sysopen(my $F, $path, O_RDONLY)
        or die "DataCube::FileUtils(contents | sysopen):\ncant sysopen:\n$path\n$!\n";
    my $size  = -s($path);
    my $bytes = sysread($F, my $contents, $size);
    die "DataCube::FileUtils(contents | sysread | bytes):\nwanted:\n".
        "$size bytes\ngot:\n$bytes bytes\nfrom:\n$path\n$!\n"
            unless $size == $bytes;
    return wantarray ? split/\n/,$contents,-1 : $contents;
}


sub write {
    my($self,%opts) = @_;
    sysopen(my $F, $opts{target}, O_WRONLY | O_CREAT)
        or die "DataCube::FileUtils(contents | sysopen):\ncant sysopen:\n$opts{target}\n$!\n";
    use bytes;
    my $size  = bytes::length($opts{content});
    my $bytes = syswrite($F, $opts{content}, $size);
    die "DataCube::FileUtils(contents | syswrite | bytes):\nwanted to write:\n".
        "$size bytes\nbut wrote:\n$bytes bytes\ninto:\n$opts{target}\n$!\n"
            unless $size == $bytes;
    return $self;
}


1;




__DATA__





__END__





