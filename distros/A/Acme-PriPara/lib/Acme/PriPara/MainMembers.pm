package Acme::PriPara::MainMembers;
use Mouse;

use Data::Section::Simple;
use YAML::Tiny;
use Data::Dumper;
use utf8;

has has_pripara_changed => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

no Mouse;

sub name {
    my ($self) = @_; 
    return $self->lastname . ' ' . $self->firstname; 
}

sub firstname {
    my ($self) = @_; 
    return $self->{firstname}; 
}

sub lastname {
    my ($self) = @_; 
    return $self->{lastname}; 
}

sub age {
    my ($self) = @_; 
    return $self->{age}; 
}

sub birthday {
    my ($self) = @_; 
    return $self->{birthday}; 
}

sub blood_type {
    my ($self) = @_; 
    return $self->{blood_type}; 
}

sub cv {
    my ($self) = @_; 
    return $self->{cv}; 
}

# alias to voiced_by
*voiced_by = \&cv;

sub say {
    my ($self) = @_; 
    return $self->{say}; 
}

sub color {
    my ($self) = @_;
    return $self->has_pripara_changed ? $self->{color} : undef;
}

sub costume_brand {
    my ($self) = @_; 
    return $self->has_pripara_changed ? $self->{costume_brand} : undef;
}

sub pripara_change {
    my ($self) = @_;
    $self->has_pripara_changed(1);
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
}

1;
