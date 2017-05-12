package Convert::CharMap::YAML;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';

BEGIN {
    no warnings 'once';
    local $@;
    if (eval { require YAML::Syck }) {
        *Dump = *YAML::Syck::Dump;
        *LoadFile = *YAML::Syck::LoadFile;
    }
    elsif (eval { require YAML::Tiny }) {
        *Dump = *YAML::Tiny::Dump;
        *LoadFile = *YAML::Tiny::LoadFile;
    }
    elsif (eval { require YAML::XS }) {
        *Dump = *YAML::XS::Dump;
        *LoadFile = *YAML::XS::LoadFile;
    }
    else {
        require YAML;
        *Dump = *YAML::Dump;
        *LoadFile = *YAML::LoadFile;
    }
}

sub in {
    my $class = shift;
    return LoadFile(+shift);
}

sub out {
    my $class = shift;
    return Dump(+shift);
}

1;
