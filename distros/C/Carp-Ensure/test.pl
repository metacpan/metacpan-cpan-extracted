# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###############################################################################

# We start with some black magic to print on failure.

use Test;

BEGIN {
  plan(tests => 220);
  $| = 1;
}

END {
  ok(0)
      unless $loaded;
}

use Carp::Ensure(qw( :DEBUG is_a ));

$loaded = 1;
ok(1);

my $errPfx = "ensure";

###############################################################################

sub ensure2Error($@) {
  eval { &ensure if DEBUG };
# warn($@) if $@;
  return $@;
}

###############################################################################

sub okType($@) {
  ok(!&ensure2Error);
}

###############################################################################

sub noType($@) {
  my $tp = $_[0];
  $tp =~ s/^[\\@]*//;
  ok(&ensure2Error, qr/^$errPfx: Invalid type: `.*' is not of type `\\*\Q$tp\E'/);
}

###############################################################################
# Test checking of parameter types

ok(ensure2Error(undef),
   qr/^$errPfx: Invalid call: Undefined first argument/);
ok(ensure2Error({ }),
   qr/^$errPfx: Invalid call: First argument must be a string or array reference/);

ok(ensure2Error([ ]),
   qr/^$errPfx: Invalid call: Second argument must be an array reference, too/);
ok(ensure2Error([ ], 1, 2),
   qr/^$errPfx: Invalid call: Too many arguments/);
ok(ensure2Error([ \1 ], [ 1 ]),
   qr/^$errPfx: Invalid call: Not a string element at index 0 of first argument/);

ok(ensure2Error('integer,', 1),
   qr/^$errPfx: Invalid description: Unparsable simple type/);

###############################################################################
# Test scalar types

my $string = "Some arbitrary string";
okType('string', $string);
noType('string', \$string);
noType('string', [ ]);

my $word = "Word";
okType('word', $word);
noType('word', $string);

my $empty = "";
okType('empty', $empty);
noType('word', $string);

my $integer = -123;
okType('integer', $integer);
okType('integer', -$integer);
okType('integer', "+" . abs($integer));
noType('integer', " +$integer");
noType('integer', $empty);
noType('integer', $word);

my $float = -123e45;
okType('float', $float);
okType('float', -$float);
okType('float', "+" . abs($float));
okType('float', 1 / $float);
okType('float', $integer);
noType('float', ".");
noType('float', "$float ");
noType('float', $empty);
noType('float', $word);

my $boolean = !undef;
okType('boolean', $boolean);
okType('boolean', $string);
okType('boolean', $empty);
okType('boolean', $float);
okType('boolean', undef);
noType('boolean', [ ]);

okType('regex', $string);
okType('regex', $empty);
okType('regex', '^$');
okType('regex', '()');
okType('regex', '^(a*)$');
noType('regex', undef);
noType('regex', '(');
noType('regex', '*a*');

###############################################################################
# Test simple special types

okType('undefined', undef);
noType('undefined', $empty);
noType('undefined', $string);
noType('undefined', [ ]);

okType('defined', $empty);
okType('defined', $string);
okType('defined', [ ]);
noType('defined', undef);

okType('anything', $empty);
okType('anything', $string);
okType('anything', undef);
okType('anything', [ ]);

###############################################################################
# Test simple reference types

my @array = ( 1, 2, 3 );
okType('ARRAY', [ ]);
okType('ARRAY', [ 1, 2, 3 ]);
okType('ARRAY', \@array);
noType('ARRAY', 1, 2, 3);
noType('ARRAY', { });
noType('ARRAY', undef);
noType('ARRAY', $string);
noType('ARRAY', \$string);

my %hash = ( eins => 1, zwei => 2, drei => 3 );
okType('HASH', { });
okType('HASH', \%hash);
noType('HASH', vier => 4);
noType('HASH', [ ]);
noType('HASH', undef);
noType('HASH', $string);
noType('HASH', \$string);

my $code = sub { return 0; };
okType('CODE', sub { return 1 });
okType('CODE', $code);
noType('CODE', vier => 4);
noType('CODE', { });
noType('CODE', undef);
noType('CODE', $string);
noType('CODE', \$string);

okType('GLOB', *STDIN);
okType('GLOB', *Carp::Ensure);
noType('GLOB', STDIN);
noType('GLOB', \*STDIN);
noType('GLOB', vier => 4);
noType('GLOB', { });
noType('GLOB', undef);
noType('GLOB', $string);
noType('GLOB', \$string);

###############################################################################
# Test user type

package Carp::Ensure;

sub is_a_natural($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && $$r =~/^[1-9]\d*$/;
}

package main;

okType('natural', 7);
okType('natural', -$integer);
noType('natural', $integer);
noType('natural', 0);
noType('natural', $string);
noType('natural', [ ]);

ok(ensure2Error('positive', 1),
   qr/^$errPfx: Invalid description: No user defined test/);

###############################################################################
# Test object type

package Grand;

sub new($ ) {
  my( $proto ) = @_;
  ::okType('^Grand|Grand', $proto);
  my $class = ref($proto) || $proto;
  my $self  = { };
  bless($self, $class);
  return $self;
}

package Parent;

@ISA = qw( Grand );

package Child;

@ISA = qw( Parent );

package main;

my $child = Child->new();
okType('Child', $child);
noType('Child', { });
noType('Child', $integer);
noType('Child', undef);
$child->new();

my $parent = Parent->new();
okType('Parent', $parent);
okType('Parent', $child);

my $grand = Grand->new();
okType('Grand', $grand);
okType('Grand', $parent);
okType('Grand', $child);

okType('UNIVERSAL', $grand);
okType('UNIVERSAL', $parent);
okType('UNIVERSAL', $child);

noType('Child', $parent);
noType('Child', $grand);
noType('Parent', $grand);

###############################################################################
# Test class type

okType('^UNIVERSAL', 'UNIVERSAL');
okType('^UNIVERSAL', 'Grand');
okType('^UNIVERSAL', 'Parent');
okType('^UNIVERSAL', 'Child');
okType('^Grand', 'Grand');
okType('^Grand', 'Parent');
okType('^Grand', 'Child');
okType('^Parent', 'Parent');
okType('^Parent', 'Child');
okType('^Child', 'Child');
okType('^Carp::Ensure', 'Carp::Ensure');

noType('^Child', 'Parent');
noType('^Child', 'Grand');
noType('^Child', 'UNIVERSAL');
noType('^Child', $string);
noType('^Child', $empty);
noType('^Child', $boolean);
noType('^Child', $integer);
noType('^Child', $float);
noType('^Child', undef);

###############################################################################
# Test reference type

ok(ensure2Error('\anything', 1),
   qr/^$errPfx: Invalid type: `.*' is not a reference/);
ok(!ensure2Error('\anything', [ ]));
okType('\integer', \1);
okType('\empty', \$empty);
okType('\undefined', \undef);
okType('\natural', \1);
okType('\HASH', \\%hash);
okType('\ARRAY', \\@array);
okType('\CODE', \$code);
okType('\GLOB', \*STDIN);
ok(ensure2Error('\\\\float', \1.955),
   qr/^$errPfx: Invalid type: `.*' is not a reference/);
okType('\\\\float', \\1.955);
noType('\\\\float', \\\1.955);
okType('\Child', \$child);
noType('\Child', \$parent);

###############################################################################
# Test alternative type

ok(!ensure2Error('integer|undefined', 1));
ok(!ensure2Error('integer|undefined', undef));
ok(ensure2Error('integer|undefined', $empty),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

ok(!ensure2Error('\integer|undefined', \1));
ok(!ensure2Error('\integer|undefined', undef));
ok(ensure2Error('\integer|undefined', 1),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

ok(!ensure2Error('\integer|\undefined', \1));
ok(!ensure2Error('\integer|\undefined', \undef));
ok(ensure2Error('\integer|\undefined', undef),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

ok(!ensure2Error('integer|word|empty|regex', 1));
ok(!ensure2Error('integer|word|empty|regex', "eins"));
ok(!ensure2Error('integer|word|empty|regex', ""));
ok(!ensure2Error('integer|word|empty|regex', ".*"));
ok(ensure2Error('integer|word|empty|regex', "("),
   qr/^$errPfx: Invalid type: `.*' is not one of/);
ok(ensure2Error('integer|word|empty|regex', [ ]),
   qr/^$errPfx: Invalid type: `.*' is not one of/);
ok(ensure2Error('integer|word|empty|regex', "+3.141"),
   qr/^$errPfx: Invalid type: `.*' is not one of/);
ok(ensure2Error('integer|word|empty|regex', undef),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

okType('natural|\word|ARRAY|Child', 1);
okType('natural|\word|ARRAY|Child', \$word);
okType('natural|\word|ARRAY|Child', [ ]);
okType('natural|\word|ARRAY|Child', $child);
ok(ensure2Error('natural|\word|ARRAY|Child', $parent),
   qr/^$errPfx: Invalid type: `.*' is not one of/);
ok(ensure2Error('natural|\word|ARRAY|Child', { }),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

###############################################################################
# Test array type

okType('@natural', 1, 2, 3);
okType('@natural');
noType('@natural', 1, 2, "drei");

okType('@natural|word', 1, 2, "drei");
okType('@natural|word|undefined', 1, 2, "drei", undef, "fuenf", 6);
ok(ensure2Error('@natural|word|undefined', 1, 2, "drei", undef, "fuenf", 6, ""),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

okType('@natural|\word|ARRAY|Child', 1, 2, \$word, [ ], $child);
ok(ensure2Error('@natural|\word|ARRAY|Child', 1, 2, \$word, [ ], $parent),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

###############################################################################
# Test hash type

my %word2Natural = ( one => 1, two => 2, three => 3 );
my %natural2Word = reverse(%word2Natural);
okType('%word=>natural', %word2Natural);
ok(ensure2Error('%word=>natural', %natural2Word),
   qr/^$errPfx: Invalid type: `.*' is not of type /);

okType('%word|natural=>word|natural', %word2Natural);
okType('%word|natural=>word|natural', %natural2Word);
okType('%word=>Grand', eins => $child, zwei => $parent, drei => $grand);

ok(ensure2Error('%word>natural', %word2Natural),
   qr/^$errPfx: Invalid description: Missing \`=>\' in hash type /);

###############################################################################
# Test references to list types

ok(ensure2Error('@natural|@regex', -1),
   qr/^$errPfx: Invalid description: Unparsable simple type /);

okType('\@integer|\@regex', [ "+1", "+2", "+3" ]);
okType('\@integer|\@regex', [ "()", ".", "a" ]);
ok(ensure2Error('\@integer|\@regex', [ "+1", "+2", "()", "." ]),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

ok(ensure2Error('%word=>@natural|regex', eins => "("),
   qr/^$errPfx: Invalid description: Unparsable simple type /);
okType('%word=>\@natural|\@regex', eins => [ 1 ], quant => [ ".?", ".+", ".*" ]);
ok(ensure2Error('%word=>\@natural|\@regex', eins => [ 1, ".?" ], quant => [ "+2", ".+", ".*" ]),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

okType('\@natural|undefined', [ 1, 2, 3 ]);
okType('\@natural|undefined', undef);
ok(ensure2Error('\@natural|undefined', [ 1, undef, 3 ]),
   qr/^$errPfx: Invalid type: `.*' is not one of/);

ok(ensure2Error('\%word|empty=>natural', { eins => 1, "" => 2 }),
   qr/^$errPfx: Invalid description: Missing \`=>\' in hash type /);

###############################################################################
# Test `is_a'

ok(is_a('word', $word));
ok(!is_a('GLOB', \*STDIN));
ok(!is_a('\Child', \$parent));
ok(is_a('\\\\float', \\1.955));
ok(is_a('natural|\word|ARRAY|Child', 1));
ok(!is_a('natural|\word|ARRAY|Child', $parent));

###############################################################################
# Test whitespace

ok(is_a(' word ', $word));
ok(!is_a(' GLOB ' . "\n", \*STDIN));
ok(!is_a('\ ' . "\t" . 'Child', \$parent));
ok(is_a('\ \ float', \\1.955));
ok(is_a('natural | \ word | ARRAY | Child', 1));

###############################################################################
# Test user definitions reducing complexity

sub Carp::Ensure::is_a_word1empty { is_a('word|empty', ${shift()}) }

okType('\word1empty', \$word);
okType('\word1empty', \$empty);
noType('\word1empty', \$string);
noType('\word1empty', \undef);

okType('\@word1empty', [ $word, $empty ]);
noType('\@word1empty', [ $word, $empty, undef ]);

okType('\%word1empty=>natural', { eins => 1, "" => 2 });
ok(ensure2Error('\%word1empty=>natural', { eins => 1, "" => 2, drei => -3 }),
   qr/^$errPfx: Invalid type: `.*' is not of type/);

###############################################################################
# Test argument lists

sub prePost($@) {
  my $tps = shift();
  my @vals = @_;

  my $r = is_a($tps, \@_) ? undef : $@;
  for(my $i = 0; $i < @vals; $i++) {
    return $i
	unless $vals[$i] eq $_[$i];
  }
  return $r;
}

ok(!prePost([ qw( word natural empty ) ], "zehn", 17, ""));
ok(!prePost([ qw( undefined|empty %word=>natural ) ], "", zehn => 10, neun => 9));
ok(!prePost([ qw( undefined|empty @float ) ], undef, -3.2, +2.1, -4.6));
ok(!prePost([ qw( HASH ) ], { zehn => 10, neun => 9 }));
ok(!prePost([ qw( ARRAY ) ], [ zehn => 10, neun => 9 ]));
ok(!prePost([ qw( ^Grand Parent ) ], "Parent", $child));
