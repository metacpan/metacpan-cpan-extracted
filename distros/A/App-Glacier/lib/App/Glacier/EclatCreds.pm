package App::Glacier::EclatCreds;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

sub _parse_access_file {
    my ($self, $file) = @_;
#    debug(1, "Looking for authentication credentials in $file");
    open(my $fd, '<', $file) or do {
	croak "$file: $!";
	return;
    };
    my $key;
    while (<$fd>) {
	chomp;
	s/^\s+//;
	if (/^#:\s*(.+?)\s*$/) {
	    $key = $1;
	} elsif (/^#/ || /^$/) {
	    next;
	} elsif (/^(?<ac>.+?):(?<sc>.+?)(?::(?<reg>.+))?\s*$/) {
	    $key = $+{ac} unless $key;
	    unless (exists($self->{_db}{$key})) {
		$self->{_db}{$key} = {
		    access => $+{ac},
		    secret => $+{sc},
		    region => $+{reg},
		    file => $file,
		    line => $.
		};
		$self->{_default} = $key unless $self->{_default};
	    }
	    $key = undef;
	}
    }
    close $fd;
}

sub new {
    my ($class, $filename) = @_;
    my $self = bless { _db => {} }, $class;
    foreach my $file (glob $filename) {
	$self->_parse_access_file($file);
    }
    return $self;
}

sub has_key {
    my ($self, $key) = @_;
    return exists $self->{_db}{$key};
}

sub get {
    my ($self, $key) = @_;
    $key = $self->{_default} unless $key;
    return undef unless $self->has_key($key);
    return $self->{_db}{$key};
}

sub access_key {
    my ($self, $key) = @_;
    $key = $self->{_default} unless $key;
    carp "no access key for $key" unless $self->has_key($key);
    return $self->{_db}{$key}{access};
}

sub secret_key {
    my ($self, $key) = @_;
    $key = $self->{_default} unless $key;
    carp "no secret key for $key" unless $self->has_key($key);
    return $self->{_db}{$key}{secret};
}

sub region {
    my ($self, $key) = @_;
    $key = $self->{_default} unless $key;
    carp "no region for $key" unless $self->has_key($key);
    return $self->{_db}{$key}{region};
}
1;

