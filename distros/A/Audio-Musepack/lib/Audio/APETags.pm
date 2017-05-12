package Audio::APETags;

# Base class wrapper.

use strict;
use Audio::Scan;

our $VERSION = '1.0';

sub new {
    my ($class, $file) = @_;

    my $method = ref $file ? 'scan_fh' : 'scan';
    my $self   = Audio::Scan->$method($file);

    bless $self, $class;

    return $self;
}

sub _extract {
    my ($self, $type, $key) = @_;

    return $self->{$type} unless $key;
    return $self->{$type}{ucfirst $key} if defined $self->{$type}{ucfirst $key};
    return $self->{$type}{$key};
}

sub info {
    return shift->_extract('info', @_);
}

sub tags {
    return shift->_extract('tags', @_);
}

1;

__END__
