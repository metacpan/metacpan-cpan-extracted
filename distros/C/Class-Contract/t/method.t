# This script should be runnable with 'make test'.

######################### We start with some black magic to print on failure.

BEGIN { $| = 1 }
END { print "not ok 1\n"  unless $loaded }

use lib qw( ./t );
use Magic;

use Class::Contract;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

::ok('desc'   => 'Simple Contract',
     'expect' => 1,
     'code'   => <<'CODE');
package Simple;
use Class::Contract;
contract {
  method 'my_method'; impl {1};
  abstract method 'my_abstract_method';
  class abstract method 'my_class_abstract_method';
  abstract class method 'my_abstract_class_method';

  attr 'my_attr';
  class attr 'my_class_attr';
};
CODE

::ok('desc'   => 'Extended Contracts',
     'expect' => 1,
     'code'   => <<'CODE');
package Grandfather;
use Class::Contract; 

contract {
  ctor 'new';
    impl { shift if $Class::Contract::VERSION < 1.10; push @::test, [0, @_]; };
  class method 'incr';
    pre  { $::test{'pre'}++;  1 };
    impl { $::test{'impl'}++; 1 };
    post { $::test{'post'}++; 1 };
  eval qq|class method '_$_'; pre {1}; impl {1}| foreach qw(a b c d e f g h i);
  eval qq|class method '_$_'; impl {1}         | foreach qw(j k l m n o p q r);
  eval qq|class method '_$_'; pre {0}; impl {1}| foreach qw(s t u v w x y z 1);
  die $@  if $@;
};

package Father; 
use Class::Contract; 
contract {
  inherits 'Grandfather';
  ctor 'new'; 
    impl { shift if $Class::Contract::VERSION < 1.10; push @::test, [1, @_]; };
  class method 'incr';
    pre  { $::test{'pre'}++;  0 };
    impl { $::test{'impl'}++; 1 };
    post { $::test{'post'}++; 1 };
  eval qq|class method '_$_'; pre {1}; impl {1}| foreach qw(a b c j k l s t u);
  eval qq|class method '_$_'; impl {1}         | foreach qw(d e f m n o v w x);
  eval qq|class method '_$_'; pre {0}; impl {1}| foreach qw(g h i p q r y z 1);
  die $@  if $@;
};

package Son; 
use Class::Contract; 
contract {
  inherits 'Father';
  ctor 'new'; 
    impl { shift if $Class::Contract::VERSION < 1.10; push @::test, [2, @_]; };
  class method 'incr';
    pre  { $::test{'pre'}++;  0 };
    impl { $::test{'impl'}++; 1 };
    post { $::test{'post'}++; 1 };
  eval qq|class method '_$_'; pre {1}; impl {1}| foreach qw(a d g j m p s v y);
  eval qq|class method '_$_'; impl {1}         | foreach qw(b e h k n q t w z);
  eval qq|class method '_$_'; pre {0}; impl {1}| foreach qw(c f i l o r u x 1);
  die $@  if $@;
};

package Args;
use Class::Contract;
contract {
  ctor 'new';
    pre  { $::test{'pre'}  = \@_; 1 };
    impl { $::test{'impl'} = \@_; 1 };
    post { $::test{'post'} = \@_; 1 };
  class method 'same';
    pre  { @{$::test{'same_pre'}}  = (@_); 1 };
    impl { @{$::test{'same_impl'}} = (@_); 1 };
    post { @{$::test{'same_post'}} = (@_); 1 };
  class method 'modify_pre';
    pre  {
      shift  if $Class::Contract::VERSION < 1.10;
      $_[0] = 'pre'; $::test{'pre'} = $_[0]; 1;
    };
    impl { shift if $Class::Contract::VERSION < 1.10; $::test{'impl'}=$_[0]; 1};
    post { shift if $Class::Contract::VERSION < 1.10; $::test{'post'}=$_[0]; 1};
  class method 'modify_impl';
    pre  { shift if $Class::Contract::VERSION < 1.10; $::test{'pre'}=$_[0]; 1};
    impl {
      shift  if $Class::Contract::VERSION < 1.10;
      $_[0] = 'impl'; $::test{'impl'} = $_[0]; 1;
    };
    post {
      shift  if $Class::Contract::VERSION < 1.10;
      $::test{'post'} = $_[0]; 1
    };
  class method 'modify_post';
    pre  {
      shift  if $Class::Contract::VERSION < 1.10;
      $::test{'pre'}=$_[0]; 1
    };
    impl {
      shift  if $Class::Contract::VERSION < 1.10;
      $::test{'impl'}=$_[0]; 1
    };
    post {
      shift  if $Class::Contract::VERSION < 1.10;
      $_[0] = 'post'; $::test{'post'} = $_[0]; 1;
    };
};
CODE


::ok('desc' => "pre gets shallow copy of args to be passed to impl",
     'expect' => 1,
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
undef %::test;
my @args = qw(1 a 2 b 4 c);
Args->same(@args);

my $fail = 0;
foreach (0..$#args) {
  $fail++
    if $::test{'same_pre'}->[$_] ne $::test{'same_impl'}->[$_]
}
$fail ? 0 : 1;
CODE


::ok('desc' => "pre can't modify args passed to method or impl",
     'expect' => 1,
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
%test = ();
my $arg = 'foo';
Args->modify_pre($arg);
join('', $arg, @test{qw(pre impl post)}) eq 'fooprefoofoo';
CODE


::ok('desc' => "impl can modify args passed to method and post",
     'expect' => 1,
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
%test = ();
my $arg = 'foo';
Args->modify_impl($arg);
join('', $arg, @test{qw( pre impl post )}) eq 'implfooimplimpl';
CODE


::ok('desc'    => "post can't modify args passed to method",
     'expect'  => 1,
     'need'    => 'Extended Contracts',
     'code'    => <<'CODE');
package main;
%test = ();
my $arg = 'foo';
Args->modify_post($arg);
join('', $arg, @test{qw( pre impl post )}) eq 'foofoofoopost';
CODE


::ok('desc'   => 'invoking abstract method raises exception',
     'expect' => qr/^Can\'t call abstract method/s,
     'need'   => 'Simple Contract',
     'code'   => <<'CODE');
package main;
Simple->my_class_abstract_method;
CODE


::ok('desc'   => 'missing impl raise an exception',
     'expect' => qr/^No implementation for method foo/s,
     'code'   => <<'CODE');
package UnDeclared_Method;
use Class::Contract;
contract { method 'foo' };
CODE


::ok('desc'   => 'simple implementation based on abstract',
     'expect' => 1,
     'need'   => 'Simple Contract',
     'code'   => <<'CODE');
package Inherited_Class_Method;
use Class::Contract;
contract {
  inherits 'Simple';
  class method 'my_class_abstract_method';
    impl { 1 };
};

package main;
Inherited_Class_Method->my_class_abstract_method,
CODE


::ok('desc'   => "implementation not inherited",
     'expect' => 1,
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
%test = ();
Son->incr;
$test{'impl'};
CODE

::ok('desc'   => 'post-conditions are inherited',
     'expect' => 3,
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
%test = ();
Son->incr;
$test{'post'};
CODE

::ok('desc'   => 'pre check must satisfy self or an ascending ancestor',
     'expect' => '',
     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
package main;
undef $@;
$fail = '';

# No inheritence involvement                                    G 
eval qq|Grandfather->_a|; $fail .= 'a' if $@;               #   1
eval qq|Grandfather->_j|; $fail .= 'j' if $@;               #  null
eval qq|Grandfather->_s|; $fail .= 's' unless $@; undef $@; #   0

# Parent Child inheritence                                  G    F 
eval qq|Father->_a|; $fail .= 'a' if $@;                #   1    1
eval qq|Father->_d|; $fail .= 'd' if $@;                #   1   null
eval qq|Father->_g|; $fail .= 'g' if $@;                #   1    0
eval qq|Father->_j|; $fail .= 'j' if $@;                #  null  1
eval qq|Father->_m|; $fail .= 'm' if $@;                #  null null
eval qq|Father->_p|; $fail .= 'p' unless $@; undef $@;  #  null  0
eval qq|Father->_s|; $fail .= 's' if $@;                #   0    1
eval qq|Father->_v|; $fail .= 'v' unless $@; undef $@;  #   0   null
eval qq|Father->_y|; $fail .= 'y' unless $@; undef $@;  #   0    0

# Grandparent Parent Child inheritence                      G    F    S
eval qq|Son->_a|; $fail .= 'a' if $@;                   #   1    1    1
eval qq|Son->_b|; $fail .= 'b' if $@;                   #   1    1   null
eval qq|Son->_c|; $fail .= 'c' if $@;                   #   1    1    0
eval qq|Son->_d|; $fail .= 'd' if $@;                   #   1   null  1
eval qq|Son->_e|; $fail .= 'e' if $@;                   #   1   null null
eval qq|Son->_f|; $fail .= 'f' if $@;                   #   1   null  0
eval qq|Son->_g|; $fail .= 'g' if $@;                   #   1    0    1
eval qq|Son->_h|; $fail .= 'h' if $@;                   #   1    0   null
eval qq|Son->_i|; $fail .= 'i' if $@;                   #   1    0    0
eval qq|Son->_j|; $fail .= 'j' if $@;                   #  null  1    1
eval qq|Son->_k|; $fail .= 'k' if $@;                   #  null  1   null
eval qq|Son->_l|; $fail .= 'l' if $@;                   #  null  1    0
eval qq|Son->_m|; $fail .= 'm' if $@;                   #  null null  1
eval qq|Son->_n|; $fail .= 'n' if $@;                   #  null null null
eval qq|Son->_o|; $fail .= 'o' unless $@; undef $@;     #  null null  0
eval qq|Son->_p|; $fail .= 'p' if $@;                   #  null  0    1
eval qq|Son->_q|; $fail .= 'q' unless $@; undef $@;     #  null  0   null
eval qq|Son->_r|; $fail .= 'r' unless $@; undef $@;     #  null  0    0
eval qq|Son->_s|; $fail .= 's' if $@;                   #   0    1    1
eval qq|Son->_t|; $fail .= 't' if $@;                   #   0    1   null
eval qq|Son->_u|; $fail .= 'u' if $@;                   #   0    1    0
eval qq|Son->_v|; $fail .= 'v' if $@;                   #   0   null  1
eval qq|Son->_w|; $fail .= 'w' unless $@; undef $@;     #   0   null null
eval qq|Son->_x|; $fail .= 'x' unless $@; undef $@;     #   0   null  0
eval qq|Son->_y|; $fail .= 'y' if $@;                   #   0    0    1
eval qq|Son->_z|; $fail .= 'z' unless $@; undef $@;     #   0    0   null
eval qq|Son->_1|; $fail .= '1' unless $@; undef $@;     #   0    0    0
print "fail: $fail\n"  if $fail;
$fail;
CODE

::ok('desc'   => 'private inheritance stays private',
     'expect' => qr/^Forget 'private'?/s,
     'code'   => <<'CODE');
package Private;
use Class::Contract;
contract {
  private class method 'foo';
    impl {1};
};

package Private::Still;
use Class::Contract;
contract {
  inherits 'Private';
  class method 'foo';
    impl {1};
};

CODE

__DATA__

##ok('desc'   => 'ancestor class method derived as object method',
#     'expect' => 1,
#     'need'   => 'additional thought',
#     'code'   => <<'CODE');
#1
#CODE

# REQ:	Pre and post conditions for methods shall receive the same argument
#       list as the implementation (Pre gets copy, Post identical)

# ?:  Do attribute preconditions get argument list?

# ?:  Are there limits as to where &old, &self, and &value can be called?

# REQ:  Invariant, pre, and post conditions may be declared optional.

# REQ:  Optional condition checking may be switched on or off using the
#       &check method (see examples below).

# REQ:  The implementation's return value shall be available in the
#	method's post condition(s) through the subroutine &value,
#       which returns a reference to a scalar or an array
#	(depending on the calling context).

# REQ:  &value shall also provide access to the value of an attribute within
#	that attribute's pre and post conditions.

# REQ:  The value of the object prior to a method shall be available in the
#	post-conditions via the &old subroutine, which returns a copy
#	of the object as it was prior to the method call.


### Garrett's additions ###

# REQ:  C<method> and C<ctor> shall croak if the naming clashes with the
#       subroutines exported by Class::Contract

# REQ:  It shall not be possible to redefine a Contract

# REQ:  ctor plays nicely with Overload.pm

# REQ:  &value plays nicely with Overload.pm
