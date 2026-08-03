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
	s#(?:[^\s]*?)?([^/]+\.p(?:m|l))#xxx/$1#gm;

	$_;
}



sub nl {
	$_ =  n( @_ );

	s#(xxx/.*?pm:)\d+#$1XXXX#gm;

	$_;
}



my $cmds;
my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	1;
	2;
	3;
	4;
	5;
	6;
PERL

is
	n( `$^X $lib -d:DbBatch='a 2 print "YES\\n";s;q' -e '$script'` )
	,$files->{ 'action' }
	,"Set action at line";

is
	n( `$^X $lib -d:DbBatch='a 2 print "YES\\n";s 2;q' -e '$script'` )
	,$files->{ 'action & steps' }
	,"Do not skip action when we do K steps";


is
	n( `$^X $lib -d:DbBatch='a 2 go 4;a 3 print "YES\\n";s;q' -e '$script'` )
	,$files->{ 'commands' }
	,"Allow debugger commands as action EXPR";

is
	n( `$^X $lib -d:DbBatch='a 2 s 4;a 3 print "YES\\n";s 2;s' -e '$script'` )
	,$files->{ 'concurrent' }
	,"Commands do not cancel each other";



__DATA__
@@ action
-e:0001  1;
YES
-e:0002  2;
@@ action & steps
-e:0001  1;
YES
-e:0003  3;
@@ commands
-e:0001  1;
YES
-e:0004  4;
@@ concurrent
-e:0001  1;
YES
-e:0003  3;
-e:0005  5;
