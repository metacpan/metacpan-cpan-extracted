#!/usr/bin/perl -w

use strict;

use Test::More tests => 23;

BEGIN { use_ok 'Class::Fields' }


package Foo;

use public      qw(this that);
use private     qw(_eep _orp);
use protected   qw(Pants _stuff);
use base qw( Class::Fields );

package Bar;

use base qw( Class::Fields Foo);

::ok( Foo->is_public('this'),           'Method:  is_public()'              );
::ok( !Foo->is_public('_stuff'),        'Method:  is_public(), false'       );
::ok( !Foo->is_public('fnord'),         'Method:  is_public(), no field'    );

::ok( Foo->is_private('_eep'),          'Method:  is_private()'             );
::ok( Foo->is_protected('_stuff'),      'Method:  is_protected()'           );
::ok( Bar->is_inherited('this'),        'Method:  is_inherited()'           );

::ok( Foo->is_field('_eep'),            'Method:  is_field()'               );
::ok( !Foo->is_field('fnord'),           'Method:  is_field(), false'       );

::is_deeply([ sort Foo->show_fields ], 
            [ sort qw(this that _eep _orp Pants _stuff) ],
                                        'Method:  show_fields() all'        );
::is_deeply([ sort Bar->show_fields(qw(Inherited)) ], 
            [ sort qw(this that Pants _stuff) ],
                                        'Method:  show_fields() Inherited'  );
::is_deeply([ sort Foo->show_fields('Public') ], 
            [ sort qw(this that) ],
                                        'Method:  show_fields() Public'     );
::is_deeply([ sort Bar->show_fields('Public', 'Inherited') ], 
            [ sort qw(this that) ],
                            'Method:  show_fields() Public & Inherited'     );
::is_deeply([ sort Foo->show_fields('Public', 'Inherited') ], 
            [ sort qw() ],
                         'Method:  show_fields() Public & Inherited, empty' );


package main;
use Class::Fields;

::ok( is_public('Foo', 'this'),         'Function:  is_public()'            );
::ok( !is_public('Foo', '_stuff'),      'Function:  is_public(), false'     );
::ok( !is_public('Foo', 'fnord'),       'Function:  is_public(), no field'  );

::ok( is_private('Foo', '_eep'),        'Function:  is_private()'           );
::ok( is_protected('Foo', '_stuff'),    'Function:  is_protected()'         );

use Class::Fields::Attribs;
::is( field_attrib_mask('Bar', 'Pants'), (PROTECTED|INHERITED),
                                        'field_attrib_mask()'               );
::is_deeply([sort &field_attribs('Bar', 'Pants')],
            [sort qw(Protected Inherited)],
                                        'field_attribs()'                   );

# Can't really think of a way to test dump_all_attribs().


# Make sure show_fields() doens't autovivify %FIELDS.
use Class::Fields::Fuxor;
::ok( !show_fields("I::have::no::FIELDS") );
::ok( !has_fields("I::have::no::FIELDS"),         "has_fields() autoviv bug" );
