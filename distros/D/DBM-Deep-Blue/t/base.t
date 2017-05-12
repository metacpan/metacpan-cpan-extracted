#!perl -w -I../blib -I../blib/arch -I../lib
use feature ':5.12';
use strict;
use warnings all=>'FATAL';

use Test::More;
use Test::Exception;
use Time::HiRes qw(time);
use DBM::Deep::Blue;
my $N = 10;
srand(1);

 {my $comment = << 'END'}
splice
END

#gdb --args c:/strawberry/perl/bin/perl.exe test.pm
#----------------------------------------------------------------------
# Label a test
#----------------------------------------------------------------------

sub p($)
 {my ($l) = @_;
  $l += __LINE__ + 6;
  "Line $l"
 } 


my $T = time();

#----------------------------------------------------------------------
# Arrays
#----------------------------------------------------------------------

# fetch/store

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();  

  $a->[1] = { a => 'foo' };
  is $a->[1]{a},  "foo", 'array/hash autovivify 1 a';

     $a->[1] = "Hello World";
  is $a->[1],  "Hello World", 'array fetch';
                             
     $a->[2][1] = "Hello World";
  is $a->[2][1],  "Hello World", 'array autovivify 21';

  $a->[1] = { a => 'foo' };
  is $a->[1]{a},  "foo", 'array/hash autovivify 1 a';
               
# $m->freeMemoryArea();
 }

# load

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();  

  @$a = qw(0 1 2 3);
  is $a->[0],  0, 'array load fetch 0';
  is $a->[1],  1, 'array load fetch 1';
  is $a->[2],  2, 'array load fetch 2';
  is $a->[3],  3, 'array load fetch 3';

  my $b = $m->allocArray();
  @{$b->[0]} = @$a;
  is $b->[0][1], 1, 'array copy';

  my $c = $m->allocArray();
  $c->[0] = $a;
  is $c->[0][2], 2, 'array reference';  
 }

# for each

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  push @$a, ("$_"x$_) for 1..$N;

  my $s = ''; $s .= "$_ " for @$a;

  is $s, '1 22 333 4444 55555 666666 7777777 88888888 999999999 10101010101010101010 ', 'for each array';
 }

# multi push

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
  my $n = push @$a, 0..$N;

  my @a;
  my $o = push @a,  0..$N;
  is $n, $o, "multi push count";
  for(0..$N)
   {is $a->[$_], $a[$_], "Multi push $_";
   }
 } 

# multi unshift

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
  my $n = unshift @$a, 0..$N*2;
  my @a;
  my $o = unshift @a,  0..$N*2; 
  is $n, $o, "multi unshift count";
  for(0..$N*2)
   {is $a->[$_], $a[$_], "Multi unshift $_";
   }
 } 

# push/shift

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  for(1..$N)
   {push @$a, $_;
    is  $a->[0],    1,  "push/shift array element 1";
    is  $a->[$#$a], $_, "push/shift array element $_";
    is @$a,         $_, "push/shift array size $_";
   } 
  for(1..$N)
   {my $e = shift @$a;
    is $e, $_, "push/shift $_";
   }

  @$a = ();  
 }

# push/pop

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  for(1..$N)
   {push @$a, $_;
    is  $a->[0],    1,  "push/pop array element 1";
    is  $a->[$#$a], $_, "push/pop array element $_";
    is @$a,         $_, "push/pop array size $_";
   } 
  for(reverse 1..$N)
   {my $e = pop @$a;
    is $e, $_, "push/pop $_";
   }

  @$a = ();  
 }

# unshift/shift

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  for(1..$N)
   {unshift @$a, $_;
    is  $a->[0],    $_, "unshift/shift array element $_";
    is  $a->[$#$a], 1,  "unshift/shift array element 1";
    is @$a,         $_, "unshift/shift array size $_";
   } 
  for(reverse 1..$N)
   {my $e = shift @$a;
    is $e, $_, "unshift/shift $_";
   }

  @$a = ();  
 }

# unshift/pop

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  for(1..$N)
   {unshift @$a, $_;
    is  $a->[0],    $_, "unshift/pop array element $_";
    is  $a->[$#$a], 1,  "unshift/pop array element 1";
    is @$a,         $_, "unshift/pop array size $_";
   } 
  for(1..$N)
   {my $e = pop @$a;
    is $e, $_, "unshift/pop $_";
   }

  @$a = ();  
 }

# Large values

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  for(1..$N)
   {push @$a, 'a'x (2**$_);
   } 
  for(1..$N)
   {my $e = shift @$a;
    is $e, 'a'x (2**$_), "long value  $_";
   }

  @$a = ();  
 }

# Global Array

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocGlobalArray();

     $a->[0] = 'hello';
  is $a->[0],  'hello', "Global Array";

     $a->[1]{a}[2]{b} = 'hello';
  is $a->[1]{a}[2]{b},  'hello', "Global Array";
 }

#----------------------------------------------------------------------
# hashes
#----------------------------------------------------------------------

# fetch/store

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();  

     $h->{hello} = "Hello World";
  is $h->{hello},  "Hello World", 'hash fetch';
                             
     $h->{a}{b} = "Hello World";
  is $h->{a}{b},  "Hello World", 'hash autovivify a b';
                             
     $h->{c}[1]{d}[2] = "Hello World";
  is $h->{c}[1]{d}[2],  "Hello World", 'hash autovivify c 1 d 2';
 }

# load

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();  

  %$h = qw(a 1 b 2 c 3);
  is $h->{a},  1, 'hash load fetch a 1';
  is $h->{b},  2, 'hash load fetch b 2';
  is $h->{c},  3, 'hash load fetch c 3';
 }

# for each

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();

  $h->{$_} = $_ x 2 for $N..$N*2;

  my $s = ''; $s .= $_. "=". $h->{$_}.' ' for sort keys %$h;

  is keys(%$h), 11, 'Scalar keys hash';
  is $s, '10=1010 11=1111 12=1212 13=1313 14=1414 15=1515 16=1616 17=1717 18=1818 19=1919 20=2020 ', 'for each hash';

# Exists/Delete/Clear

  ok !exists ($h->{zz}), "Not exists non existent key"; 
  ok !delete ($h->{zz}), "Not delete non existent key"; 
  ok !exists ($h->{zz}), "Not exists non existent key after delete of non existent key";
  ok !defined($h->{zz}), "Not defined non existent key";

  $h->{zz} = 1;
  ok defined($h->{zz}),  "Defined value for previously non existent key";
  $h->{zz} = undef();

  ok  exists ($h->{zz}), "Exists undefined key"; 
  ok !defined($h->{zz}), "Not defined undefined key";
  ok !delete ($h->{zz}), "Not delete undefined key"; 
  ok !exists ($h->{zz}), "Not exist after delete of undefined key";
  ok !defined($h->{zz}), "Not defined deleted key";

  %$h = ();
  is %$h, 0, 'Clear Hash';
 }

# Long keys

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();

  my $k = "a" x 10_000;

     $h->{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k} = 'Hello';
  is $h->{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k}{$k},  'Hello', "Long keys";
 }

# Global Hash

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocGlobalHash();

     $h->{a} = 'hello';
  is $h->{a},  'hello', "Global Hash";
# For the moment the global object is not changeable
# my $H = $m->allocGlobalHash();
#    $H->{z} = $h;
# is $H->{z}{a},  'hello', "Global Hash replaced with another hash";

# my $A = $m->allocGlobalArray();
#    $A->[1] = $H;
# is $A->[1]{z}{a},  'hello', "Global Hash replaced with array";
 }

#----------------------------------------------------------------------
# Tests - arrays - compare with Perl
#----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::new();
   {my $A = $m->allocArray();

    my @a;
    @a      = ();
    ok @a   ~~ [], 'Empty array';
    ok @a   == 0,  'Empty array scalar 0';
    ok $#a  == -1, 'Empty array size  -1'; 

       @$a  =  ();
    ok @a  ~~ @$a, 'Empty array';
    ok @a  == @$a,  'Empty array scalar 0';
    ok $#a == $#$a, 'Empty array size - 1';
 
    @a = qw(abc def ghi abcd);
    ok @a   ~~ [qw(abc def ghi abcd)];
    ok @a   == 4,  'Array scalar 4';
    ok $#a  == 3, 'Array size 3';

    @$a     =  qw(abc def ghi abcd);
    ok @a  ~~ @$a, 'Dump array 1';
    ok @a  == @$a, 'Scalar Array';
    ok $#a == $#$a, 'Size array';

    $a[1] = 'xyz'; $a->[1] = 'xyz';
    ok @a ~~ @$a, 'Array Update';
    is $a[0], $a->[0], 'A[0]'; 
    is $a[1], $a->[1], 'A[1]'; 
    is $a[2], $a->[2], 'A[2]'; 
    is $a[3], $a->[3], 'A[3]'; 

    ok scalar(@$a) == scalar(@a), 'Scalar 4';

# STORESIZE

    $#a =    7; $#$a =    7; is scalar(@a), scalar(@$a), 'Storesize 1';
    ok @a ~~ @$a, 'Size 1';
    $#a =    2; $#$a =    2; is scalar(@a), scalar(@$a), 'Storesize 2';
    ok @a ~~ @$a, 'Size 2';
    $#a = 1002; $#$a = 1002; is scalar(@a), scalar(@$a), 'Storesize 3';
    ok @a ~~ @$a, 'Size 3';
    $#a =    0; $#$a =    0; is scalar(@a), scalar(@$a), 'Storesize 4';
    ok @a ~~ @$a, 'Size 4';
    $#a =   -1; $#$a =   -1; is scalar(@a), scalar(@$a), 'Storesize 5';
    ok @a ~~ @$a, 'Size 5';
   }
 }

# ClEAR

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
 
  my @a  = qw(abc def ghi abcd);
     @$a = qw(abc def ghi abcd);

  @a = (); @$a = ();
  ok @a ~~ @$a, 'Clear Array';
 } 

# Push/Pop/Shift/Unshift

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
  my @a = @$a = 1..$N;

# Push

  for(1..$N)
   {push @a,  ('x' x $_);
    push @$a, ('x' x $_);
    ok  @a ~~ @$a,               "Push $_ arrays match";
    is  scalar(@a), scalar(@$a), "Push $_ array sizes match";
   } 

# Unshift

  for(1..$N)
   {unshift @a,  ('y' x $_);
    unshift @$a, ('y' x $_);
    ok  @a ~~ @$a,               "Unshift $_ arrays match";
    is  scalar(@a), scalar(@$a), "Unshift $_ array sizes match";
   } 

# Shift/Pop

  for(1..@$a)
   {shift @a; shift @$a;
    ok  @a ~~ @$a,               "Shift $_ arrays match";
    is  scalar(@a), scalar(@$a), "Shift $_ array sizes match";
    pop   @a; pop   @$a;
    ok  @a ~~ @$a,               "Pop $_ arrays match";
    is  scalar(@a), scalar(@$a), "Pop $_ array sizes match";
   } 

# Splice

# createArray($m, my @B);
#        push @B, 2,1,2;
# my @b; push @b, 2,1,2;
# ok @b ~~ @B, 'Create Array';

# ok @A ~~ @a, 'Splice Start';
# splice @a, 2, 1, @b;
# splice @A, 2, 1, @B;
# ok @A ~~ @a, 'Splice End';

 }

# Reverse of array with undef element in middle

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  my @a = @$a = qw(1 2 3 4);
  $a->[2] = $a[2] = undef;

  ok @a ~~ @$a, 'Reverse start';

  @a  = reverse @a;
  @$a = reverse @$a;

  ok @a ~~ @$a, 'Reverse end';
 }

# Auto vivify

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
     $a->[1][2]          =  3;
  ok $a->[1][2]          == 3, 'autovivify array 1';
     $a->[1][3][4]       =  5;
  ok $a->[1][3][4]       == 5, 'autovivify array 2';
     $a->[1][4][5][6]    =  7;
  ok $a->[1][4][5][6]    == 7, 'autovivify array 3';
     $a->[1][5][6][7][8] =  9;
  ok $a->[1][5][6][7][8] == 9, 'autovivify array 4';
 }

# Iterate an array

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  my @a = @$a = qw(a 1 b 2 c 3 d 4a 1 b 2 c 3 d 4a 1 b 2 c 3 d 4a 1 b 2 c 3 d 4a 1 b 2 c 3 d 4a 1 b 2 c 3 d 4);
  my $A = ''; $A .= " $_ ". $a->[$_] for 0..$#$a;
  my $B = ''; $B .= " $_ ". $a  [$_] for 0..$#a;

  is $B, $A, 'Iterate array';
 }

# Write a script of randomly generated actions, the script can be dumped and debugged separately if necessary

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
  my @a;

  my $S = '';
  for my $l(1..$N*$N)
   {my $action = int rand 20;
    my $s = '';

    given($action)
     {when([0..4]) {$s .= << 'END'}
{my $s = ('a' x XXXX)."XXXX"; push @a, $s; push @$a, $s}
END
      when(5)      {$s .= << 'END'} 
{my $s = ('b' x XXXX)."XXXX"; unshift @a, $s; unshift @$a, $s}
END
      when([6..7]) {$s .= << 'END'}
{pop   @a; pop @$a}
END
      when([8..9]) {$s .= << 'END'}
{shift @a; shift @$a}
END
      when(10)     {$s .= << 'END'}
 {$a  [XXXX % @a]  = undef if @a;
  $a->[XXXX % @$a] = undef if @$a;
 }
END
      when(11)     {$s .= << 'END'}
 {$a  [1 + @a]  = 'xx' if @a;
  $a->[1 + @$a] = 'xx' if @$a;
 }
END
      when(12)     {$s .= << 'END'}
{@a  = reverse @a;
 @$a = reverse @$a;
}
END
     }

    $s .= << 'END';
cmp_ok  @a, '~~', @$a, "Array XXXX";
END

    $s =~ s/XXXX/$l/g;
    $S .= "$s\n";
   }

  eval $S; die $@ if $@;
 }


#----------------------------------------------------------------------
# Tests - hash
#----------------------------------------------------------------------

# Create

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();
  my %h;

  %$h = %h = (a=>1, c=>3, b=>2);

  is $h{a}, $h->{a}, "Hash a1";
  is $h{b}, $h->{b}, "Hash b2";
  is $h{c}, $h->{c}, "Hash c3";

# Store/Fetch

  my @v = qw(d 4 e 5 f 6 g 7 h 8 i 9 j 10 hjg 1 fhbfLI GFHB 34  BHKDFBD rt BDFB bhdgf 45  a gdfg hfeh 12 h32 hj 3k 3r5jk34rjn kew kjwke eknj efkj kj fjkj jeekjekj jkejekje jekjrkwth gfsdfjbn); 
  my %v = @v;

  for(keys %v)
   {$h->{$_} = $h{$_} = $v{$_};
   }

  my $a = ''; $a .= "$_ ". $h  {$_}. ' ' for sort keys %h;
  my $b = ''; $b .= "$_ ". $h->{$_}. ' ' for sort keys %$h;

  is $a, $b,    "Hashes iterate";
  ok %h ~~ %$h, "Hashes match after iterate";

# Exists/Delete

  for(@v)
   {ok %h ~~ %$h, "Hashes match";
    ok exists($h{$_}) == exists($h->{$_}), "Exists or not $_ 1";
    if (rand(2) > 1)
     {is ((delete $h{$_}), (delete $h->{$_}), "Delete $_");
     }
    ok exists($h{$_}) == exists($h->{$_}), "Exists or not $_ 2";
   }

# Clear

  %$h = %h = ();
  ok %h ~~ %$h, "Hashes match after clear";
 }


# Auto vivify

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();

     $h->{1}{2}          = 3;
  is $h->{1}{2},           3, 'autovivify hash 1';
     $h->{1}{3}{4}       = 5;
  is $h->{1}{3}{4},        5, 'autovivify hash 2';

     $h->{1}{4}{5}{6}    = 7;
  is $h->{1}{4}{5}{6},     7, 'autovivify hash 3';
     $h->{1}{5}{6}{7}{8} = 9;
  is $h->{1}{5}{6}{7}{8},  9, 'autovivify hash 4';
 }

# Random

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();
  my %h;

  for my $l(1..$N*$N)
   {my $action = int rand 6;

    my $k = ('k' x $l).$l;
    my $v = ('v' x $l).$l;

    given($action)
     {when([1..2]) {$h{$k} = $v; $h->{$k} = $v}
      when(3)      {my @k = keys(%h); my $k = shift @k; if ($k) {delete $h{$k};         delete $h->{$k}}}
      when(4)      {my @k = keys(%h); my $k = shift @k; if ($k) {       $h{$k} = undef;        $h->{$k} = undef}}
     }

    ok (%h ~~ %$h,  "Hash $l") or last;
   }
 }

# Auto vivify Hash/Array chain - very long

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();
  my %h;

       $h{1}[2][3]{4}[5][6]{7}[8]{9}{10}[11]{12}{13}{14}{15}[16][17][18][19]{20}[21][22][23][24][25]{26}{27}{28}{29}[30]{31}[32][33][34][35][36][37]{38}{39}[40]{41}{42}{43}{44}{45}{46}{47}[48]{49}[50][51]{52}[53]{54}[55]{56}[57][58][59][60]{61}{62}{63}{64}[65][66]{67}[68]{69}{70}{71}{72}[73][74][75]{76}[77][78]{79}{80}[81][82]{83}[84]{85}{86}[87]{88}{89}[90][91]{92}{93}[94]{95}[96][97][98]{99}[100]
 =    $h->{1}[2][3]{4}[5][6]{7}[8]{9}{10}[11]{12}{13}{14}{15}[16][17][18][19]{20}[21][22][23][24][25]{26}{27}{28}{29}[30]{31}[32][33][34][35][36][37]{38}{39}[40]{41}{42}{43}{44}{45}{46}{47}[48]{49}[50][51]{52}[53]{54}[55]{56}[57][58][59][60]{61}{62}{63}{64}[65][66]{67}[68]{69}{70}{71}{72}[73][74][75]{76}[77][78]{79}{80}[81][82]{83}[84]{85}{86}[87]{88}{89}[90][91]{92}{93}[94]{95}[96][97][98]{99}[100]
 =  'A1B2';

 is    $h{1}[2][3]{4}[5][6]{7}[8]{9}{10}[11]{12}{13}{14}{15}[16][17][18][19]{20}[21][22][23][24][25]{26}{27}{28}{29}[30]{31}[32][33][34][35][36][37]{38}{39}[40]{41}{42}{43}{44}{45}{46}{47}[48]{49}[50][51]{52}[53]{54}[55]{56}[57][58][59][60]{61}{62}{63}{64}[65][66]{67}[68]{69}{70}{71}{72}[73][74][75]{76}[77][78]{79}{80}[81][82]{83}[84]{85}{86}[87]{88}{89}[90][91]{92}{93}[94]{95}[96][97][98]{99}[100],
     $h->{1}[2][3]{4}[5][6]{7}[8]{9}{10}[11]{12}{13}{14}{15}[16][17][18][19]{20}[21][22][23][24][25]{26}{27}{28}{29}[30]{31}[32][33][34][35][36][37]{38}{39}[40]{41}{42}{43}{44}{45}{46}{47}[48]{49}[50][51]{52}[53]{54}[55]{56}[57][58][59][60]{61}{62}{63}{64}[65][66]{67}[68]{69}{70}{71}{72}[73][74][75]{76}[77][78]{79}{80}[81][82]{83}[84]{85}{86}[87]{88}{89}[90][91]{92}{93}[94]{95}[96][97][98]{99}[100],
  'autovivify hash array very long';
 }

# Weird hash keys

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();
  my %h;

  $h->{''} = $h{''} = 1; ok %h ~~ %$h, 'Hash empty string';
  $h->{ 0} = $h{ 0} = 1; ok %h ~~ %$h, 'Hash zero  string';
 }

#######################################################################
# Tests - plagiarized from DBM:Deep
#######################################################################

#----------------------------------------------------------------------
# 01_basic.t
#----------------------------------------------------------------------

# {my $f = 'memory/test.data'; unlink $f;
#  my $db = new($f);
#  $db->{foo} = 'bar';
#  is( $db->{foo}, 'bar', 'We can write and read.' );
# }

#----------------------------------------------------------------------
# 02_hash.t
#----------------------------------------------------------------------

 {my $comment = <<'END'};

DBM::Deep::Blue does not provide utility functions as all operations can be
done via the standard Perl hash/array syntax: tests that do not need to be run
are marked as #U.  Where it is necessary to duplicate an action to maintain the
test integrity, the code has been marked #M.

Weaknesses in Deep are marked as #W
-----------------------------------

reftype instead of ref: ref is the standard perl function and is used by
Blue, but Deep uses reftype().

Failure messsages do not correspond to those produced by Perl in an
analagous situation. Marked with #F

Errors found in Deep's tests are marked as #E:
----------------------------------------------

The Exists Error is documented by the execution of the following code.

#!perl -w
use feature ':5.12';
use Test::More;
use strict;

my $h;

ok !exists $h->{a};
is         $h->{a}, undef();
ok !exists $h->{a};
           $h->{a} = undef();
ok  exists $h->{a};

# From DBM::Deep 02_hash.t

my $db;
    ok( !exists $db->{key4}, "exists() function works for keys that aren't there" );
    is( $db->{key4}, undef, "Autovivified key4" );
    ok( exists $db->{key4}, "Autovivified key4 now exists" ) or diag "DBM::Deep thinks this should succeed";

# From DBM::Deep 03_bighash.t

my $foo;
  ok( !exists $foo->{does_not_exist}, "EXISTS works on large hashes for non-existent keys" );
  is( $foo->{does_not_exist}, undef, "autovivification works on large hashes" );
  ok( exists $foo->{does_not_exist}, "EXISTS works on large hashes for newly-existent keys" )  or diag "DBM::Deep thinks this should succeed";;

done_testing;

END


   {my $m = DBM::Deep::Blue::new();
    my $db = $m->allocHash();

    ##
    # put/get key
    ##
    $db->{key1} = "value1";
#U  is( $db->get("key1"), "value1", "get() works with hash assignment" );
#U  is( $db->fetch("key1"), "value1", "... fetch() works with hash assignment" );
    is( $db->{key1}, "value1", "... and hash-access also works" );

#M  $db->put("key2", undef);
    $db->{key2} = undef;
#U  is( $db->get("key2"), undef, "get() works with put()" );
#U  is( $db->fetch("key2"), undef, "... fetch() works with put()" );
    is( $db->{key2}, undef, "... and hash-access also works" );

#M  $db->store( "0", "value3" );
    $db->{0} = "value3";
#U  is( $db->get("0"), "value3", "get() works with store()" );
#U  is( $db->fetch("0"), "value3", "... fetch() works with put()" );
    is( $db->{0}, 'value3', "... and hash-access also works" );

    # Verify that the keyval pairs are still correct.
    is( $db->{key1}, "value1", "Key1 is still correct" );
    is( $db->{key2}, undef, "Key2 is still correct" );
    is( $db->{0}, 'value3', "Key3 is still correct" );

#U  ok( $db->exists("key1"), "exists() function works" );
    ok( exists $db->{key2}, "exists() works against undefined values" );

    ok( !exists $db->{key4}, "exists() function works for keys that aren't there" );
    is( $db->{key4}, undef, "Autovivified key4" );
#E  ok( exists $db->{key4}, "Autovivified key4 now exists" );

    delete $db->{key4};
    ok( !exists $db->{key4}, "And key4 doesn't exists anymore" );

    # Keys will be done via an iterator that keeps a breadcrumb trail of the last
    # key it provided. There will also be an "edit revision number" on the
    # reference so that resetting the iterator can be done.
    #
    # Q: How do we make sure that the iterator is unique? Is it supposed to be?

    ##
    # count keys
    ##
    is( scalar keys %$db, 3, "keys() works against tied hash" );

    ##
    # step through keys
    ##
    my $temphash = {};
    while ( my ($key, $value) = each %$db ) {
        $temphash->{$key} = $value;
    }

    is( $temphash->{key1}, 'value1', "First key copied successfully using tied interface" );
    is( $temphash->{key2}, undef, "Second key copied successfully" );
    is( $temphash->{0}, 'value3', "Third key copied successfully" );

#U  $temphash = {};
#U  my $key = $db->first_key();
#U  while (defined $key) {
#U      $temphash->{$key} = $db->get($key);
#U      $key = $db->next_key($key);
#U  }


    is( $temphash->{key1}, 'value1', "First key copied successfully using OO interface" );
    is( $temphash->{key2}, undef, "Second key copied successfully" );
    is( $temphash->{0}, 'value3', "Third key copied successfully" );

    ##
    # delete keys
    ##
    is( delete $db->{key2}, undef, "delete through tied inteface works" );
#M  is( $db->delete("key1"), 'value1', "delete through OO inteface works" );
    is( delete $db->{"key1"}, 'value1', "delete through OO inteface works" );
    is( $db->{0}, 'value3', "The other key is still there" );
    ok( !exists $db->{key1}, "key1 doesn't exist" );
    ok( !exists $db->{key2}, "key2 doesn't exist" );

    is( scalar keys %$db, 1, "After deleting two keys, 1 remains" );

    ##
    # delete all keys
    ##
#U  ok( $db->clear(), "clear() returns true" );
    %$db = ();

    is( scalar keys %$db, 0, "After clear(), everything is removed" );

    ##
    # replace key
    ##
#M  $db->put("key1", "value1");
    $db->{"key1"}="value1";
#M  is( $db->get("key1"), "value1", "Assignment still works" );
    is( $db->{"key1"}, "value1", "Assignment still works" );

#M  $db->put("key1", "value2");
    $db->{"key1"} = "value2";
#M  is( $db->get("key1"), "value2", "... and replacement works" );
    is( $db->{"key1"}, "value2", "... and replacement works" );

#M  $db->put("key1", "value222222222222222222222222");
#M  is( $db->get("key1"), "value222222222222222222222222", "We set a value before closing the file" );
    $db->{key1}= "value222222222222222222222222";
    is( $db->{key1}, "value222222222222222222222222", "We set a value before closing the file" );

    ##
    # Make sure DB still works after closing / opening
    ##
#   undef $db;
#M  $db = $dbm_maker->();
#   $db = new($f);
#M  is( $db->get("key1"), "value222222222222222222222222", "The value we set is still there after closure" );
#   is( $db->{key1}, "value222222222222222222222222", "The value we set is still there after closure" );

    ##
    # Make sure keys are still fetchable after replacing values
    # with smaller ones (bug found by John Cardenas, DBM::Deep 0.93)
    ##
#M  $db->clear();
    %$db = ();
#M  $db->put("key1", "long value here");
#M  $db->put("key2", "longer value here");
    $db->{key1} = "long value here";
    $db->{key2}  = "longer value here";

    $db->{key1} = "short value";
    $db->{key2} = "shorter v";

#   my $first_key = $db->first_key();
#   my $next_key = $db->next_key($first_key);
    my $first_key = each %$db;
    my $next_key = each %$db;

    ok(
        (($first_key eq "key1") || ($first_key eq "key2")) && 
        (($next_key eq "key1") || ($next_key eq "key2")) && 
        ($first_key ne $next_key)
        ,"keys() still works if you replace long values with shorter ones"
    );

    # Test autovivification
    $db->{unknown}{bar} = 1;
    ok( $db->{unknown}, 'Autovivified hash exists' );
#W  is( reftype($db->{unknown}), 'HASH', "... and it's a HASH" );
    is( ref    ($db->{unknown}), 'HASH', "... and it's a HASH" );
    cmp_ok( $db->{unknown}{bar}, '==', 1, 'And the value stored is there' );

    # Test failures
#F  throws_ok {
#F      $db->fetch();
#F  } qr/Cannot use an undefined hash key/, "FETCH fails on an undefined key";
#F
#F  throws_ok {
#F      $db->fetch(undef);
#F  } qr/Cannot use an undefined hash key/, "FETCH fails on an undefined key";

#F  throws_ok {
#F      $db->store();
#F  } qr/Cannot use an undefined hash key/, "STORE fails on an undefined key";

#F  throws_ok {
#F      $db->store(undef, undef);
#F  } qr/Cannot use an undefined hash key/, "STORE fails on an undefined key";

#F  throws_ok {
#F      $db->delete();
#F  } qr/Cannot use an undefined hash key/, "DELETE fails on an undefined key";

#F  throws_ok {
#F      $db->delete(undef);
#F  } qr/Cannot use an undefined hash key/, "DELETE fails on an undefined key";

#F  throws_ok {
#F      $db->exists();
#F  } qr/Cannot use an undefined hash key/, "EXISTS fails on an undefined key";

#F  throws_ok {
#F      $db->exists(undef);
#F  } qr/Cannot use an undefined hash key/, "EXISTS fails on an undefined key";



    # RT# 50541 (reported by Peter Scott)
    # clear() leaves one key unless there's only one

    {%$db = ();
     
        $db->{block} = { };
        $db->{critical} = { };
        $db->{minor} = { };

        cmp_ok( scalar(keys( %$db )), '==', 3, "Have 3 keys" );

#M      $db->clear;
        %$db = ();

        cmp_ok( scalar(keys( %$db )), '==', 0, "clear clears everything" );
    }

  }

#----------------------------------------------------------------------
# 03_bighash.t
#----------------------------------------------------------------------

 {my $comment = <<'END'};

Again the question of exists

END

  {my $m = DBM::Deep::Blue::new();
   my $db = $m->allocHash();

   $db->{foo} = {};
   my $foo = $db->{foo};

   ##
   # put/get many keys
   ##
   my $max_keys = 4000;

   for ( 0 .. $max_keys ) {
#M     $foo->put( "hello $_" => "there " . $_ * 2 );
       $foo->{"hello $_"} = "there " . $_ * 2;
    }

   my $count = -1;
   for ( 0 .. $max_keys ) {
       $count = $_;
       unless ( $foo->{"hello $_"} eq "there " . $_ * 2 ) {
           last;
       };
   }
   is( $count, $max_keys, "We read $count keys" );

   my @keys = sort keys %$foo;
   cmp_ok( scalar(@keys), '==', $max_keys + 1, "Number of keys is correct" );
   my @control =  sort map { "hello $_" } 0 .. $max_keys;
#M cmp_deeply( \@keys, \@control, "Correct keys are there" );
    is_deeply( \@keys, \@control, "Correct keys are there" );

   ok( !exists $foo->{does_not_exist}, "EXISTS works on large hashes for non-existent keys" );
   is( $foo->{does_not_exist}, undef, "autovivification works on large hashes" );
#W ok( exists $foo->{does_not_exist}, "EXISTS works on large hashes for newly-existent keys" );
#W cmp_ok( scalar(keys %$foo), '==', $max_keys + 2, "Number of keys after autovivify is correct" );

#M  $db->clear;
   %$db = ();
   cmp_ok( scalar(keys %$db), '==', 0, "Number of keys after clear() is correct" );
 }

#----------------------------------------------------------------------
# 04_array.t
#----------------------------------------------------------------------

 {my $comment = <<'END'};

delete() and exists() deprecated on Arrays see: perlfunc. Marked with
#D.

@db = () returns value 0. marked with #X

Failure messsages do not correspond to those produced by Perl in an
analagous situation. Marked with #F

END

   {my $m = DBM::Deep::Blue::new();
    my $db = $m->allocArray();

    ##
    # basic put/get/push
    ##
    $db->[0] = "elem1";
#M  $db->push( "elem2" );
    push @$db,  "elem2";
#M  $db->put(2, "elem3");
    $db->[2]  = "elem3";
#M  $db->store(3, "elem4");
    $db->[3] =    "elem4";
#M  $db->unshift("elem0");
    unshift @$db, "elem0";

    is( $db->[0], 'elem0', "Array get for shift works" );
    is( $db->[1], 'elem1', "Array get for array set works" );
    is( $db->[2], 'elem2', "Array get for push() works" );
    is( $db->[3], 'elem3', "Array get for put() works" );
    is( $db->[4], 'elem4', "Array get for store() works" );

#U  is( $db->get(0), 'elem0', "get() for shift() works" );
#U  is( $db->get(1), 'elem1', "get() for array set works" );
#U  is( $db->get(2), 'elem2', "get() for push() works" );
#U  is( $db->get(3), 'elem3', "get() for put() works" );
#U  is( $db->get(4), 'elem4', "get() for store() works" );

#U  is( $db->fetch(0), 'elem0', "fetch() for shift() works" );
#U  is( $db->fetch(1), 'elem1', "fetch() for array set works" );
#U  is( $db->fetch(2), 'elem2', "fetch() for push() works" );
#U  is( $db->fetch(3), 'elem3', "fetch() for put() works" );
#U  is( $db->fetch(4), 'elem4', "fetch() for store() works" );

#M  is( $db->length, 5, "... and we have five elements" );
    is( scalar(@$db),5, "... and we have five elements" );

    is( $db->[-1], $db->[4], "-1st index is 4th index" );
    is( $db->[-2], $db->[3], "-2nd index is 3rd index" );
    is( $db->[-3], $db->[2], "-3rd index is 2nd index" );
    is( $db->[-4], $db->[1], "-4th index is 1st index" );
    is( $db->[-5], $db->[0], "-5th index is 0th index" );

    # This is for Perls older than 5.8.0 because of is()'s prototype
    { my $v = $db->[-6]; is( $v, undef, "-6th index is undef" ); }

#M  is( $db->length, 5, "... and we have five elements after abortive -6 index lookup" );
    is( scalar(@$db),5, "... and we have five elements after abortive -6 index lookup" );

    $db->[-1] = 'elem4.1';
    is( $db->[-1], 'elem4.1' );
    is( $db->[4], 'elem4.1' );
#U  is( $db->get(4), 'elem4.1' );
#U  is( $db->fetch(4), 'elem4.1' );

    throws_ok {
        $db->[-6] = 'whoops!';
    } qr/Modification of non-creatable array value attempted, subscript -6/, "Correct error thrown";

#M  my $popped = $db->pop;
    my $popped = pop @$db;
#M  is( $db->length, 4, "... and we have four after popping" );
    is( scalar(@$db),4, "... and we have four after popping" );
    is( $db->[0], 'elem0', "0th element still there after popping" );
    is( $db->[1], 'elem1', "1st element still there after popping" );
    is( $db->[2], 'elem2', "2nd element still there after popping" );
    is( $db->[3], 'elem3', "3rd element still there after popping" );
    is( $popped, 'elem4.1', "Popped value is correct" );

#M  my $shifted = $db->shift;
    my $shifted = shift @$db;
#M  is( $db->length, 3, "... and we have three after shifting" );
    is( scalar(@$db),3, "... and we have three after shifting" );
    is( $db->[0], 'elem1', "0th element still there after shifting" );
    is( $db->[1], 'elem2', "1st element still there after shifting" );
    is( $db->[2], 'elem3', "2nd element still there after shifting" );
    is( $db->[3], undef, "There is no third element now" );
    is( $shifted, 'elem0', "Shifted value is correct" );

    ##
    # delete
    ##
#M  my $deleted = $db->delete(0);
    my $deleted = $db->[0]; $db->[0] = undef;
#M  is( $db->length, 3, "... and we still have three after deleting" );
    is( scalar(@$db),3, "... and we still have three after deleting" );
    is( $db->[0], undef, "0th element now undef" );
    is( $db->[1], 'elem2', "1st element still there after deleting" );
    is( $db->[2], 'elem3', "2nd element still there after deleting" );
    is( $deleted, 'elem1', "Deleted value is correct" );

#U  is( $db->delete(99), undef, 'delete on an element not in the array returns undef' );
#M  is( $db->length, 3, "... and we still have three after a delete on an out-of-range index" );
    is( scalar(@$db),3, "... and we still have three after a delete on an out-of-range index" );

#U  is( delete $db->[99], undef, 'DELETE on an element not in the array returns undef' );
#M  is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range index" );
    is( scalar(@$db),3, "... and we still have three after a DELETE on an out-of-range index" );

#U  is( $db->delete(-99), undef, 'delete on an element (neg) not in the array returns undef' );
#M  is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range negative index" );
    is( scalar(@$db),3, "... and we still have three after a DELETE on an out-of-range negative index" );

    is( delete $db->[-99], undef, 'DELETE on an element (neg) not in the array returns undef' );
#M  is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range negative index" );
    is( scalar(@$db),3, "... and we still have three after a DELETE on an out-of-range negative index" );

#M  $deleted = $db->delete(-2);
    $deleted = $db->[-2]; $db->[-2] = undef;
    is( scalar(@$db),3, "... and we still have three after deleting" );
#M  is( $db->length, 3, "... and we still have three after deleting" );
    is( $db->[0], undef, "0th element still undef" );
    is( $db->[1], undef, "1st element now undef" );
    is( $db->[2], 'elem3', "2nd element still there after deleting" );
    is( $deleted, 'elem2', "Deleted value is correct" );

    $db->[1] = 'elem2';

    ##
    # exists
    ##
#D  ok( $db->exists(1), "The 1st value exists" );
#D  ok( $db->exists(0), "The 0th value doesn't exist" );
#D  ok( !$db->exists(22), "The 22nd value doesn't exists" );
#D  ok( $db->exists(-1), "The -1st value does exists" );
#D  ok( !$db->exists(-22), "The -22nd value doesn't exists" );

    ##
    # clear
    ##
#C  ok( $db->clear(), "clear() returns true if the file was ever non-empty" );
    @$db = ();
#M  is( $db->length(), 0, "After clear(), no more elements" );
    is( scalar(@$db), 0, "After clear(), no more elements" );

#M  is( $db->pop, undef, "pop on an empty array returns undef" );
    is( pop @$db, undef, "pop on an empty array returns undef" );
#M  is( $db->length(), 0, "After pop() on empty array, length is still 0" );
    is( scalar(@$db), 0, "After pop() on empty array, length is still 0" );

#M  is( $db->shift, undef, "shift on an empty array returns undef" );
    is( shift @$db, undef, "shift on an empty array returns undef" );
#M  is( $db->length(), 0, "After shift() on empty array, length is still 0" );
    is( scalar(@$db), 0, "After shift() on empty array, length is still 0" );

#M  is( $db->unshift( 1, 2, 3 ), 3, "unshift returns the number of elements in the array" );
    is( unshift (@$db, ( 1, 2, 3 )), 3, "unshift returns the number of elements in the array" );
#M  is( $db->unshift( 1, 2, 3 ), 6, "unshift returns the number of elements in the array" );
    is( unshift (@$db, ( 1, 2, 3 )), 6, "unshift returns the number of elements in the array" );
#M  is( $db->push( 1, 2, 3 ), 9, "push returns the number of elements in the array" );
    is( push (@$db, ( 1, 2, 3 )), 9, "push returns the number of elements in the array" );

#M  is( $db->length(), 9, "After unshift and push on empty array, length is now 9" );
    is( scalar(@$db), 9, "After unshift and push on empty array, length is now 9" );

#M  $db->clear;
    @$db = ();

    ##
    # multi-push
    ##
#M  $db->push( 'elem first', "elem middle", "elem last" );
    push @$db, ( 'elem first', "elem middle", "elem last" );
#M  is( $db->length, 3, "3-element push results in three elements" );
    is( scalar(@$db),3, "3-element push results in three elements" );
    is($db->[0], "elem first", "First element is 'elem first'");
    is($db->[1], "elem middle", "Second element is 'elem middle'");
    is($db->[2], "elem last", "Third element is 'elem last'");

###################################### Need splice
if (0) {
    ##
    # splice with length 1
    ##
#M  my @returned = $db->splice( 1, 1, "middle A", "middle B" );
    my @returned = splice @$db, 1, 1, ("middle A", "middle B" );
    is( scalar(@returned), 1, "One element was removed" );
    is( $returned[0], 'elem middle', "... and it was correctly removed" );
#M  is($db->length(), 4);
    is(scalar(@$db), 4,               p __LINE__);
    is($db->[0], "elem first",        p __LINE__);
    is($db->[1], "middle A",          p __LINE__);
    is($db->[2], "middle B",          p __LINE__);
    is($db->[3], "elem last",         p __LINE__);

    ##
    # splice with length of 0
    ##
#M  @returned = $db->splice( -1, 0, "middle C" );
    @returned = splice @$db, -1, 0, "middle C";
    is( scalar(@returned), 0, "No elements were removed" );
#M  is($db->length(), 5);
    is(scalar(@$db), 5,               p __LINE__);
    is($db->[0], "elem first",        p __LINE__);
    is($db->[1], "middle A",          p __LINE__);
    is($db->[2], "middle B",          p __LINE__);
    is($db->[3], "middle C",          p __LINE__);
    is($db->[4], "elem last",         p __LINE__);

    ##
    # splice with length of 3
    ##
#M  my $returned = $db->splice( 1, 3, "middle ABC" );
    my $returned = splice @$db, 1, 3, "middle ABC" ;
    is( $returned, 'middle C', "Just the last element was returned" );
#M  is($db->length(), 3);
    is(scalar(@$db), 3,               p __LINE__);
    is($db->[0], "elem first",        p __LINE__);
    is($db->[1], "middle ABC",        p __LINE__);
    is($db->[2], "elem last",         p __LINE__);

#M  @returned = $db->splice( 1 );
    @returned = splice @$db, 1;
#M  is($db->length(), 1);
    is(scalar(@$db), 1,               p __LINE__);
    is($db->[0], "elem first",        p __LINE__);
    is($returned[0], "middle ABC",    p __LINE__);
    is($returned[1], "elem last",     p __LINE__);

#M  $db->push( @returned );
    push @$db, @returned;

#M  @returned = $db->splice( 1, -1 );
    @returned = splice @$db, 1, -1;
#M  is($db->length(), 2);
    is(scalar(@$db), 2,               p __LINE__);
    is($db->[0], "elem first",        p __LINE__);
    is($db->[1], "elem last",         p __LINE__);
    is($returned[0], "middle ABC",    p __LINE__);

#M  @returned = $db->splice;
    @returned = splice @$db;
#M  is( $db->length, 0 );
    is( scalar(@$db), 0 ,             p __LINE__);
    is( scalar(@$db),0 ,              p __LINE__);
    is( $returned[0], "elem first" ,  p __LINE__);
    is( $returned[1], "elem last" ,   p __LINE__);
}

    $db->[0] = [ 1 .. 3 ];
    $db->[1] = { a => 'foo' };
#U  is( $db->[0]->length, 3, "Reuse of same space with array successful" );
    is( $db->[0][$#$db],  3, "Reuse of same space with array successful" );
#U  is( $db->[1]->fetch('a'), 'foo', "Reuse of same space with hash successful" );
    is( $db->[1]{a},          'foo', "Reuse of same space with hash successful" );

    # Test autovivification

    $db->[9999]{bar} = 1;
    ok( $db->[9999], 'Found Hash' );
    cmp_ok( $db->[9999]{bar}, '==', 1, 'Found 1 in hash');

#F  # Test failures
#F  throws_ok {
#F      $db->fetch( 'foo' );
#F  } qr/Cannot use 'foo' as an array index/, "FETCH fails on an illegal key";

#F  throws_ok {
#F      $db->fetch();
#F  } qr/Cannot use an undefined array index/, "FETCH fails on an undefined key";

#F  throws_ok {
#F      $db->store( 'foo', 'bar' );
#F  } qr/Cannot use 'foo' as an array index/, "STORE fails on an illegal key";

#F  throws_ok {
#F      $db->store();
#F  } qr/Cannot use an undefined array index/, "STORE fails on an undefined key";

#F  throws_ok {
#F      $db->delete( 'foo' );
#F  } qr/Cannot use 'foo' as an array index/, "DELETE fails on an illegal key";

#F  throws_ok {
#F      $db->delete();
#F  } qr/Cannot use an undefined array index/, "DELETE fails on an undefined key";

#F  throws_ok {
#F      exists $db->[ 'foo' ];
#F  } qr/Cannot use 'foo' as an array index/, "EXISTS fails on an illegal key";

#U  throws_ok {
#U      $db->exists();
#U  } qr/Cannot use an undefined array index/, "EXISTS fails on an undefined key";

# Bug reported by Mike Schilli
# Also, RT #29583 reported by HANENKAMP

    @$db = ();

    push @{$db}, 3, { foo => 1 }; 
    lives_ok {
        shift @{$db};
    } "Shift doesn't die moving references around";
    is( $db->[0]{foo}, 1, "Right hashref there" );

    lives_ok {
        unshift @{$db}, [ 1 .. 3, [ 1 .. 3 ] ];
        unshift @{$db}, 1;
    } "Unshift doesn't die moving references around";
    is( $db->[1][3][1], 2, "Right arrayref there" );
    is( $db->[2]{foo}, 1, "Right hashref there" );

    # Add test for splice moving references around

#   lives_ok {                        ############ need splice
#       splice @{$db}, 0, 0, 1 .. 3;
#   } "Splice doesn't die moving references around";
#   is( $db->[4][3][1], 2, "Right arrayref there" );
#   is( $db->[5]{foo}, 1, "Right hashref there" );

  }

#----------------------------------------------------------------------
# 05_bigarray.t
#----------------------------------------------------------------------

  {my $m = DBM::Deep::Blue::new();
   my $db = $m->allocArray();

    ##
    # put/get many keys
    ##
    my $max_keys = 4000;

    for ( 0 .. $max_keys ) {
        $db->[$_] = $_ * 2;
    }

    my $count = -1;
    for ( 0 .. $max_keys ) {
        $count = $_;
        unless ( $db->[$_ ] == $_ * 2 ) {
            last;
        };
    }
    is( $count, $max_keys, "We read $count keys" );

    cmp_ok( scalar(@$db), '==', $max_keys + 1, "Number of elements is correct" );
    @$db = ();
    cmp_ok( scalar(@$db), '==', 0, "Number of elements after clear() is correct" );
  }

#----------------------------------------------------------------------
# 08_deephash.t
#----------------------------------------------------------------------

  {my $m = DBM::Deep::Blue::new();
   my $db = $m->allocHash();

   ##
   # basic deep hash
   ##
   $db->{company} = {};
   $db->{company}->{name} = "My Co.";
   $db->{company}->{employees} = {};
   $db->{company}->{employees}->{"Henry Higgins"} = {};
   $db->{company}->{employees}->{"Henry Higgins"}->{salary} = 90000;

   is( $db->{company}->{name}, "My Co.", "Set and retrieved a second-level value" );
   is( $db->{company}->{employees}->{"Henry Higgins"}->{salary}, 90000, "Set and retrieved a fourth-level value" );

# Load

   ##
   # super deep hash
   ##
   $db->{base_level} = {};
   my $max_levels = 1000;
   my $temp_db = $db->{base_level};

   for my $k ( 0 .. $max_levels ) {
       $temp_db->{"level$k"} = {};
       $temp_db = $temp_db->{"level$k"};
   }
   $temp_db->{deepkey} = "deepvalue";

# Close and reopen ##################### Need backing file

#   my $r = tied(%$db)->{memory}->od();
#   undef $db;
#   $db = new($f);
#   is tied(%$db)->{memory}->od(), $r, 'Reopened database matches closed database';

# Reread

   my $cur_level = -1;
      $temp_db = $db->{base_level};
   for my $k ( 0 .. $max_levels ) {
       $cur_level = $k;
       $temp_db = $temp_db->{"level$k"};
   }
   is( $cur_level, $max_levels, "We read all the way down to level $cur_level" );
   is( $temp_db->{deepkey}, "deepvalue", "And we retrieved the value at the bottom of the ocean" );
  }

#----------------------------------------------------------------------
# 09_deeparray.t
#----------------------------------------------------------------------

  {my $m = DBM::Deep::Blue::new();
   my $db = $m->allocArray();

   my $max_levels = 1000;

# Load

    {$db->[0] = [];
     my $temp_db = $db->[0];
     for my $k ( 0 .. $max_levels)
      {$temp_db->[$k] = [];
       $temp_db = $temp_db->[$k];
      }
     $temp_db->[0] = "deepvalue";
    }

# Close and reopen      ################### Need backing file

#   my $r = tied(@$db)->{memory}->od();
#   undef $db;
#   $db = newArray($f);
#   ok compare(tied(@$db)->{memory}->od(), $r), 'Reopened database matches closed database';

# Reread

    {my  $cur_level = -1;
     my $temp_db = $db->[0];
     for my $k ( 0 .. $max_levels)
      {$cur_level = $k;
       $temp_db = $temp_db->[$k];
      }
     is( $cur_level, $max_levels, "We read all the way down to level $cur_level" );
     is( $temp_db->[0], "deepvalue", "And we retrieved the value at the bottom of the ocean" );
    }
  }

#----------------------------------------------------------------------
# 10_largekeys.t
#----------------------------------------------------------------------

   {my $m = DBM::Deep::Blue::new();
    my $db = $m->allocHash();

    ##
    # large keys
    ##
#   my $key1 = "Now is the time for all good men to come to the aid of their country." x 100;
#   my $key2 = "The quick brown fox jumped over the lazy, sleeping dog." x 1000;
#   my $key3 = "Lorem dolor ipsum latinum suckum causum Ium cannotum rememberum squatum." x 1000;
    my $key1 = "Now is the time for all good men to come to the aid of their country." x 1000;
    my $key2 = "The quick brown fox jumped over the lazy, sleeping dog." x 1000;
    my $key3 = "Lorem dolor ipsum latinum suckum causum Ium cannotum rememberum squatum." x 1000;

#M  $db->put($key1, "value1");
    $db->{$key1} = "value1";
#M  $db->store($key2, "value2");
    $db->{$key2} = "value2";
    $db->{$key3} = "value3";

    is( $db->{$key1}, 'value1', "Hash retrieval of put()" );
    is( $db->{$key2}, 'value2', "Hash retrieval of store()" );
    is( $db->{$key3}, 'value3', "Hash retrieval of hashstore" );
#U  is( $db->get($key1), 'value1', "get() retrieval of put()" );
#U  is( $db->get($key2), 'value2', "get() retrieval of store()" );
#U  is( $db->get($key3), 'value3', "get() retrieval of hashstore" );
#U  is( $db->fetch($key1), 'value1', "fetch() retrieval of put()" );
#U  is( $db->fetch($key2), 'value2', "fetch() retrieval of store()" );
#U  is( $db->fetch($key3), 'value3', "fetch() retrieval of hashstore" );
  
#M  my $test_key = $db->first_key();
    my $test_key = each %$db;
    ok(
        ($test_key eq $key1) || 
        ($test_key eq $key2) || 
        ($test_key eq $key3),
        "First key found",
    );

#M  $test_key = $db->next_key($test_key);
     $test_key = each %$db;
    ok(
        ($test_key eq $key1) || 
        ($test_key eq $key2) || 
        ($test_key eq $key3),
        "Second key found",
    );

#M  $test_key = $db->next_key($test_key);
     $test_key = each %$db;
    ok(
        ($test_key eq $key1) || 
        ($test_key eq $key2) || 
        ($test_key eq $key3),
        "Third key found",
    );

#M  $test_key = $db->next_key($test_key);
    $test_key = each %$db;
    ok( !$test_key, "No fourth key" );
   }

done_testing;

say "Time ", time() - $T;

