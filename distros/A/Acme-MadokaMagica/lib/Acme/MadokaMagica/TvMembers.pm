package Acme::MadokaMagica::TvMembers;
use strict;
use warnings;
use utf8;
use Data::Section::Simple;
use YAML::Tiny;

sub new {
    my ($class, %args) = @_;

    my $self = { _has_qb => undef };
    my $ds = Data::Section::Simple->new($class);
    my $sections = $ds->get_data_section;
    for my $section_name ( keys %{$sections} ) {
        my $yml = YAML::Tiny->read_string($sections->{$section_name});
        my $member_info = $yml->[0];
        for my $key ( keys %{$member_info} ) {
            $self->{$key} = $member_info->{$key};
        }
    }
    if (defined $args{line}) {
        $self->{startline} = $args{line};
    } else {
        $self->{startline} = (caller)[2];
    }

    return bless $self, $class;
}

sub has_qb {
    my $self = shift;

    if (@_){
      $self->{_has_qb} = shift;
    }

    return $self->{_has_qb};
}

sub name {
    my ($self) = @_;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->has_qb ? $self->{witchename} : $self->lastname.' '.$self->firstname;
}

sub firstname {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if($line >= $limit ) {
        return undef;
    }
    return $self->{firstname};
}

sub birthday {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if($line >= $limit ) {
        return undef;
    }
    return $self->{birthday};
}

sub blood_type {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->{blood_type};
}

sub lastname {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->{lastname};
}

sub age {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->{age};
}

sub color{
    my ($self) = @_;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }

    return $self->has_qb ? "black" : $self->{color};
}

sub qb {
    my ($self) = @_;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }

    $self->has_qb(1);
}

sub say {
    my ($self) = @_;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->{say};
}

sub cv {
    my $self = shift;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->{cv};
}


1;
