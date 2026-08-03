package DB;

# NOTICE: Subroutines compiled at DB:: package are not debuggable

## Manual
# Get general information about frames.
# In void context instead print them.
sub f {
	my( $count, $lvl ) =  @_;
	$count //=  -1; # infinite

	my @frames;
	local $" =  ' - ';
	while( $count--  &&  (my @frame =  caller( ++$lvl )) ) {
		push @frames, [ @frame[0..3] ];
	}


	# Print frames in void context:
	!defined wantarray
		or return \@frames;

	DB::say( "@$_" )   for @frames;
	return;
}



# Returns the number of frames without debugger
sub fcount {
	my $count; my $db =  0;

	if( $db +=  DB::state( 'dbcall' ) ) {
		$db++   while (caller( $count++ ))[3] ne 'DB::dbcall';
	}
	$count++   while caller( $count );

	return $count -$db;
}



# Dump the specified amount of frames with all frame information
sub frames {
	my( $count ) =  @_;
	$count ||=  -1; # infinite

	my $dbcall =  DB::state( 'dbcall' );
	my $frames =  [];
	my $lvl =  0;
	if( ( !defined $_[0] || $_[0] != 0 )  &&  $dbcall ) {
		$lvl++   while (caller( $lvl ))[3] ne 'DB::dbcall';
		$lvl +=  $dbcall;
	}

	while( $count--  &&  (my @frame =  caller( $lvl++ )) ) {
		if( my $args =  eval{ [ @DB::args ] } ) {
			push @$frames, [ [ @DB::args ], @frame ];
		}
		else {
			push @$frames, [ [ 'FREED' ], @frame ];
		}
	}

	return $frames;
}



# Just put DB::stop in any debugger command and execution will be stopped there
# The same as DB::x but for debuggable code (without is_debuggeable flag enabled)
# inside debugger.
sub stop {
	# return   unless !@_  ||  $_[0];
	return $^D|= (1<<30), $DB::single =  1   if !@_;
	return $^D|= (1<<30), $DB::single =  1   if $DB::x{ $_[0] };
}



=item x

DB::x       -- break script execution
DB::x 'str' -- break script execution if $DB::x{ 'str' } is true

The second form is useful in cases when some code is executed frequently. Thus we
can not put DB::x expression there. So we write 'DB::x = "str"' there. This means
execution will be stopped there only when '$DB::x{str} = 1' expression will be
reached in a main script.

=cut

our %x;
sub x {
	# return   unless !@_  ||  $_[0]
	return $DB::single =  1   if !@_;
	return $DB::single =  1   if $DB::x{ $_[0] };
}



sub xx {
	return $DB::stop   =  1   if !@_;
	return $DB::single =  1   if $DB::stop  &&  $_[0];
}



# Display the important flags about current state of debugger.
sub flags {
	return "s:$DB::single t:$DB::trace i:$DB::instance c:".@DB::state;
}



# Reflect the fact that we started a debug debugger session.
sub start_dd {
	$DB::instance++;
	DB::say( "\e[91mDebug debugger\e[0m " .DB::flags )   if DB::state( 'ddd' );
	DB::state( xx => 1 );
}



# Reflect the fact that we stopped a debug debugger session.
sub finish_dd {
	DB::state( xx => undef );
	DB::say( "\e[91mFinish debugger debugging\e[0m " .DB::flags )   if DB::state( 'ddd' );
	$DB::instance--;
}



# Colorise text using ESCape sequences.
sub _c {
	return shift   if $ENV{ DEBUGGER_NO_COLOR };
	my( $str, $color ) =  @_;
	return "\e[${color}m$str\e[0m";
}



## External
sub deparse {
	my( $coderef ) =  shift;
	require B::Deparse;
	return $coderef   unless ref $coderef;
	return B::Deparse->new("-p", "-sC")->coderef2text( $coderef );
}



# use Sub::Identify qw/ sub_name /;
use B qw/ svref_2object /;

# Returns subroutine name from its CODE ref.
sub sub_name {
    my $r = shift;
    return $r unless ref $r;
    return $r unless my $cv =  svref_2object( $r );
    # return $r unless $cv->isa( 'B::CV' );
    # and my $gv = $cv->GV
    #          ;
    return $r unless $cv->isa( 'B::CV' );
    my $gv = $cv->GV;
    my $name = '';

    # https://github.com/Perl/perl5/issues/13187#issuecomment-544047320
    if ((!$gv or ref($gv) eq 'B::SPECIAL') and $cv->can('NAME_HEK')) {
        $name =  "HEK $gv: >" .$cv->NAME_HEK ."<";
    }
    #$gv   or return;

    # if( ref $gv eq 'B::SPECIAL' ) {
    #   warn "$r";
    #   warn "What is this: $name -- $r\n";
    #   Devel::Peek::Dump( $r );
    #   Devel::Peek::Dump( $cv );
    #   Devel::Peek::Dump( $gv );
    #
    #   my $lvl;
    #   local $" =  ' - ';
    #   while( my @frame =  caller( ++$lvl ) ) {
    #       warn "@frame[0..3]\n";
    #   }
    #   warn "X\n";
    #   warn "Deparsed: ". deparse( $r ) ."\n";
    #   warn "Z\n";
    # }
    # if( ref $gv eq 'B::SPECIAL' ) {
    #  warn "$r"   if $DB::z;
    # }
    if ( $gv->can('STASH')  &&  (my $st = $gv->STASH) ) {
        $name = $st->NAME . '::';
    }else{
            # warn 'NO STASH';
    }
    my $n = $gv->can('NAME')  &&  $gv->NAME;
    if ( $n ) {
        $name .= $n;
        if ( $n eq '__ANON__' ) {
            $name .= ' defined at ' . $gv->FILE . ':' . $gv->LINE;
            $name =~ s/$DB::options{ pwd }/~/;
        }
    }else{
        # warn 'NONAME'
    }

    # if( $DB::z ) {
    #   $DB::z =  1;
    #   warn "NAME: $name\n";
    #   warn "Deparsed: ". deparse( $r ) ."\n"   if ref $gv eq 'B::SPECIAL';

    #   my $lvl;
    #   local $" =  ' - ';
    #   while( my @frame =  caller( ++$lvl ) ) {
    #       warn "@frame[0..3]\n";
    #   }
    # }

    return $name;
}



my $old;
## Data display routines
# Returns correct indentaion for the current level of nesting.
sub indentation { return (shift//'  ')x(shift//$DB::instance) }


sub say {
	if( (!defined $old  ||  $old != @DB::state)  &&  DB::state( 'ddd' ) &16 ) {
		unshift @_, DB::_c( "Level: i:$DB::instance c:" .scalar @DB::state, 91 );
		$old =  @DB::state;
	}

	local $" =  "\n" .indentation( undef );
	print $DB::OUT indentation( undef )."@_" =~ s/^(\h+)$//mgr;  #/
	print $DB::OUT "\n";
}


# Converts all undef values to a configured visible representation.
sub vis_undef {
	my @res =  map{ ref $_ ? ref $_ : $_ } map{ $_ // $DB::options{ undef } } @_;
	return @res   if wantarray;
	# return ''     unless @res; # Should we display empty string if there is no result?
	return (pop @res) // $DB::options{ undef };
}

sub warn {
	unshift @_, '';
	local $" =  indentation( undef, $DB::instance );
	print $DB::ERR "@_\n";
}

use Sub::Metadata qw/ mutate_sub_is_debuggable /;
mutate_sub_is_debuggable( \&_c, 0 );
mutate_sub_is_debuggable( \&say, 0 );
mutate_sub_is_debuggable( \&warn, 0 );
mutate_sub_is_debuggable( \&vis_undef, 0 );
mutate_sub_is_debuggable( \&dumper, 0 );
mutate_sub_is_debuggable( \&indentation, 0 );
mutate_sub_is_debuggable( \&DB::source, 0 );
mutate_sub_is_debuggable( \&DB::file, 0 );
mutate_sub_is_debuggable( \&DB::can_break, 0 );


my %seen;
my %gexclude =  (
	_result_source     =>  1,
	_relationship_data =>  1,
	related_resultsets =>  1,
	config             =>  1,
);

# TODO: document parameters. It is unclear what is going on here...
my %filters =  (
	'Mojolicious::Routes' => { children => 1,  hidden => 1,  reverse => 1, cache => 1, hiding => 1, },
	'Mojolicious::Routes::Route' => { children => 1, parent => 1, 'Mojolicious::Routes::Route' => 1 },
	'Mojolicious::Routes::Match' => { root => 1, },
	'Mojolicious::Controller' => { app => 1, match => 1, tx => 1, },
	'Mojo::Exception' => { frames => 1, },
	'JSON::Validator::OpenAPI::Mojolicious' => { schema => 1, schemas => 1, },
	'Mojolicious::Plugin::OpenAPI' => { validator => 1, route => 1, _default_response => 1, },
	'DBIx::Class::ResultSource::Table' => 1,
	'Mojolicious::Validator' => 1,
	'Mojolicious::Static' => 1,
	'@' => [qw/ DBIx::Class::ResultSet Mojolicious::Controller Mojolicious DateTime::TimeZone DateTime DbMapper::DataSet /],
	'DBIx::Class::ResultSet' => { _attrs => 1 },
	'Mojolicious::Validator' => { checks => 1, filters => 1, },
	'Mojolicious' => { types => 1,  plugins => 1, renderer => 1 },
	'DateTime' => sub{ my $dt= shift; "$dt " .$dt->{tz}{name} },
	'SQL::Translator::Schema::Table' => sub{ shift->name },
	'Mojo::Exception' => sub{ shift ."" },
	'DBIx::Class::Storage::DBI::Cursor' => { args => 1,  storage => 1, },
	'Mojolicious::Renderer' => { handlers => 1, tempaltes => 1, },
	'DateTime::TimeZone' => { rules => 1, spans => 1, last_observance => 1, },
	'DBIx::Class::ResultSource::View' => { schema => 1, },
	# 'SQL::Translator::Schema::Table' => { schema => 1, },
	'DbMapper::DataSet' => { mapper => 1 },
);
# { package X;

# We need a custom dumper to not retrigger debugger when calling dumpers at user's space.
use Scalar::Util qw/ reftype blessed /;
sub DB::dumper {
	my( $data, $level, $path ) =  @_;
	%seen =  ()   if !defined $level;
	$level //=  $DB::instance;
	$path  //=  'TOPIC';

	my %exclude =  %gexclude;

	my $result =  '';
	my $type;
	if( $DB::options{ DumpObjects }  &&  (my $class =  blessed( $data )) ) {
		$result .= "$class ";
		my $ignore =  $filters{ $class }; # Check inherited classes later
		$ignore //=  $filters{ (grep{ $class->isa($_) } $filters{'@'}->@*)[0] };
		if( $ignore ) {
			# Use provided sub to dump data
			return $result .$ignore->( $data )   if ref $ignore eq 'CODE';

			# Ignore only deep objects
			return $result .'IGNORED'   if !ref $ignore  &&  $level;
			@exclude{ keys %$ignore } =  values %$ignore   if ref $ignore eq 'HASH';
		}

		$type =  reftype( $data );
	}
	else {
		$type =  ref $data;
	}


	if( $type ) {
		exists $seen{ $data } ? return $seen{ $data } : ($seen{ $data } =  $path);
	}

	if( $type eq 'HASH' ) {
		$result .=  '{';
		$result .=  join '', map{
			my $value =  $exclude{$_} ? "IGNORED" :
				$exclude{ ref $data->{$_} } ? ref( $data->{$_} ) ." IGNORED" :
					DB::dumper( $data->{$_}, $level +1, "$path\{$_\}" );

			"\n" .'  'x($level+1) ."$_ => $value,"
		} sort keys %$data;
		$result .=  ((keys %$data)?"\n" .'  'x($level):'') ."}";

		# TODO: Implement 'expand_tied' flag
		my $tied =  tied %$data;
		$result .= ' (tied to ' .(ref $tied) .')'   if $tied;
	}
	elsif( $type eq 'ARRAY' ) {
		$result .=  '[';
		$result .=  join '', map{
			my $value =  $exclude{ ref $data->[$_] } ? ref( $data->[$_] ) ." IGNORED" :
				DB::dumper( $data->[$_], $level +1, "$path\[$_\]" );
			"\n" .'  'x($level+1) ."$value,"
		} keys @$data;
		$result .=  (@$data?"\n" .'  'x($level):'') ."]";

		my $tied =  tied @$data;
		$result .= ' (tied to ' .(ref $tied) .')'   if $tied;
	}
	elsif( $type eq 'CODE' ) {
		$result .=  '&' .DB::sub_name( $data );
		# $result .=  " #$data";
	}
	elsif( $type eq 'SCALAR' ) {
		$result .=  '\\' .DB::dumper( $$data, $level +1, "$path SCALAR" );

		my $tied =  tied $$data;
		$result .= ' (tied to ' .(ref $tied) .')'   if $tied;
	}
	elsif( $type eq 'REF' ) {
		$result .=  '\\' .DB::dumper( $$data, $level +1, "$PATH REF" );

		my $tied =  tied $$data;
		$result .= ' (tied to ' .(ref $tied) .')'   if $tied;
	}
	elsif( $type eq 'REGEXP' ) {
		$result .=  "$data";
	}
	else {
		# TODO: use DB::vis_undef
		$result .=  defined $data ? ($type ? $type : $data) : 'undef';
	}

	return $result;
} #}



# Returns information about a caller sub, file, line and debugger type
sub who {
	my $lvl =  @_ ? 0 : 1;
	my( $p, $f, $l, $callee ) =  (caller($lvl))[0..3];
	my( $caller ) =  (caller($lvl+1))[3];
	# $caller =~ s/^$p\:://; # TODO? Implement flag to hide package name

	$callee =  shift   if @_;
	# $callee =~ s/^$p\:://;

	my $pwd =  $DB::options{ pwd };
	$f      =~ s/$pwd/~/;
	$caller =~ s/$pwd/~/;

	if( $caller =~ m/$f/  &&  $caller =~ m/$l/ ) {
		$f =  $l =  '';
	}


	# Highlight <-- by different color if we are inside debugger?
	my $arrow =  $lvl ? '<--' :
	   $DB::state[$DB::instance]{ dbcall } ? DB::_c("<--", '2;93' ) : DB::_c( "<--", 32 )
	;
	return DB::_c($callee,'2;33') ." $arrow $caller ($f:$l)";
}



## Event utilities
our $events;
sub on    { push @{ $events->{ $_[0] } },                $_[1]   and return $_[1] }
sub RT_on { push @{ DB::state( 'events' )->{ $_[0] } },  $_[1]   and return $_[1] }



sub once {
	my( $name, $cb ) =  @_;

	my $wrapper; $wrapper = sub {
		DB::unsubscribe( $name => $wrapper );
		# TODO? Leak? Undefine $wrapper here.
		$cb->( @_ );
	};

	return DB::on( $name => $wrapper );
}



sub subscribers { $events->{ shift() } //= [] }



sub unsubscribe {
	my( $name, $cb ) =  @_;

	$events->{ $name } =  [ grep { $cb ne $_ } @{ $events->{$name} } ];
	delete $events->{ $name }   unless @{ $events->{$name} };

	return;
}



sub RT_unsubscribe {
	my( $name, $cb ) =  @_;

	my $events =  DB::state( 'events' );
	$events->{ $name } =  [ grep { $cb ne $_ } @{ $events->{$name} } ];
	delete $events->{ $name }   unless @{ $events->{$name} };

	return;
}



# There two types of events: global and per debugger instance.
sub events {
	my( $name ) =  @_;

	my $db_events =  DB::state( 'events' );
	return   unless $events->{ $name }  ||  $db_events->{ $name };

	my @list;
	$events->{ $name }      and push @list, @{ $events->{ $name } };
	$db_events->{ $name }   and push @list, @{ $db_events->{ $name } };

	return @list;
}



# Handlers are kind of subroutines which are called via 'process' interface.
sub emit {
	my $name =  shift;
	my $ddd  =  DB::state( 'ddd' ) &32;

	my @list =  DB::events( $name )   or do{
		$ddd  &&  DB::say "No subscribers for $name";
		return;
	};

	if( $ddd ) {
		DB::say "Event subscriber(s) for $name:";
		DB::say " ". DB::sub_name( $_ ) for @list;
		DB::say;
	}


	if( defined wantarray ) {
		my @res;
		# TODO: $_ is global. In this form there could be some issues with stored
		# context from @DB::args. $_ is linked to en array item and could modified
		# inside subroutine. Thus stored value will be changed and therefor restored
		# to a wrong value.
		push @res, process( $_, @_ )   for @list;

		return @res;
	}


	process( $_, @_ )   for @list;
	return;
}



# Receives CODE and arguments. Runs that code with specified arguments and returns
# a result as a scalar value.
# I. Result could be another CODE, which will be executed with the original arguments.
#    ^^^ This is useful, when CODE understands it can not process and wants to fallback
# to something more reasonable.
# II. Result could be ARRAY. In this case the first item is CODE and the rest items will
#     be passed to it as arguments after some processing depending on its type. If it is:
# a) CODE/ARRAY -- call 'process' recursively.
# b) scalar -- evaluate its value at user's context.

# 'process' is called from 'emit'. No other places which uses this sub at the moment.
sub process {
	my $ddd =  DB::state( 'ddd' ) &32;

	my $handler =  shift;
	my( $code, @args, @result );
	while( my $htype =  ref $handler ) {
		if( $htype eq 'ARRAY' ) {
			# We will run $code with list of $expr which are evaluated in user context first
			$code =  shift @$handler;
			@args =  ();

			DB::say "Got list of expressions to evaluate in usercontext:", "@$handler"   if $ddd;
			for my $expr ( @$handler ) {
				# $expr should be simple string. If it is not it is special
				push @args, ref $expr ? process( $expr ) : [ DB::eval( $expr ) ];
				$args[-1] =  bless { error => $@ }, 'DB::Error'   if $@;
			}
		}
		elsif( $htype eq 'CODE' ) {
			$code =  $handler;
			@args =  @_;
		}
		else {
			die "Handler type should be ARRAY or CODE";
		}

		if( DB::state( 'dd' ) ) {
			DB::say 'Force debugging for next call: $single =  1'   if $ddd;
			$DB::single =  1;
		}
		else {
			DB::say 'Disable debugging for next call: $single =  0'   if $ddd;
			$DB::single =  0;
		}

		if( $ddd ) {
			my $args =  @args ? DB::dumper( \@args ) : '';
			DB::say "Run callback: " .DB::_c(sub_name( $code ),'2;33') ."( $args )";
		}


		@result  =  $code->( @args );
		$handler =  $result[0];
	}

	DB::say "Processing is finished: " .sub_name( $code )   if $ddd;
	return $handler; # @handler
}



# Returns TRUE if $filename was compiled/evaled
# The file is evaled if it looks like (eval 34)
# But this may be changed by #file:line. See ??? for info
sub DB::file {
	my $filename =  shift // DB::state( 'file' );
	$filename =~ s/^_<//;
	$filename =~ s/^~/$DB::options{ pwd }/;

	# NOTICE differences:
	# https://stackoverflow.com/q/56273829/4632019
	# https://stackoverflow.com/q/56270222/4632019
	# https://stackoverflow.com/q/56260910/4632019
	# https://stackoverflow.com/q/56273425/4632019
	no strict 'refs';
	unless( exists ${ 'main::' }{ "_<$filename" } ) {
		DB::warn "File '$filename' is not compiled yet";

		return;
	}

	return ${ $::{"_<$filename"} }
}



# Returns source for $filename
# r 1 test of cmd_r; s;s;DB::state( dd => 1 );r 1;r;r;r;r;r;r;r;r
# And we stop in DB::source, but we do not, because it has is_debaggable == 0
sub DB::source {
	my $filename =  DB::file( shift );
	return []   unless defined $filename;

	no strict 'refs';
	return \@{ $::{"_<$filename"} };
}



# Returns TRUE if we can set trap for $file:line
sub DB::can_break {
	my( $file, $line ) =  @_;

	($file, $line) =  split ':', $file
		unless defined $line;

	$file =  DB::file( $file );
	return   unless defined $file;

	no strict 'refs';
	return $line >= 0  &&  $line <= $#{ $::{"_<$file"} }
		&& ${ $::{"_<$file"} }[ $line ] != 0;

	# http://perldoc.perl.org/perldebguts.html#Debugger-Internals
	# Values in this array are magical in numeric context:
	# they compare equal to zero only if the line is not breakable.
}



# Returns list of compiled files/evaled strings
# The $filename for evaled strings looks like (eval 34)
sub DB::sources {
	no strict 'refs';
	return grep{ m/^_</ } keys %{ 'main::' };
}



# Returns hashref of traps for $filename keyed by $line
sub DB::traps {
	my $filename =  DB::file( shift );
	return {}   unless defined $filename;

	# Keep list of $filenames we perhaps manipulate traps
	$DB::_tfiles->{ $filename } =  1;


	no strict 'refs';
	*DB::dbline =  $main::{ "_<$filename" }; # WORKRAOUND RT#119799 (see commit)

	return \%{ $::{"_<$filename"} };
}



# Returns the location where $subname is defined in the form:
# filename:startline-endline
sub DB::location {
	my $sub =  shift;

	return   unless $sub;
	$sub =  DB::sub_name( $sub )   if ref $sub; # The $sub maybe a CODEREF
	die "Can not find subroutine location for $sub"   if ref $sub;

	# The subs from DB::* are not placed here. Why???
	# A? Maybe they are placed after module loaded?
	return $DB::sub{ $sub };
}



# Returns list of all defined not ANON subs.
# We may limit the list by supplying regex
sub DB::subs {
	return keys %DB::sub   unless @_;

	my $re =  shift;
	return grep { /$re/ } keys %DB::sub;
}



package DB::Utils;

use strict;
use warnings;



sub import {
	my $pkg =  caller;
	my( $class, @events ) =  @_;

	no strict 'refs';
	@events =  map{ /^on_(.*)$/?$1:() } keys %{ "main::${pkg}::" }
	   unless @events;

	# Subscribe each event handler to event
	for my $event ( @events ) {
		my $sub =  ${ "main::${pkg}::" }{ "on_$event" }; #IT: check that glob has sub ref
		DB::on( $event => \&$sub );
	}
}


1;
