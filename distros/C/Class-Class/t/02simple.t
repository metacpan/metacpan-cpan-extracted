# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 31; }

use strict;
use vars qw ($x);

use Test;


# Test 1:
eval {
  package X;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (Class::Class);

  # NB: use "scalar_" instead of "scalar" because of keywork conflict:
  %MEMBERS = (scalar_ => '$', scalarref => '\$',
	      array => '@', arrayref => '\@',
	      hash => '%', hashref => '\%',
	      glob => '*', globref => '\*',
	      code => '&', coderef => '\&',
	      object => 'X::Struct', objectref => '\X::Struct');

  use Class::Struct;

  use Class::Class;


  struct ('X::Struct' =>
	  [scalar_ => '$', scalarref => '*$',
	   array => '@', arrayref => '*@',
	   hash => '%', hashref => '*%',
	   # Use FileHandle since it ships with Perl and has a new:
	   object => 'FileHandle',
	   # BROKEN?  *FileHandle tries to make 'new F'  --bko FIXME
	   # objectref => '*FileHandle',
	  ]);

  1;
};
ok (not $@);

# Test 2, 3:
my $x;
eval { $x = new X; };
ok (not $@);
ok ($x);

# Test 4, 5:
ok (eval { $x->scalar_ (4); }, 4);
ok (eval { ${$x->scalarref (5)}; }, 5);

# Test 6 - 11:
ok (not defined $$x{array}); # first peek
ok (eval { $x->array (1, 7); }, 7);
ok (not defined eval { $x->array (0); });
ok (not defined $$x{arrayref}); # first peek
ok (eval { ${$x->arrayref (1, 10)}; }, 10);
ok (not defined eval { ${$x->arrayref (0)}; });

# Test 12 - 17:
ok (not defined $$x{hash}); # first peek
ok (eval { $x->hash (a => 13); }, 13);
ok (not defined eval { $x->hash ('b'); });
ok (not defined $$x{hashref}); # first peek
ok (eval { ${$x->hashref (a => 16)}; }, 16);
ok (not defined eval { ${$x->hashref ('b')}; });

# Test 18, 19:
use Symbol ( );
*g = *{Symbol::gensym ( )};
ok (eval { $x->glob (*g); }, *g);
ok (eval { *{$x->globref (*g)}; }, *g);

# Test 20 - 27:
ok (not defined $$x{code}); # first peek
eval { $x->code (sub ($@) { return scalar @_; }); };
ok (not $@);
my $r = eval { $x->code (1 .. 22); };
ok (not $@);
ok ($r, 23);
ok (not defined $$x{coderef}); # first peek
eval { $x->coderef (sub ($@) { return scalar @_; }); };
ok (not $@);
$r = eval { $x->coderef->(1 .. 26); };
ok (not $@);
ok ($r, 27);

# Test 28 - 31:
ok (not defined $$x{object}); # first peek
ok (eval { $x->object->scalar_ (29); }, 29);
ok (not defined $$x{objectref}); # first peek
ok (eval { ${$x->objectref}->scalar_ (31); }, 31);


