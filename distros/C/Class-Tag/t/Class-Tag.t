

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Tag.t'

use strict;

use Test::More;
BEGIN {	plan tests => 105; } # allows to calcualte tests plan, but now SKIP is (better) used instead

BEGIN { $^W = 0; } 

BEGIN { use_ok('Class::Tag') };  

{ 
	package Foo;
	use Class::Tag; 
}
ok( Class::Tag->is('Foo')); 
ok(!Class::Tag->is('Bar')); 

my $foo = bless {}, 'Foo';
my $bar = bless {}, 'Bar';

ok( Class::Tag->is($foo)); 
ok(!Class::Tag->is($bar)); 

{ 
	package Foo;
	#no   Class::Tag; # at compile-time
	untag Class::Tag; # same at run-time
}
ok(!Class::Tag->is('Foo')); 

# Using custom tag 'class': 
{
	package Foo;
	use Class::Tag qw(class pureperl); 
}
ok( Class::Tag->class(   'Foo')); 
ok( Class::Tag->pureperl('Foo')); 
ok(!Class::Tag->class(   'Bar')); 
ok(!Class::Tag->pureperl('Bar')); 

ok( Class::Tag->class(   $foo)); 
ok( Class::Tag->pureperl($foo)); 
ok(!Class::Tag->class(   $bar)); 
ok(!Class::Tag->pureperl($bar)); 

# Using "valued" tags:
{
	package Foo;
	use Class::Tag { class => 'is awesome', author => 'metadoo' };  

	# and now also tagging object of Foo class with same tags different values...
	Class::Tag->class( $foo => 'is awesome too');
	Class::Tag->author($foo =>    'metadoo too');

}
is(Class::Tag->class( 'Foo'), 'is awesome');     
is(Class::Tag->author('Foo'),    'metadoo');     
is(Class::Tag->class( $foo),  'is awesome too'); 
is(Class::Tag->author($foo),     'metadoo too'); 

# modifying tag values with accessors...
is(Class::Tag->class( 'Foo',  'is pupe-perl'), 'is pupe-perl');
is(Class::Tag->class( 'Foo'), 'is pupe-perl');
is(Class::Tag->author('Foo',  'nobody'), 'nobody');
is(Class::Tag->author('Foo'), 'nobody');
is(Class::Tag->class( $foo),    'is awesome too');  # unaffected
is(Class::Tag->author($foo),       'metadoo too');  # unaffected
is(Class::Tag->class( $foo,   'is pupe-perl too'), 'is pupe-perl too');
is(Class::Tag->class( $foo),  'is pupe-perl too');
is(Class::Tag->author($foo,         'nobody too'), 'nobody too');
is(Class::Tag->author($foo),        'nobody too');
is(Class::Tag->class( 'Foo'), 'is pupe-perl');      # unaffected
is(Class::Tag->author('Foo'),       'nobody');      # unaffected

# Inheriting tags, using for example the default 'is' tag:
{
	package Foo;
	use Class::Tag 'inherits';  

	@Bar::ISA = 'Foo';
}
ok( Class::Tag->inherits('Foo')); # true
ok( Class::Tag->inherits('Bar')); # true ('is' tag inherited)
ok( Class::Tag::inherits('Foo')); # true
ok(!Class::Tag::inherits('Bar')); # false (no tag inheritance)

{ 
	package Awesome; # tagger class
	use Class::Tag 'tagger_class';
	use     Awesome 'AUTOLOAD'; 

	package Foo2;
	use Awesome; 
}
ok( Awesome->is('Foo2')); # true
ok(!Awesome->is('Bar2')); # false  

my $foo = bless {}, 'Foo2';
my $bar = bless {}, 'Bar2';

ok( Awesome->is($foo)); # true
ok(!Awesome->is($bar)); # false  

{ 
	package Foo2;
	#no   Awesome; # at compile-time
	untag Awesome; # same at run-time
}
ok(!Awesome->is('Foo2')); 
ok(!Awesome->is($foo)); 

{
	package Buz; 
	# tagging class Foo with tags 'class' and 'pureperl' of Awesome tagger class...
	use Awesome  'class';
	use Awesome              'pureperl';
	package Buz2; 
	use Awesome  'class',    'pureperl';       # same
	package Buz3; 
	use Awesome { class => 1, pureperl => 1 }; # same
}
ok( Awesome->class(   'Buz'));   
ok( Awesome->pureperl('Buz'));   
ok( Awesome->class(   'Buz2'));  
ok( Awesome->pureperl('Buz2'));  
ok( Awesome->class(   'Buz3'));  
ok( Awesome->pureperl('Buz3'));  
ok(!Awesome->class(   'Other')); 
ok(!Awesome->pureperl('Other')); 

{
	package Buz; 
	# tagging class Foo with tags 'class' and 'pureperl' of Awesome tagger class...
	untag Awesome  'class';
	untag Awesome              'pureperl';
	package Buz2; 
	untag Awesome  'class',    'pureperl';       # same
	package Buz3; 
	untag Awesome { class => 1, pureperl => 1 }; # same
}
ok(!Awesome->class(   'Buz'));   
ok(!Awesome->pureperl('Buz'));   
ok(!Awesome->class(   'Buz2'));  
ok(!Awesome->pureperl('Buz2'));  
ok(!Awesome->class(   'Buz3'));  
ok(!Awesome->pureperl('Buz3'));  
ok(!Awesome->class(   'Other')); 
ok(!Awesome->pureperl('Other')); 

{
	package Foo2;
	use     Class::Tag { ortogonal =>      'class_tag' };
	use        Awesome { ortogonal =>      'awesome' }; 
	use        Awesome 'really';
}
is(         Class::Tag->ortogonal('Foo2'), 'class_tag');
is(            Awesome->ortogonal('Foo2'), 'awesome') ;
ok(     really Awesome    'Foo2' );
ok( not really Class::Tag 'Foo2' );

# Using custom tag 'class': 
{
	package Awesome; # tagger class
	use Class::Tag tagger_class => [qw(class pureperl)];

	package Foo2;
	use Awesome qw(class pureperl); 
}
ok( Awesome->class(   'Foo2')); 
ok( Awesome->pureperl('Foo2')); 
ok(!Awesome->class(   'Bar2')); 
ok(!Awesome->pureperl('Bar2')); 

ok( Awesome->class(   $foo)); 
ok( Awesome->pureperl($foo)); 
ok(!Awesome->class(   $bar)); 
ok(!Awesome->pureperl($bar)); 

# Using "valued" tags:
{
	package Awesome; # tagger class
	use Class::Tag tagger_class => [qw(class author)];

	package Foo2;
	use Awesome { class => 'is awesome', author => 'metadoo' }; 

	# and now also tagging object of Foo class with same tags different values...
	Awesome->class( $foo => 'is awesome too');
	Awesome->author($foo =>    'metadoo too');
}
is(Awesome->class(    'Foo2'), 'is awesome'); 
is(Awesome->author(   'Foo2'),    'metadoo');    
is(Awesome->class( $foo),      'is awesome too'); 
is(Awesome->author($foo),         'metadoo too'); 

# modifying tag values with accessors...
is(Awesome->class(    'Foo2',  'is pupe-perl'), 'is pupe-perl');
is(Awesome->class(    'Foo2'), 'is pupe-perl');
is(Awesome->author(   'Foo2',  'nobody'), 'nobody');
is(Awesome->author(   'Foo2'), 'nobody');
is(Awesome->class( $foo),        'is awesome too');  # unaffected
is(Awesome->author($foo),           'metadoo too');  # unaffected
is(Awesome->class( $foo,       'is pupe-perl too'), 'is pupe-perl too');
is(Awesome->class( $foo),      'is pupe-perl too');
is(Awesome->author($foo,             'nobody too'), 'nobody too');
is(Awesome->author($foo),            'nobody too');
is(Awesome->class(    'Foo2'), 'is pupe-perl');      # unaffected
is(Awesome->author(   'Foo2'),       'nobody');      # unaffected

# Inheriting tags, using for example the default 'is' tag:
{
	package Awesome; # tagger class
	use Class::Tag 'tagger_class';

	package Foo2;
	use Awesome 'inherits'; 

	@Bar2::ISA = 'Foo2';
}
ok( Awesome->inherits('Foo2')); # true
ok( Awesome->inherits('Bar2')); # true ('is' tag inherited)
ok( Awesome::inherits('Foo2')); # true
ok(!Awesome::inherits('Bar2')); # false (no tag inheritance)

# checking non-AUTOLOAD tags...
{ 
	package Cool; # tagger class
	use Awesome 'tagger_class'; 
	use     Cool;  # 'is' tag declared
	use     Cool 'class', 'author'; 

	package Foo3;
	use       Cool 'is';
	use       Cool { class => 'is cool', author => 'metadoo2' }; 
	eval{ tag Cool 'undeclared' };
} 
ok($@); 
ok( Cool->is('Foo3')); 
ok(!Cool->is('Bar3')); 
is( Cool->class( 'Foo3'), 'is cool'); 
is( Cool->author('Foo3'), 'metadoo2'); 

# evolving notion of tag...
{ 
	package Tag; # tagger class
	use Awesome 'tagger_class'; 
	use     Tag { evolved  => sub{ join ' ', @_ } }; 
	use     Tag { AUTOLOAD => sub{ join ' ', @_ } }; 
} 
my @args = (3, 2, 5);
is( Tag->evolved('Zoo', @args), join ' ', 'Tag', 'Zoo', @args); 
is( Tag::evolved('Zoo', @args), join ' ', undef,  'Zoo', @args); 
is( Tag->evolved('Zoo'       ), join ' ', 'Tag', 'Zoo'       ); 
is( Tag::evolved('Zoo'       ), join ' ', undef,  'Zoo'       ); 
is( Tag->evolved(),             join ' ', undef,  'Tag'      ); 
is( Tag::evolved(),             join ' ', undef,              ); 

is( Tag->beloved('Zoo', @args), join ' ', 'Tag', 'Zoo', @args); 
is( Tag::beloved('Zoo', @args), join ' ', undef,  'Zoo', @args); 
is( Tag->beloved('Zoo'       ), join ' ', 'Tag', 'Zoo'       ); 
is( Tag::beloved('Zoo'       ), join ' ', undef,  'Zoo'       ); 
is( Tag->beloved(),             join ' ', undef,  'Tag'      ); 
is( Tag::beloved(),             join ' ', undef,              ); 

