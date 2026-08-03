package DB::Hooks::Remote;

# You still need to use DB::Hooks::Terminal in conjunction with this module
# PERL5DB="use DB::Hooks qw'::Terminal ::Remote'"

use strict;
use warnings;



# We can not track DB::Commands loading if 'use' it before DB::Hooks
use DB::Commands qw/ set_command get_command run /;
# Commands should be available immediately. This is important when
# we are debugging at CT: when DB is in process of loading
BEGIN {
	set_command next_command =>  \&fetch_command;
}


# We should define utility subs first...
## IO::Async stuff
# global DATA
my $loop;
my $stream;



my $ti =  0;
sub tinfo {
	return " - $$ ($loop) w:" .uwsgi::worker_id();
}


# event handlers
sub handle_write_eof {
	die "Write error: >>@_<<";
}


sub handle_write_error {
	die "Write error: >>@_<<";
}


# TODO: Need to check. Because of eof does not seen until write the event is not
# occour until write handle is closed
sub handle_closed {
	$DB::OUT =  \*STDOUT;
	undef $stream;
	my $time =  localtime();
	warn "$time Session closed";
}


sub read_command {
	my( $self, $buffref, $eof ) =  @_;

	warn 'New Command: ' .$$buffref   if length $$buffref;


	if( $$buffref =~ s/^(.*?)\r?(\n)// ) {
		warn "\nThis is the thread (RC): " .tinfo() ."\n\n"   if $ti;

		$$buffref = "$1$2$$buffref"   unless defined &readline( "$1$2" );

		return 0;
	}

	warn "Text '$$buffref' is left in buffer"   if $$buffref;

	if( $eof ) {
		warn "TTYIN EOF";
		$self->close_when_empty();
	}

	return 0;
}


sub start_dbg_session {
	if( defined $stream ) {
		$_[0]->write( "Debugging session is attached already\n" );
		$_[0]->close_when_empty();
		return;
	}


	warn "New client connected";
	( $stream ) =  @_;

	$stream->configure(
		close_on_read_eof =>  1
		,on_read          =>  \&read_command
		,on_write_eof     =>  \&handle_write_eof
		,on_write_error   =>  \&handle_write_error
		,on_closed        =>  \&handle_closed
		,autoflush        =>  1
		,write_all        =>  1
	);

	$loop->add( $stream );
	$DB::OUT =  $stream->read_handle();

	if( $ti ) {
		my $str =  "This is the thread (Start): " .tinfo() ."\n";
		$stream->write( $str );
		warn $str;
	}
}


sub listen {
	my( $loop ) =  @_;

	$loop->listen(
		# family =>  'unix',
		# path   =>  'file.sock',
		family   =>  'inet',
		socktype =>  'stream',
		host     =>  '127.0.0.1',
		service  =>  $ENV{ DBG_PORT }  || 9001,
		on_resolve_error =>  sub { die "Cannot resolve - $_[1] <<< @_\n"; },
		on_listen_error  =>  sub { die "Cannot listen  - $_[1] <<< @_\n"; },
		on_listen        =>  sub {
			my( $s ) =  @_;

			warn "listening on: " .$s->sockhost . ':' .$s->sockport;
			warn "\nThis is the thread(Listen): " .tinfo()   if $ti;
		},

		# This sub is invoked for each new incoming connection
		on_stream =>  \&start_dbg_session,
	);
}

use IO::Async::Loop;
$loop =  IO::Async::Loop->new;


my $dbg_buffer;
sub readline {
	# set
	if( @_ ) {
		return   if defined $dbg_buffer;

		return( $dbg_buffer =  shift )
	}


	# get
	while( !defined $dbg_buffer ) {
		if( $stream ) {
			$stream->invoke_event( 'on_read', \$stream->{ readbuff } );
			last   if defined $dbg_buffer;
		}

		$loop->loop_once();
	}


	my $result =  $dbg_buffer;
	undef $dbg_buffer;
	return $result;
}
# END OF IO::Async stuff



my $last_command;
BEGIN{ $last_command =  '' }
sub fetch_command {
	print $DB::OUT "\n\e[2;96m", DB::indentation( 'D', $DB::instance +1 ) ,"BG>\e[0m";

	my $command =  &readline();
	chomp $command;

	return $last_command   unless length $command;

	return $last_command =  $command;
}


&listen( $loop );
$loop->loop_once( 0 );

1;
