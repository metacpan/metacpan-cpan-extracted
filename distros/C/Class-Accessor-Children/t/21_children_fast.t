# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 29;
    use_ok qw( Class::Accessor::Children::Fast );
# ----------------------------------------------------------------
{
    package Foo;
    use base qw( Class::Accessor::Children::Fast );
    __PACKAGE__->mk_child_accessors(
        Odd     =>  [qw( one   seven )],
        Even    =>  [qw( two   eight )],
    );
    __PACKAGE__->mk_child_ro_accessors(
        Odd     =>  [qw( three nine )],
        Even    =>  [qw( four  ten  )],
    );
    __PACKAGE__->mk_child_wo_accessors(
        Odd     =>  [qw( five  eleven )],
        Even    =>  [qw( six   twelve )],
    );
}
# ----------------------------------------------------------------
{
    my $odd  = Foo::Odd->new( {one=>1,three=>3,five=>5} );
    ok( ref $odd, 'odd - new' );
    ok( $odd->isa( 'Class::Accessor' ), 'odd - isa' );
    ok( ! $odd->can( 'zero' ), 'odd - zero' );

    my $even = Foo::Even->new( {two=>2,four=>4,six=>6} );
    ok( ref $even, 'even - new' );
    ok( $even->isa( 'Class::Accessor' ), 'even - isa' );
    ok( ! $even->can( 'zero' ), 'even - zero' );

    # read

    is( $odd->one,    1,      'read one' );
    is( $even->two,   2,      'read two' );
    is( $odd->three,  3,      'read three' );
    is( $even->four,  4,      'read four' );
    {
        local $@;
        eval { $odd->five; };
        ok( $@, 'read five [write-only]' );
    }
    {
        local $@;
        eval { $even->six; };
        ok( $@, 'read six [write-only]' );
    }
    is( $odd->seven,  undef,  'read three' );
    is( $even->eight, undef,  'read eight' );
    is( $odd->nine,   undef,  'read nine' );
    is( $even->ten,   undef,  'read ten' );

    # write

    ok( $odd->seven( 7 ),    'write seven' );
    ok( $even->eight( 8 ),   'write eight' );
    {
        local $@;
        eval { $odd->nine( 9 ); };
        ok( $@, 'write nine [read-only]' );
    }
    {
        local $@;
        eval { $odd->ten( 10 ); };
        ok( $@, 'write ten [read-only]' );
    }
    ok( $odd->eleven( 11 ),  'write eleven' );
    ok( $even->twelve( 12 ), 'write twelve' );

    # read

    is( $odd->seven,  7,      'read three' );
    is( $even->eight, 8,      'read eight' );
    is( $odd->nine,   undef,  'read nine' );
    is( $even->ten,   undef,  'read ten' );
    {
        local $@;
        eval { $odd->eleven; };
        ok( $@, 'read eleven [write-only]' );
    }
    {
        local $@;
        eval { $even->twelve; };
        ok( $@, 'read twelve [write-only]' );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
