package Crypt::Keyczar::FileWriter;
use base 'Crypt::Keyczar::Writer';
use strict;
use warnings;
use Carp;
use File::Path;


sub location {
    my $self = shift;
    if (@_) {
        my $l = shift || '';
        $l =~ s{/$}{};
        $self->{location} = $l;
    }
    return $self->{location};
}


sub put_metadata {
    my $self = shift;
    my $meta = shift;

    if (!-d $self->location) {
        mkpath([$self->location], 0, 0755);
    }
    my $path = sprintf '%s/meta', $self->location;
    _put($path, $meta->to_string);
}


sub put_key {
    my $self = shift;
    my ($version, $key) = @_;

    if (!-d $self->location) {
        mkpath([$self->location], 0, 0755);
    }
    my $path = sprintf '%s/%u', $self->location, $version;
    _put($path, $key->to_string);
}


sub delete_key {
    my $self = shift;
    my $version = shift;
    my $path = sprintf '%s/%u', $self->location, $version;
    return unlink($path) == 1;
}


sub _put {
    my $path = shift;
    my $json = shift;

    open my $fh, '>', $path or croak "can't open file: $path: $!";
    print $fh $json, "\n";
    close $fh;
}

1;
__END__
