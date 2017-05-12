# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 15;
    use_ok qw( Class::Accessor::Children::Fast );
# ----------------------------------------------------------------
{
    package Foo;
    use base qw( Class::Accessor::Children::Fast );
    __PACKAGE__->mk_accessors(qw( one two ));
    __PACKAGE__->mk_ro_accessors(qw( three four ));
    __PACKAGE__->mk_wo_accessors(qw( five six ));
}
# ----------------------------------------------------------------
foreach my $class (qw( Foo )) {
    my $foo = $class->new( {one=>1,three=>3,five=>5} );
    ok( ref $foo, 'foo - new' );
    ok( $foo->isa( 'Class::Accessor' ), 'foo - isa' );
    ok( ! $foo->can( 'zero' ), 'foo - zero' );

    # read

    is( $foo->one,      1,      'read one' );
    is( $foo->two,      undef,  'read two' );
    is( $foo->three,    3,      'read three' );
    is( $foo->four,     undef,  'read four' );
    {
        local $@;
        eval { $foo->five; };
        ok( $@, 'read five [write-only]' );
    }

    # write

    ok( $foo->two( 2 ), 'write two' );
    {
        local $@;
        eval { $foo->four( 4 ); };
        ok( $@, 'write four [read-only]' );
    }
    ok( $foo->six( 6 ), 'write six' );

    # read

    is( $foo->two,  2,      'read two' );
    is( $foo->four, undef,  'read four' );
    {
        local $@;
        eval { $foo->six; };
        ok( $@, 'read six [write-only]' );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
