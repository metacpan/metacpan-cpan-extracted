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
	s#(xxx/.*?pm line )\d+#$1XXXX#gm;

	$_;
}



my $cmds;
my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		print "$@\n";
	}
	$@ =  'value';
	t1();
PERL

$cmds =  'go';
is
	n( `PERLDB_OPTS='ddd=0' $^X $lib -d:DbContext='$cmds' -e '$script'` )
	,$files->{ 'context when call' }
	,"Save/restore context when sub is called";


($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		$@ =  'value';
	}
	t1();
	print "$@\n";
PERL

$cmds =  'go';
is
	n( `PERLDB_OPTS='ddd=0' $^X $lib -d:DbContext='$cmds' -e '$script'` )
	,$files->{ 'context when return' }
	,"Save/restore context when sub is returned";


($script =  <<'PERL') =~ s#^\t##gm;
	$_ =  1;
	require Arg;
	print;
	print "\n";
PERL

$cmds =  'go';
is
	n( `PERLDB_OPTS='ddd=0' $^X $lib -d:DbContext='$cmds' -e '$script'` )
	,$files->{ 'context when require' }
	,"Save/restore context when module is required";


__DATA__
@@ context when call
value
@@ context when return
value
@@ context when require
12
