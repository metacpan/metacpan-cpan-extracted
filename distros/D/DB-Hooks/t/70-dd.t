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
	sub t1 {
		1;
	}
	t1();
	2;
PERL

# FIX: we should not require last 's' to see '-e:0002    1;'
$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;s;s;s;s;s;r 3;s;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'debug cmd sbs' }
	,"Debug command step-by-step";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;s;n;r 3;s;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'debug cmd step over' }
	,"Debug command with step over";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;s 2;r;r 3;s;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'debug cmd return' }
	,"Debug command with return";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;s 2;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'debug cmd quit' }
	,"Quit from debug debugger command process";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;right();q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'call debugger sub' }
	,"Subroutine call from debugger scope when debug debugger command";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 14;DB::state( "line" );q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'DB::state when dd' }
	,"Get debugger state while debugger debugging";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;nested;$DB::state->[-1]{stack}[-1]{line};q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'prevent position when call' }
	,"Position should not be updated when we call sub while { dd }";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;debug;s 10;1+1;$DB::state->[-1]{stack}[-1]{line};q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'prevent position when calc' }
	,"Position should not be updated when we calcs while { dd }";


$cmds =  'DB::state( debug => "\@interact" );n;n;n;s;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'outer step into' }
	,"Step into at client's scipt after debugger debugging";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;n;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'outer step over' }
	,"Step over at client's scipt after debugger debugging";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;global;global;r;q;';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'wrong global vars usage' }
	,"Debugger commands should not use any global variables";

$cmds =  'DB::state( debug => "\@interact" );n;n;n;right_global;right_global;r;q;';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'global vars usage' }
	,"Debugger globals per instance";


$cmds =  'DB::state( debug => "\@push_frame" );s;n;s;s 2;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'step into at debugger' }
	,"Step into at debugger";

$cmds =  'DB::state( debug => "\@push_frame" );s;n;n;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'step over at debugger' }
	,"Step over at debugger";

$cmds =  'DB::state( debug => "\@push_frame" );s;n;s;r;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'return s' }
	,"Return from debugger. 's' command";

$cmds =  'DB::state( debug => "\@push_frame" );n;n;s;r;r;q';
is
	nl( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'return n' }
	,"Return from debugger. 'n' command";



__DATA__
@@ debug cmd sbs
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
xxx/DbInteract.pm:XXXX    nested();
xxx/DbInteract.pm:XXXX    2;
xxx/DbInteract.pm:XXXX    printf $DB::OUT "%s at %s:%s\n"
1 at -e:4
xxx/DbInteract.pm:XXXX    3;
xxx/DbInteract.pm:XXXX    4;
-e:0002    1;
@@ debug cmd step over
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
xxx/DbInteract.pm:XXXX    nested();
1 at -e:4
xxx/DbInteract.pm:XXXX    4;
-e:0002    1;
@@ debug cmd return
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
xxx/DbInteract.pm:XXXX    2;
1 at -e:4
xxx/DbInteract.pm:XXXX    4;
-e:0002    1;
@@ debug cmd quit
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
xxx/DbInteract.pm:XXXX    2;
@@ call debugger sub
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
scope
@@ DB::state when dd
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
1 at -e:4
xxx/DbInteract.pm:XXXX    3;
4
@@ prevent position when call
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
1 at -e:4
3
62
@@ prevent position when calc
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
xxx/DbInteract.pm:XXXX    1;
2
62
@@ outer step into
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
-e:0002    1;
@@ outer step over
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
-e:0005  2;
@@ wrong global vars usage
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
1
2
@@ global vars usage
-e:0004  t1();
@interact
xxx/Commands.pm:XXXX    my $handler =  shift;
xxx/Commands.pm:XXXX    my $dbg =  $handler->{ context }; # This is better
xxx/Commands.pm:XXXX    my $str =  $dbg->get_command();
xxx/Commands.pm:XXXX    return   unless defined $str;
1
1
@@ step into at debugger
-e:0004  t1();
@push_frame
xxx/DebugHooks.pm:XXXX      no warnings 'void';
xxx/DebugHooks.pm:XXXX      test();
xxx/DebugHooks.pm:XXXX    1;
xxx/DebugHooks.pm:XXXX      3;
-e:0002    1;
@@ step over at debugger
-e:0004  t1();
@push_frame
xxx/DebugHooks.pm:XXXX      no warnings 'void';
xxx/DebugHooks.pm:XXXX      test();
xxx/DebugHooks.pm:XXXX      3;
-e:0002    1;
@@ return s
-e:0004  t1();
@push_frame
xxx/DebugHooks.pm:XXXX      no warnings 'void';
xxx/DebugHooks.pm:XXXX      test();
xxx/DebugHooks.pm:XXXX    1;
xxx/DebugHooks.pm:XXXX      3;
-e:0002    1;
@@ return n
-e:0004  t1();
@push_frame
xxx/DebugHooks.pm:XXXX      no warnings 'void';
xxx/DebugHooks.pm:XXXX      test();
xxx/DebugHooks.pm:XXXX    1;
xxx/DebugHooks.pm:XXXX      3;
-e:0005  2;
