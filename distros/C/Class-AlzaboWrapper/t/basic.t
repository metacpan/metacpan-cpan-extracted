#!perl -w

use strict;
use warnings;

use Alzabo::Create::Schema;
use Class::AlzaboWrapper;
use Test::More;


my $schema = _test_schema();

plan skip_all => 'Requires DBD::mysql or DBD::PG'
    unless $schema;

plan tests => 8;


{
    package TestPackage1;

    use base 'Class::AlzaboWrapper';

    eval { __PACKAGE__->MakeColumnMethods() };
    ::like( $@, qr/must call SetTable/i, 'cannot call MakeColumnMethods() before SetTable()' );

    __PACKAGE__->SetAlzaboTable( $schema->table('User') );

    ::is( __PACKAGE__->Table()->name(), 'User', 'table for __PACKAGE__ is User' );

    __PACKAGE__->MakeColumnMethods();

    ::can_ok( __PACKAGE__, qw( user_id username bio ) );

    ::is_deeply( [ sort __PACKAGE__->AlzaboAttributes() ],
                 [ qw( bio user_id username ) ],
                 'check AlzaboAttributes()' );

    ::can_ok( __PACKAGE__, qw( new create select update delete is_live ) );
}

{
    package TestPackage2;

    # make sure old "magic import" still works
    Class::AlzaboWrapper->import( table => $schema->table('User') );

    ::is( __PACKAGE__->Table()->name(), 'User', 'table for __PACKAGE__ is User' );
    ::can_ok( __PACKAGE__, qw( user_id username bio ) );
}

{
    package TestPackage3;

    use base 'Class::AlzaboWrapper';

    __PACKAGE__->SetAlzaboTable( $schema->table('User') );
    __PACKAGE__->MakeColumnMethods( skip => 'bio' );

    ::can_ok( __PACKAGE__, qw( user_id username ) );
}


sub _test_schema
{
    my $dbms =
        ( eval { require Alzabo::Driver::MySQL; 1 }
          ? 'MySQL'
          : eval { require Alzabo::Driver::PostgreSQL; 1 }
          ? 'PostgreSQL'
          : undef
        );

    return unless $dbms;

    my $schema =
        Alzabo::Create::Schema->new
            ( name  => 'testing_class_alzabowrapper',
              rdbms => $dbms,
            );

    my $user_t = $schema->make_table( name => 'User' );
    $user_t->make_column( name => 'user_id',
                          type => 'integer',
                          sequenced => 1,
                          primary_key => 1,
                        );

    $user_t->make_column( name => 'username',
                          type => 'varchar',
                          length => 250,
                        );

    $user_t->make_column( name => 'bio',
                          type => 'text',
                        );
}
