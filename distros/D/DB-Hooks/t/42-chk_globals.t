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



sub nn {
	$_ =  n( @_ );

	s#( at ).*$#$1...#gm;    # Remove file:line info

	$_;
}



my $cmds;
my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	print sort{
		$a <=> $b
	} qw/ 3 1 2 /;
PERL

is
	n( `$^X $lib -d:DbInteract='off;s 2;\$a;\$b;go' -e '$script'` ) ."\n"
	,$files->{ 'anb' }
	,"\$a \$b should not be changed by debugger";



SKIP: {
	eval { require List::Util };
	skip "List::Util is not installed"   if $@;
	skip "List::Util v1.29 required"
		if $List::Util::VERSION < 1.29;

	List::Util->import( qw/ pairmap / );


	($script =  <<'	PERL') =~ s#^\t+##gm;
		use List::Util qw/ pairmap /;
		print pairmap{
			"$a - $b"
		} qw/ 1 2 3 4 /;
	PERL

	# RT#115608 Guard's ENTER/LEAVE force List::Util to use $DB::a variable under debugger
	TODO: {
		local $TODO =  "FIX: List::Util should not notice debugger";
		is
			n( `$^X $lib -d:DbInteract='off;s 2;\$a;\$b;go' -e '$script'` ) ."\n"
			,$files->{ 'ab context' }
			,"Debugger should not change context";
	}
}



($script =  <<'PERL') =~ s#^\t##gm;
	$_ =  7;
	@_ =  ( 1..$_ );
	1;
PERL

is
	n( `$^X $lib -d:DbInteract='s 2;\$_;\@_;q' -e '$script'` )
	,$files->{ '$_ not clash' }
	,"Debugger should show user's \@_ and \$_";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t0 {
		$_ =  3;
	}
	$_ =  1;
	2;
PERL

is
	n( `$^X $lib -d:DbInteract='s;t0();\$_;q' -e '$script'` )
	,$files->{ 'save context of $_' }
	,"Evaluating user's code should keep globals intact";



($script =  <<'PERL') =~ s#^\t##gm;
	eval { 1/0; };
	print $@;
PERL

is
	nn( `$^X $lib -d:DbInteract='go 2;\$\@;e \$\@;s' -e '$script'` )
	,$files->{ 'keep $@' }
	,"Do not change exception message (\$@) at user's script";



__DATA__
@@ anb
-e:0002    $a <=> $b
1
2
123
@@ ab context
-e:0004  } qw/ 1 2 3 4 /;
3
4
1 - 23 - 4
@@ $_ not clash
-e:0001  $_ =  7;
-e:0003  1;
7
1 2 3 4 5 6 7
@@ save context of $_
-e:0004  $_ =  1;
-e:0005  2;
3
1
@@ keep $@
-e:0001  eval { 1/0; };
-e:0002  print $@;
Illegal division by zero at ...

"Illegal division by zero at ...
Illegal division by zero at ...
