
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

=pod
-- test --
-- use tt --
[%# try original template -%]
original [% "template" -%]
-- expect --
original template
=cut


__END__


-- test --
-- use att --
[%# try original template -%]
original [% "template" -%]
-- expect --
original template

#------------------------------------------------------------------------
# load Foo plugin through custom PLUGIN_BASE
#------------------------------------------------------------------------
-- test --
[%# try modern event -%]
[% USE Second(); IF Second; 'modern'; END -%]
-- expect --
modern

-- test --
[%# event call and plugin -%]
[% USE s = Second -%]
[% res = undef -%]
first chunk
[% EVENT res = s.start(-1) -%]
event (negative): [% IF res.error; 'error'; END %]
[% EVENT res = s.start(1) -%]
event (positive): [% res.result %]
-- expect --
first chunk
event (negative): error
event (positive): ok

-- test --
[%# original nested while -%]
[%
   i = 3;
   a = [ '-', 'c', 'b', 'a' ];
   WHILE i;
     j = 3;
     i;
     WHILE j;
       a.$j;
       j = j - 1;
     END;
     "\n";
     i = i - 1;
   END;
   "done";
%]
-- expect --
3abc
2abc
1abc
done

-- test --
[%# evented nested while -%]
[% USE s = Second -%]
[%
   i = 3;
   a = [ '-', 'c', 'b', 'a' ];
   WHILE i;
     j = 3;
     res = undef;
     EVENT res = s.start(0);
     "$i : ${res.result}\n";
     WHILE j;
       '  '; a.$j;
       res = undef;
       EVENT res = s.start(0);
       " : ${res.result}\n";
       j = j - 1;
     END;
     i = i - 1;
   END;
   "done";
%]
-- expect --
3 : ok
  a : ok
  b : ok
  c : ok
2 : ok
  a : ok
  b : ok
  c : ok
1 : ok
  a : ok
  b : ok
  c : ok
done

-- test --
[%# evented switch in while -%]
[%
USE s = Second;
n = 4;
WHILE n;
   SWITCH n;
   CASE '1';     '1';
   CASE DEFAULT; 'd';
   END;

   SWITCH n;
   CASE '1'; 'a';
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
   n = n - 1;
END
%]
-- expect -- 
dDEq
d3q
d2eq
1aq

-- test --
[%# evented switch in foreach -%]
[%
USE s = Second;
list = [ '4', 3, 2, '1' ];
FOREACH n = list;
   SWITCH n;
   CASE '1';     '1';
   CASE DEFAULT; 'd';
   END;

   SWITCH n;
   CASE '1'; 'a';
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
END
%]
-- expect -- 
dDEq
d3q
d2eq
1aq

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
END;
%]
-- expect --
4d3Eec2Bb1BEeaEeB

-- test --
[%# evented IF simple -%]
[%
   USE s = Second;
   r = { result => 1 };
   EVENT r = s.start(0) IF 0; r.result;
   EVENT r = s.start(0) IF 1; r.result;
   r = { result => 2 };
   EVENT r = s.start(0) UNLESS 1; r.result;
   EVENT r = s.start(0) UNLESS 0; r.result;
-%]
-- expect --
1ok2ok

-- test --
[%# evented IF with else -%]
[%
   USE s = Second;
   r_one = { result => 1 }; 
#
   r=r_one; IF 0; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; IF 1; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; UNLESS 1; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; UNLESS 0; EVENT r = s.start(0); END; r.result;
"\n";
   r=r_one; IF 1; 2; ELSE; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; IF 0; 2; ELSE; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; UNLESS 0; 2; ELSE; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; UNLESS 1; 2; ELSE; EVENT r = s.start(0); END; r.result;
"\n";
   r=r_one; IF 1; EVENT r = s.start(0); ELSE; 3; END; r.result; " ";
   r=r_one; IF 0; EVENT r = s.start(0); ELSE; 3; END; r.result; " ";
   r=r_one; UNLESS 0; EVENT r = s.start(0); ELSE; 3; END; r.result; " ";
   r=r_one; UNLESS 1; EVENT r = s.start(0); ELSE; 3; END; r.result;
-%]
-- expect --
1 ok 1 ok
21 ok 21 ok
ok 31 ok 31

-- test --
[%# evented IF with elsif -%]
[%
   USE s = Second;
   r_one = { result => 1 }; 
#
   r=r_one; IF 1; EVENT r = s.start(0); ELSIF 0; 2; END; r.result; " ";
   r=r_one; IF 0; EVENT r = s.start(0); ELSIF 1; 2; END; r.result; " ";
   r=r_one; IF 1; 3; ELSIF 0; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; IF 0; 3; ELSIF 1; EVENT r = s.start(0); END; r.result;
"\n";
   r=r_one; UNLESS 1; ELSIF 1; EVENT r = s.start(0); ELSE; 4; END; r.result; " ";
   r=r_one; UNLESS 1; ELSIF 0; EVENT r = s.start(0); ELSE; 4; END; r.result; " ";
   r=r_one; UNLESS 1; ELSIF 1; 5; ELSE; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; UNLESS 1; ELSIF 0; 5; ELSE; EVENT r = s.start(0); END; r.result;
"\n";
   r=r_one; IF 0; ELSIF 1; EVENT r = s.start(0); ELSIF 0; 6; END; r.result; " ";
   r=r_one; IF 0; ELSIF 0; EVENT r = s.start(0); ELSIF 1; 6; END; r.result; " ";
   r=r_one; IF 0; ELSIF 1; 7; ELSIF 0; EVENT r = s.start(0); END; r.result; " ";
   r=r_one; IF 0; ELSIF 0; 7; ELSIF 1; EVENT r = s.start(0); END; r.result;
-%]
-- expect --
ok 21 31 ok
ok 41 51 ok
ok 61 71 ok

-- test --
[%# original capture anon block and edirectives -%]
3[%
NB = BLOCK;
   IF 1; 1; ELSE; 0; END;
%]
[% END %] 2 [% NB %]
-- expect --
3 2 1

-- test --
[%# evented capture anon block and edirectives -%]
4[%
NB = BLOCK;
   2; " ";
   USE s = Second;
   EVENT res = s.start(1);
   res.result;
   " ";
   IF 1; 1; ELSE; 0; END;
-%]
[% END %] 3 [% NB %] z
-- expect --
4 3 2 ok 1 z

-- test --
[% # check localization variable for PROCESS/INCLUDE
USE s = Second;
BLOCK block;
   EVENT res = s.start(0);
   var; ':'; 
   var=1;
   EVENT res = s.start(0);
END;
INCLUDE block;       EVENT res = s.start(0); var; " ";
PROCESS block;       EVENT res = s.start(0); var; " ";
INCLUDE block var=2; EVENT res = s.start(0); var; " ";
PROCESS block var=3; EVENT res = s.start(0); var; " ";
%]
-- expect --
: :1 2:1 3:1 

-- test--
[% # simple external template
   letters = [ 'a', 'b', 'c' ];
   numbers = [ 1, 2, 3 ];
   FOREACH item IN letters;
     item; INCLUDE loop_simple list=numbers;
   END;
%]
-- expect --
a123b123c123


-- test--
[% # evented external template
   letters = [ 'a', 'b', 'c' ];
   numbers = [ 1, 2, 3 ];
   FOREACH item IN letters;
     item; INCLUDE loop_evented list=numbers;
   END;
%]
-- expect --
a123b123c123

-- test --
[% # await operator
USE Second;
FOREACH rec = [0.25, 0.125];
   r = AWAIT Second.start(rec, 2*rec);
   "${rec}-${r.result}~";
END
%]
-- expect --
0.25-0.5~0.125-0.25~

-- test --
[% # async-await togather
USE s0 = Second;
USE s1 = Second;
quick = 0.25;
slow  = 0.5;
list = [[quick,slow], [slow,quick]];
list.push(list.0,list.1);
FOREACH rec = list;
   start = s1.now;
   r0 = ASYNC s0.start(rec.0, rec.0+1);
   r1 = ASYNC s1.start(rec.1, rec.1+1);
   r0 = AWAIT r0;
   r1 = AWAIT r1;
   "res0 " IF rec.0+1 == r0.result;
   "res1 " IF rec.1+1 == r1.result;
   finish = s1.now;
   max = rec.0 > rec.1 ? rec.0 : rec.1;
   min = rec.0 < rec.1 ? rec.0 : rec.1;
   "min " IF start + max <= finish;
   "max " IF start + max + min > finish;
   "ok\n";
END
%]
-- expect --
res0 res1 min max ok
res0 res1 min max ok
res0 res1 min max ok
res0 res1 min max ok

-- test --
[% WRAPPER wrapper + wrapperex %] the content [% END %]
-- expect --
start startex  the content  finishex finish

-- test --
[%
  WRAPPER wrapper + wrapperex;
  USE s = Second;
  EVENT res = s.start(0);
%] the async content [% END %]
-- expect --
start startex  the async content  finishex finish
