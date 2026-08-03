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
	END{ 4; }
	1;
	2;
	3;
PERL

is
	n( `$^X $lib -d:DbInteract -e '$script'` )
	,$files->{ 'step-by-step' }
	,"Step-by-step debugging";



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
	n( `$^X $lib -d:DbInteract -e '$script'` )
	,$files->{ 'sbs subs' }
	,"Step-by-step debugging subroutines";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		goto &t1;
		2;
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbInteract -e '$script'` )
	,$files->{ 'sbs goto' }
	,"Step-by-step debugging goto";



TODO: {
	local $TODO =  "RT#127379";

	($script =  <<'	PERL') =~ s#^\t\t##gm;
		$x =  1;
		if( $x > 2 ) {
			1;
		}
		elsif( $x == 0 ) {
			2;
		}
		else {
			3;
		}
	PERL

	is
		n( `$^X $lib -d:DbInteract -e'$script'` )
		,$files->{ 'sbs if block' }
		,"Step-by-step debugging if block";
}

__DATA__
@@ step-by-step
-e:0002  1;
-e:0003  2;
-e:0004  3;
-e:0001  END{ 4; }
@@ sbs subs
-e:0008  t2();
-e:0005    t1();
-e:0002    1;
-e:0006    2;
-e:0009  3;
@@ sbs goto
-e:0008  t2();
-e:0005    goto &t1;
-e:0002    1;
-e:0009  3;
@@ sbs if block
-e:0001  $x =  1;
-e:0002  if( $x > 2 ) {
-e:0005  elsif( $x == 0 ) {
-e:0009    3;
