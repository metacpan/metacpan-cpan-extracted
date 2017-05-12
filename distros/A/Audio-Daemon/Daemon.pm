package Audio::Daemon;

use IO::Socket::INET;
use IO::Select;
use vars qw($VERSION);
$VERSION='0.99Beta';

sub new {
  my ($proto, %arg)  = @_;
  my $class = ref($proto) || $proto;
  my $self = {};
  foreach my $k (qw/Allow Deny Server Port Log Pass/) {
    $self->{$k} = $arg{$k} if (defined $arg{$k});
  }
  # if you feel like changing the main seperator value:
  $self->{sep} = sprintf("%c", 255);
  # or changing the secondary seperator value:
  $self->{subsep} = sprintf("%c", 254);
  bless($self, $class);
  $self->parse_acl('Allow') if ($self->{Allow});
  $self->parse_acl('Deny') if ($self->{Deny});
  return $self;
}

sub debug { my $self = shift; return $self->log('debug', @_); }
sub info { my $self = shift; return $self->log('info', @_); }
sub error { my $self = shift; return $self->log('error', @_); }
sub crit { my $self = shift; return $self->log('crit', @_); }
sub warn { my $self = shift; return $self->log('warn', @_); }

sub log {
  my $self = shift;
  my @caller = caller(2);
  # print "caller line is ".$caller[2]."\n";
  # ($package, $filename, $line, $subroutine, $hasargs,
  #  $wantarray, $evaltext, $is_require, $hints, $bitmask)
  if (defined $self->{Log}) {
    &{$self->{Log}}(@_, @caller);
    return 1;
  } else {
    return 0;
  }
}

sub socket {
  my $self = shift;
  if (ref $self->{socket} eq 'IO::Socket::INET') {
    $self->debug('caller requested existing socket');
    return $self->{socket} 
  }
  my $package = (split '::', (ref $self))[-1];
  if ($package ne 'Client') {
    if (! defined $self->{Port}) {
      $self->crit("No Port defined for socket creation");
      return;
    }
    $self->{socket} = IO::Socket::INET->new(LocalPort => $self->{Port}, Proto=>'udp');
  } else {
    if (! defined $self->{Port} || ! defined $self->{Server}) {
      $self->crit("Need both the Port and Server defined for socket creation");
      return;
    }
    $self->{socket} = IO::Socket::INET->new(PeerPort => $self->{Port}, PeerAddr => $self->{Server}, Proto=>'udp');
  }
  if (! defined $self->{socket}) {
    $self->crit("Failed to initialize Socket: $!");
    return;
  }
  return $self->{socket};
}

# randomze takes in an array reference and returns an array of randomzied indixes
sub randomize {
  my $self = shift;
  my $start = shift;
  return unless (ref $start eq 'ARRAY');
  my @stack;
  my $count = 0;
  while (scalar @$start) {
    my $pick = int (rand() * (scalar @$start));
    push @stack, $start->[$pick];
    splice(@{$start}, $pick, 1);
  }
  $self->{random} = \@stack;
  my @revstack;
  foreach my $t (0..$#stack) {
    $revstack[$stack[$t]] = $t
  }
  $self->{revrandom} = \@revstack;
}

# Generic read routine, should return a hash ref of values read from client.
# will return undef if request comes from unallowed IP.
sub read_client {
  my $self = shift;
  my $socket = $self->socket;
  my ($newmsg, $remote, $iaddr);
  my $from_addr = $socket->recv($newmsg, 1024, undef);
  ($remote->{port}, $iaddr) = sockaddr_in($from_addr);
  $remote->{ip} = inet_ntoa($iaddr);
  # $self->debug("Remote :".$remote->{ip}." : ".$remote->{port});
  
  return unless ($self->allowed_host($remote));
  unless (length $newmsg > 0) {
    $self->warn("Message length was ".(length $newmsg)." returning...");
    return;
  }
  my @a;
  ($remote->{cmd}, @a) = split $self->{sep}, $newmsg;
  $remote->{args} = \@a;
  return $remote;
}

# called from read_client to verify client is an allowed IP
sub allowed_host {
  my $self = shift;
  my $remote = shift;
  my $ip = $self->convert_ip($remote->{ip});
  $ip = join '', sprintf("%03d%03d%03d%03d", unpack("CCCC", $ip));
  if (defined $self->{Deny} && ref $self->{Deny}) {
    foreach my $ref (@{$self->{Deny}}) {
      if ($ref->{low} <= $ip && $ip <= $ref->{high}) {
        $self->crit('Host '.$remote->{ip}.' is denied by Deny Rule');
        return 0;
      }
    }
  }
  if (defined $self->{Allow} && ref $self->{Allow}) {
    foreach my $ref (@{$self->{Allow}}) {
      if ($ref->{low} <= $ip && $ip <= $ref->{high}) {
        # $self->debug('Host '.$remote->{ip}.' is allowed by Allow rule');
        return 1;
      }
    }
    $self->crit('Host '.$remote->{ip}.' is denied by Allow Rule');
    return 0;
  }
  # else, it's not denied and no allow only is specified, c'mon in.
  return 1;
}
  
# setting up IP ranges, called when new socket initiated.
sub parse_acl {
  my $self = shift;
  my $baseacl = shift;
  # $self->debug("Parsing $baseacl");
  $self->{$baseacl}=~s/\s+//g;
  my @acl = split ',', $self->{$baseacl};
  my @section;
  foreach my $string (@acl) {
    # $self->debug("Looking at $string");
    push @section, $self->set_ip_range($string);
    # $self->debug('low -> '.($section[$#section]{low}).'   high -> '.($section[$#section]{high}));
    pop @section if (! defined $section[$#section]);
  }
  $self->{$baseacl} = \@section;
  # $self->debug("Leaving");
}

# sets a low and high IP comparison index
sub set_ip_range {
  my $self = shift;
  my $string = shift;
  my ($low, $high);
  if ($string=~/\-/) {
    my @ip = split '-', $string;
    if ($#ip != 1) {
      $self->error("Unknown string: $string");
      return;
    }
    foreach (@ip) {
      if (! $self->valid_ip($_)) {
        $self->error("Invalid IP address: $_");
        return;
      }
    }
    $low = sprintf("%03d%03d%03d%03d", unpack("CCCC", $self->convert_ip($ip[0])));
    $high = sprintf("%03d%03d%03d%03d", unpack("CCCC", $self->convert_ip($ip[1])));
  } else {
    my ($addr, $mask) = split '/', $string;
    unless ($self->valid_ip($addr)) {
      $self->error("Invalid IP address: $addr");
      return;
    }
    $mask = 32 if (! defined $mask);
    my $addr_bin = $self->convert_ip($addr);
    my $mask_bin = $self->convert_mask($mask);
    my $inv_mask = $self->inv_mask($mask_bin);
    my $broadcast = $inv_mask | $addr_bin;
    my $network = $broadcast ^ $inv_mask;
    $low = sprintf("%03d%03d%03d%03d", unpack("CCCC", $network));
    $high = sprintf("%03d%03d%03d%03d", unpack("CCCC", $broadcast));
  }
  return {low=>$low, high=>$high};
}

# just returns true if value passed in is a valid IP
# I got sick of typing this regex.
sub valid_ip {
  my $self = shift;
  return 1 if ($_[0]=~/\d{0,3}(\.\d{0,3}){3}/);
  return;
}

# invert subnet mask
sub inv_mask {
  my $self = shift;
  my @sects = split '', shift;
  my $overall = '';
  foreach my $pos (0..$#sects) {
    my $current = '';
    vec($current, 0, 8) = 0;
    for (my $c = 1; $c < 255; $c*=2) {
      my $one = '';
      vec($one, 0, 8) = $c;
      if (! unpack("C", ($sects[$pos] & $one))) {
        $current = $current | $one;
      }
    }
    $overall .= $current;
  }
  return $overall;
}

sub convert_ip {
  my $self = shift;
  return join '', map {pack("C", $_)} (split /\./, shift);
}

sub convert_mask {
  my $self = shift;
  my $mask = shift;
  return $self->convert_ip($mask) if ($self->valid_ip($mask));
  my $overall;
  my $string = reverse sprintf("%032s", '1' x $mask);
  for (my $c=0; $c<32; $c+=8) {
    my $out = 0;
    my @wank = split '', substr($string, $c, 8);
    for (my $m=1; $m<255; $m*=2) {
      $out += $m if (pop @wank);
    }
    $overall .= pack("C", $out);
  }
  return $overall;
}
1;

__END__

=head1 NAME

Audio::Daemon - UDP Daemon for various Sound Players

=head1 SYNOPSIS

  This isn't called directly, but exists for inheritance reasons.

  For Servers :
  use Audio::Daemon::MPG123;
  use Audio::Daemon::Xmms;
  use Audio::Daemon::Shout;
  
  or for the single client interface:
  use Audio::Daemon::Client;

=head1 DESCRIPTION

Audio::Daemon is a udp service providing a single udp interface around various 
other modules, like Xmms, Audio::Play::MPG123 and libshout (for icecast streaming). 

=head1 AUTHOR

Jay Jacobs jayj@cpan.org

=head1 SEE ALSO

Audio::Daemon::MPG123
Audio::Daemon::Xmms
Audio::Daemon::Shout
Audio::Daemon::Client

=cut
