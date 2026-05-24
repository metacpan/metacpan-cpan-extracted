package CPAN::Mirror::Tiny::Tempdir;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);
use File::Temp ();
use File::Path ();
use File::pushd ();

sub as_string ($self) { $self->{tempdir} }

sub new ($class, $base) {
    my $tempdir = File::Temp::tempdir(CLEANUP => 0, DIR => $base);
    bless { tempdir => $tempdir }, $class;
}

sub pushd ($class, $base) {
    my $self = $class->new($base);
    $self->{guard} = File::pushd::pushd($self->as_string);
    $self;
}

sub DESTROY ($self) {
    undef $self->{guard};
    local ($@, $!);
    eval { File::Path::rmtree($self->{tempdir}) };
}


1;
