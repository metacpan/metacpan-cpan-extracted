{ package Logger; sub info{ shift; warn @_, "\n" } }

package DB::Hooks::TraceVariable;

use strict;
use warnings;

# use Log::Log4perl;
my $logger = bless {}, 'Logger';


use DB::Commands qw/ set_command get_command stay /;
sub cmd_trace_variable {
	my( $var ) =  shift;

	return [ stay {},
		"tie $var, 'DB::Hooks::TraceVariable', \\$var, desc => '$var'",
	]
}

set_command tv => \&cmd_trace_variable, 'trace_variable';



our $lvl = 0;

sub TIESCALAR {
	my $class =  shift;
	my $data  =  shift;

	local $lvl =  1;
	my %info =  @_;
	$logger->info( access_msg(
		$info{ desc }, '&defined'
	));


	my $obj = { data => $$data, @_ };

	return bless $obj, 'ScalarHistory';
}

sub TIEHASH {
	my $class =  shift;
	my $data  =  shift;

	local $lvl =  1;
	my %info   =  @_;
	$logger->info( access_msg(
		$info{ desc }, '&defined'
	));


	my $obj;
	@{ $obj->{ data } }{ keys %$data } =  values %$data;
	@$obj{ keys %info }                =  values %info;

	return bless $obj, 'HashHistory';
}

sub TIEARRAY {
	my $class =  shift;
	my $data  =  shift;

	local $lvl =  1;
	my %info   =  @_;
	$logger->info( access_msg(
		$info{ desc }, '&defined'
	));

	my $obj;
	@{ $obj->{ data } }[ keys @$data ] =  values @$data;
	@$obj{ keys %info }                =  values %info;

	return bless $obj, 'ArrayHistory';
}



sub access_msg {
	my( $name, $old, $new ) =  @_;

	my( $sub ) =  (caller(2+$lvl))[3] // '(main)';
	my( $file, $line ) =  (caller(1+$lvl))[1,2];
	$old =  DB::vis_undef( ref_name( $old ) );
	$new =  @_ > 2 ? ' -> ' .DB::vis_undef( ref_name( $new ) ) : '';

	# return "Access from $sub ($file:$line) to \e[36m$name\e[0m($DB::instance) value: \e[3;37m$old$new\e[0m";
	return DB::_c( $name, 36 ).": ".DB::_c( "$old$new", '3;37' ).' '.DB::_c( "at $file:$line", '1;90' );
}


sub ref_name {
	map{ ref $_ eq 'REF' || ref $_ eq 'SCALAR' ? '\\'.(tied $$_)->{ desc } : $_ } @_;
	# map{ ref $_ ? '\\'.(tied $$_)->{ desc } : $_ } @_;
}



{
	package             # hide the package from the PAUSE indexer
		ScalarHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';

	*{ ScalarHistory::access_msg } =  \&DB::Hooks::TraceVariable::access_msg;
	*{ ScalarHistory::ref_name   } =  \&DB::Hooks::TraceVariable::ref_name;


	sub FETCH {
		my $self =  shift;

		my $name =  $self->{ desc };
		$logger->info( access_msg( $name, $self->{ data } ) );

		return $self->{ data };
	}


	sub STORE {
		my( $self, $value ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg( $name, $self->{ data }, $value ) );

		$self->{ data } =  $value;
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}

{
	package             # hide the package from the PAUSE indexer
		HashHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';

	*{ HashHistory::access_msg } =  \&DB::Hooks::TraceVariable::access_msg;
	*{ HashHistory::ref_name   } =  \&DB::Hooks::TraceVariable::ref_name;


	sub FETCH {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\{ $key }", $self->{ data }{ $key }
		));

		return $self->{ data }{ $key };
	}


	sub STORE {
		my( $self, $key, $value ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\{ $key }", $self->{ data }{ $key }, $value
		));

		$self->{ data }{ $key } =  $value;
	}


	sub DELETE {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\{ $key }", $self->{ data }{ $key }, '&DELETE'
		));

		delete $self->{ data }{ $key };
	}


	sub CLEAR {
		my( $self ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&()'
		));

		%{ $self->{ data } } =  ();
	}


	sub EXISTS {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		my $exists =  exists $self->{ data }{ $key };
		$logger->info( access_msg(
			"$name\{ $key }", '&'. ($exists?'':'NOT ') .'EXISTS'
		));

		$exists;
	}


	sub FIRSTKEY {
		my( $self ) =  @_;

		keys %{ $self->{ data } };    # reset each() iterator
		each %{ $self->{ data } };
	}


	sub NEXTKEY {
		my( $self, $lastkey ) =  @_;

		each %{ $self->{ data } };
	}


	sub SCALAR {
		my $self =  shift;

		scalar %{ $self->{ data } };
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}


{
	package             # hide the package from the PAUSE indexer
		ArrayHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';

	*{ ArrayHistory::access_msg } =  \&DB::Hooks::TraceVariable::access_msg;
	*{ ArrayHistory::ref_name   } =  \&DB::Hooks::TraceVariable::ref_name;


	sub FETCH {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\[ $index ]", $self->{ data }[ $index ]
		));

		return $self->{ data }[ $index ];
	}


	sub STORE {
		my( $self, $index, $value ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\[ $index ]", $value
		));

		$self->{ data }[ $index ] =  $value;
	}


	sub DELETE {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			"$name\[ $index ]", '&DELETE'
		));

		delete $self->{ data }[ $index ];
	}


	sub CLEAR {
		my( $self ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&()'
		));

		@{ $self->{ data } } =  ();
	}


	sub EXISTS {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		my $exists =  exists $self->{ data }[ $index ];
		$logger->info( access_msg(
			"$name\[ $index ]", '&'. ($exists?'':'NOT ') .'EXISTS'
		));

		$exists;
	}


	sub FETCHSIZE {
		my $self =  shift;
		my $count =  scalar @{ $self->{ data } };

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&FETCHSIZE '.$count
		));

		$count;
	}


	sub STORESIZE {
		my( $self, $count ) =  @_;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&STORESIZE ' .$count
		));

		$#{ $self->{ data } } =  $count;
	}


sub PUSH {
		my $self =  shift;

		local $" =  ' | ';
		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&PUSH'." @{[ ref_name( @_ ) ]}"
		));

		push @{ $self->{ data } }, @_;
	}


	sub POP {
		my $self =  shift;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&POP'
		));

		pop @{ $self->{ data } };
	}


	sub SHIFT {
		my $self =  shift;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&SHIFT'
		));

		shift @{ $self->{ data } };
	}


	sub UNSHIFT {
		my $self =  shift;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&UNSHIFT'
		));

		unshift @{ $self->{ data } }, @_;
	}


	sub SPLICE {
		my $self =  shift;

		my $name =  $self->{ desc };
		$logger->info( access_msg(
			$name, '&SPLICE'
		));

		splice @{ $self->{ data } }, @_;
	}


	sub EXTEND {
		# Do nothing
		return;
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}

1;


__END__
Test cases:
my $x; $x=1; print $x;
my( $x, @y );
my $x = 1;
my( @y, $x ); push @y, \$x; # @y: &PUSH \$x

For case when sub called without G_DISCARD: G_NOARGS | G_VOID
In this case print "XCCC" willbe called twice
my $x;my @y;
print "XCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n", "\n"x100;
my $z;
__END__
