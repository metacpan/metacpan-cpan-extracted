package Audio::Daemon::MPG123;

use IO::Socket::INET;
use IO::Select;
use vars qw($VERSION);
$VERSION='0.9Beta';

sub new {
  my ($proto, %arg)  = @_;
  my $class = ref($proto) || $proto;
  my $self = {};
  foreach my $k (qw/Allow Deny Server Port Log/) {
    $self->{$k} = $arg{$k} if (defined $arg{$k});
  }
  $self->{sep} = sprintf("%c", 255);
  $self->{subsep} = sprintf("%c", 254);
  bless($self, $class);
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
  if (ref $self eq 'Audio::Daemon::MPG123::Server') {
    if (! defined $self->{Port}) {
      $self->crit("No Port defined for socket creation");
      return;
    }
    $self->{socket} = IO::Socket::INET->new(LocalPort => $self->{Port}, Proto=>'udp');
  } elsif (ref $self eq 'Audio::Daemon::MPG123::Client') {
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

1;

__END__

=head1 NAME

Audio::Daemon::MPG123 - UDP Daemon wrapper around Audio::Play::MPG123

=head1 SYNOPSIS

  This isn't called directly, but exists for inheritance reasons.

  use Audio::Daemon::MPG123::Server;
  # or 
  use Audio::Daemon::MPG123::Client;

=head1 DESCRIPTION

Audio::Daemon::MPG123 is a wrapper around Audio::Play::MPG123, adding two big 
features, Multiple clients accessing the same Audio::Play::MPG123 instance, and 
udp messaging allowing the client to be removed from the server.  There are 
other interesting features, but those were the two goals of this project.

There are two subclasses to Audio::Daemon::MPG123, one for the server and one 
for the client.  The Server needs Audio::Play::MPG123, Audio::Mixer (for optional
volume control).  The Client needs IO::Socket.

=back

=head1 AUTHOR

Jay Jacobs jayj@cpan.org

=head1 SEE ALSO

Audio::Daemon::MPG123::Server
Audio::Daemon::MPG123::Client

Audio::Play::MPG123

perl(1).

=cut

