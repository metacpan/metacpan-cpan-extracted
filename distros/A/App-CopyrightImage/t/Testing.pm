package Testing;
use warnings;
use strict;

use File::Copy;
use File::Path qw(remove_tree);

sub new {
    my $self = bless {
        data => 't/data',
        build => 't/build',
        base => 't/build/base.jpg',
        copyr => 't/build/copyr.jpg',
    }, shift;
    
    $self->build;
    return $self;
}
sub data { return shift->{data}; };
sub base { return shift->{base}; };
sub copyr { return shift->{copyr}; };
sub build {
   if (! -d $_[0]->{build}){ 
        mkdir $_[0]->{build} or die $!;
        copy("$_[0]->{data}/base.jpg", $_[0]->{build});
        copy("$_[0]->{data}/copyr.jpg", $_[0]->{build});
    }
    return $_[0]->{build};
}
sub clean { remove_tree($_[0]->{build}) or die $! if -d 't/build';};
sub DESTROY { shift->clean; };  
1;
