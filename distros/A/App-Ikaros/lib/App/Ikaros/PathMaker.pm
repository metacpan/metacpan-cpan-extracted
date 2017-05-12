package App::Ikaros::PathMaker;
use strict;
use warnings;
use File::Basename qw/dirname/;
use parent 'Exporter';

our @EXPORT_OK = qw/
    perl
    prove
    forkprove
    lib_top_dir
    lib_dir
/;

sub perl($) {
    my ($host) = @_;
    my $env = ($host->perlbrew) ? 'source $HOME/perl5/perlbrew/etc/bashrc;' : '';
    return $env . 'perl';
}

sub prove {
    my $path = dirname $INC{'App/Ikaros/PathMaker.pm'};
    return $path . '/Runner/Prove.pm';
}

sub forkprove {
    my $path = dirname $INC{'App/Ikaros/PathMaker.pm'};
    return $path . '/Runner/ForkProve.pm';
}

sub lib($) {
    my $class = shift;
    require $class;
    return dirname $INC{$class};
}

sub __dirs {
    my $lib = shift;
    return [ grep { $_ ne '' } split '/', $lib ];
}

sub lib_top_dir($) {
    my $class = shift;
    my $dirs  = __dirs(lib($class));
    my $class_depth = scalar @{__dirs($class)};
    my $total_depth = scalar @$dirs;
    my $end = $total_depth - ($class_depth - 1);
    return '/' . join '/', @$dirs[0 .. $end];
}

sub lib_dir($) {
    my $class = shift;
    my $dirs  = __dirs(lib($class));
    my $class_depth = scalar @{__dirs($class)};
    my $total_depth = scalar @$dirs;
    my $end = $total_depth - ($class_depth + 1);
    return '/' . join('/', @$dirs[0 .. $end]);
}

1;
