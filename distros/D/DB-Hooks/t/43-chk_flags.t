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
	BEGIN{ 1; }
	print "OK\n";
PERL

is
	n( `$^X $lib -d:DbInteract='q' -e '$script'` )
	,$files->{ 'first OP' }
	,"Stop on first script OP";

is
	nl( `$^X $lib -d:DbInteract='s 4;scalar\@{ DB::state( "stack" ) };q,Stop' -e '$script'` )
	,$files->{ 'BEGIN' }
	,"Stop at BEGIN block OP";

is
	n( `$^X $lib -d:DbInteract='1,NonStop' -e '$script'` )
	,$files->{ 'end' }
	,"Run script until the end";



__DATA__
@@ first OP
-e:0002  print "OK\n";
@@ BEGIN
xxx/DbInteract.pm:XXXX    DB::state( 'inDB', 1 );
-e:0001  BEGIN{ 1; }
2
@@ end
OK
