package Crypt::Keyczar::KeyMetadata;
use strict;
use warnings;
use Crypt::Keyczar::KeyVersion;
use Crypt::Keyczar::Util qw(decode_json encode_json json_true json_false json_null);


sub get_name { $_[0]->{name} }
sub get_purpose { $_[0]->{purpose} }
sub get_type { $_[0]->{type} }
sub encrypted {
    my $self = shift;
    $self->{encrypted} = shift if @_;
    return $self->{encrypted};
}


sub new {
    my $class = shift;
    my ($name, $purpose, $type) = @_;
    my $self = bless {
        name    => $name,
        purpose => $purpose,
        type    => $type,
        encrypted => undef,
        __version_map => {},
        versions => [],
    }, $class;
    return $self;
}

sub read {
    my $class = shift;
    my $json_string = shift;
    my $obj = decode_json($json_string);
    my $self = $class->new($obj->{name}, $obj->{purpose}, $obj->{type});
    $self->{encrypted} = $obj->{encrypted};
    for my $v (@{$obj->{versions}}) {
        if (!$v) {
            $self->add_version(undef);
        }
        else {
            $self->add_version(Crypt::Keyczar::KeyVersion->new($v->{versionNumber}, $v->{status}, $v->{exportable}));
        }
    }
    return $self;
}


sub get_versions {
    my $self = shift;
    return @{$self->{versions}};
}


sub get_version {
    my $self = shift;
    my $version = shift;
    return $self->{__version_map}->{$version};
}


sub add_version {
    my $self = shift;
    my $key_version = shift;

    if (defined $key_version) {
        if (exists $self->{__version_map}->{$key_version->get_number}) {
            return undef;
        }
        $self->{__version_map}->{$key_version->get_number()} = $key_version;
    }
    push @{$self->{versions}}, $key_version;
    return 1;
}


sub remove_version {
    my $self = shift;
    my $version_number = shift;

    if (!exists $self->{__version_map}->{$version_number}) {
        return undef;
    }
    undef $self->{versions}->[$version_number - 1];
    delete $self->{__version_map}->{$version_number};

    return 1;
}


sub expose {
    my $self = shift;
    my $expose = {};

    $expose->{name} = $self->{name};
    $expose->{purpose} = $self->{purpose};
    $expose->{type}    = $self->{type};
    $expose->{encrypted} = $self->{encrypted} ? json_true() : json_false();
    $expose->{versions} = [];
    for my $v ($self->get_versions) {
        push @{$expose->{versions}}, $v ? $v->expose : json_null();
    }

    return $expose;
}


sub to_string { return encode_json($_[0]->expose) }


1;
__END__
