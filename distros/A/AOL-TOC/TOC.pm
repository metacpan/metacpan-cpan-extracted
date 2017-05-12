package AOL::TOC;

use IO;
use Socket;
use AOL::SFLAP;

$VERSION      = "0.34";
$TOC_VERSION  = "1.0";
$ROASTING_KEY = "Tic/Toc";

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

=head1 NAME

AOL::TOC - Perl extension for interfacing with AOL's AIM service

=head1 SYNOPSIS

  use AOL::TOC;
  $toc = AOL::TOC::new($toc_server, $login_server, $port,
         $screenname, $password); 
  $toc->connect();

=head1 DESCRIPTION

This module implements SFLAP, which I presume to be AOL's authenticiation
protocol, and TOC, which is the actual "meat" of the AIM protocol.

=head1 INTERFACE

=head2 connect

connects to the AIM server

=head2 register_callback

This function takes two arguments, the EVENT and the subroutine reference.
Callbacks are similar to the ones found in Net::IRC. The module defines
several AIM "events": ERROR, CLOSED, SIGN_ON, IM_IN, CHAT_IN, UPDATE_BUDDY.
These events can be bound to subroutines.

=head2 dispatch

This flushes all messages to the server, and retreives all current messages.

=head2 add_buddy

Takes one arguement, the nick of the buddy. 
This adds a buddy to your buddy list.

=head2 send_im

Takes two arguments, the name of the buddy and the name of the message, and
sends the IM.

=head2 get_info

Takes one argument, the name of the buddy, and returns the info.

=head2 chat_join

Takes one argument, the name of the chat room to join

=head2 chat_send

Takes two arguments, the name of the chat room, and the message.

=head1 AUTHOR

xjharding@newbedford.k12.ma.us cleaned it up and added DOC
james@foo.org was the original author

=head1 SEE ALSO

Net::AIM, a new module, but it doesn't have the features of this one

=cut

sub roast_password {
  my ($password, $key) = @_;
  my @skey;
  my $rpassword = "0x";
  my $i = 0;

  if (!$key) { $key = $ROASTING_KEY; }

  @skey = split('', $key);

  for $c (split('', $password)) {
    $p = unpack("c", $c);
    $k = unpack("c", @skey[$i % length($key)]);
    $rpassword = sprintf("%s%02x", $rpassword, $p ^ $k);
    $i ++;
  }

  return ($rpassword);
}


sub encode_string {
  my ($self, $str) = @_;
  my ($estr, $i);

  if (!$str) { $str = $self; }

  $estr = "\"";
  for $i (split('', $str)) {
    if (
      ($i eq "\\") || ($i eq "\{") || ($i eq "\}") ||
      ($i eq "\(") || ($i eq "\)") || ($i eq "\[") ||
      ($i eq "\]") || ($i eq "\$") || ($i eq "\""))  
      { 
        $estr .= "\\";
      }
      $estr .= $i;
  }
  $estr .= "\"";

  return ($estr);
}


sub register_callback {
  my ($self, $event, $func, @args) = @_;

  push (@{$self->{callback}{$event}}, $func);
  @{$self->{callback}{$func}} = @args;

  return;
}


sub callback {
  my ($self, $event, @args) = @_;
  my $func;

  for $func (@{$self->{callback}{$event}}) {
    eval { &{$func} ($self, @args, @{$self->{callback}{$func}}) };
  }

  return;
}


sub clear_callbacks {
  my ($self) = @_;
  my $k; 
 
  print "................ TOC clear_callbacks\n";
  for $k (keys %{$self->{callback}}) {
    print ".............. Clear key ($k)\n";
    delete $self->{callback}{$k};
  }

  print "...............S TOC scan callbacks\n";
  for $k (keys %{$self->{callback}}) {
    print ".............S Scan key ($k)\n";
  }
}


sub new {
  my ($tochost, $authorizer, $port, $nickname, $password) = @_;
  my ($self, $ipaddr, $sflap);

  $self = { 
      nickname => $nickname, 
      password => $password, 
      caller => "file:line" 
      };
  
  bless($self);

  $sflap = AOL::SFLAP::new($tochost, $authorizer, $port, $nickname);
  $self->{sflap} = $sflap;

  #print "*************************** AOL::TOC::new(...) sflap = $self->{sflap}\n";
  #print "                            sflap cb = $self->{sflap}{callback}\n";

  #$self->{sflap}->register_callback($AOL::SFLAP::SFLAP_SIGNON,    \&sflap_signon, $password, "english", "TIK:\$Revision: 1.148 \$", $self);
  #$self->{sflap}->register_callback($AOL::SFLAP::SFLAP_DATA,      \&sflap_data, $self);
  #$self->{sflap}->register_callback($AOL::SFLAP::SFLAP_ERROR,     \&sflap_error, $self);
  #$self->{sflap}->register_callback($AOL::SFLAP::SFLAP_SIGNOFF,   \&sflap_signoff, $self);
  #$self->{sflap}->register_callback($AOL::SFLAP::SFLAP_KEEPALIVE, \&sflap_keepalive, $self);
  #
  #$self->register_callback("SIGN_ON", \&check_version);
  #$self->register_callback("CHAT_JOIN", \&_chat_join);

  return $self;
}


sub destroy {
  my ($self) = @_;
  
  print "toc destroy\n";
  $self->{sflap}->destroy();

  $self->{callback} = undef;
  $self = undef;

  return;
}


sub set_debug {
  my ($self, $level) = @_;

  $self->{sflap}->set_debug($level);
}


sub debug {
  my ($self, @args) = @_;

  if ($self->{debug_level} > 0) {
    print @args;
  }
}


sub connect {
  my ($self) = @_;

  $self->{sflap}->register_callback($AOL::SFLAP::SFLAP_SIGNON,    \&sflap_signon, $self->{password}, "english", "TIK:\$Revision: 1.148 \$", $self);
  $self->{sflap}->register_callback($AOL::SFLAP::SFLAP_DATA,      \&sflap_data, $self);
  $self->{sflap}->register_callback($AOL::SFLAP::SFLAP_ERROR,     \&sflap_error, $self);
  $self->{sflap}->register_callback($AOL::SFLAP::SFLAP_SIGNOFF,   \&sflap_signoff, $self);
  $self->{sflap}->register_callback($AOL::SFLAP::SFLAP_KEEPALIVE, \&sflap_keepalive, $self);
  
  $self->register_callback("SIGN_ON", \&check_version);
  $self->register_callback("CHAT_JOIN", \&_chat_join);

  $self->{sflap}->connect();
}

sub close {
  my ($self) = @_;
  my $k;

  $self->clear_callbacks();
  $self->{sflap}->close();
}


sub check_version {
  my ($self, $version) = @_;

  if ($version > $TOC_VERSION) {
    $self->destroy();
  }

  $self->init_done();

  return;
}


sub send {
  my ($self, $data) = @_;

  $self->{sflap}->send($AOL::SFLAP::SFLAP_DATA, $data);
}


sub dispatch {
  my ($self) = @_;

  $self->{sflap}->recv();
}


# Utilities

sub signon {
  my ($self, $authorizer, $port, $nickname, $roasted_password, $language, $version) = @_;

  $self->send("toc_signon $authorizer $port $nickname $roasted_password $language " . &encode_string($version));
  return;
}

sub init_done {
  my ($self) = @_;

  $self->send("toc_init_done");
  return;
}


sub send_im {
  my ($self, $nickname, $message, $auto) = @_;

  $auto = "" unless defined $auto;

  $self->send("toc_send_im $nickname " . &encode_string($message) . " $auto");
  return;
}


sub add_buddy {
  my ($self, @buddies) = @_;

  $self->send("toc_add_buddy @buddies");
  return;
}


sub remove_buddy {
  my ($self, @buddies) = @_;

  $self->send("toc_remove_buddy @buddies");
  return;
}


sub set_config {
  my ($self, $config) = @_;

  $self->send("toc_set_config $config");
  return;
}


sub evil {
  my ($self, $nickname, $mode) = @_;

  $self->send("toc_evil $nickname $mode\n");
  return;
}


sub add_permit {
  my ($self, @buddies) = @_;

  $self->send("toc_add_permit @buddies");
  return;
}


sub add_deny {
  my ($self, @buddies) = @_;

  $self->send("toc_add_deny @buddies");
  return;
}


sub chat_join {
  my $self = shift;
  my $exchange = shift;
  my $room;
  
  if ($exchange  =~ /\D/) {
    $room = $exchange;
    $exchange = 4;
  } else {
    $room = shift;
  }

  $self->send("toc_chat_join $exchange " . &encode_string($room));
  return;
}


sub _chat_join {
  my ($self, $room_id, $room_name) = @_;

  $self->{chatrooms}{$room_id}   = $room_name;
  $self->{chatrooms}{$room_name} = $room_id;
  return;
}


sub chat_send {
  my ($self, $room_id, $message) = @_;

  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }

  $self->send("toc_chat_send $room_id " . &encode_string($message));
  return;
}


sub chat_whisper {
  my ($self, $room_id, $nickname, $message) = @_;
    
  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }

  $self->send("toc_chat_whisper $room_id $nickname " . &encode_string($message));
  return;
}


sub chat_evil {
  my ($self, $room_id, $nickname, $mode) = @_;
    
  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }

  $self->send("toc_chat_evil $room_id $nickname $mode");
  return;
}


sub chat_invite {
  my ($self, $room_id, $message, @buddies) = @_;
    
  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }

  $self->send("toc_chat_invite $room_id " . &encode_string($message) . " @buddies");
  return;
}


sub chat_leave {
  my ($self, $room_id) = @_;

  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }
  
  $self->send("toc_chat_leave $room_id");
  return;
}


sub chat_accept {
  my ($self, $room_id) = @_;                    

  if ($room_id  =~ /\D/) {
    $room_id = $self->{chatrooms}{$room_id};
  }

  $self->send("toc_chat_accept $room_id");                      
  return;
}


sub get_info {
  my ($self, $nickname) = @_;

  $self->send("toc_get_info $nickname");
  return;
}


sub set_info {
  my ($self, $info) = @_;

  $self->send("toc_set_info " . &encode_string($info));
  return;
}


# SFLAP Callbacks

sub sflap_signon {
  my ($self, $data, $password, $language, $version, $toc) = @_;
  my ($buffer, $roasted_password);

  $roasted_password = roast_password($password, $ROASTING_KEY);

  $buffer = pack("Nnna*", 1, 1, length($toc->{sflap}->{nickname}), $toc->{sflap}->{nickname});
  $toc->{sflap}->send($AOL::SFLAP::SFLAP_SIGNON, $buffer);

  $toc->signon($toc->{sflap}->{authorizer}, $toc->{sflap}->{port}, $toc->{sflap}->{nickname}, $roasted_password, $language, $version);
}

sub sflap_data {
  my ($self, $data, $toc) = @_;
  my ($cmd, $args);

  ($cmd, $args) = ($data =~ /^(\w+)\:(.*)$/);

  return unless defined $cmd && defined $args;

  if ($cmd eq "SIGN_ON") {
    ($toc_version) = ($args =~ /^TOC(.*)$/);
    $toc->callback("SIGN_ON", $toc_version);
  }

  if ($cmd eq "CONFIG") {
    $toc->callback("CONFIG", $args);
  }

  if ($cmd eq "NICK") {
    ($beautified_nick) = ($args =~ /^(.*)$/);
    $toc->callback("NICK", $beautified_nick);
  }

  if ($cmd eq "IM_IN") {
    ($nickname, $autoresponse, $message) = ($args =~ /^(.*)\:(.*)\:(.*)$/);
    $toc->callback("IM_IN", $nickname, $autoresponse, $message);
  }

  if ($cmd eq "UPDATE_BUDDY") {
    ($nickname, $online, $evil, $signon_time, $idle_time, $class) = ($args =~ /^(.*)\:(.*)\:(.*)\:(.*)\:(.*)\:(.*)$/);
    $toc->callback("UPDATE_BUDDY", $nickname, $online, $evil, $signon_time, $idle_Time, $class);
  }

  if ($cmd eq "ERROR") {
    ($code, $args) = ($args =~ /^(\d*).?(.*)$/);
    $toc->callback("ERROR", $code, $args);
  }

  if ($cmd eq "EVILED") {
    ($evil_level, $nickname) = ($args =~ /^(.*)\:(.*)$/);
    $toc->callback("EVILED", $evil_level, $nickname);
  }

  if ($cmd eq "CHAT_JOIN") {
    ($room_id, $room_name) = ($args =~ /^(.*)\:(.*)$/);
    $toc->callback("CHAT_JOIN", $room_id, $room_name);
  }

  if ($cmd eq "CHAT_IN") {
    ($room_id, $nickname, $whisper, $message) = ($args =~ /^(.*)\:(.*)\:(.*)\:(.*)$/);
    $toc->callback("CHAT_IN", $room_id, $nickname, $whisper, $message);
  }

  if ($cmd eq "CHAT_UPDATE_BUDDY") {
    ($room_id, $inside, $nicknames) = ($args =~ /^(.*)\:(.*)\:(.*)$/);
    $toc->callback("CHAT_UPDATE_BUDDY", $room_id, $inside, $nicknames);
  }

  if ($cmd eq "CHAT_INVITE") {
    ($room_name, $room_id, $nickname, $message) = ($args =~ /^(.*)\:(.*)\:(.*)\:(.*)$/);
    $toc->callback("CHAT_INVITE", $room_name, $room_id, $nickname, $message);
  }

  if ($cmd eq "CHAT_LEFT") {
    ($room_id) = ($args =~ /^(.*)$/);
    $toc->callback("CHAT_LEFT", $room_id);
  }

  if ($cmd eq "GOTO_URL") {
    ($window_name, $url) = ($args =~ /^(.*)\:(.*)$/);
    $toc->callback("GOTO_URL", $window_name, $url);
  }

  if ($cmd eq "PAUSE") {
    $toc->callback("PAUSE");
  }

}

sub sflap_error {
  my ($self, $data, $toc) = @_;

  return;
}

sub sflap_signoff {
  my ($self, $data, $toc) = @_;

  $toc->callback("CLOSED");

  #foreach $k (keys %{$toc->{callback}}) {
  #  print "Deleting .. $k\n";
  #  delete $toc->{callback}{$k};
  #}

  $toc->destroy();

  return;
}

sub test {
  my ($self) = @_;

  return \&test($self);
}

sub send_signoff {
  my ($self) = @_;

  $self->{sflap}->send($AOL::SFLAP::SFLAP_SIGNOFF, "");
}

1;
__END__
