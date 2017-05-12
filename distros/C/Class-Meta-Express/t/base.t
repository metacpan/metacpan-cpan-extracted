#!/usr/bin/perl -w

use strict;
use Test::More tests => 94;
use Carp;
use File::Spec;

##############################################################################
# Test basic functionality.
TESTPKG: {
    package My::Test;
    use Test::More;
    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::Perl';
    }

    class {
        meta   test => ();
        ctor   new  => ();
        has    foo  => ( type => 'scalar' );
        method meth => sub {
            pass 'Method called';
        };
    };

    ok !defined &meta,   'meta should no longer be defined';
    ok !defined &ctor,   'ctor should no longer be defined';
    ok !defined &has,    'has should no longer be defined';
    ok !defined &method, 'method should no longer be defined';
    ok !defined &build,  'build should no longer be defined';
    ok !defined &class,  'class should no longer be defined';
}

ok my $meta = +My::Test->my_class, 'Get the Test meta object';
is $meta->key, 'test', 'The key should be "test"';
ok my $test = My::Test->new, 'Construct a test object';
is $test->foo, undef, 'The "foo" attribute should be undef';
ok $test->foo('bar'), 'Set "foo" attribute';
is $test->foo, 'bar', 'It should not be set';
SKIP: {
    skip 'add_method code parameter requires Class::Meta 0.51', 1
        if Class::Meta->VERSION < 0.51;
    $test->meth;
}

##############################################################################
# Test calling the functions with hash references.
TESTHASH: {
    package My::TestHash;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    class {
        meta   hash => { trust => 'My::Test' };
        ctor   new =>  { label => 'Label' };
        has    foo =>  { type  => 'string' };
        method meth => { code => sub { pass 'Method called' } };
    }
}

ok $meta = +My::TestHash->my_class, 'Get the TestHash meta object';
is $meta->key, 'hash', 'The key should be "hash"';
ok $test = My::TestHash->new, 'Construct a TestHash object';
is $test->foo, undef, 'The "foo" attribute should be undef';
ok $test->foo('bar'), 'Set "foo" attribute';
is $test->foo, 'bar', 'It should not be set';
SKIP: {
    skip 'add_method code parameter requires Class::Meta 0.51', 1
        if Class::Meta->VERSION < 0.51;
    $test->meth;
}
ok my $new = $meta->constructors('new'), 'Get new ctor';
is $new->label, 'Label', 'Its label should be "Label"';
ok my $foo = $meta->attributes('foo'), 'Get foo attr';
is $foo->type, 'string', 'Its type should be "string"';

##############################################################################
# Test meta_class and default_type.
TESTSUBCLASS: {
    package My::MetaClass;
    use base 'Class::Meta';
    use Test::More;

    sub new {
        pass 'new should be called';
        shift->SUPER::new(@_);
    }
}

TESTDEFAULT: {
    package My::TestDefault;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    class {
        meta default => (
            default_type => 'string',
            meta_class   => 'My::MetaClass'
        );

        ctor new => sub { bless { sub => 'yes' }, shift };
        has  'foo';
    }
}

ok my $def = My::TestDefault->new, 'Construct TestDefault object';
SKIP: {
    skip 'add_constructor code parameter requires Class::Meta 0.51', 1
        if Class::Meta->VERSION < 0.53;
    is $def->{sub}, 'yes', 'The custom constructor should have been called';
}
ok $meta = +My::TestDefault->my_class, 'Get the TestDefault meta object';
ok $foo = $meta->attributes('foo'), 'Get foo attr';
is $foo->type, 'string', 'Its type should be "string"';

##############################################################################
# Test re-exporting.
TESTEXPORT: {
    package My::TestExport;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    BEGIN {
        class {
            meta export => ( reexport => 1 );
        }
    }
}

TESTIMPORT: {
    package My::TestImport;
    use Test::More;

    BEGIN {
        My::TestExport->import;
    }

    ok class {
        meta 'import';
        has  foo => ( type => 'scalar');
    }, 'Build My::TestImport';
}

ok $meta = +My::TestImport->my_class, 'Get the TestImportDef meta object';
ok $foo = $meta->attributes('foo'), 'Get foo attr';
is $foo->type, 'scalar', 'Its type should be "string"';

##############################################################################
# Test re-exporting with defaults.
TESTEXPORTDEF: {
    package My::TestExportDef;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    BEGIN {
        class {
            meta exportdef => (
                default_type => 'string',
                meta_class   => 'My::MetaClass',
                reexport     => 1
            );
        }
    }
}

TESTIMPORTDEF: {
    package My::TestImportDef;
    use Test::More;

    BEGIN {
        My::TestExportDef->import;
    }

    ok class {
        meta 'importdef';
        has  foo => ();
    }, 'Build My::TestImportDef';
}

ok $meta = +My::TestImportDef->my_class, 'Get the TestImportDef meta object';
ok $foo = $meta->attributes('foo'), 'Get foo attr';
is $foo->type, 'string', 'Its type should be "string"';

##############################################################################
# Test re-exporting with custom import.
TESTEXPORTER: {
    package My::TestExporter;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    BEGIN {
        class {
            meta exporter => (
                default_type => 'string',
                meta_class   => 'My::MetaClass',
                reexport     => sub { pass 'importer should be called' },
            );
        }
    }
}

TESTIMPORTER: {
    package My::TestImporter;
    use Test::More;

    BEGIN {
        My::TestExporter->import;
    }

    ok class {
        meta 'importer';
        has  foo => ();
        }, 'Build My::TestImporter';
}

ok $meta = +My::TestImportDef->my_class, 'Get the TestImportDef meta object';
ok $foo = $meta->attributes('foo'), 'Get foo attr';
is $foo->type, 'string', 'Its type should be "string"';

##############################################################################
# Test re-exporting with custom import.
TESTEXPORTER2: {
    package My::TestExporter2;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    BEGIN {
        class {
            meta exporter2 => (
                reexport => sub {
                    my $caller = caller;
                    no strict 'refs';
                    *{"$caller\::somat"} = \'foo';
                },
            );
        }
    }
}

TESTIMPORTER2: {
    package My::TestImporter2;
    use Test::More;

    BEGIN {
        My::TestExporter2->import;
    }
    is $somat, 'foo', '$somat should be set to "foo"';

    ok class {
        meta 'importer2';
        has  foo => ( type => 'scalar' );
    }, 'Build My::TestImporter2';
    is $somat, 'foo', '$somat should still be set to "foo"';
}

ok $meta = +My::TestImportDef->my_class, 'Get the TestImportDef meta object';

##############################################################################
# Test subclassing.
SUBEXPRESS: {
    package My::SubExpress;

    use base 'Class::Meta::Express';

    sub meta {
        splice @_, 1, 0, default_type => 'string';
        goto &Class::Meta::Express::meta;
    }
}

USESUBEXPRESS: {
    package My::TestSubExpress;
    use Test::More;
    BEGIN {
        My::SubExpress->import;
    }

    class {
        meta subex => ();
        has  foo => ();
    }
}

ok $meta = +My::TestSubExpress->my_class, 'Get the SubExpress meta object';
ok my $attr = $meta->attributes('foo'), 'Get the "foo" attribute';
is $attr->type, 'string', 'Its type should be "string"';

##############################################################################
# Test no meta.
NOMETA: {
    package My::NoMEta;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    class {
        ctor   new  => ();
        has    foo  => ( type => 'scalar' );
    };
}

ok my $nom = My::NoMEta->new, 'Construct My::NoMeta object';
ok $meta = +My::NoMEta->my_class, 'Get the NoMEta meta object';
is $meta->key, 'no_meta', 'Its key should be "no_meta"';

##############################################################################
# Make sure default is inherited when no meta.
# INHERITNOMETA: {
#     package My::NoMetaInherit;
#     use base 'My::TestDefault';
#     use Test::More;
#     BEGIN { use_ok 'Class::Meta::Express' or die }

#     class {
#         has 'zoz';
#     }
# }

# ok $meta = My::NoMetaInherit->my_class, 'Get the NoMetaInherit object';
# is $meta->key, 'no_meta_inherit', 'Its key should be "no_meta_inherit"';
# ok $attr = $meta->attributes('zoz'), 'Get the "zoz" attribute object';
# is $attr->type, 'string', 'It should be a string';

##############################################################################
# Test view, just to be sure.
VIEW: {
    package My::View;
    use Test::More;

    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::String';
    }

    class {
        meta view      => ( default_type => 'string' );
        ctor new       => ();
        has  public    => ( view => Class::Meta::PUBLIC );
        has  private   => ( view => Class::Meta::PRIVATE );
        has  trusted   => ( view => Class::Meta::TRUSTED );
        has  protected => ( view => Class::Meta::PROTECTED );
    };

    ok my $view = My::View->new, 'Create new private view object';
    is undef, $view->public,     'Should be able to access public';
    is undef, $view->private,    'Should be able to access private';
    is undef, $view->trusted,    'Should be able to access trusted';
    is undef, $view->protected,  'Should be able to access protected';
}

ok my $view = My::View->new, 'Create new public view object';
is undef, $view->public,     'Should be able to access public';
eval { $view->private };
chk( 'private exception', qr/private is a private attribute of My::View/);
eval { $view->trusted };
chk( 'trusted exception', qr/trusted is a trusted attribute of My::View/);
eval { $view->protected };
chk( 'protected exception', qr/protected is a protected attribute of My::View/);

sub chk {
    my ($name, $qr) = @_;
    # Catch the exception.
    ok( my $err = $@, "Caught $name error" );
    # Check its message.
    like( $err, $qr, "Correct error" );
    SKIP: {
        skip 'Older Carp lacks @CARP_NOT support', 2 unless $] >= 5.008;
        # Make sure it refers to this file.
        like( $err, qr/(?:at\s+t.base[.]t|t.base[.t]\s+at)\s+line/, 'Correct context' );
        # Make sure it doesn't refer to other Class::Meta files.
        unlike( $err, qr|lib/Class/Meta|, 'Not incorrect context')
    }
}
