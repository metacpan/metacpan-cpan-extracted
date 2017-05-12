use Test::More tests => 2;

BEGIN {
    package Test::Class::Std::Fast;
    ::use_ok('Class::Std::Fast');

    package Test::Class::Std::Fast::Storable;
    ::use_ok('Class::Std::Fast::Storable');
}

diag( "Testing Class::Std::Fast $Class::Std::Fast::VERSION" );
diag( "Testing Class::Std::Fast::Storable $Class::Std::Fast::Storable::VERSION" );
