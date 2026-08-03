package DB::Commands;

use strict;
use warnings;

#To work with color
my $hl;
my $lm;
my $is_exists = `ldconfig -p | grep -c libsource-highlight`;
chomp($is_exists);

sub highlighting {
    require Syntax::SourceHighlight;

    $hl = Syntax::SourceHighlight->new('esc.outlang');
    $lm = Syntax::SourceHighlight::LangMap->new();
    $hl->setStyleFile('esc256.style');

    return 1;
}

our $lines_before =  10;
our $lines_after  =  20;
my $highlight     =  $is_exists && !$ENV{ DEBUGGER_NO_COLOR } ? highlighting() : 0;

sub DB::say;
sub import {
	my $pkg      =  shift;
	my $call_pkg =  caller;

	no strict "refs";
	*{"$call_pkg\::$_"} = \&{"$pkg\::$_"}   foreach @_;
}



sub set_command {
	my( $name, $handler, $alias ) =  @_;

	$DB::commands->{ $name  } =  $handler;
	$DB::commands->{ $alias } =  $handler   if length $alias;
}



sub get_command {
	my( $name ) =  @_;

	return $DB::commands->{ $name };
}



# Purpose of this sub is to display error if it occurs OR call supplied CODE
# Then return command to continue interaction with user
sub stay(&) {
	my $stay =  DB::state( 'stay' ) // get_command 'interact';
	my $code =  shift;
	return sub{
		$code->( @_ ), return $stay
		   unless ref $_[0] eq 'DB::Error';

		DB::say DB::_c( "ERROR", "1;31" ) .": $_[0]";
		return $stay;
	}
}



sub interact {
	my $str =  get_command( 'next_command' )->() // exit;
	# DB::say DB::_c("Your input: ") .$str;

	while(1) {
		my $result =  run( $str );
		return   unless defined $result;    # Stop interaction if we got undef
		return $result   if ref $result;    # Restart processing based on command result

		# Continue interaction if we got TRUE value
		return get_command 'interact'   unless $result == 0;

		# $result == 0: Command not found, so
		# Run default command for not recognised string

		$str =~ m/^\s/?
			($str =  "mdump $str"):
			($str =  "vars $str");
	}
}



sub run {
	my $str =  shift // return;

	my( $cmd, $args_str ) =  $str =~ m/^\s*([\w.]+)(?:\s+(.*?)\s*)?$/;
	$args_str //=  '';


	unless(  $cmd  &&  exists $DB::commands->{ $cmd } ) {
		# print $DB::OUT "No such command: '$str'\n"   if DB::state( 'ddd' );
		return 0;
	}

	# The command should return defined value to keep interaction
	# print $DB::OUT "Start to run '$cmd' command\n"   if DB::state( 'ddd' );
	my $result =  eval { $DB::commands->{ $cmd }( $args_str ) };
	# print $DB::OUT "Command '$cmd' done\n"   if DB::state( 'ddd' );
	do{ DB::say "'$cmd' " .DB::_c( "command died", '1;31' ). ": $@"; return -1; }   if $@;

	return $result;
}



sub _dd {
	require Data::Dump;
	Data::Dump::pp( @_ );
}



## Debugger commands
# filename/number; delimeter ':' ; linenumber
my $file_line =  qr/(?:(.+):)?(\d+|\.)/;

# Evaluate data in user's context and display it in various format
sub cmd_mdump {
	my( $expr ) =  @_;

	return [ stay {
		DB::say DB::_c( "Evaluation result: ", 32 )   if DB::state( 'ddd' ) &1;
		DB::say $_   for map{ DB::dumper( $_ ) } @{ $_[0] };
	}
		,$expr
	];
}



sub cmd_print_eval {
	my( $expr ) =  @_;

	return [ stay {
		DB::say DB::_c( "Evaluation result: ", 32 )   if DB::state( 'ddd' ) &1;
		DB::say join "\n", DB::vis_undef( @{ $_[0] } );
	}
		,$expr
	];
}



sub cmd_dump_eval {
	my( $expr ) =  @_;

	return [ stay {
		DB::say DB::_c( "Dump result: ", 32 )   if DB::state( 'ddd' ) &1;
		DB::say _dd( @{ $_[0] } );
	}
		,length $expr ? $expr : DB::state( 'last_eval' ) // ''
	];
}



sub cmd_ddp {
	my( $expr ) =  @_;
	require DDP;

	return [ stay {
		DB::say DDP::np( @{ $_[0] } );
	}
		,length $expr ? $expr : DB::state( 'last_eval' ) // ''
	];
}



sub cmd_peek {
	my( $expr ) =  @_;
	require Devel::Peek;

	return [ stay {
		Devel::Peek::Dump( @{ $_[0] } );
	}
		,length $expr ? $expr : DB::state( 'last_eval' ) // ''
	];
}



# Main set of commands
sub cmd_quit {
	DB::state( single => 0 );
	exit;
}



sub cmd_step {
	if( shift =~ m/^(\d+)$/ ) {
		my $steps_left =  $1;
		DB::state( 'step.steps_left' => \$steps_left );

		my $handler; $handler =  sub {
			return 0   if --$steps_left;

			DB::state( 'step.steps_left' => undef );
			DB::unsubscribe( stop => $handler );

			# Is not required: single step is based on fact that $DB::single is TRUE
			# DB::state( single => 1 );
			return 1;
		};

		DB::on( stop => $handler );
	}

	DB::state( single => 1 );
	return;
}



sub cmd_stepover {
	my( $steps_left ) =  shift =~ m/^(\d+)$/;
	$steps_left //=  1;
	DB::state( 'stepover.steps_left' => \$steps_left );


	## Count frames
	my $frames_left =  0;
	my $increase =  sub{
		DB::state( 'stepover.frames_left' => \$frames_left ) ,DB::state( single => 0 )
		   if $frames_left == 0;

		$frames_left++;
		return;
	};
	my $decrease =  sub{
		$frames_left--;
		DB::state( 'stepover.frames_left' => undef )         ,DB::state( single => 2 )
		   if $frames_left == 0;

		return;
	};
	my $goto =  sub{
		# .at_frame has DB::DB frame (breakpoint line), DB::goto has no DB::DB frame, so +1
		$increase->()   if DB::state( 'stepover.at_frame' ) == 1+ DB::fcount;

		return;
	};


	my $finish; $finish =  sub {
		# use and require silently add frame into callstack
		# So we check here that we stopped at same or upper level
		# TODO? Should we check $is_require flag to ensure (eval)?
		# Use of uninitialized value in numeric lt (<) at ...
		return   if DB::state( 'stepover.at_frame' ) < DB::fcount;

		return 0   if --$steps_left;

		DB::state( 'stepover.at_frame'  => undef );
		DB::state( 'stepover.steps_left' => undef );
		DB::unsubscribe( call   =>  $increase );
		DB::unsubscribe( return =>  $decrease );
		DB::unsubscribe( goto   =>  $goto     );
		DB::unsubscribe( stop   =>  $finish  );

		# Is not required: step over is based on fact that $DB::single is TRUE
		# DB::state( single => 2 );
		return 1;
	};

	DB::state( 'stepover.at_frame' => DB::fcount );
	DB::on( call   =>  $increase );
	DB::on( return =>  $decrease );
	DB::on( goto   =>  $goto     );
	DB::on( stop   =>  $finish  );

	DB::state( single => 2 );
	return;
}



sub cmd_stepout {
	my( $frames_left, $sharp ) =  shift =~ m/^(\d+)(\^)?$/;

	if( $sharp ) {
		my $frames;
		1 while caller( 12 + $frames++ );
		$frames_left =  $frames -$frames_left +1;

		return -2   if $frames_left <= 0; # Do nothing for unexisting frame
	}

	my $leave_chain =  defined $frames_left;
	$frames_left //=  1;

	DB::state( 'stepout.frames_left' => \$frames_left );


	## Count frames
	my $increase =  sub{
		DB::state( single => 0 )   if $leave_chain  &&  !$frames_left;
		$frames_left++;
		return
	};
	my $decrease =  sub{
		return   if --$frames_left;

		# When we return from sub we do not know what would be next:
		# 1. We stopped at outer frame
		# 2. We stopped at another call
		DB::state( single => 1 );
		return;
	};
	my $finish; $finish =  sub {
		DB::state( 'stepout.frames_left' => undef );
		DB::unsubscribe( call   => $increase );
		DB::unsubscribe( return => $decrease );
		DB::unsubscribe( stop   => $finish   );
		# TODO: IT: make test to that checks no subscribers are left after command is finished

		return 1;
	};

	DB::on( call   => $increase );
	DB::on( return => $decrease );
	DB::on( stop   => $finish   );


	DB::state( single => 0 );
	return;
}



sub cmd_continue {
	if( length $_[0] ) {
		get_command( 'breakpoint' )->( "$_[0]!" );
	}

	DB::state( single => 0 );
	return;
}



sub breakpoint_handler {
	my( $trap, $f, $l ) =  @_;

	if( $trap->{ once } ) {
		delete $trap->{ once };
		delete DB::traps( $f )->{ $l }   if !keys %$trap;
		return 1;
	}

	return 0   if $trap->{ disabled }  ||  !exists $trap->{ condition };

	# Evaluate condition at user's context and just return obtained result
	return [ sub{
		return 0   unless my $result =  shift->[0];


		DB::say "Stopped by breakpoint condition: "
		   .$trap->{ condition } .' --> ' .DB::dumper $result
		   if DB::state( 'verbose.commands' );

		return 1;
	}
		,$trap->{ condition }
	];
}



sub breakpoint_on_call_handler {
	my( $subname ) =  @_;

	my $traps =  DB::state( 'breakpoint.subs' );

	my $by;
	if(
		$traps->{ $subname }    # not disabled (value is TRUE)

		|| grep{                # OR
			$by =  $_;
			$traps->{ $_ }      # not disabled
				&&              #   &&
			$subname =~ m/$_/   # current sub match
		} keys %$traps
	) {
		DB::say "Stopped by subroutine condition: " .$by
		   if DB::state( 'verbose.commands' );
		DB::state( single => 1 ); # Stop on next OP
	}

	return;
}



sub list_breakpoints {
	my( $file ) =  @_;
	my $list =  [];


	# First display traps in the current file
	DB::say "Breakpoints:";
	for my $source ( $file, grep { $_ ne $file } keys %$DB::_tfiles ) {
		my $traps =  DB::traps( $source );
		next   unless keys %$traps;

		push @$list, $source;
		DB::say $#$list ." $source";

		for( sort{ $a <=> $b } keys %$traps ) {
			DB::say sprintf "  %-3d%s %s"
				, $_
				, exists $traps->{ $_ }{ once   } ? '!'
					: exists $traps->{ $_ }{ disabled  }? '-' : ':'
				, $traps->{ $_ }{ condition } // ''; # One time trap has no condition

			DB::say sprintf "  %-3d%s %s", $_, 'a', $traps->{ $_ }{ action }
				if exists $traps->{ $_ }{ action };


			DB::warn "The breakpoint at $_ is not breakable"
				if $traps->{ $_ } == 0;
		}
	}
	DB::state( 'files.list', $list );


	DB::say "Stop on subs:";
	my $traps =  DB::state( 'breakpoint.subs' );

	DB::say ' ' .($traps->{ $_ } ? ' ' : '-') ."$_"
		for keys %$traps;

	DB::say '';

	return 1;
}



sub cmd_breakpoint {
	my( $sign, $f, $l, $subname, $condition, $once ) =
		shift =~ m/^([-+])?(?:${file_line}|([\w:\$\^\|]+|&\d*))(?:\s+(.+?))??\s*(!)?$/;

	if( length $subname ) {
		if( $subname =~ m/^&(\d*)$/ ) {
			my $frame =  defined $1 ? $1 : DB::state( 'list.level' )//0;
			$subname  =  DB::sub_name( sub_at_frame( $frame ) );
		}

		return -1   unless $subname; # main:: is not subroutine

		## Set breakpoint
		my $bs =  DB::state( 'breakpoint.subs' );
		unless( $bs ) {
			$bs =  {};
			DB::on( call => \&breakpoint_on_call_handler );
			DB::on( goto => \&breakpoint_on_call_handler );
		}
		$bs->{ $subname } =  $sign  &&  $sign eq '-' ? 0 : 1;
		DB::state( 'breakpoint.subs' => $bs );

		DB::say "$subname is added to breakpoint list"
		   if DB::state( 'verbose.commands' );

		return 1;
	}


	$f =  current_file( $f );
	return list_breakpoints( $f )   unless defined $l;

	# FIX: Get line at current level
	$l =  DB::state( 'line' )   if $l eq '.';

	unless( DB::can_break( $f, $l ) ) {
		DB::warn( "$f:$l -- This line is not breakable" );
		# Set breakpoint in any case. This is usefull when you edit file
		# and want to add traps to those new lines
		# return -1;
	}


	## Set breakpoint
	my $trap =  \DB::traps( $f )->{ $l };

	# TODO: Move trap from/into $traps into/from $disabled_traps
	# This will allow us to not trigger DB::DB if trap is disabled
	$$trap->{ disabled } =  1     if $sign  &&  $sign eq '-';
	delete $$trap->{ disabled }   if $sign  &&  $sign eq '+';

	if( $once ) { # One time breakpoint has not condition
	   $$trap->{ once } =  1;
	}
	else {
	   $$trap->{ condition } =  $condition   if defined $condition;
	   $$trap->{ condition } //=  1; # Trigger always by default
	};


	return 1;
}



sub action_handler {
	my( $trap, $f, $l ) =  @_;

	defined $trap->{ action }   or return;

	DB::state( stay => 0 ); # Prevent command from interaction with user
	my $result =  run( $trap->{ action } );
	DB::state( stay => undef );
	return $result   unless defined $result  &&  $result == 0;

	# Evaluate action at user's context and return zero to not stop execution
	return [ sub{ 0 }, $trap->{ action } ];
}



sub cmd_action {
	my( $f, $l, $expr ) =  shift =~ m/^${file_line}(?:\s+(.*))$/;
	return   unless length $expr;

	$f =  current_file( $f );
	$l =  DB::state( 'line' )   if $l eq '.';


	unless( DB::can_break( $f, $l ) ) {
		DB::warn( "$f:$l -- This line is not breakable" );
		# Set action in any case. This is usefull when you edit file
		# and want to add traps to those new lines
		# return -1;
	}


	## Set action
	my $trap =  \DB::traps( $f )->{ $l };

	$$trap->{ action } =  $expr;


	return 1;
}



sub current_file {
	return DB::state( 'files.current' ) // DB::state( 'file' )
	   unless @_;

	my( $file ) =  @_;
	$file //=  DB::state( 'files.current' ) // DB::state( 'file' );

	my $files =  DB::state( 'files.list' );
	$file =  $files->[ $file ]
	   if $file =~ m/^(\d+)$/  &&  exists $files->[ $file ];

	# TODO? warn if file is not loaded into project

	DB::state( 'files.current', $file );

	return $file;

}



sub cmd_files {
	my( $args, $expr ) =  @_;

	# Set chosen file as current:
	if( $args ne ''  &&  $args =~ /^(\d+)$/ ) {
		DB::say current_file( $args );
		return 1;
	}

	# List available files
	my $cmd_f      =  [];
	my $file_no    =  0;
	my @not_loaded =  map{ "Not loaded: $_" } grep{ !defined $INC{ $_ } } keys %INC;
	for( sort $0, @not_loaded, grep{ defined } values %INC, DB::sources() ) {
	# for( sort $0, keys %$expr ) {
		if( /(?:$args)/ ) {
			push @$cmd_f, $_;
			DB::say $file_no++ ." $_";
		}
	}


	DB::state( 'files.list', $cmd_f );
	1;
}



sub call_points {
	my( $file, $frames ) =  @_;
	$frames //=  DB::frames();

	my $lvl =  0;
	my $lines =  {};
	for( @$frames ) {
		$lines->{ $_->[ 3 ] } //=  $lvl   if $_->[ 2 ] eq $file;
		$lvl++;
	}

	return $lines;
}



sub list_source {
	my( $file, $from, $to ) =  @_;

	# Fix window boundaries
	my $source =  DB::source( $file );
	$from =  0           if $from < 0;        # TODO: testcase; 0 exists if -d
	$to   =  $#$source   if $to > $#$source;  # TODO: testcase

	# The place where to display *cursor*: '>>'
	my $cursor_at =  call_points( $file );


	my $traps  =  DB::traps( $file );
	for my $line ( $from..$to ) {
		next   unless exists $source->[ $line ];

		my $info =  '';
		# Print flags
		if( exists $traps->{ $line } ) {
			$info .=  exists $traps->{ $line }{ action } ? 'a' : ' ';
			$info .=  exists $traps->{ $line }{ once   } ? '!'
				: exists $traps->{ $line }{ disabled  }? '-'
				: exists $traps->{ $line }{ condition }? 'b' : ' ';
		}
		else {
			$info .=  '  ';
		}


		# Print *breakable* and *cursor* marks
		if( defined( my $level =  $cursor_at->{ $line } ) ) {
			if( $level ) {
				if( $level < 10 ) {
					$info .=  DB::_c( "$level>", '2;33' );
				}
				else {
					$info .=  DB::_c( "*>", '2;93' );
				}
			}
			else {
				$info .=  DB::_c( ">>", '2;93' );
			}
		}
		else {
			$info .=  DB::can_break( $file, $line ) ? ' x' : '  ';
		}


		# Print source line number
		$info .=  "$line:";


		# Print source line
		(my $src =  $source->[ $line ]) =~ s/^\t/    /g;
		$src = "$info $src";
		$src =~ s/\s+$//; # Remove whitespaces at EOL

        $src = $highlight ? $hl->highlightString( $src, $lm->getMappedFileName('perl') ) : $src;

        DB::say $src;
	}

	DB::say; # WORKAROUND: Data::Section::Simple: last line always has EOL
}



sub list_file {
	my( $stack, $file, $from, $to ) =  @_;

	if( !defined $stack  &&  !defined $from ) {                      # case: l
		# Just list source at current position
		$from =  DB::state( 'list.line' );
		$from =  defined $from ? $from +$lines_before : DB::state( 'line' );
	}
	elsif( $stack  &&  !defined $file  ||  $from eq '.' ) {
		if( $stack  &&  (my( $sub ) =  $stack =~ m/^-(\D.*)$/) ) {   # case: l -sub
			my $frames =  DB::frames();

			$from =  0;
			while( @$frames ) {
				last   if $frames->[0][4] =~ m/$sub/;
				shift @$frames;
				$from++;
			}

			# Return if not found requested sub at stack
			@$frames  or return 1;

			DB::say( "Found at frame -$from" );
		}

		if( !defined $from ) {                                       # case: l -
			$from =  DB::state( 'list.level' ) +1;
			DB::say "Level: $from"   if $from > 9;
		}

		$from   =  DB::state( 'list.level' ) // 0   if $from eq '.'; # case: l .
		DB::state( 'list.level', $from );

		my $frames =  DB::frames();
		return -2   if $from +1 > @$frames;

		( $file, $from ) =  @{ $frames->[ $from ] }[ 2, 3 ];
		$to    =  $from +$lines_before;
		$from -=  $lines_after;
	}
	elsif( $from eq '0' ) {                                          # case: l 0
		DB::state( 'files.current', undef );
		DB::state( 'list.level', undef );
		$file =  DB::state( 'file' );
		$from =  DB::state( 'line' );
	}
	else {                                                           # case: l f/ile:10
		# file:line are provided we should flush { list.level } (See commit)
		DB::state( 'list.level', undef );
	}

	$file  =  current_file( $file );
	if( !defined $to ) {
		$to    =  $from +$lines_after;
		$from -=  $lines_before;
	}

	DB::say '', $file;  # Print current file unconditionally
	list_source( $file, $from, $to );

	DB::state( 'list.line',  $to +1 );  # continue listing from next line
	return 1;
}



sub list_sub {
	my( $deparse, $eval, $subname ) =  @_;
	return -2   unless defined $subname;

	# 1. List sub by code ref in the variable
	$eval  &&  return [ stay {
		list_sub( $deparse, undef, $_[0][0] );
	}
		,'$' .$subname
	];



	$subname =  DB::state( 'package' ) ."::$subname"
		if !ref $subname  &&  $subname !~ m/::/;

	# 2. Deparse sub
	if( $deparse ) {
		no strict 'refs';
		DB::say DB::sub_name( $subname ) .' '
			.DB::deparse ref $subname ? $subname : \&{ $subname };

		DB::say; # WORKAROUND: Data::Section::Simple: last line always has EOL
		return 1;
	}


	# 3. List sub from source
	my $location =  DB::location( $subname );
	DB::warn "Subroutine $subname is not known"
	   ,return -1   unless defined $location;

	# The location format is 'file:from-to'
	$location =~ m/^(.*):(\d+)-(\d+)$/;
	list_source( $1, $2, $3 );


	return 1;
}



sub sub_at_frame {
	my( $frame ) =  @_;
	$frame //=  DB::state( 'list.level' );
	$frame += 2;

	my $frames =  DB::frames( $frame );
	return   if @$frames < $frame; # We have less frames then requested

	return $frames->[-1][4];
}



sub cmd_list {
	my( $args ) =  @_;

	my @args =  $args =~ m/^(&?)(\$?)([A-Za-z].*)$/;
	return list_sub( @args )   if @args;

	@args =  $args =~ m/^&(\d+)?$/;
	return list_sub( undef, undef, sub_at_frame( @args ) )   if @args;

	# stack mark '-'; optional subname; fileline; range '-number'
	@args =  $args =~ m/^(-(?:\D.*)?)?${file_line}?(?:-(\d+))?$/;
	return list_file( @args );
}



my $trace_format =  {()
	,sub   =>
		'"$fn $package - $subname"'
	,simple   =>
		'"$fn $package - $file:$line - $subname"'
	,oneline   =>
		'"\n$fn $context $subname$args <--  $file:$line"'
	,multiline =>
		'"\n$fn $subname\n    $context $args\n    <--  $file:$line"'
};
sub cmd_stack_trace {
	my( $one, $count, $format ) =  shift =~ m/^(-?)(\d+)(?:\s+(\w*))?$/;
	$format //=  'oneline'; # TODO: Get default format from options

	# TODO: Clarify code
	my $frames =  DB::frames( defined $count? $count +($one?1:0) : () );
	my $fn =  0; # frame number
	if( $one ) { # At this case $count means target frame
		return get_command 'interact'   unless $count <= @$frames;
		$fn     =  $count;
		$frames =  [ $frames->[ $fn ] ];
	}

	for my $frame ( @$frames ) {
		my( $package, $file, $line, $subname ) =  @$frame[1..4];
		$fn =  0   if $subname eq 'DB::DB';
		my $args    =  $frame->[5] ? $frame->[0] : '';
		my $context =  $frame->[6]? '@' : defined $frame->[6]? '$' : ';';

		if( $args ) {
			$args =  join ', ', map{ defined $_ ? $_ : 'undef' } @$args;
			$args = "($args)";
		}

		DB::say eval $trace_format->{ $format };
		DB::say $@   if $@;
		$fn++;
	}

	return get_command 'interact';
}



sub cmd_debug_expr {
	my( $expr ) =  @_;

	$expr =~ s/(?<!\\);/;\n/;
	$expr =~ s/\\;/;/;

	return [ stay {
		DB::say "Debug result: @{ $_[0] }";
	}
		,"\$^D |= (1<<30);\$DB::single= 1;\n" .$expr
	]
}



sub get_stash {
    require 'Package/Stash.pm'; # BUG? spoils DB:: by emacs, dbline

    my $pkg =  DB::state( 'package' );
    my $stash =  Package::Stash->new( $pkg )->get_all_symbols();

    return $stash, $pkg;
}



sub get_variables {
    require 'PadWalker.pm';
    # my @subs;
    # my $package_name =  caller( DB::state( 'level.frame' ) )[0];
    # foreach $name ( keys %{$package_name .'::'} ) {
    #   push @subs, $name;
    # }

    my $my  =  PadWalker::peek_my ( DB::state( 'level.frame' ) );
    my $our =  PadWalker::peek_our( DB::state( 'level.frame' ) );



    return $my, $our;
}



sub cmd_variables {
	my( $level, $flags, $expr ) =
		(' '.shift) =~ m/^(?:\s+-(\d+))?(?:\s+([amogucs]+))?(?:\s+(.*))?$/;

	$flags //=  '';

	my $type =  0;
	for( split '', $flags ) {
		$type |= ~0   if /^a|all$/;
		$type |= 1    if /^m|my$/;
		$type |= 2    if /^o|our$/;
		$type |= 4    if /^g|global$/;
		$type |= 8    if /^u|used$/;
		$type |= 16   if /^c|closured$/;
		$type |= 24   if /^s|sub$/;       #u+c
	}
	$level //=  DB::state( 'list.level' ) // 0;
	$type  ||=  DB::state( 'vars.type' ) || 3   unless $expr;

	my( $frames, $evals ) =  ( 0, 0 );
	{ # Count debugger and eval frames
		my @frame;
		while( @frame =  caller( $frames++ )  and  $frame[3] ne 'DB::DB' ) {
			$evals++   if $frame[3] eq '(eval)';
		}
		while( @frame =  caller( $frames++ )  and  $level-- > 0 ) {
			$evals++   if $frame[3] eq '(eval)';
		}
		$frames--;
	}



	#FIX: When we debug debugger we can not 'go <line>' we always stops at
	#require at third line at PadWalker.pm. Debug who set $DB::state = 1
	require 'PadWalker.pm';

	my $my  =  PadWalker::peek_my ( $frames -$evals );
	my $our =  PadWalker::peek_our( $frames -$evals );

	if( $type & 1 ) {
		# TODO: for terminals which support color show
		# 1. not used variables as grey
		# 2. closed over variables as green or bold
		DB::say "MY:", join( ', ', sort keys %$my );
	}

	if( $type & 2 ) {
		DB::say "OUR:", join( ', ', sort keys %$our );
	}

	if( $type & 4 ) {
		require 'Package/Stash.pm'; # BUG? spoils DB:: by emacs, dbline

		my $pkg =  DB::state( 'package' );
		my $stash =  Package::Stash->new( $pkg )->get_all_symbols();
		# Show only user defined variables
		# TODO? implement verbose flag
		# Probably, as MST adviced, we can capture the contents of 'main'
		# *before* you evaluate anything
		if( $pkg eq 'main' ) {
			for( keys %$stash ) {
				delete $stash->{ $_ }   if /::$/;
				delete $stash->{ $_ }   if /^_</;
				delete $stash->{ $_ }   if /^[\x00-\x1f]/; #Remove $^ variables
			}

			delete @$stash{ qw# STDERR stderr STDIN stdin STDOUT stdout # };
			delete @$stash{ qw# BEGIN INIT CHECK END # };
			delete @$stash{ qw# SIG INC F ] ENV ; > < ) ( $ " _ # }; # a b
			delete @$stash{ qw# - + ` & ' #, 0..99 };
			# BUG? warning still exists despite on explicit escaping of ','
			delete @$stash{ ',', qw# ARGV ARGVOUT . / \\ | # };
			delete @$stash{ qw# % - : = ^ ~ # };
			delete @$stash{ qw# ! @ ? # };
		}
		delete $stash->{ sub }   if $pkg eq 'DB';

		my @globals =  ();
		my %sigil =  ( SCALAR => '$', ARRAY => '@', HASH => '%' );
		for my $key ( keys %$stash ) {
			my $glob =  $stash->{ $key };
			for my $type ( keys %sigil ) {
				next   unless defined *{ $glob }{ $type };
				next   if $type eq 'SCALAR'  &&  !defined $$glob;
				next   if $key =~ /::/;
				push @globals, $sigil{ $type } .$key;
			}
		}

		DB::say "GLOBAL:", join( ', ', sort @globals );
	}

	if( $type & 8 ) {
		DB::say "USED:";

		# First element starts at -1 subscript
		# FIX: When debug debugger and we step over this statement
		# the $sub contain reference to &vars instead of name of last
		# client's sub
		my $sub =  DB::frames( $level +2 )->[-1][4];
		if( !defined $sub ) {
			# TODO: Mojolicious::__ANON__[/home/feelsafe/perl_lib/lib/perl5/Mojolicious.pm:119]
			# convert this to subroutine refs
			DB::say "Not in a sub: $sub";
		}
		else {
			$sub =  \&$sub;
			DB::say join( ', ', sort keys %{ PadWalker::peek_sub( $sub ) } );
		}
	}

	if( $type & 16 ) {
		DB::say "CLOSED OVER:";

		# First elements starts at -1 subscript
		my $sub =  DB::frames( $level +2 )->[-1][4];
		if( !defined $sub ) {
			DB::say "Not in a sub: $sub";
		}
		else {
			$sub =  \&$sub;
			DB::say join( ', ', sort keys %{ (PadWalker::closed_over( $sub ))[0] } );
		}
	}

	if( $expr ) {
		(my $vars, $expr) =  split ';', $expr, 2;                          # We can explicitly define variables by enumerating them
		my @vars =  ( $vars || $expr ) =~ m/([\$\%\@]\w+)/g;               # Extract variables from varlist or expression
		$expr //=  $vars;                                                  # By default just dump variables
		@vars =  keys %{{ map{ $_ => 1 } @vars }};                         # Make vars uniq

		# PadWalder returns references to variables. We derefference them at
		# our subroutine. Thus we able to evalutate @array, %hash variables
		# along with $scalar
		$vars =  ''; my $idx =  0;
		for( @vars ) {
			m/^([\$\@\%])/;
			# TODO: Create alias'es instead of new variables
			$vars .=  "\tmy $_ =  $1\{ \$_[$idx] };\n";
			$idx++;
		}

		# TODO: We should eval at user's package to make sub_name( ... ) work
		# Currently we must use Package::Name::sub_name( ... )
		my $result =  eval "return sub{ \n$vars\t$expr\n }";
		DB::say( $@ ), return 1   if $@;


		# Replace variables by theirs values
		for( @vars ) {
			($_ =  $my ->{ $_ }), next   if exists $my ->{ $_ };
			($_ =  $our->{ $_ }), next   if exists $our->{ $_ };

			DB::say "Variable '$_' does not exists at this scope";
			$_ =  \undef;
		}

		DB::say DB::dumper $_   for $result->( @vars );
	}

	return 1;
}



sub cmd_edit_file {
	die 'You should setup EDITOR environment variable'   unless $ENV{ EDITOR };

	## INIT
	my( $file, $line, $editor_args ) =  shift =~ m/^${file_line}?(.*)$/;
	$editor_args //=  '';

	if( !defined $line ) {
		$line =  DB::state( 'list.line' ) -1;

		# Put cursor at required line. EDITOR should center scroll to this line
		$line -=  defined DB::state( 'list.level' )? $lines_before : $lines_after;
	}
	$line =  ':' .$line;

	$file =  current_file( $file ) =~ s/^~/$DB::options{ pwd }/r;
	$file =  `realpath --relative-base $ENV{ PWD } $file`;# Get relative to current symlink
	$file =~ s/\n$//;                                     # Strip new lines at the end
	$file =  "$ENV{ PWD }/$file"   unless $file =~ m#^/#; # Make path absolute


	## Run editor
	my $cmd =  "$ENV{ EDITOR } $editor_args $file" .($ENV{EDITOR_NOLINE}?'':$line);
	DB::say "Run: $cmd"   if DB::state( 'ddd' ) &1;
	`$cmd`;


	1;
}



set_command interact   => \&interact;

set_command mdump      => \&cmd_mdump;
set_command print_eval => \&cmd_print_eval;
set_command e          => \&cmd_dump_eval, 'eval';
set_command ddp        => \&cmd_ddp;
set_command peek       => \&cmd_peek;
set_command q          => \&cmd_quit, 'quit';
set_command s          => \&cmd_step, 'step';
set_command n          => \&cmd_stepover, 'stepover';
set_command r          => \&cmd_stepout, 'stepout';
set_command go         => \&cmd_continue;
set_command b          => \&cmd_breakpoint, 'breakpoint';
set_command a          => \&cmd_action, 'action';
set_command f          => \&cmd_files, 'files';
set_command l          => \&cmd_list, 'list';
set_command T          => \&cmd_stack_trace;
set_command d          => \&cmd_debug_expr, 'debug';
set_command vars       => \&cmd_variables, 'variables';

set_command ge => \&cmd_edit_file;
set_command z => sub{
	DB::stop;
	DB::traps;
	1;
	return;
};


DB::on( trap => \&breakpoint_handler );
DB::on( trap => \&action_handler );
1;
