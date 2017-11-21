package Data::Pokemon::Go::Pokemon;
use 5.008001;
use Carp;

use Moose;
use Moose::Util::TypeConstraints;

use Data::Pokemon::Go::Relation;
use Data::Pokemon::Go::Skill;

my $skill = Data::Pokemon::Go::Skill->new();

use Path::Tiny;
#my $in_file = path( 'data', 'Pokemon.yaml' );
my $in_file = path( 'data', 'Kanto.yaml' );

use YAML::XS;
my $data = YAML::XS::LoadFile($in_file);
map{ $data->{$_}{name} = $_ } keys %$data;
our @All = map{ $_->{name} } sort{ $a->{ID} cmp $b->{ID} } values %$data;
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
    return CORE::exists $data->{$name};
}

sub id {
    my $self = shift;
    my $name = $self->name();
    my $id = $data->{$name}{ID};
    carp "'ID' may be invalid: $id" unless $id =~ /^\d{3}$/;
    return $id;
}

sub types {
    my $self = shift;
    my $name = $self->name();
    my $typesref = $data->{$name}{Types};
    carp "'Types' may be invalid: $typesref" unless ref $typesref eq 'ARRAY';
    return $typesref;
}

sub skill {
    my $self = shift;
    my $name = $self->name();
    my $ref = $data->{$name}{Skill};
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
    my $ref = $data->{$name}{Special};
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
    croak "'Stamina' is undefined for $name" unless exists $data->{$name}{Stamina};
    return $data->{$name}{Stamina};
}

sub attack {
    my $self = shift;
    my $name = $self->name();
    croak "'Attack' is undefined for $name" unless exists $data->{$name}{Attack};
    return $data->{$name}{Attack};
}

sub defense {
    my $self = shift;
    my $name = $self->name();
    croak "'Defense' is undefined for $name" unless exists $data->{$name}{Defense};
    return $data->{$name}{Defense};
}

sub hatchedMAX {
    my $self = shift;
    my $name = $self->name();
    croak "'HatchedMAX' is undefined for $name" unless exists $data->{$name}{HatchedMAX};
    return $data->{$name}{HatchedMAX};
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
