package Data::Pokemon::Go::Pokemon;
use 5.008001;
use Carp;
use Exporter 'import';
our @EXPORT_OK = qw( $All @List @Types );

use Moose;
use Moose::Util::TypeConstraints;
use YAML::XS;
use File::Share 'dist_dir';
my $dir = $ENV{'USER'} eq 'yuki.yoshida'? 'share': dist_dir('Data-Pokemon-Go');

use Data::Pokemon::Go::Relation;
our @Types = @Data::Pokemon::Go::Role::Types::All;
use Data::Pokemon::Go::Skill;

my $skill = Data::Pokemon::Go::Skill->new();

our $All = {};
our @List = ();
foreach my $region (qw|Kanto Johto Hoenn Sinnoh Unova Alola|){
    my $data = YAML::XS::LoadFile("$dir/$region.yaml");
    map{
        my $fullname = _get_fullname( $_, 'ja' );
        $All->{ $fullname } = $_;
        push @List, $fullname;
    } @$data;
}

enum 'PokemonName' => \@List;
has name => ( is => 'rw', isa => 'PokemonName' );

before 'name' => sub {
    my $self = shift;
    my $name = shift;
    my $form = shift || '';
    if ( defined $name and $name =~ /^(\w+)\((\w+)\)$/ ){
        $name = $1;
        $form = $2;
    }
    
    croak "unvalid name: $name&$form" if $name and not $self->exists($name) and not $self->exists("$name($form)");
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub exists {
    my $self = shift;
    my $name = shift;
    return CORE::exists $All->{$name};
}

sub id {
    my $self = shift;
    my $name = $self->name();
    my $id = $All->{$name}{ID};
    carp "'ID' may be invalid: $id" unless $id =~ /^\d{3}$/;
    return $id;
}

sub types {
    my $self = shift;
    my $name = $self->name();
    my $typesref = $All->{$name}{Types};
    carp "'Types' may be invalid: $typesref" unless ref $typesref eq 'ARRAY';
    return $typesref;
}

sub skill {
    my $self = shift;
    my $name = $self->name();
    my $ref = $All->{$name}{Skill};
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
    my $ref = $All->{$name}{Special};
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
    croak "'Stamina' is undefined for $name" unless exists $All->{$name}{'Stamina'};
    return $All->{$name}{Stamina};
}

sub attack {
    my $self = shift;
    my $name = $self->name();
    croak "'Attack' is undefined for $name" unless exists $All->{$name}{'Attack'};
    return $All->{$name}{Attack};
}

sub defense {
    my $self = shift;
    my $name = $self->name();
    croak "'Defense' is undefined for $name" unless exists $All->{$name}{'Defense'};
    return $All->{$name}{Defense};
}

sub max {
    my $self = shift;
    my $when = shift;
     croak "Unvalid param $when into sub max()"
    unless $when =~ /(:?Boosted|Hatched|Grown)/;

    my $name = $self->name();
    croak "'$when' is undefined for $name" unless exists $All->{$name}{'MAXCP'}{$when};
    return $All->{$name}{'MAXCP'}{$when};
}

sub isNotWild {
    my $self = shift;
    my $name = $self->name();
    return $All->{$name}{'isNotWild'};
}

sub isNotAvailable {
    my $self = shift;
    my $name = $self->name();
    return $All->{$name}{'isNotAvailable'};
}

sub isAlola {
    my $self = shift;
    my $name = $self->name();
    return $All->{$name}{'isAlola'};
}

sub hasForms {
    my $self = shift;
    my $name = $self->name();
    return exists $All->{$name}{'Form'}? $All->{$name}{'Form'} : 0;
}

sub _get_fullname {
    my $ref = shift;
    my $lang = shift;
    my $fullname = __PACKAGE__->get_Pokemon_name( $ref, $lang );
    $fullname .= "($ref->{'Form'})" if exists $ref->{'Form'};
    return $fullname;
}

sub get_Pokemon_name {
    my $self = shift;
    my $ref = shift;
    my $lang = shift || 'jp';
    croak "No name for $lang" unless exists $ref->{'Name'}{$lang};
    return $ref->{'Name'}{$lang};
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
