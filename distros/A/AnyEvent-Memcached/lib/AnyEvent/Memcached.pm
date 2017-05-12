package AnyEvent::Memcached;

use 5.8.8;

=head1 NAME

AnyEvent::Memcached - AnyEvent memcached client

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use AnyEvent::Memcached;

    my $memd = AnyEvent::Memcached->new(
        servers => [ "10.0.0.15:11211", "10.0.0.15:11212" ], # same as in Cache::Memcached
        debug   => 1,
        compress_threshold => 10000,
        namespace => 'my-namespace:',

        # May use another hashing algo:
        hasher  => 'AnyEvent::Memcached::Hash::WithNext',

        cv      => $cv, # AnyEvent->condvar: group callback
    );

    $memd->set_servers([ "10.0.0.15:11211", "10.0.0.15:11212" ]);

    # Basic methods are like in Cache::Memcached, but with additional cb => sub { ... };
    # first argument to cb is return value, second is the error(s)

    $memd->set( key => $value, cb => sub {
        shift or warn "Set failed: @_"
    } );

    # Single get
    $memd->get( 'key', cb => sub {
        my ($value,$err) = shift;
        $err and return warn "Get failed: @_";
        warn "Value for key is $value";
    } );

    # Multi-get
    $memd->get( [ 'key1', 'key2' ], cb => sub {
        my ($values,$err) = shift;
        $err and return warn "Get failed: @_";
        warn "Value for key1 is $values->{key1} and value for key2 is $values->{key2}"
    } );

    # Additionally there is rget (see memcachedb-1.2.1-beta)

    $memd->rget( 'fromkey', 'tokey', cb => sub {
        my ($values,$err) = shift;
        $err and warn "Get failed: @_";
        while (my ($key,$value) = each %$values) {
            # ...
        }
    } );

    # Rget with sorted responce values
    $memd->rget( 'fromkey', 'tokey', rv => 'array' cb => sub {
        my ($values,$err) = shift;
        $err and warn "Get failed: @_";
        for (0 .. $#values/2) {
            my ($key,$value) = @$values[$_*2,$_*2+1];
        }
    } );

=head1 DESCRIPTION

Asyncronous C<memcached/memcachedb> client for L<AnyEvent> framework

=head1 NOTICE

There is a notices in L<Cache::Memcached::AnyEvent> related to this module. They all has been fixed

=over 4

=item Prerequisites

We no longer need L<Object::Event> and L<Devel::Leak::Cb>. At all, the dependency list is like in L<Cache::Memcached> + L<AnyEvent>

=item Binary protocol

It seems to me, that usage of binary protocol from pure perl gives very little advantage. So for now I don't implement it

=item Unimplemented Methods

There is a note, that get_multi is not implementeted. In fact, it was implemented by method L</get>, but the documentation was wrong.

=back

In general, this module follows the spirit of L<AnyEvent> rather than correspondence to L<Cache::Memcached> interface.

=cut

use common::sense 2;m{
use strict;
use warnings;
}x;

use Carp;
use AnyEvent 5;
#use Devel::Leak::Cb;

use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::Connection;
use AnyEvent::Connection::Util;
use AnyEvent::Memcached::Conn;
use Storable ();

use AnyEvent::Memcached::Peer;
use AnyEvent::Memcached::Hash;
use AnyEvent::Memcached::Buckets;

# flag definitions
use constant F_STORABLE => 1;
use constant F_COMPRESS => 2;

# size savings required before saving compressed value
use constant COMPRESS_SAVINGS => 0.20; # percent

our $HAVE_ZLIB;
BEGIN {
	$HAVE_ZLIB = eval "use Compress::Zlib (); 1;";
}

=head1 METHODS

=head2 new %args

Currently supported options:

=over 4

=item servers
=item namespace
=item debug
=item cv
=item compress_threshold
=item compress_enable
=item timeout
=item hasher

If set, will use instance of this class for hashing instead of default.
For implementing your own hashing, see sources of L<AnyEvent::Memcached::Hash> and L<AnyEvent::Memcached::Hash::With::Next>

=item noreply

If true, additional connection will established for noreply commands.

=item cas

If true, will enable cas/gets commands (since they are not suppotred in memcachedb)

=back

=cut

sub new {
	my $self = bless {}, shift;
	my %args = @_;
	$self->{namespace} = exists $args{namespace} ? delete $args{namespace} : '';
	for (qw( debug cv compress_threshold compress_enable timeout noreply cas)) {
		$self->{$_} = exists $args{$_} ? delete $args{$_} : 0;
	}
	$self->{timeout} ||= 3;
	$self->{_bucker} = $args{bucker} || 'AnyEvent::Memcached::Buckets';
	$self->{_hasher} = $args{hasher} || 'AnyEvent::Memcached::Hash';

	$self->set_servers(delete $args{servers});
	$self->{compress_enable} and !$HAVE_ZLIB and carp("Have no Compress::Zlib installed, but have compress_enable option");
	carp "@{[ keys %args ]} options are not supported yet" if %args;
	Carp::confess "Invalid characters in 'namespace' option: '$self->{namespace}'" if $self->{namespace} =~ /[\x00-\x20\x7F]/;
	$self;
}

=head2 set_servers

    Setup server list

=cut

sub set_servers {
	my $self = shift;
	my $list = shift;
	my $buckets = $self->{_bucker}->new(servers => $list);
	#warn R::Dump($list, $buckets);
	$self->{hash} = $self->{_hasher}->new(buckets => $buckets);
	$self->{peers} = 
	my $peers = $buckets->peers;
	for my $peer ( values %{ $peers } ) {
		$peer->{con} = AnyEvent::Memcached::Peer->new(
			port      => $peer->{port},
			host      => $peer->{host},
			timeout   => $self->{timeout},
			debug     => $self->{debug},
		);
		# Noreply connection
		if ($self->{noreply}) {
			$peer->{nrc} = AnyEvent::Memcached::Peer->new(
				port      => $peer->{port},
				host      => $peer->{host},
				timeout   => $self->{timeout},
				debug     => $self->{debug},# || 1,
			);
		}
	}
	return $self;
}

=head2 connect

    Establish connection to all servers and invoke event C<connected>, when ready

=cut

sub connect {
	my $self = shift;
	$_->{con}->connect
		for values %{ $self->{peers} };
}

sub _handle_errors {
	my $self = shift;
	my $peer = shift;
	local $_ = shift;
	if ($_ eq 'ERROR') {
		warn "Error";
	}
	elsif (/(CLIENT|SERVER)_ERROR (.*)/) {
		warn ucfirst(lc $1)." error: $2";
	}
	else {
		warn "Bad response from $peer->{host}:$peer->{port}: $_";
	}
}

sub _do {
	my $self    = shift;
	my $key     = shift; utf8::decode($key) xor utf8::encode($key) if utf8::is_utf8($key);
	my $command = shift; utf8::decode($command) xor utf8::encode($command) if utf8::is_utf8($command);
	my $worker  = shift; # CODE
	my %args    = @_;
	my $servers = $self->{hash}->servers($key);
	my %res;
	my %err;
	my $res;

	if ($key =~ /[\x00-\x20\x7F]/) {
		carp "Invalid characters in key '$key'";
		return $args{cb} ? $args{cb}(undef, "Invalid key") : 0;
	}
	if ($args{noreply} and !$self->{noreply}) {
		if (!$args{cb}) {
			carp "Noreply option not set, but noreply command requested. command ignored";
			return 0;
		} else {
			carp "Noreply option not set, but noreply command requested. fallback to common command";
		}
		delete $args{noreply};
	}
	if ($args{noreply}) {
		for my $srv ( keys %$servers ) {
			for my $real (@{ $servers->{$srv} }) {
				my $cmd = $command.' noreply';
				substr($cmd, index($cmd,'%s'),2) = $real;
				$self->{peers}{$srv}{nrc}->request($cmd);
				$self->{peers}{$srv}{lastnr} = $cmd;
				unless ($self->{peers}{$srv}{nrc}->handles('command')) {
					$self->{peers}{$srv}{nrc}->reg_cb(command => sub { # cb {
						shift;
						warn "Got data from $srv noreply connection (while shouldn't): @_\nLast noreply command was $self->{peers}{$srv}{lastnr}\n";
					});
					$self->{peers}{$srv}{nrc}->want_command();
				}
			}
		}
		$args{cb}(1) if $args{cb};
		return 1;
	}
	$_ and $_->begin for $self->{cv}, $args{cv};
	my $cv = AE::cv {
		#use Data::Dumper;
		#warn Dumper $res,\%res,\%err;
		if ($res != -1) {
			$args{cb}($res);
		}
		elsif (!%err) {
			warn "-1 while not err";
			$args{cb}($res{$key});
		}
		else {
			$args{cb}(undef, dumper($err{$key}));
		}
		#warn "cv end";
		
		$_ and $_->end for $args{cv}, $self->{cv};
	};
	$cv->begin;
	for my $srv ( keys %$servers ) {
		for my $real (@{ $servers->{$srv} }) {
			$cv->begin;
			my $cmd = $command;
			substr($cmd, index($cmd,'%s'),2) = $real;
			$self->{peers}{$srv}{con}->command(
				$cmd,
				cb => sub { # cb {
					if (defined( local $_ = shift )) {
						my ($ok,$fail) = $worker->($_);
						if (defined $ok) {
							$res{$real}{$srv} = $ok;
							$res = (!defined $res ) || $res == $ok ? $ok : -1;
						} else {
							$err{$real}{$srv} = $fail;
							$res = -1;
						}
					} else {
						warn "do failed: @_/$!";
						$err{$real}{$srv} = $_;
						$res = -1;
					}
					$cv->end;
				}
			);
		}
	}
	$cv->end;
	return;
}

sub _set {
	my $self = shift;
	my $cmd = shift;
	my $key = shift;
	my $cas;
	if ($cmd eq 'cas') {
		$cas = shift;
	}
	my $val = shift;
	my %args = @_;
	return $args{cb}(undef, "Readonly") if $self->{readonly};
	if ($cas =~ /\D/) {
		carp "Invalid characters in cas '$cas'";
		return $args{cb}(undef, "Invalid cas");
	}

	#warn "cv begin";

	use bytes; # return bytes from length()

	warn "value for memkey:$key is not defined" unless defined $val;
	my $flags = 0;
	if (ref $val) {
		local $Carp::CarpLevel = 2;
		$val = Storable::nfreeze($val);
		$flags |= F_STORABLE;
	}
	my $len = length($val);

	if ( $self->{compress_threshold} and $HAVE_ZLIB
	and $self->{compress_enable} and $len >= $self->{compress_threshold}) {

		my $c_val = Compress::Zlib::memGzip($val);
		my $c_len = length($c_val);

		# do we want to keep it?
		if ($c_len < $len*(1 - COMPRESS_SAVINGS)) {
			$val = $c_val;
			$len = $c_len;
			$flags |= F_COMPRESS;
		}
	}

	my $expire = int($args{expire} || 0);
	return $self->_do(
		$key,
		"$cmd $self->{namespace}%s $flags $expire $len".(defined $cas ? ' '.$cas : '')."\015\012$val",
		sub { # cb {
			local $_ = shift;
			if    ($_ eq 'STORED')     { return 1 }
			elsif ($_ eq 'NOT_STORED') { return 0 }
			elsif ($_ eq 'EXISTS')     { return 0 }
			else                       { return undef, $_ }
		},
		cb => $args{cb},
	);
	$_ and $_->begin for $self->{cv}, $args{cv};
	my $servers = $self->{hash}->servers($key);
	my %res;
	my %err;
	my $res;
	my $cv = AE::cv {
		if ($res != -1) {
			$args{cb}($res);
		}
		elsif (!%err) {
			warn "-1 while not err";
			$args{cb}($res{$key});
		}
		else {
			$args{cb}(undef, dumper($err{$key}));
		}
		warn "cv end";
		
		$_ and $_->end for $args{cv}, $self->{cv};
	};
	for my $srv ( keys %$servers ) {
		# ??? Can hasher return more than one key for single key passed?
		# If no, need to remove this inner loop
		#warn "server for $key = $srv, $self->{peers}{$srv}";
		for my $real (@{ $servers->{$srv} }) {
			$cv->begin;
			$self->{peers}{$srv}{con}->command(
				"$cmd $self->{namespace}$real $flags $expire $len\015\012$val",
				cb => sub { # cb {
					if (defined( local $_ = shift )) {
						if ($_ eq 'STORED') {
							$res{$real}{$srv} = 1;
							$res = (!defined $res)||$res == 1 ? 1 : -1;
						}
						elsif ($_ eq 'NOT_STORED') {
							$res{$real}{$srv} = 0;
							$res = (!defined $res)&&$res == 0 ? 0 : -1;
						}
						elsif ($_ eq 'EXISTS') {
							$res{$real}{$srv} = 0;
							$res = (!defined $res)&&$res == 0 ? 0 : -1;
						}
						else {
							$err{$real}{$srv} = $_;
							$res = -1;
						}
					} else {
						warn "set failed: @_/$!";
						#$args{cb}(undef, @_);
						$err{$real}{$srv} = $_;
						$res = -1;
					}
					$cv->end;
				}
			);
		}
	}
	return;
}

=head2 set( $key, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Unconditionally sets a key to a given value in the memcache.

C<$rc> is

=over 4

=item '1'

Successfully stored

=item '0'

Item was not stored

=item undef

Error happens, see C<$err>

=back

=head2 cas( $key, $cas, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

    $memd->gets($key, cb => sub {
        my $value = shift;
        unless (@_) { # No errors
            my ($cas,$val) = @$value;
            # Change your value in $val
            $memd->cas( $key, $cas, $value, cb => sub {
                my $rc = shift;
                if ($rc) {
                    # stored
                } else {
                    # ...
                }
            });
        }
    })

C<$rc> is the same, as for L</set>

Store the C<$value> on the server under the C<$key>, but only if CAS value associated with this key is equal to C<$cas>. See also L</gets>

=head2 add( $key, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Like C<set>, but only stores in memcache if the key doesn't already exist.

=head2 replace( $key, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Like C<set>, but only stores in memcache if the key already exists. The opposite of add.

=head2 append( $key, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Append the $value to the current value on the server under the $key.

B<append> command first appeared in memcached 1.2.4.

=head2 prepend( $key, $value, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Prepend the $value to the current value on the server under the $key.

B<prepend> command first appeared in memcached 1.2.4.

=cut

sub set     { shift->_set( set => @_) }
sub cas     {
	my $self = shift;
	unless ($self->{cas}) { shift;shift;my %args = @_;return $args{cb}(undef, "CAS not enabled") }
	$self->_set( cas => @_)
}
sub add     { shift->_set( add => @_) }
sub replace { shift->_set( replace => @_) }
sub append  { shift->_set( append => @_) }
sub prepend { shift->_set( prepend => @_) }

=head2 get( $key, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Retrieve the value for a $key. $key should be a scalar

=head2 get( $keys : ARRAYREF, [cv => $cv], [ expire => $expire ], cb => $cb->( $values_hash, $err ) )

Retrieve the values for a $keys. Return a hash with keys/values

=head2 gets( $key, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Retrieve the value and its CAS for a $key. $key should be a scalar.

C<$rc> is a reference to an array [$cas, $value], or nothing for non-existent key

=head2 gets( $keys : ARRAYREF, [cv => $cv], [ expire => $expire ], cb => $cb->( $rc, $err ) )

Retrieve the values and their CAS for a $keys.

C<$rc> is a hash reference with $rc->{$key} is a reference to an array [$cas, $value]

=cut

sub _deflate {
	my $self = shift;
	my $result = shift;
	for (
		ref $result eq 'ARRAY' ? 
			@$result ? @$result[ map { $_*2+1 } 0..int( $#$result / 2 ) ] : ()
			: values %$result
	) {
		if ($HAVE_ZLIB and $_->{flags} & F_COMPRESS) {
			$_->{data} = Compress::Zlib::memGunzip($_->{data});
		}
		if ($_->{flags} & F_STORABLE) {
			eval{ $_->{data} = Storable::thaw($_->{data}); 1 } or delete $_->{data};
		}
		if (exists $_->{cas}) {
			$_ = [$_->{cas},$_->{data}];
		} else {
			$_ = $_->{data};
		}
	}
	return;
}

sub _get {
	my $self = shift;
	my $cmd  = shift;
	my $keys = shift;
	my %args = @_;
	my $array;
	if (ref $keys and ref $keys eq 'ARRAY') {
		$array = 1;
	}
	if (my ($key) = grep { /[\x00-\x20\x7F]/ } $array ? @$keys : $keys) {
		carp "Invalid characters in key '$key'";
		return $args{cb} ? $args{cb}(undef, "Invalid key") : 0;
	}

	$_ and $_->begin for $self->{cv}, $args{cv};
	my $servers = $self->{hash}->servers($keys, for => 'get');
	my %res;
	my $cv = AE::cv {
		$self->_deflate(\%res);
		$args{cb}( $array ? \%res :  $res{ $keys } );
		$_ and $_->end for $args{cv}, $self->{cv};
	};
	for my $srv ( keys %$servers ) {
		#warn "server for $key = $srv, $self->{peers}{$srv}";
		$cv->begin;
		my $keys = join(' ',map "$self->{namespace}$_", @{ $servers->{$srv} });
		$self->{peers}{$srv}{con}->request( "$cmd $keys" );
		$self->{peers}{$srv}{con}->reader( id => $srv.'+'.$keys, res => \%res, namespace => $self->{namespace}, cb => sub { # cb {
			$cv->end;
		});
	}
	return;
}
sub get  { shift->_get(get => @_) }
sub gets {
	my $self = shift;
	unless ($self->{cas}) { shift;my %args = @_;return $args{cb}(undef, "CAS not enabled") }
	$self->_get(gets => @_)
}

=head2 delete( $key, [cv => $cv], [ noreply => 1 ], cb => $cb->( $rc, $err ) )

Delete $key and its value from the cache.

If C<noreply> is true, cb doesn't required

=head2 del

Alias for "delete"

=head2 remove

Alias for "delete"

=cut

sub delete {
	my $self = shift;
	my ($cmd) = (caller(0))[3] =~ /([^:]+)$/;
	my $key = shift;
	my %args = @_;
	return $args{cb}(undef, "Readonly") if $self->{readonly};
	my $time = $args{delay} ? " $args{delay}" : '';
	return $self->_do(
		$key,
		"delete $self->{namespace}%s$time",
		sub { # cb {
			local $_ = shift;
			if    ($_ eq 'DELETED')    { return 1 }
			elsif ($_ eq 'NOT_FOUND')  { return 0 }
			else                       { return undef, $_ }
		},
		cb => $args{cb},
		noreply => $args{noreply},
	);
}
*del   =  \&delete;
*remove = \&delete;

=head2 incr( $key, $increment, [cv => $cv], [ noreply => 1 ], cb => $cb->( $rc, $err ) )

Increment the value for the $key by $delta. Starting with memcached 1.3.3 $key should be set to a number or the command will fail.
Note that the server doesn't check for overflow.

If C<noreply> is true, cb doesn't required, and if passed, simply called with rc = 1

Similar to DBI, zero is returned as "0E0", and evaluates to true in a boolean context.

=head2 decr( $key, $decrement, [cv => $cv], [ noreply => 1 ], cb => $cb->( $rc, $err ) )

Opposite to C<incr>

=cut

sub _delta {
	my $self = shift;
	my ($cmd) = (caller(1))[3] =~ /([^:]+)$/;
	my $key = shift;
	my $val = shift;
	my %args = @_;
	return $args{cb}(undef, "Readonly") if $self->{readonly};
	return $self->_do(
		$key,
		"$cmd $self->{namespace}%s $val",
		sub { # cb {
			local $_ = shift;
			if    ($_ eq 'NOT_FOUND')  { return 0 }
			elsif (/^(\d+)$/)          { return $1 eq '0' ? '0E0' : $_ }
			else                       { return undef, $_ }
		},
		cb => $args{cb},
		noreply => $args{noreply},
	);
}
sub incr { shift->_delta(@_) }
sub decr { shift->_delta(@_) }

#rget <start key> <end key> <left openness flag> <right openness flag> <max items>\r\n
#
#- <start key> where the query starts.
#- <end key>   where the query ends.
#- <left openness flag> indicates the openness of left side, 0 means the result includes <start key>, while 1 means not.
#- <right openness flag> indicates the openness of right side, 0 means the result includes <end key>, while 1 means not.
#- <max items> how many items at most return, max is 100.

# rget ($from,$till, '+left' => 1, '+right' => 0, max => 10, cb => sub { ... } );

=head2 rget( $from, $till, [ max => 100 ], [ '+left' => 1 ], [ '+right' => 1 ], [cv => $cv], [ rv => 'array' ], cb => $cb->( $rc, $err ) )

Memcachedb 1.2.1-beta implements rget method, that allows to look through the whole storage

=over 4

=item $from

the starting key

=item $till

finishing key

=item +left

If true, then starting key will be included in results. true by default

=item +right

If true, then finishing key will be included in results. true by default

=item max

Maximum number of results to fetch. 100 is the maximum and is the default

=item rv

If passed rv => 'array', then the return value will be arrayref with values in order, returned by memcachedb.

=back

=cut

sub rget {
	my $self = shift;
	#my ($cmd) = (caller(0))[3] =~ /([^:]+)$/;
	my $cmd = 'rget';
	my $from = shift;
	my $till = shift;
	my %args = @_;
	my ($lkey,$rkey);
	#$lkey = ( exists $args{'+left'} && !$args{'+left'} ) ? 1 : 0;
	$lkey = exists $args{'+left'}  ? $args{'+left'}  ? 0 : 1 : 0;
	$rkey = exists $args{'+right'} ? $args{'+right'} ? 0 : 1 : 0;
	$args{max} ||= 100;

	my $result;
	if (lc $args{rv} eq 'array') {
		$result = [];
	} else {
		$result = {};
	}
	my $err;
	my $cv = AnyEvent->condvar;
	$_ and $_->begin for $self->{cv}, $args{cv};
	$cv->begin(sub {
		undef $cv;
		$self->_deflate($result);
		$args{cb}( $err ? (undef,$err) : $result );
		undef $result;
		$_ and $_->end for $args{cv}, $self->{cv};
	});

	for my $peer (keys %{$self->{peers}}) {
		$cv->begin;
		my $do;$do = sub {
			undef $do;
			$self->{peers}{$peer}{con}->request( "$cmd $self->{namespace}$from $self->{namespace}$till $lkey $rkey $args{max}" );
			$self->{peers}{$peer}{con}->reader( id => $peer, res => $result, namespace => $self->{namespace}, cb => sub {
				#warn "rget from: $peer";
				$cv->end;
			});
		};
		if (exists $self->{peers}{$peer}{rget_ok}) {
			if ($self->{peers}{$peer}{rget_ok}) {
				$do->();
			} else {
				#warn
					$err = "rget not supported on peer $peer";
				$cv->end;
			}
		} else {
			$self->{peers}{$peer}{con}->command( "$cmd 1 0 0 0 1", cb => sub {
				local $_ = shift;
				if (defined $_) {
					if ($_ eq 'END') {
						$self->{peers}{$peer}{rget_ok} = 1;
						$do->();
					}
					else {
						#warn
							$err = "rget not supported on peer $peer: @_";
						$self->{peers}{$peer}{rget_ok} = 0;
						undef $do;
						$cv->end;
					}
				} else {
					$err = "@_";
					undef $do;
					$cv->end;
				}
			} );
			
		}
	}
	$cv->end;
	return;
}

=head2 incadd ( $key, $increment, [cv => $cv], [ noreply => 1 ], cb => $cb->( $rc, $err ) )

Increment key, and if it not exists, add it with initial value. If add fails, try again to incr or fail

=cut

sub incadd {
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my %args = @_;
	$self->incr($key => $val, cb => sub {
		if (my $rc = shift or @_) {
			#if (@_) {
			#	warn("incr failed: @_");
			#} else {
			#	warn "incr ok";
			#}
			$args{cb}($rc, @_);
		}
		else {
			$self->add( $key, $val, %args, cb => sub {
				if ( my $rc = shift or @_ ) {
					#if (@_) {
					#	warn("add failed: @_");
					#} else {
					#	warn "add ok";
					#}
					$args{cb}($val, @_);
				}
				else {
					#warn "add failed, try again";
					$self->incadd($key,$val,%args);
				}
			});
		}
	});
}

=head2 destroy

Shutdown object as much, as possible, incl cleaning of incapsulated objects

=cut

sub AnyEvent::Memcached::destroyed::AUTOLOAD {}

sub destroy {
	my $self = shift;
	$self->DESTROY;
	bless $self, "AnyEvent::Memcached::destroyed";
}

sub DESTROY {
	my $self = shift;
	warn "(".int($self).") Destroying AE:MC" if $self->{debug};
	for (values %{$self->{peers}}) {
		$_->{con} and $_->{con}->destroy;
	}
	%$self = ();
}

=head1 BUGS

Feature requests are welcome

Bug reports are welcome

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::Memcached
