package Crypt::Keyczar::FileReader;
use base 'Crypt::Keyczar::Reader';
use strict;
use warnings;
use Carp;

sub META_FILE {'meta'}



sub new {
    my $class = shift;
    my $location = shift;

    my $self = bless {
        __location => $location
    }, $class;
    $self->init;
    return $self;
}


sub init {
    my $self = shift;
    if ($self->{__location} && $self->{__location} !~ m{/$}) {
        $self->{__location} .= '/';
    }
    return $self;
}


sub get_key {
    my $self = shift;
    my $version = shift;
    if (!defined $version || $version < 1) {
        croak "require version number";
    }
    return $self->_read(sprintf '%s%d', $self->{__location}, $version);
}


sub get_metadata {
    my $self = shift;
    return $self->_read(sprintf '%s%s', $self->{__location}, META_FILE);
}


sub _read {
    my $self = shift;
    my $path = shift;

    open my $fh, '<', $path or croak "can't open key file: $path: $!";
    local $/ = undef;
    my $contents = <$fh>;
    close $fh;
    return $contents;
}


1;
__END__
