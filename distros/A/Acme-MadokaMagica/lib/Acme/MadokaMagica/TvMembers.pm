package Acme::MadokaMagica::TvMembers;

use Mouse;

use utf8;
use Data::Section::Simple;
use YAML::Tiny;

has has_qb => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 0,
);

no Mouse;

sub name {
    my ($self) = @_;
    my $line = (caller)[2];

    my $limit = $self->{startline} +100;
    if( $line >= $limit ) {
        return undef;
    }
    return $self->has_qb ? $self->{witchename}:$self->lastname . ' ' .$self->firstname;
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

sub BUILD {
    my ($self, $args) = @_;

    my $ds = Data::Section::Simple->new( ref $self );
    my $sections = $ds->get_data_section;
    for my $section_name ( keys %{$sections} ) {
        my $yml = YAML::Tiny->read_string( $sections->{$section_name} );
        my $member_info = $yml->[0];
        for my $key ( keys %{$member_info} ) {
            $self->{$key} = $member_info->{$key};
        }
    }
    if (defined $args->{line}) {
        $self->{startline} = $args->{line};
    } else {
        $self->{startline} = (caller)[2];
    }
}

1;
