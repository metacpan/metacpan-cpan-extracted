use strict;
use Test::More 0.98;
use App::PerlPackage2PlantUMLClassDiagram::Package;

subtest 'basic' => sub {
    my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/User.pm');
    isa_ok $package, 'App::PerlPackage2PlantUMLClassDiagram::Package';
    is $package->source, 't/data/User.pm';
    isa_ok $package->document, 'PPI::Document';
    is $package->package_name, 'User';

    is_deeply $package->static_methods, ['new(%args)'];

    is_deeply $package->public_methods, ['name()'];
    is_deeply $package->private_methods, ['_password()'];

    is_deeply $package->parent_packages, ['Mammal', 'HasPassword'];

    is $package->to_class_syntax, <<'UML';
class User {
  {static} new(%args)
  + name()
  - _password()
}
UML
};

subtest 'method_signiture' => sub {
    subtest 'empty' => sub {
        my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/Constant.pm');
        is_deeply $package->public_methods, ['pi()'];
    };

    subtest 'with arguments' => sub {
        my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/HasPassword.pm');
        is_deeply $package->public_methods, ['authenticate($login_info, $callback)'];
    };

    subtest 'function' => sub {
        my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/Math.pm');
        is_deeply $package->public_methods, ['add($a, $b)'];
    };
};

subtest 'without inheritance' => sub {
    my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/Mammal.pm');
    is $package->to_inherit_syntax, '';
};

subtest 'without method' => sub {
    my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/EmptyClass.pm');
    is_deeply $package->_methods, [];
};

subtest 'method which start with _' => sub {
    my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/MethodWithUnderscore.pm');
    is_deeply $package->public_methods, ['user_info()'];
};

subtest 'not existing file' => sub {
    local $@;

    eval {
        App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/NotExist.pm');
    };
    like $@, qr{^file not exist: t/data/NotExist.pm};
};

subtest 'not a package' => sub {
    my $package = App::PerlPackage2PlantUMLClassDiagram::Package->new('t/data/hello.pl');
    is $package->to_class_syntax, '';
    is $package->to_inherit_syntax, '';
};

done_testing;

