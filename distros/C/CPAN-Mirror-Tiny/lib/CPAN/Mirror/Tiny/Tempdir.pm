package CPAN::Mirror::Tiny::Tempdir;
use strict;
use warnings;
use File::Temp ();
use File::Path ();
use File::pushd ();

use overload '""' => sub { shift->as_string };

sub as_string { shift->{tempdir} }

sub new {
    my ($class, $base) = @_;
    my $tempdir = File::Temp::tempdir(CLEANUP => 0, DIR => $base);
    bless { tempdir => $tempdir }, $class;
}

sub pushd {
    my ($class, $base) = @_;
    my $self = $class->new($base);
    $self->{guard} = File::pushd::pushd($self->as_string);
    $self;
}

sub DESTROY {
    my $self = shift;
    undef $self->{guard};
    local ($@, $!);
    eval { File::Path::rmtree($self->{tempdir}) };
}


1;
