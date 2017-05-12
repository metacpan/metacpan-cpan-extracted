use strict;
use Test::More 0.98;
use App::PerlPackage2PlantUMLClassDiagram::Repository;

subtest 'when empty' => sub {
    my $repository = App::PerlPackage2PlantUMLClassDiagram::Repository->new;
    isa_ok $repository, 'App::PerlPackage2PlantUMLClassDiagram::Repository';
    is_deeply $repository->packages, [];
    is $repository->to_plantuml, <<'UML';
@startuml
@enduml
UML
};

subtest 'render a package' => sub {
    my $repository = App::PerlPackage2PlantUMLClassDiagram::Repository->new;
    $repository->load_package('t/data/Mammal.pm');
    is @{$repository->packages}, 1;
    isa_ok $repository->packages->[0], 'App::PerlPackage2PlantUMLClassDiagram::Package';
    is $repository->to_plantuml, <<'UML';
@startuml
class Mammal {
  {static} new(%args)
  + walk()
}
@enduml
UML
};

subtest 'render packages' => sub {
    my $repository = App::PerlPackage2PlantUMLClassDiagram::Repository->new;
    $repository->load_package('t/data/Mammal.pm');
    $repository->load_package('t/data/HasPassword.pm');
    $repository->load_package('t/data/User.pm');
    is $repository->to_plantuml, <<'UML';
@startuml
class Mammal {
  {static} new(%args)
  + walk()
}
class HasPassword {
  + authenticate($login_info, $callback)
}
class User {
  {static} new(%args)
  + name()
  - _password()
}
Mammal <|-- User
HasPassword <|-- User
@enduml
UML
};

done_testing;

