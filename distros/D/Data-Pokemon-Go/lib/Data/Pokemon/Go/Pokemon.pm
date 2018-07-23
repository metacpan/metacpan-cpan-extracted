package Data::Pokemon::Go::Pokemon;
use 5.008001;
use Carp;

use Moose;
use Moose::Util::TypeConstraints;

use Data::Pokemon::Go::Relation;
use Data::Pokemon::Go::Skill;

my $skill = Data::Pokemon::Go::Skill->new();

use YAML::XS;
use Path::Tiny;

my $all = {};
foreach my $region (qw|Kanto Johto Hoenn Alola|){
    my $in_file = path( 'data', "$region.yaml" );
    my $data = YAML::XS::LoadFile($in_file);
    map{ $data->{$_}{'name'} = $_ } keys %$data;
    %$all = ( %$all, %$data );
}

our @All = map{ $_->{name} } sort{ $a->{ID} cmp $b->{ID} } values %$all;
enum 'PokemonName' => \@All;
has name => ( is => 'rw', isa => 'PokemonName' );

before 'name' => sub {
    my $self = shift;
    my $name = shift;
    croak "unvalid name" if $name and not $self->exists($name);
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub exists {
    my $self = shift;
    my $name = shift;
    return CORE::exists $all->{$name};
}

sub id {
    my $self = shift;
    my $name = $self->name();
    my $id = $all->{$name}{ID};
    carp "'ID' may be invalid: $id" unless $id =~ /^\d{3}$/;
    return $id;
}

sub types {
    my $self = shift;
    my $name = $self->name();
    my $typesref = $all->{$name}{Types};
    carp "'Types' may be invalid: $typesref" unless ref $typesref eq 'ARRAY';
    return $typesref;
}

sub skill {
    my $self = shift;
    my $name = $self->name();
    my $ref = $all->{$name}{Skill};
    my @skill;
    foreach my $name (@$ref) {
        $skill->name($name);
        $skill->own_type( $self->types() );
        push @skill, $skill->as_string();
    }
    return @skill;
}

sub special {
    my $self = shift;
    my $name = $self->name();
    my $ref = $all->{$name}{Special};
    my @skill;
    foreach my $name (@$ref) {
        $skill->name($name);
        $skill->own_type( $self->types() );
        push @skill, $skill->as_string();
    }
    return @skill;
}

sub effective {
    my $self = shift;
    return Data::Pokemon::Go::Relation->new( types => $self->types() )->effective();
};

sub invalid {
    my $self = shift;
    return Data::Pokemon::Go::Relation->new( types => $self->types() )->invalid();
};

sub advantage {
    my $self = shift;
    return Data::Pokemon::Go::Relation->new( types => $self->types() )->advantage();
};

sub disadvantage {
    my $self = shift;
    return Data::Pokemon::Go::Relation->new( types => $self->types() )->disadvantage();
};

sub recommended {
    my $self = shift;
    return Data::Pokemon::Go::Relation->new( types => $self->types() )->recommended();
};

sub stamina {
    my $self = shift;
    my $name = $self->name();
    croak "'Stamina' is undefined for $name" unless exists $all->{$name}{'Stamina'};
    return $all->{$name}{Stamina};
}

sub attack {
    my $self = shift;
    my $name = $self->name();
    croak "'Attack' is undefined for $name" unless exists $all->{$name}{'Attack'};
    return $all->{$name}{Attack};
}

sub defense {
    my $self = shift;
    my $name = $self->name();
    croak "'Defense' is undefined for $name" unless exists $all->{$name}{'Defense'};
    return $all->{$name}{Defense};
}

sub hatchedMAX {
    my $self = shift;
    my $name = $self->name();
    croak "'Hatched' is undefined for $name" unless exists $all->{$name}{'MAXCP'}{'Hatched'};
    return $all->{$name}{'MAXCP'}{'Hatched'};
}

sub boostedMAX {
    my $self = shift;
    my $name = $self->name();
    croak "'Boosted' is undefined for $name" unless exists $all->{$name}{'MAXCP'}{'Boosted'};
    return $all->{$name}{'MAXCP'}{'Boosted'};
}

sub isNotWild {
    my $self = shift;
    my $name = $self->name();
    return $all->{$name}{'isNotWild'};
}

sub isNotAvailable {
    my $self = shift;
    my $name = $self->name();
    return $all->{$name}{'isNotAvailable'};
}

sub isAlola {
    my $self = shift;
    my $name = $self->name();
    return $all->{$name}{'isAlola'};
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Pokemon - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Pokemon;

=head1 DESCRIPTION

Data::Pokemon::Go::Pokemon is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut
