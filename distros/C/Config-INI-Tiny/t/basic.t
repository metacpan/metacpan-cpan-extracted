use 5.006; use strict; use warnings;

use Test::More tests => 25;
use Config::INI::Tiny ();

sub p { scalar( /./g ); Config::INI::Tiny->new(@_)->to_hash($_) }

is_deeply p, {}, 'empty string' for '';

is_deeply p, {}, 'whitespace only' for "    \n\t\n";

is_deeply p, {}, 'comments' for <<'';
# this = comment
; so is this

is_deeply p, {}, 'empty comment markers' for <<'';
#
;

is_deeply p, { '' => { qw( foo 1 bar 2 ) } }, 'initial properties' for <<'';
foo=1
bar=2

is_deeply p, { '' => { empty => '' } }, 'property without a value' for <<'';
empty=

is_deeply p, { empty => {} }, 'empty section' for <<'';
[empty]

is_deeply p, { section => { qw( foo 1 bar 2 ) } }, 'section with properties' for <<'';
[section]
foo=1
;
bar=2

is_deeply p, { '' => { foo => 1 }, empty => {} }, 'initial properties and empty section' for <<'';
foo=1
;
[empty]

is_deeply p, { '' => { foo => 1 }, section => { bar => 1 } }, 'initial properties and section' for <<'';
foo=1
[section]
bar=1

is_deeply p, { empty => {}, section => { qw( foo 1 bar 2 ) } }, 'reopened section' for <<'';
[section]
foo=1
;
[empty]
;
[section]
bar=2

is_deeply p, { '' => { foo => 3 } }, 'last property value wins' for <<'';
foo=1
foo=2
foo=3
;

is_deeply p, { empty => {} }, 'section line whitespace padding' for <<'';
[empty]
  [empty]
[  empty]
  [  empty]
[empty  ]
  [empty  ]
[  empty  ]
  [  empty  ]
[empty]  
  [empty]  
[  empty]  
  [  empty]  
[empty  ]  
  [empty  ]  
[  empty  ]  
  [  empty  ]  

is_deeply p, { '' => { foo => 1 } }, 'property line whitespace padding' for <<'';
foo=1
  foo=1
foo  =1
  foo  =1
foo=  1
  foo=  1
foo  =  1
  foo  =  1
foo=1  
  foo=1  
foo  =1  
  foo  =1  
foo=  1  
  foo=  1  
foo  =  1  
  foo  =  1  

is_deeply p, { 'sec  tion' => {} }, 'whitespace inside section names' for <<'';
[  sec  tion  ]

is_deeply p, { '' => { 'foo  bar' => 'baz  quux' } }, 'whitespace inside property names/values' for <<'';
  foo  bar  =  baz  quux  

is_deeply p, { '' => { qw( [foo bar foo bar] ) } }, 'properties that might look like sections' for <<'';
[foo=bar
foo=bar]

is_deeply p( section0 => '_' ), {}, 'initial section can be renamed' for <<'';

is_deeply p( section0 => '_' ), { _ => { foo => 1 } }, '... with content' for <<'';
foo=1

is_deeply p( section0 => '_' ), { _ => {} }, '... and proper merging' for <<'';
[_]

my @error = (
	'meaningless non-whitespace' => 'foo bar baz quux',
	'nameless property'          => '= foo bar "baz" quux',
	'floating equals sign'       => '=',
	'incomplete section (left)'  => '[ section',
	'incomplete section (right)' => 'section ]',
);

while ( my ( $desc, $cfg ) = splice @error, 0, 2 ) {
	$desc = "syntax error for $desc";
	my ( $p ) = eval { Config::INI::Tiny->new->to_hash( $cfg ) }, my $l = __LINE__;
	if ( defined $p ) { fail $desc; diag 'got: ', explain $p; next }
	$cfg =~ s/"/\\"/g;
	like $@, qr/\ABad INI syntax at line 1: "\Q$cfg\E" at ${\__FILE__} line $l\.?\n\z/, $desc;
}
