=head1 NAME

DBfilelock - Class to encapsulate filelocking

=head1 SYNOPSIS

This class encapsulates filelocking.  DO NOT USE IT since file locking
is bad and subject to race conditions.  Use flock instead.

=head1 LICENSE

Copyright (C) 2002 Globewide Network Academy
Released under the SCHEME license see LICENSE.SCHEME.txt for details

=cut


package DBfilelock;
use IO::File;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    ($self->{'FILENAME'}) = @_;
    $self->{'ENDTIME'} = 20;
    
    $self->{'FH'} = undef;

    bless ($self, $class);
    $self->set();
    return $self;
}

sub set {
    my ($self) = @_;
    my ($release_time) = time + $self->{'ENDTIME'};
    while (-e $self->{'FILENAME'} && time < $release_time) {
	sleep(1);
    }
    $self->{'FH'} = IO::File->new(">$self->{'FILENAME'}");
    if (!defined($self->{'FH'})) {
	die "Cannot open lock file $self->{'FILENAME'}";
    }
}

sub release {
    my ($self) = @_;
    $self->{'FH'}->close();
    $self->{'FH'} = undef;
    unlink($self->{'FILENAME'});
}

1;

