
#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 20.07.2016

use strict;
use lib qw( t/lib ./lib ../lib ../blib/arch );
use Template::Test;
use Template::Plugins;
use Template::Constants qw( :debug );
use Async::Template;

use FindBin '$Bin';
my $lib = "$Bin/lib";
my $src = "$Bin/tmpl";
unshift @INC, $lib;

my $DEBUG = grep(/^--?d(debug)?$/, @ARGV);

my $att = Async::Template->new({
   INCLUDE_PATH => $src,
   COMPILE_DIR  => '.',
   DEBUG        => $DEBUG ? DEBUG_PLUGINS : 0,
#   DEBUG        => DEBUG_ALL,
}) || die Template->error();

my $tt = [
    tt  => Template->new(),
    att => $att,
];

test_expect(\*DATA, $tt, &callsign());


__END__


-- test --
-- use att --
[% USE s = Second -%]
first
[% EVENT res = s.start(1) -%]
second
[% RETURN %]
unreach
[% res.result %]
unreach
-- expect --
first
second

-- test --
[%# evented nested while -%]
[% USE s = Second -%]
[%
   i = 3;
   a = [ '-', 'c', 'b', 'a' ];
   WHILE i;
     j = 3; res = undef;
     EVENT res = s.start(0);
     "$i : ${res.result}\n";
     WHILE j;
       a.$j; res = undef;
       EVENT res = s.start(0);
       " : ${res.result}\n";
       j = j - 1;
       RETURN;
     END;
     i = i - 1;
   END;
   "unreach";
%]
-- expect --
3 : ok
a : ok

-- test --
[%# evented switch in while -%]
[%
USE s = Second;
n = 4;
WHILE n;
   SWITCH n;
   CASE '1'; 'a'; RETURN;
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
   n = n - 1;
END;
"unreach"
%]
-- expect -- 
DEq
3q
2eq
a

-- test --
[%# evented switch in foreach -%]
[%
USE s = Second;
list = [ '4', 3, 2, '1' ];
FOREACH n = list;
   SWITCH n;
   CASE '1'; 'a'; RETURN;
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
END;
"unreach";
%]
-- expect -- 
DEq
3q
2eq
a

-- test --
[%# evented PROCESS/INCLUDE directives -%]
[%
USE s = Second;
n = 4;
WHILE n;
   SWITCH n;
   CASE '4'; '4'; EVENT res = s.start(0); 'd';
   CASE '3'; '3'; PROCESS evblock; 'c';
   CASE '2'; '2'; PROCESS block; 'b';
   CASE '1'; '1'; PROCESS block + evblock; 'a';
   END;
   n = n - 1;
END;
PROCESS evblock + block;

BLOCK block;
  "B";
END;

BLOCK evblock;
  "E"; EVENT res = s.start(0); 'e';
  RETURN IF 1 == n;
END;
%]
-- expect --
4d3Eec2Bb1BEe

-- test --
[%# evented IF simple -%]
[%
   USE s = Second;
   r = { result => 1 };
   EVENT r = s.start(0) IF 0; r.result;
   EVENT r = s.start(0) IF 1; r.result;
   RETURN UNLESS !r.result; "unreach";
-%]
-- expect --
1ok

-- test --
[%# evented IF with else -%]
[%
   USE s = Second;
   r_one = { result => 1 }; 
#
   r=r_one; IF 0; EVENT r = s.start(0); END; r.result; 
   r=r_one; IF 0; ELSE; RETURN; END;
   "unreach";
-%]
-- expect --
1

-- test --
[%# evented IF with elsif -%]
[%
   USE s = Second;
   r_one = { result => 1 }; 
#
   r=r_one; IF 1; EVENT r = s.start(0); ELSIF 0; 2; END; r.result; 
   r=r_one; IF 0; EVENT r = s.start(0); ELSIF 1; RETURN; END; r.result; " ";
   "unreach";
-%]
-- expect --
ok

-- test --
[%# original capture anon block and edirectives -%]
3[%
NB = BLOCK;
   IF 1; 1; ELSE; 0; END;
   RETURN;
%]
[% END %] 2 [% NB %]
-- expect --
31

-- test --
[%# evented capture anon block and edirectives -%]
4[%
NB = BLOCK;
   2; " ";
   USE s = Second;
   EVENT res = s.start(1);
   res.result;
   " ";
   RETURN;
-%]
[% END %] 3 [% NB %] z
-- expect --
4

-- test--
[% # simple external template
   letters = [ 'a', 'b', 'c' ];
   numbers = [ 1, 2, 3 ];
   FOREACH item IN letters;
     item; INCLUDE loop_simple_return list=numbers;
   END;
%]
-- expect --
a1

