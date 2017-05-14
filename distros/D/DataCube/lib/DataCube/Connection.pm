


package DataCube::Connection;

use strict;
use warnings;
use DataCube::FileUtils;
use DataCube::Connection::Table;

sub new {
    my($class,$source) = @_;
    die "DataCube::Connection(new):\nplease provide a directory to the new constructor\n$!\n"
        unless -d($source);
    my $self   = bless {}, ref($class) || $class; 
    my $utils  = DataCube::FileUtils->new;
    my @source = $utils->dir($source);
    for(@source){
        my $path = "$source/$_";
        next unless -d($path);
        $self->{tables}->{$path} = DataCube::Connection::Table->new($path);
    }
    return $self;
}

sub sync {
    my($self) = @_;
    for(keys %{$self->{tables}}){
        my $dir = $_;
        $self->{tables}->{$dir}->sync($dir);
    }
    return $self;
}

sub source {
    my($self) = @_;
    return $self->{source};
}

sub report {
    my($self,$dir) = @_;
    die "DataCube::Connection(report):\nplease provide a directory to save reports\n$!\n"
        unless -d($dir);
    for(keys %{$self->{tables}}){
        $self->{tables}->{$_}->report($dir);
    }
    return $self;
}

sub report_html {
    my($self,$dir) = @_;
    die "DataCube::Connection(report):\nplease provide a directory to save reports\n$!\n"
        unless -d($dir);
    for(keys %{$self->{tables}}){
        $self->{tables}->{$_}->report_html($dir);
    }
    return $self;
}






1;











