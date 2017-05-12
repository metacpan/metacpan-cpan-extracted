package Audio::Play::MPG123;

use strict 'subs';
use Carp;

require Exporter;
use Fcntl;
use IPC::Open3;
use Cwd;
use File::Spec;
use Errno qw(EAGAIN EINTR);

BEGIN { $^W=0 } # I'm fed up with bogus and unnecessary warnings nobody can turn off.

@ISA = qw(Exporter);

@_consts = qw();
@_funcs = qw();

@EXPORT = @_consts;
@EXPORT_OK = @_funcs;
%EXPORT_TAGS = (all => [@_consts,@_funcs], constants => \@_consts);
$VERSION = '0.63';

$MPG123 = "mpg123";

$OPT_AUTOSTAT = 1;

sub new {
   my $class = shift;
   my $self = bless { @_ }, $class;
   $self->start_mpg123(@{$self->{mpg123args} || []});
   $self;
}

sub start_mpg123 {
   my $self = shift;
   local *DEVNULL;
   open DEVNULL, ">/dev/null" or die "/dev/null: $!";
   $self->{r} = local *MPG123_READER;
   $self->{w} = local *MPG123_WRITER;
   $self->{pid} = open3($self->{w},$self->{r},">&DEVNULL",$MPG123,'-R','--aggressive',@_,'');
   die "Unable to start $MPG123" unless $self->{pid};
   fcntl $self->{r}, F_SETFL, O_NONBLOCK;
   fcntl $self->{r}, F_SETFD, FD_CLOEXEC;
   $self->parse(qr/^\@?R (\S+)/,1) or die "Error during player startup: $self->{err}\n";
   $self->{version}=$1;
}

sub stop_mpg123 {
   my $self = shift;
   if (delete $self->{pid}) {
      print {$self->{w}} "Q\n";
      close $self->{w};
      close $self->{r};
   }
}

sub line {
   my $self = shift;
   my $wait = shift;
   while() {
      return $1 if $self->{buf} =~ s/^([^\n]*)\n+//;
      my $len = sysread $self->{r},$self->{buf},4096,length($self->{buf});
      # telescope the most frequent event, very useful for slow machines
      $self->{buf} =~ s/^(?:\@F[^\n]*\n)+(?=\@F)//s;
      if (defined $len || ($! != EAGAIN && $! != EINTR)) {
         die "connection to mpg123 process lost: $!\n" if $len == 0;
      } else {
         if ($wait) {
            my $v = ""; vec($v,fileno($self->{r}),1)=1;
            select ($v, undef, undef, 60);
         } else {
            return ();
         }
      }
   }
}

sub parse {
   my $self = shift;
   my $re   = shift;
   my $wait = shift;
   while (my $line = $self->line ($wait)) {
      if ($line =~ /^\@F (.*)$/) {
         $self->{frame}=[split /\s+/,$1];
         # sno rno tim1 tim2
      } elsif ($line =~ /^\@S (.*)$/) {
         @{$self}{qw(type layer samplerate mode mode_extension
                     bpf channels copyrighted error_protected
                     emphasis bitrate extension lsf)}=split /\s+/,$1;
         $self->{tpf} = ($self->{layer}>1 ? 1152 : 384) / $self->{samplerate};
         $self->{tpf} *= 0.5 if $self->{lsf};
         $self->{state} = 2;
      } elsif ($line =~ /^\@I ID3:(.{30})(.{30})(.{30})(....)(.{30})(.*)$/) {
         $self->{title}=$1;   $self->{artist}=$2;
         $self->{album}=$3;   $self->{year}=$4;
         $self->{comment}=$5; $self->{genre}=$6;
         $self->{$_} =~ s/\s+$// for qw(title artist album year comment genre);
      } elsif ($line =~ /^\@I (.*)$/) {
         $self->{title}=$1;
         delete @{$self}{qw(artist album year comment genre)}
      } elsif ($line =~ /^\@P (\d+)(?: (\S+))?$/) {
         $self->{state} = $1;
         # 0 = stopped, 1 = paused, 2 = continued
      } elsif ($line =~ /^\@E (.*)$/) {
         $self->{err}=$1;
         return ();
      } elsif ($line !~ $re) {
         $self->{err}="Unknown response: $line";
         return ();
      }
      return $line if $line =~ $re;
   }
   delete $self->{err};
   return ();
}

sub poll {
   my $self = shift;
   my $wait = shift;
   $self->parse(qr//,1) if $wait;
   $self->parse(qr/^X\0/,0);
}

sub canonicalize_url {
   my $self = shift;
   my $url  = shift;
   if ($url !~ m%^http://%) {
      $url =~ s%^file://[^/]*/%%;
      $url = fastcwd."/".$url unless $url =~ /^\//;
   }
   $url;
}

sub load {
   my $self = shift;
   my $url  = $self->canonicalize_url(shift);
   $self->{url} = $url;
   if ($url !~ /^http:/ && !-f $url) {
      $self->{err} = "No such file or directory: $url";
      return ();
   }
   print {$self->{w}} "LOAD $url\n";
   delete @{$self}{qw(frame type layer samplerate mode mode_extension bpf lsf
                      channels copyrighted error_protected title artist album
                      year comment genre emphasis bitrate extension)};
   $self->parse(qr{^\@[SP]\s},1);
   return $self->{state};
}

sub stat {
   my $self = shift;
   return unless $self->{state};
   print {$self->{w}} "STAT\n";
   $self->parse(qr{^\@F},1);
}

sub pause {
   my $self = shift;
   print {$self->{w}} "PAUSE\n";
   $self->parse(qr{^\@P},1);
}

sub paused {
   2 - $_[0]{state};
}

sub jump {
   my $self = shift;
   print {$self->{w}} "JUMP $_[0]\n";
}

sub statfreq {
   my $self = shift;
   print {$self->{w}} "STATFREQ $_[0]\n";
}

sub stop {
   my $self = shift;
   print {$self->{w}} "STOP\n";
   $self->parse(qr{^\@P},1);
}

sub IN {
   $_[0]->{r};
}

sub tpf {
   my $self = shift;
   $self->{tpf};
}

for my $field (qw(title artist album year comment genre state url
                  type layer samplerate mode mode_extension bpf frame
                  channels copyrighted error_protected title artist album
                  year comment genre emphasis bitrate extension)) {
  *{$field} = sub { $_[0]{$field} };
}

sub error { shift->{err} }

1;
__END__

=head1 NAME

Audio::Play::MPG123 - a frontend to mpg123 version 0.59r and beyond.

=head1 SYNOPSIS

  use Audio::Play::MPG123;
  
  $player = new Audio::Play::MPG123;
  $player->load("kult.mp3");
  print $player->artist,"\n";
  $player->poll(1) until $player->state == 0;

  $player->load("http://x.y.z/kult.mp3");

  # see also mpg123sh from the tarball

=head1 DESCRIPTION

This is a frontend to the mpg123 player. It works by starting an external
mpg123 process with the C<-R> option and feeding commands to it.

While the standard mpg123 player can be used to play back mp3's using
this module you will encounter random deadlocks, due to bugs in its
communication code. Also, many features (like C<statfreq>) only work with
the included copy of mpg123, so better use that one before deciding that
this module is broken.

(In case you wonder, the mpg123 author is not interested in including
these fixes and enhancements into mpg123).

=head2 METHODS

Most methods can be either BLOCKING (they wait until they get an answer,
which usually takes half a mpeg frame of playing time), NONBLOCKING (the
functions return as soon as they send their message, which is usallly
instant) or CACHING (the method returns some cached data which only gets
refreshed by an asynchronous STAT event or an explicit call to C<state>).

=over 4

=item new [parameter => value, ...]

This creates a new player object and also starts the mpg123 process. New
supports the following parameters:

   mpg123args      an arrayreg with additional arguments for the mpg123 process

=item load(<path or url>) [BLOCKING]

Immediately loads the specified file (or url, http:// and file:/// forms
supported) and starts playing it. If you really want to play a file with
a name starting with C<file://> or C<http://> then consider prefixing all
your paths with C<file:///>. Returns a true status when the song could be
started, false otherwise.

=item stat [BLOCKING]

This can be used to poll the player for it's current state (playing mode,
frame position &c). As every other function that requires communication
with mpg123, it might take up to one frame delay until the answer returns.
Using C<statfreq> and infrequent calls to C<poll> is often a better
strategy.

=item pause [BLOCKING]

Pauses or unpauses the song. C<state> (or C<paused>) can be used to find
out about the current mode.

=item paused [CACHING]

Returns the opposite of C<state>, i.e. zero when something is playing
and non-zero when the player is stopped or paused.

=item jump [BLOCKING]

Jumps to the specified frame of the song. If the number is prefixed with
"+" or "-", the jump is relative, otherweise it is absolute.

=item stop [BLOCKING]

Stops the currently playing song and unloads it.

=item statfreq(rate) [NONBLOCKING]

Sets the rate at which automatic frame updates are sent by mpg123. C<0>
turns it off, everything else is the average number of frames between
updates.  This can be a floating pount value, i.e.

 $player->statfreq(0.5/$player->tpf);

will set two updates per second (one every half a second).

=item state [CACHING]

Returns the current state of the player:

 0  stopped, not playing anything
 1  paused, song loaded but not playing
 2  playing, song loaded and playing

=item poll(<wait>) [BLOCKING or NONBLOCKING]

Parses all outstanding events and status information. If C<wait> is zero
it will only parse as many messages as are currently in the queue, if it
is one it will wait until at least one event occured.

This can be used to wait for the end of a song, for example. This function
should be called regularly, since mpg123 will stop playing when it can't
write out events because the perl program is no longer listening...

=item title artist album year comment genre url type layer samplerate mode mode_extension bpf frame channels copyrighted error_protected title artist album year comment genre emphasis bitrate extension [CACHING]

These accessor functions return information about the loaded
song. Information about the C<artist>, C<album>, C<year>, C<comment> or
C<genre> might not be available and will be returned as C<undef>.

The accessor function C<frame> returns a reference to an array containing
the frames played, frames left, seconds played, and seconds left in this
order. Seconds are returned as floating point numbers.

=item tpf [CACHING]

Returns the "time per frame", i.e. the time in seconds for one frame. Useful with the C<jump>-method:

 $player->jump (60/$player->tpf);

Jumps to second 60.

=item IN

Returns the input filehandle from the mpg123 player. This can be used for selects() or poll().

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>.

=head1 SEE ALSO

perl(1).

=cut
