package Danga::Socket::Redis;
use strict;
use IO::Socket;
use Danga::Socket::Callback;

=head1 NAME

Danga::Socket::Redis - An asynchronous redis client.

=head1 SYNOPSIS

    use Danga::Socket::Redis;

    my $rs = Danga::Socket::Redis->new ( connected => \&redis_connected );
 
    sub redis_connected {
        $rs->set ( "key", "value" );
        $rs->get ( "key", sub { my ( $self, $value ) = @_; print "$key = $value\n" } );
        $rs->publish ( "newsfeed", "Twitter is down" );
        $rs->hset ( "hkey", "field", "value" );
        $rs->hget ( "hkey", "field", sub { my ( $self, $value ) = @_ } );
        $rs->subscribe ( "newsfeed", sub { my ( $self, $msg ) = @_ } );
    }
    
Danga::Socket->EventLoop;


=head1 DESCRIPTION

An asynchronous client for the key/value store redis. Asynchronous
basically means a method does not block. A supplied callback will be
called with the results when they are ready.

=head1 USAGE



=head1 BUGS

Only started, a lot of redis functions need to be added.


=head1 SUPPORT

dm @martinredmond
martin @ tinychat.com

=head1 AUTHOR

    Martin Redmond
    CPAN ID: REDS
    Tinychat.com
    @martinredmond
    http://Tinychat.com/about.php

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.06';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(set get 
		      hset hget
		      publish subscribe);
    %EXPORT_TAGS = ();
}

our $AUTOLOAD;

our %cmds = (
	     exists => { args => 1 },
	     del => { args => 1 },
	     type => { args => 1 },
	     keys => { args => 1 },
	     randomkey => { args => 0 },
	     rename => { args => 2 },
	     renamenx => { args => 2 },
	     dbsize => { args => 0 },
	     expire => { args => 2 },
	     ttl => { args => 2 },
	     select => { args => 1 },
	     move => { args => 2 },
	     flushdb => { args => 0 },
	     flushall => { args => 0 },

	     set => { args => 2 }, 
	     get => { args => 1 }, 
	     getset => { args => 2 }, 
	     mget => { margs => 1 }, 
	     setnx => { args => 2 }, 
	     setex => { args => 3 }, 
	     mset => { margs => 1 }, 
	     msetnx => { margs => 1 }, 
	     incr => { args => 1 }, 
	     incrby => { args => 1 }, 
	     decr => { args => 1 }, 
	     decrby => { args => 1 }, 
	     append => { args => 2 }, 
	     substr => { args => 3 }, 

	     rpush => { args => 2 }, 
	     lpush => { args => 2 }, 
	     llen => { args => 1 }, 
	     lrange => { args => 2 }, 
	     ltrim => { args => 3 }, 
	     lindex => { args => 2 }, 
	     lset => { args => 3 }, 
	     lrem => { args => 3 }, 
	     lpop => { args => 1 }, 
	     rpop => { args => 1 }, 
	     blpop => { margs => 1 }, 
	     brpop => { margs => 1 }, 
	     rpoplpush => { args => 2 }, 

	     sadd => { args => 2 }, 
	     srem => { args => 2 }, 
	     spop => { args => 1 }, 
	     smove => { args => 3 }, 
	     scard => { args => 1 }, 
	     sismember => { args => 2 }, 
	     sinter => { margs => 1 }, 
	     sinterstore => { margs => 1 }, 
	     sunion => { margs => 1 }, 
	     sunionstore => { margs => 1 }, 
	     sdiff => { margs => 1 },

	     smembers => { args => 1 }, 
	     srandmember => { args => 1 }, 
	     sdiffstore => { margs => 1 }, 
	     
	     zadd => { args => 3 }, 
	     zrem => { args => 2 }, 
	     zincrby => { args => 3 }, 
	     zrank => { args => 2 }, 
	     zrevrank => { args => 2 }, 
	     zrange => { args => 3 }, 
	     zrevrange => { args => 3 }, 
	     zrangebyscore => { args => 3 }, 
	     zcount => { args => 4 }, 
	     zcard => { args => 1 }, 
	     zscore => { args => 0 }, 
	     zremrangebyrank => { args => 0 }, 
	     zremrangebyscore => { args => 0 }, 
	     zunionstore => { args => 0 }, 

	     hset => { args => 3 }, 
	     hget => { args => 2 }, 
	     hmget => { margs => 1 }, 
	     hmset => { margs => 1 }, 
	     hincrby => { args => 0 }, 
	     hexists => { args => 2 }, 
	     hdel => { args => 2 }, 
	     hlen => { args => 1 }, 
	     hkeys => { args => 1 }, 
	     hvals => { args => 1 }, 
	     hgetall => { args => 1 }, 

	     subscribe => { args => 1 },
	     unsubscribe => { args => 1 },
	     publish => { args => 2 },

	     # * MULTI/EXEC/DISCARD/WATCH/UNWATCH  Redis atomic transactions 
	     sort => { args => 0 }, 
	     save => { args => 0 }, 
	     bgsave => { args => 0 }, 
	     lastsave => { args => 0 }, 
	     shutdown => { args => 0 }, 
	     bgrewriteaof => { args => 0 }, 

	     info => { args => 0 }, 
	     monitor => { args => 0 }, 
	     slaveof => { args => 0 }, 
	     config => { args => 0 }, 
	    );

1;

sub new {
  my ($class, %args) = @_;
  my $self = bless ({}, ref ($class) || $class);
  my $peeraddr = "localhost:6379";
  $peeraddr = "$args{host}:6379" if $args{host};
  $peeraddr = "localhost:$args{port}" if $args{port};
  $peeraddr = "$args{host}:$args{port}" if $args{host} && $args{port};
  my $sock = IO::Socket::INET->new (
				    PeerAddr => $peeraddr,
				    Blocking => 0,
				   );
  $self->{connected_cb} = $args{connected} if $args{connected};
  my $a = '';
  $self->{rs} = Danga::Socket::Callback->new
    (
     handle => $sock,
     context => { buf => \$a, rs => $self },
     on_read_ready => sub {
       my $self = shift;
       my $bref = $self->read ( 1024 * 8 );
       my $buf = $self->{context}->{buf};
       if ( $bref ) {
	 $buf = length ( $$buf ) > 0 ? 
	   \ ($$buf . $$bref) :
	     $bref;
	 $self->{context}->{buf} = $self->{context}->{rs}->do_buf ( $buf );
       } else {
	 $self->close ( 'read' );
	 die "reading from redis";
       }
     },
     on_write_ready => sub {
       my $self = shift;
       $self->watch_write ( 0 );
       my $cb = delete $self->{context}->{rs}->{connected_cb};
       &$cb ( $self->{context}->{rs} ) if $cb;
     }
    );
  return bless $self;
}

sub do_buf {
  my ( $self, $buf ) = @_;
  my $o;
  while ( 1 ) {
    ( $buf, $o ) =
      $self->redis_read ( $buf );
    last unless $o;
    $self->redis_process ( $o );
  }
  return $buf;  # there may be some stuff left over from this read
}

sub redis_read {
  my ( $self, $bref ) = @_;
  return ( $bref, undef ) if length ( $$bref ) == 0;
  my $nlpos = index ( $$bref, "\n" );
  return ( $bref, undef ) if $nlpos == -1;
  my $tok = substr ( $$bref, 0, 1 );
  if ( $tok eq ':' ) {
    my $n = substr ( $$bref, 1, $nlpos - 2 );
    my $r = substr ( $$bref, $nlpos + 1 );
    return ( \$r, { type => 'int', value => $n } );
  } elsif ( $tok eq '-' ) {
    my $e = substr ( $$bref, 1, $nlpos - 2 );
    my $r = substr ( $$bref, $nlpos + 1 );
    return ( \$r, { type => 'error', value => $e } );
  } elsif ( $tok eq '+' ) {
    my $l = substr ( $$bref, 1, $nlpos - 2 );
    my $r = substr ( $$bref, $nlpos + 1 );
    return ( \$r, { type => 'line', value => $l } );
  } elsif ( $tok eq '$' ) {
    my $l = substr ( $$bref, 1, $nlpos - 2 );
    if ( $l == -1 ) {
      my $r = substr ( $$bref, $nlpos + 1 );
      return ( \$r, { type => 'bulkerror' } );
    }
    #	    warn "better check this" if length ( $$bref ) < $nlpos + 1 + $l + 2;
    return ( $bref, undef ) if length ( $$bref ) < $nlpos + 1 + $l + 2;  # need more data
    my $v = substr ( $$bref, $nlpos + 1, $l );
    my $r = substr ( $$bref, $nlpos + $l + 1 + 2 );
    return ( \$r, { type => 'bulk', value => $v } );
  } elsif ( $tok eq '*' ) {
    my $l = substr ( $$bref, 1, $nlpos - 2 );
    if ( $l == -1 ) {
      my $r = substr ( $$bref, $nlpos + 1 );
      return ( \$r, { type => 'multibulkerror' } );
    }
    my $obref = $bref;
    my $r = substr ( $$bref, $nlpos + 1 );
    $bref = \$r;
    my @res;
    while ( $l-- ) {
      my $o;
      ( $bref, $o ) = $self->redis_read ( $bref );
      return $obref unless $o;    # read more?
      push @res, $o;
    }
    return ( $bref, { type => 'bulkmulti', values => \@res } );
  } else {
    die "Danga::Socket::Redis bref", $$bref;
  }
}

sub redis_process {
    my ( $self, $o ) = @_;
    my $v = $o->{values};
    if ( $v && $v->[0]->{value} eq 'message' ) {
      if ( my $cb = $self->{subscribe}->{callback}->{$v->[1]->{value}} ) {
	&$cb ( $self, $v->[2]->{value}, $o );
      }
      return;
    }
    my $cmd = shift @{$self->{cmdqueue}};
    if ( my $cb = $cmd->{callback} ) {
	if ( $o->{type} eq 'bulkerror' ) {
	    &$cb ( $self, $o );
	} else {
	    if ( $o->{type} eq 'bulkmulti' ) {
		my  @vs = map { $_->{value} } @{$o->{values}};
		&$cb ( $self, \@vs, $o );
	    } else {
		&$cb ( $self, $o->{value}, $o );
	    }
	}
    }
}

sub DESTROY {}

sub AUTOLOAD {
  my $self = shift;
  my $cc = $AUTOLOAD;
  $cc =~ s/.*:://;
  $cc = lc $cc;

  my $opts = $Danga::Socket::Redis::cmds{$cc};
  return undef unless $opts;

  my $cmd = { type => $cc };
  if ( $opts->{args} > 0 ) {
    push @{$cmd->{args}}, shift for 1 .. $opts->{args};
    $cmd->{callback} = shift;
    $cmd->{options} = shift;
  } elsif ( $opts->{margs} == 1 ) {
    my $last = pop @_;
    if ( ref $last eq 'HASH' ) {
      $cmd->{options} = $last;
      $last = pop @_;
    }
    if ( ref $last eq 'CODE' ) {
      $cmd->{callback} = $last;
    } else {
      push @_, $last;
    }
    @{$cmd->{args}} = @_;
  }
  if ( $cc eq 'subscribe' && $cmd->{callback} && $cmd->{args} &&
       scalar @{$cmd->{args}} == 1 ) {
    $self->{subscribe}->{callback}->{$cmd->{args}->[0]} = $cmd->{callback};
  }
  $self->redis_send ( $cmd );
}

sub redis_send {
  my ( $self, $cmd ) = @_;
  $cmd->{args} = [] unless ref $cmd->{args} eq 'ARRAY';
  unless ( $cmd->{type} eq 'subscribe' ) {
    push @{$self->{cmdqueue}}, $cmd;
  }
  my $send = "*" . ( scalar ( @{$cmd->{args}} ) + 1 ) . "\r\n" .
    "\$" . length ( $cmd->{type} ) . "\r\n" .
      $cmd->{type} . "\r\n";
  foreach ( @{$cmd->{args}} ) {
    $send .= "\$" . length ($_) . "\r\n$_\r\n";
  }
  $self->{rs}->write ( $send );
}
