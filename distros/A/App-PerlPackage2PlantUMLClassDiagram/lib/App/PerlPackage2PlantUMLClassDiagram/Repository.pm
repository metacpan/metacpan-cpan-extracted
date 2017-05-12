package App::PerlPackage2PlantUMLClassDiagram::Repository;
use 5.014;
use strict;
use warnings;

use App::PerlPackage2PlantUMLClassDiagram::Package;

sub new {
    my ($class) = @_;

    bless {
        packages => [],
    }, $class;
}

sub packages {
    my ($self) = @_;

    $self->{packages};
}

sub load_package {
    my ($self, $path) = @_;

    push @{$self->{packages}}, App::PerlPackage2PlantUMLClassDiagram::Package->new($path);
}

sub to_plantuml {
    my ($self) = @_;

    my @class_syntaxes = grep { chomp($_); $_ } map {
        $_->to_class_syntax
    } @{$self->packages};

    my @inherit_syntaxes = grep { chomp($_); $_ } map {
        $_->to_inherit_syntax
    } @{$self->packages};

    join "\n", '@startuml', @class_syntaxes, @inherit_syntaxes, '@enduml', '';
}

1;
