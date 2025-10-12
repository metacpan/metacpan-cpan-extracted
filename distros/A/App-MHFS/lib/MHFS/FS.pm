package MHFS::FS v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Cwd qw(abs_path);
use File::Basename qw(fileparse);

sub lookup {
    my ($self, $name, $sid) = @_;

    if(! exists $self->{'sources'}{$sid}) {
        return undef;
    }

    my $src = $self->{'sources'}{$sid};
    if($src->{'type'} ne 'local') {
        say "unhandled src type ". $src->{'type'};
        return undef;
    }
    my $location = $src->{'folder'};
    my $absolute = abs_path($location.'/'.$name);
    return undef if( ! $absolute);
    return undef if ($absolute !~ /^$location/);
    return _media_filepath_to_src_file($absolute, $location);
}

sub _media_filepath_to_src_file {
    my ($filepath, $flocation) = @_;
    my ($name, $loc, $ext) = fileparse($filepath, '\.[^\.]*');
    $ext =~ s/^\.//;
    return { 'filepath' => $filepath, 'name' => $name, 'containingdir' => $loc, 'ext' => $ext, 'fullname' => substr($filepath, length($flocation)+1), 'root' => $flocation};
}

sub new {
    my ($class, $sources) = @_;
    my %self = ('sources' => $sources);
    bless \%self, $class;
    return \%self;
}

1;
