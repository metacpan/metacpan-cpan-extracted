package Crypt::Keyczar::Manager;
use base 'Crypt::Keyczar';
use strict;
use warnings;
use Crypt::Keyczar::FileReader;
use Crypt::Keyczar::Key;
use Carp;


sub promote {
    my $self = shift;
    my $version_number = shift;

    my $version = $self->get_version_by_number($version_number);
    if ($version->status eq 'PRIMARY') {
        croak "can't promote primary key#$version_number";
    }
    elsif ($version->status eq 'ACTIVE') {
        $version->status('PRIMARY');
        if ($self->primary) {
            $self->primary->status('ACTIVE');
        }
        $self->primary($version);
    }
    elsif ($version->status eq 'INACTIVE') {
        $version->status('ACTIVE');
    }
}


sub demote {
    my $self = shift;
    my $version_number = shift;

    my $version = $self->get_version_by_number($version_number);
    if ($version->status eq 'PRIMARY') {
        $version->status('ACTIVE');
        $self->primary(undef);
    }
    elsif ($version->status eq 'ACTIVE') {
        $version->status('INACTIVE');
    }
    elsif ($version->status eq 'INACTIVE') {
        croak "can't demote inactive key#$version_number";
    }
}


sub revoke {
    my $self = shift;
    my $version_number = shift;

    my $version = $self->get_version_by_number($version_number);
    if ($version->status eq 'INACTIVE') {
        $self->metadata->remove_version($version_number);
    }
    else {
        croak "can't revoke active or primary key#$version_number";
    }
}


sub add_version {
    my $self = shift;
    my ($status, $size) = @_;
    $status ||= 'ACTIVE';

    my $num = scalar($self->metadata->get_versions) + 1;
    my $version = Crypt::Keyczar::KeyVersion->new($num, $status, undef);
    if (uc $status eq 'PRIMARY') {
        if ($self->primary) {
            $self->primary->status('ACTIVE');
        }
        $self->primary($version);
    }
    if (!$size) {
        # find default size $self->metadata->get_type;
    }
    my $key;
    do {
        $key = Crypt::Keyczar::Key->generate_key($self->metadata->get_type, $size);
    } while ($self->get_key($key->hash));
    $self->add_key($version, $key);
    return $version;
}


sub get_version_by_number {
    my $self = shift;
    my $version_number = shift;
    my $version = $self->metadata->get_version($version_number);
    if (!defined $version) {
        croak "no such key version#$version_number";
    }
    return $version;
}


1;
__END__
