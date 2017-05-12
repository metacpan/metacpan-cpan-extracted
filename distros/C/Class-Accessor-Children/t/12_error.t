# ----------------------------------------------------------------
    package Foo;
    use strict;
    use Test::More tests => 9;
    use_ok qw( Class::Accessor::Children );
    use base qw( Class::Accessor::Children );
# ----------------------------------------------------------------
{
    {
        local $@;
        eval { __PACKAGE__->mk_child_accessors(); };
        ok( ! $@, 'no accessors' );
    }
    {
        local $@;
        eval { __PACKAGE__->mk_child_accessors( 'odd' ); };
        ok( $@, 'odd number arguments' );
    }
    {
        local $@;
        eval { __PACKAGE__->mk_child_accessors( [], [] ); };
        ok( $@, 'Invalid child class name' );
    }
    {
        local $@;
        eval { __PACKAGE__->mk_child_accessors( child => 'aaa bbb' ); };
        ok( ! $@, 'scalar' );
        ok( Foo::child->can( 'aaa' ), 'split 1' );
        ok( Foo::child->can( 'bbb' ), 'split 2' );
    }
    {
        local $@;
        eval { __PACKAGE__->mk_child_accessors( '' => [qw( ccc )] ); };
        ok( ! $@, 'zero' );
        ok( Foo->can( 'ccc' ), 'base' );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
