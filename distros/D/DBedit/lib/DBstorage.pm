=head1 NAME

DBstorage - Base class for DBstorage classes

=head1 SYNOPSIS

This class is the base class for DBstorage classes.  It is an abstract 
class with mostly empty methods.

=head1 LICENSE

Copyright (C) 2002 Globewide Network Academy
Relased under the SCHEME license see LICENSE.SCHEME.txt for details

=cut

package DBstorage;

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
	bless ($self, $class);
	return $self;
}

sub connect {
}

sub open {
}

sub read {
}

sub close {
}

sub disconnect {
}

sub find {
}

sub get_nth {
}

sub create {
}

sub attrib {
}

sub delete {
}

sub append {
}

sub replace {
}

sub commit {
}

sub exists {
    return 1;
}

sub debug {
    my ($self, $val) = @_;
    if (defined($val)) {
	$self->{'debug'} = $val;
    }
    return $self->{'debug'};
}

sub errstr {
    return "";
}
1;
