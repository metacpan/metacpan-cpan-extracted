#!/usr/bin/perl -w

use strict;
use Test::More tests => 67;
use Carp;
BEGIN { $SIG{__DIE__} = \&confess };

##############################################################################
# Test basic functionality.
TESTPKG: {
    package My::Test;
    use Test::More;
    BEGIN {
        use_ok 'Class::Meta::Express' or die;
        use_ok 'Class::Meta::Types::Perl';
    }

    BEGIN {
        meta   test => ();
        ctor   new  => ();
        has    foo  => ( type => 'scalar' );
        method meth => sub {
            pass 'Method called';
        };
        build;

        ok !defined &meta,   'meta should no longer be defined';
        ok !defined &ctor,   'ctor should no longer be defined';
        ok !defined &has,    'has should no longer be defined';
        ok !defined &method, 'method should no longer be defined';
        ok !defined &build,  'build should no longer be defined';
    }
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

    meta   hash => { trust => 'My::Test' };
    ctor   new =>  { label => 'Label' };
    has    foo =>  { type  => 'string' };
    method meth => { code => sub { pass 'Method called' } };
    build;
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

    meta default => (
         default_type => 'string',
         meta_class   => 'My::MetaClass'
    );

    ctor new => sub { bless { sub => 'yes' }, shift };
    has  'foo';
    build;
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
        meta export => ( reexport => 1 );
        build;
    }
}

TESTIMPORT: {
    package My::TestImport;
    use Test::More;

    BEGIN {
        My::TestExport->import;
    }
    meta 'import';
    has  foo => ( type => 'scalar');
    ok build, 'Build My::TestImport';
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
        meta exportdef => (
             default_type => 'string',
             meta_class   => 'My::MetaClass',
             reexport     => 1
        );

        build;
    }
}

TESTIMPORTDEF: {
    package My::TestImportDef;
    use Test::More;

    BEGIN {
        My::TestExportDef->import;
    }
    meta 'importdef';
    has  foo => ();
    ok build, 'Build My::TestImportDef';
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
        meta exporter => (
             default_type => 'string',
             meta_class   => 'My::MetaClass',
             reexport     => sub { pass 'importer should be called' },
        );

        build;
    }
}

TESTIMPORTER: {
    package My::TestImporter;
    use Test::More;

    BEGIN {
        My::TestExporter->import;
    }
    meta 'importer';
    has  foo => ();
    ok build, 'Build My::TestImporter';
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
        meta exporter2 => (
             reexport => sub {
                 my $caller = caller;
                 no strict 'refs';
                 *{"$caller\::somat"} = \'foo';
             },
         );

        build;
    }
}

TESTIMPORTER2: {
    package My::TestImporter2;
    use Test::More;

    BEGIN {
        My::TestExporter2->import;
    }
    is $somat, 'foo', '$somat should be set to "foo"';
    meta 'importer2';
    has  foo => ( type => 'scalar' );
    ok build, 'Build My::TestImporter2';
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
    meta subex => ();
    has  foo => ();
    build;
}

ok $meta = +My::TestSubExpress->my_class, 'Get the SubExpress meta object';
ok my $attr = $meta->attributes('foo'), 'Get the "foo" attribute';
is $attr->type, 'string', 'Its type should be "string"';

