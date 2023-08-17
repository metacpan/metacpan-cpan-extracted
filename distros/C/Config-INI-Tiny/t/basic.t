use 5.006; use strict; use warnings;

use Test::More tests => 26;
use Config::INI::Tiny ();

BEGIN { defined &explain or *explain = sub {
	require Data::Dumper;
	map {
		my $dumper = Data::Dumper->new( [$_] )->Indent(1)->Terse(1);
		$dumper->Sortkeys(1) if $dumper->can( 'Sortkeys' );
		$dumper->Dump;
	} @_;
} }

# mess up the pos() as a cheap fuzz test of the parser
sub h { pos = rand length; eval {   Config::INI::Tiny->new(@_)->to_hash($_) } or ( warn, return ) }
sub p { pos = rand length; eval { [ Config::INI::Tiny->new(@_)->parse($_) ] } or ( warn, return ) }

is_deeply h, {}, 'empty string' for '';

is_deeply h, {}, 'whitespace only' for "    \n\t\n";

is_deeply h, {}, 'comments' for <<'';
# this = comment
; so is this

is_deeply h, {}, 'empty comment markers' for <<'';
#
;

is_deeply h, { '' => { qw( foo 1 bar 2 ) } }, 'initial properties' for <<'';
foo=1
bar=2

is_deeply h, { '' => { empty => '' } }, 'property without a value' for <<'';
empty=

is_deeply h, { empty => {} }, 'empty section' for <<'';
[empty]

is_deeply h, { section => { qw( foo 1 bar 2 ) } }, 'section with properties' for <<'';
[section]
foo=1
;
bar=2

is_deeply h, { '' => { foo => 1 }, empty => {} }, 'initial properties and empty section' for <<'';
foo=1
;
[empty]

is_deeply h, { '' => { foo => 1 }, section => { bar => 1 } }, 'initial properties and section' for <<'';
foo=1
[section]
bar=1

is_deeply h, { empty => {}, section => { qw( foo 1 bar 2 ) } }, 'reopened section' for <<'';
[section]
foo=1
;
[empty]
;
[section]
bar=2

is_deeply h, { '' => { foo => 3 } }, 'last property value wins' for <<'';
foo=1
foo=2
foo=3
;

is_deeply h, { empty => {} }, 'section line whitespace padding' for <<'';
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

is_deeply h, { '' => { foo => 1 } }, 'property line whitespace padding' for <<'';
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

is_deeply h, { 'sec  tion' => {} }, 'whitespace inside section names' for <<'';
[  sec  tion  ]

is_deeply h, { '' => { 'foo  bar' => 'baz  quux' } }, 'whitespace inside property names/values' for <<'';
  foo  bar  =  baz  quux  

is_deeply h, { '' => { qw( [foo bar foo bar] ) } }, 'properties that might look like sections' for <<'';
[foo=bar
foo=bar]

is_deeply h( section0 => '_' ), {}, 'initial section can be renamed' for <<'';

is_deeply h( section0 => '_' ), { _ => { foo => 1 } }, '... with content' for <<'';
foo=1

is_deeply h( section0 => '_' ), { _ => {} }, '... and proper merging' for <<'';
[_]

is_deeply p( pairs => 1 ), [ [ '' ], [ section => [ foo => 1 ] ], [ 'empty' ], [ section => [ bar => 2 ] ] ], 'parsing to pairs works as expected' for <<'';
[section]
foo=1
;
[empty]
;
[section]
bar=2

my @error = (
	'meaningless non-whitespace' => 'foo bar baz quux',
	'nameless property'          => '= foo bar "baz" quux',
	'floating equals sign'       => '=',
	'incomplete section (left)'  => '[ section',
	'incomplete section (right)' => 'section ]',
);

while ( my ( $desc, $cfg ) = splice @error, 0, 2 ) {
	$desc = "syntax error for $desc";
	my ( $h ) = eval { Config::INI::Tiny->new->to_hash( $cfg ) }, my $l = __LINE__;
	if ( defined $h ) { fail $desc; diag join ' ', 'got:', explain $h; next }
	$cfg =~ s/"/\\"/g;
	like $@, qr/\ABad INI syntax at line 1: "\Q$cfg\E" at \Q${\__FILE__}\E line $l\.?\n\z/, $desc;
}
