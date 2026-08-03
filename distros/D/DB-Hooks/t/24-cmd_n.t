#!/usr/bin/env perl


use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;
use FindBin qw/ $Bin /;  my $lib =  "-I$Bin/lib -I$Bin/../lib";
use Data::Section::Simple qw/ get_data_section /;

use Test::Differences;
unified_diff();
{
	no warnings qw/ redefine prototype /;
	*is =  \&eq_or_diff;
}



sub n {
	$_ =  join '', @_;

	s#\t#  #gm;
	s#(?:.*?)?([^/]+\.p(?:m|l))#xxx/$1#gm;

	$_;
}



my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	1;
	2;
	3;
PERL

is
	n( `$^X $lib -d:DbBatch='n;q' -e '$script'` )
	,$files->{ 'sbs' }
	,"Step-by-step debugging. Step over";

is
	n( `$^X $lib -d:DbBatch='s 1;q' -e '$script'` )
	,$files->{ 'sbs' }
	,"'n 1' and 'n' should do same";

is
	n( `$^X $lib -d:DbBatch='n 2;q' -e '$script'` )
	,$files->{ 'do n steps' }
	,"Do N steps at once";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		t1();
		2;
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbBatch='n;n' -e '$script'` )
	,$files->{ 'step over sub' }
	,"Step over sub";

is
	n( `$^X $lib -d:DbBatch='go 2;n;q' -e '$script'` )
	,$files->{ 'step from sub' }
	,"Step from sub";



$script =~  s/t1\(\)/goto &t1/;
is
	n( `$^X $lib -d:DbBatch='s;n;q' -e '$script'` )
	,$files->{ 'step over goto' }
	,"Step over goto";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		t1();
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbBatch='go 2;n;q' -e '$script'` )
	,$files->{ 'double step from sub' }
	,"Double step from sub";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		t1();
		t1();
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbBatch='go 5;n;q' -e '$script'` )
	,$files->{ 'step over sub #2' }
	,"Step over sub in a sub";

#FIX: FAIL randomly
# is
# 	n( `$^X $lib -d:DbBatch='go 5;n 2;q' -e '$script'` )
# 	,$files->{ 'do n steps in sub' }
# 	,"Do N steps at once in sub";

is
	n( `$^X $lib -d:DbBatch='go 5;n;s;q' -e '$script'` )
	,$files->{ 'into after over' }
	,"Step into after step over";



($script =  <<'PERL') =~ s#^\t##gm;
	sub c3 {
		1;
	}
	sub c2 {
		\&c3;
	}
	sub c1 {
		c2();
	}
	sub c4 {
		c1->();
	}
	c4();
	2;
PERL

is
	n( `$^X $lib -d:DbBatch='s 2;n;n' -e '$script'` )
	,$files->{ 'stay at chain' }
	,"Do not leave chain when step over inside it";



($script =  <<'PERL') =~ s#^\t##gm;
	require Empty;
	1;
PERL

is
	n( `$^X $lib -d:DbBatch='n' -e '$script'` )
	,$files->{ 'step over require' }
	,"Step over require";



($script =  <<'PERL') =~ s#^\t##gm;
	sub c1 {
		require Empty;
	}
	c1();
	1;
PERL

is
	n( `$^X $lib -d:DbBatch='s;n;' -e '$script'` )
	,$files->{ 'step over require #2' } # Just like 'double step from sub'
	,"Step over require #2";



__DATA__
@@ sbs
-e:0001  1;
-e:0002  2;
@@ do n steps
-e:0001  1;
-e:0003  3;
@@ step over sub
-e:0008  t2();
-e:0009  3;
@@ step from sub
-e:0008  t2();
-e:0002    1;
-e:0006    2;
@@ step over goto
-e:0008  t2();
-e:0005    goto &t1;
-e:0009  3;
@@ double step from sub
-e:0007  t2();
-e:0002    1;
-e:0008  3;
@@ step over sub #2
-e:0008  t2();
-e:0005    t1();
-e:0006    t1();
@@ do n steps in sub
-e:0008  t2();
-e:0005    t1();
-e:0009  3;
@@ into after over
-e:0008  t2();
-e:0005    t1();
-e:0006    t1();
-e:0002    1;
@@ stay at chain
-e:0013  c4();
-e:0008    c2();
-e:0002    1;
-e:0014  2;
@@ step over require
-e:0001  require Empty;
-e:0002  1;
@@ step over require #2
-e:0004  c1();
-e:0002    require Empty;
-e:0005  1;
