use 5.006;
use strict;
use warnings;
package Capture::Tiny::Extended;
our $VERSION = '0.114'; # VERSION
# ABSTRACT: Capture STDOUT and STDERR from from Perl, XS or external programs (with some extras)
use Carp ();
use Exporter ();
use IO::Handle ();
use File::Spec ();
use File::Temp qw/tempfile tmpnam/;
# Get PerlIO or fake it
BEGIN {
  local $@;
  eval { require PerlIO; PerlIO->can('get_layers') }
    or *PerlIO::get_layers = sub { return () };
}

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/capture capture_merged tee tee_merged capture_files/;
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

my $IS_WIN32 = $^O eq 'MSWin32';

our $DEBUG = $ENV{PERL_CAPTURE_TINY_DEBUG};
my $DEBUGFH;
open $DEBUGFH, ">&STDERR" if $DEBUG;

*_debug = $DEBUG ? sub(@) { print {$DEBUGFH} @_ } : sub(){0};

our $TIMEOUT = 30;

#--------------------------------------------------------------------------#
# command to tee output -- the argument is a filename that must
# be opened to signal that the process is ready to receive input.
# This is annoying, but seems to be the best that can be done
# as a simple, portable IPC technique
#--------------------------------------------------------------------------#
my @cmd = ($^X, '-e', '$SIG{HUP}=sub{exit}; '
  . 'if( my $fn=shift ){ open my $fh, qq{>$fn}; print {$fh} $$; close $fh;} '
  . 'my $buf; while (sysread(STDIN, $buf, 2048)) { '
  . 'syswrite(STDOUT, $buf); syswrite(STDERR, $buf)}'
);

#--------------------------------------------------------------------------#
# filehandle manipulation
#--------------------------------------------------------------------------#

sub _relayer {
  my ($fh, $layers) = @_;
  _debug("# requested layers (@{$layers}) to $fh\n");
  my %seen = ( unix => 1, perlio => 1 ); # filter these out
  my @unique = grep { !$seen{$_}++ } @$layers;
  _debug("# applying unique layers (@unique) to $fh\n");
  binmode($fh, join(":", ":raw", @unique));
}

sub _name {
  my $glob = shift;
  no strict 'refs'; ## no critic
  return *{$glob}{NAME};
}

sub _open {
  open $_[0], $_[1] or Carp::confess "Error from open(" . join(q{, }, @_) . "): $!";
  _debug( "# open " . join( ", " , map { defined $_ ? _name($_) : 'undef' } @_ ) . " as " . fileno( $_[0] ) . "\n" );
}

sub _close {
  close $_[0] or Carp::confess "Error from close(" . join(q{, }, @_) . "): $!";
  _debug( "# closed " . ( defined $_[0] ? _name($_[0]) : 'undef' ) . "\n" );
}

my %dup; # cache this so STDIN stays fd0
my %proxy_count;
sub _proxy_std {
  my %proxies;
  if ( ! defined fileno STDIN ) {
    $proxy_count{stdin}++;
    if (defined $dup{stdin}) {
      _open \*STDIN, "<&=" . fileno($dup{stdin});
      _debug( "# restored proxy STDIN as " . (defined fileno STDIN ? fileno STDIN : 'undef' ) . "\n" );
    }
    else {
      _open \*STDIN, "<" . File::Spec->devnull;
      _debug( "# proxied STDIN as " . (defined fileno STDIN ? fileno STDIN : 'undef' ) . "\n" );
      _open $dup{stdin} = IO::Handle->new, "<&=STDIN";
    }
    $proxies{stdin} = \*STDIN;
    binmode(STDIN, ':utf8') if $] >= 5.008;
  }
  if ( ! defined fileno STDOUT ) {
    $proxy_count{stdout}++;
    if (defined $dup{stdout}) {
      _open \*STDOUT, ">&=" . fileno($dup{stdout});
      _debug( "# restored proxy STDOUT as " . (defined fileno STDOUT ? fileno STDOUT : 'undef' ) . "\n" );
    }
    else {
      _open \*STDOUT, ">" . File::Spec->devnull;
      _debug( "# proxied STDOUT as " . (defined fileno STDOUT ? fileno STDOUT : 'undef' ) . "\n" );
      _open $dup{stdout} = IO::Handle->new, ">&=STDOUT";
    }
    $proxies{stdout} = \*STDOUT;
    binmode(STDOUT, ':utf8') if $] >= 5.008;
  }
  if ( ! defined fileno STDERR ) {
    $proxy_count{stderr}++;
    if (defined $dup{stderr}) {
      _open \*STDERR, ">&=" . fileno($dup{stderr});
      _debug( "# restored proxy STDERR as " . (defined fileno STDERR ? fileno STDERR : 'undef' ) . "\n" );
    }
    else {
      _open \*STDERR, ">" . File::Spec->devnull;
      _debug( "# proxied STDERR as " . (defined fileno STDERR ? fileno STDERR : 'undef' ) . "\n" );
      _open $dup{stderr} = IO::Handle->new, ">&=STDERR";
    }
    $proxies{stderr} = \*STDERR;
    binmode(STDERR, ':utf8') if $] >= 5.008;
  }
  return %proxies;
}

sub _unproxy {
  my (%proxies) = @_;
  _debug( "# unproxing " . join(" ", keys %proxies) . "\n" );
  for my $p ( keys %proxies ) {
    $proxy_count{$p}--;
    _debug( "# unproxied " . uc($p) . " ($proxy_count{$p} left)\n" );
    if ( ! $proxy_count{$p} ) {
      _close $proxies{$p};
      _close $dup{$p} unless $] < 5.008; # 5.6 will have already closed this as dup
      delete $dup{$p};
    }
  }
}

sub _copy_std {
  my %handles = map { $_, IO::Handle->new } qw/stdin stdout stderr/;
  _debug( "# copying std handles ...\n" );
  _open $handles{stdin},   "<&STDIN";
  _open $handles{stdout},  ">&STDOUT";
  _open $handles{stderr},  ">&STDERR";
  return \%handles;
}

sub _open_std {
  my ($handles) = @_;
  _open \*STDIN, "<&" . fileno $handles->{stdin};
  _open \*STDOUT, ">&" . fileno $handles->{stdout};
  _open \*STDERR, ">&" . fileno $handles->{stderr};
}

#--------------------------------------------------------------------------#
# private subs
#--------------------------------------------------------------------------#

sub _start_tee {
  my ($which, $stash) = @_;
  # setup pipes
  $stash->{$_}{$which} = IO::Handle->new for qw/tee reader/;
  pipe $stash->{reader}{$which}, $stash->{tee}{$which};
  _debug( "# pipe for $which\: " .  _name($stash->{tee}{$which}) . " "
    . fileno( $stash->{tee}{$which} ) . " => " . _name($stash->{reader}{$which})
    . " " . fileno( $stash->{reader}{$which}) . "\n" );
  select((select($stash->{tee}{$which}), $|=1)[0]); # autoflush
  # setup desired redirection for parent and child
  $stash->{new}{$which} = $stash->{tee}{$which};
  $stash->{child}{$which} = {
    stdin   => $stash->{reader}{$which},
    stdout  => $stash->{old}{$which},
    stderr  => $stash->{capture}{$which},
  };
  # flag file is used to signal the child is ready
  $stash->{flag_files}{$which} = scalar tmpnam();
  # execute @cmd as a separate process
  if ( $IS_WIN32 ) {
    local $@;
    eval "use Win32API::File qw/CloseHandle GetOsFHandle SetHandleInformation fileLastError HANDLE_FLAG_INHERIT INVALID_HANDLE_VALUE/ ";
    _debug( "# Win32API::File loaded\n") unless $@;
    my $os_fhandle = GetOsFHandle( $stash->{tee}{$which} );
    _debug( "# Couldn't get OS handle: " . fileLastError() . "\n") if ! defined $os_fhandle || $os_fhandle == INVALID_HANDLE_VALUE();
    if ( SetHandleInformation( $os_fhandle, HANDLE_FLAG_INHERIT(), 0) ) {
      _debug( "# set no-inherit flag on $which tee\n" );
    }
    else {
      _debug( "# can't disable tee handle flag inherit: " . fileLastError() . "\n");
    }
    _open_std( $stash->{child}{$which} );
    $stash->{pid}{$which} = system(1, @cmd, $stash->{flag_files}{$which});
    # not restoring std here as it all gets redirected again shortly anyway
  }
  else { # use fork
    _fork_exec( $which, $stash );
  }
}

sub _fork_exec {
  my ($which, $stash) = @_;
  my $pid = fork;
  if ( not defined $pid ) {
    Carp::confess "Couldn't fork(): $!";
  }
  elsif ($pid == 0) { # child
    _debug( "# in child process ...\n" );
    untie *STDIN; untie *STDOUT; untie *STDERR;
    _close $stash->{tee}{$which};
    _debug( "# redirecting handles in child ...\n" );
    _open_std( $stash->{child}{$which} );
    _debug( "# calling exec on command ...\n" );
    exec @cmd, $stash->{flag_files}{$which};
  }
  $stash->{pid}{$which} = $pid
}

sub _files_exist { -f $_ || return 0 for @_; return 1 }

sub _wait_for_tees {
  my ($stash) = @_;
  my $start = time;
  my @files = values %{$stash->{flag_files}};
  my $timeout = defined $ENV{PERL_CAPTURE_TINY_TIMEOUT}
              ? $ENV{PERL_CAPTURE_TINY_TIMEOUT} : $TIMEOUT;
  1 until _files_exist(@files) || ($timeout && (time - $start > $timeout));
  Carp::confess "Timed out waiting for subprocesses to start" if ! _files_exist(@files);
  unlink $_ for @files;
}

sub _kill_tees {
  my ($stash) = @_;
  if ( $IS_WIN32 ) {
    _debug( "# closing handles with CloseHandle\n");
    CloseHandle( GetOsFHandle($_) ) for values %{ $stash->{tee} };
    _debug( "# waiting for subprocesses to finish\n");
    my $start = time;
    1 until wait == -1 || (time - $start > 30);
  }
  else {
    _close $_ for values %{ $stash->{tee} };
    waitpid $_, 0 for values %{ $stash->{pid} };
  }
}

sub _slurp {
  seek $_[0],0,0; local $/; return scalar readline $_[0];
}

#--------------------------------------------------------------------------#
# _capture_tee() -- generic main sub for capturing or teeing
#--------------------------------------------------------------------------#

sub _capture_tee {
  _debug( "# starting _capture_tee with (@_)...\n" );
  my ($tee_stdout, $tee_stderr, $merge, $code, $files) = @_;
  # save existing filehandles and setup captures
  local *CT_ORIG_STDIN  = *STDIN ;
  local *CT_ORIG_STDOUT = *STDOUT;
  local *CT_ORIG_STDERR = *STDERR;
  # find initial layers
  my %layers = (
    stdin   => [PerlIO::get_layers(\*STDIN) ],
    stdout  => [PerlIO::get_layers(\*STDOUT)],
    stderr  => [PerlIO::get_layers(\*STDERR)],
  );
  _debug( "# existing layers for $_\: @{$layers{$_}}\n" ) for qw/stdin stdout stderr/;
  # bypass scalar filehandles and tied handles
  my %localize;
  $localize{stdin}++,  local(*STDIN)  if grep { $_ eq 'scalar' } @{$layers{stdin}};
  $localize{stdout}++, local(*STDOUT) if grep { $_ eq 'scalar' } @{$layers{stdout}};
  $localize{stderr}++, local(*STDERR) if grep { $_ eq 'scalar' } @{$layers{stderr}};
  $localize{stdout}++, local(*STDOUT), _open( \*STDOUT, ">&=1") if tied *STDOUT && $] >= 5.008;
  $localize{stderr}++, local(*STDERR), _open( \*STDERR, ">&=2") if tied *STDERR && $] >= 5.008;
  _debug( "# localized $_\n" ) for keys %localize;
  my %proxy_std = _proxy_std();
  _debug( "# proxy std is @{ [%proxy_std] }\n" );
  my $stash = { old => _copy_std() };
  # update layers after any proxying
  %layers = (
    stdin   => [PerlIO::get_layers(\*STDIN) ],
    stdout  => [PerlIO::get_layers(\*STDOUT)],
    stderr  => [PerlIO::get_layers(\*STDERR)],
  );
  _debug( "# post-proxy layers for $_\: @{$layers{$_}}\n" ) for qw/stdin stdout stderr/;
  # get handles for capture and apply existing IO layers
  $stash->{new}{$_} = $stash->{capture}{$_} = _capture_file( $_, $files ) for qw/stdout stderr/;
  _debug("# will capture $_ on " .fileno($stash->{capture}{$_})."\n" ) for qw/stdout stderr/;
  # tees may change $stash->{new}
  _start_tee( stdout => $stash ) if $tee_stdout;
  _start_tee( stderr => $stash ) if $tee_stderr;
  _wait_for_tees( $stash ) if $tee_stdout || $tee_stderr;
  # finalize redirection
  $stash->{new}{stderr} = $stash->{new}{stdout} if $merge;
  $stash->{new}{stdin} = $stash->{old}{stdin};
  _debug( "# redirecting in parent ...\n" );
  _open_std( $stash->{new} );
  # execute user provided code
  my ($exit_code, $inner_error, $outer_error, @user_code_result);
  {
    local *STDIN = *CT_ORIG_STDIN if $localize{stdin}; # get original, not proxy STDIN
    local *STDERR = *STDOUT if $merge; # minimize buffer mixups during $code
    _debug( "# finalizing layers ...\n" );
    _relayer(\*STDOUT, $layers{stdout});
    _relayer(\*STDERR, $layers{stderr}) unless $merge;
    _debug( "# running code $code ...\n" );
    local $@;
    @user_code_result = eval {
      my @res = $code->();
      $inner_error = $@;
      return @res;
    };
    $exit_code = $?; # save this for later
    $outer_error = $@; # save this for later
  }
  # restore prior filehandles and shut down tees
  _debug( "# restoring ...\n" );
  _open_std( $stash->{old} );
  _close( $_ ) for values %{$stash->{old}}; # don't leak fds
  _unproxy( %proxy_std );
  _kill_tees( $stash ) if $tee_stdout || $tee_stderr;
  # return captured output
  _relayer($stash->{capture}{stdout}, $layers{stdout});
  _relayer($stash->{capture}{stderr}, $layers{stderr}) unless $merge;
  _debug( "# slurping captured $_ with layers: @{[PerlIO::get_layers($stash->{capture}{$_})]}\n") for qw/stdout stderr/;
  my $got_out = _slurp($stash->{capture}{stdout});
  my $got_err = $merge ? q() : _slurp($stash->{capture}{stderr});
  print CT_ORIG_STDOUT $got_out if $localize{stdout} && $tee_stdout;
  print CT_ORIG_STDERR $got_err if !$merge && $localize{stderr} && $tee_stdout;
  $? = $exit_code;
  $@ = $inner_error if $inner_error;
  die $outer_error if $outer_error;
  _debug( "# ending _capture_tee with (@_)...\n" );
  return wantarray ? ($got_out, @user_code_result) : $got_out if $merge;
  return wantarray ? ($got_out, $got_err, @user_code_result) : $got_out;
}

#--------------------------------------------------------------------------#
# capture to files
#--------------------------------------------------------------------------#

sub _capture_file {
  my ( $target, $files ) = @_;
  
  return File::Temp->new if !$files->{$target};
  
  Carp::confess "$target file '$files->{$target}' already exists, set clobber => 1 to override"
    if $files->{new_files} and _files_exist( $files->{$target} );
  
  my $mode = "+>>";
  $mode = "+>" if $files->{clobber};
  
  my $fh = Symbol::gensym;
  _open $fh, "$mode$files->{$target}";
  
  return $fh;
}

sub capture_files { return { @_ }; }

#--------------------------------------------------------------------------#
# create API subroutines from [tee STDOUT flag, tee STDERR, merge flag]
#--------------------------------------------------------------------------#

my %api = (
  capture         => [0,0,0],
  capture_merged  => [0,0,1],
  tee             => [1,1,0],
  tee_merged      => [1,0,1], # don't tee STDOUT since merging
);

for my $sub ( keys %api ) {
  my $args = join q{, }, @{$api{$sub}};
  eval "sub $sub(&;\$) {unshift \@_, $args; goto \\&_capture_tee;}"; ## no critic
}

1;



=pod

=head1 NAME

Capture::Tiny::Extended - Capture STDOUT and STDERR from from Perl, XS or external programs (with some extras)

=head1 VERSION

version 0.114

=head1 SYNOPSIS

   use Capture::Tiny::Extended qw/capture tee capture_merged tee_merged/;
 
   # capture return values
 
   my ($stdout, $stderr, @return) = capture {
     # your code here
     return system( 'ls' );
   };
 
   ($merged, @return) = capture_merged {
     # your code here
     return system( 'ls' );
   };
 
   # or use explicit capture files
 
   ($stdout, $stderr, @return) = capture(
     sub { # your code here },
     { stdout => 'stdout.log' }
   );
 
   # or with sugar
 
   use Capture::Tiny::Extended qw/capture tee capture_merged tee_merged capture_files/;
 
   ($stdout, $stderr, @return) = capture {
     # your code here
   }
   capture_files (
     stdout => 'stdout.log',
     stderr => 'stderr.log',
   );

=head1 DESCRIPTION

Capture::Tiny::Extended is a fork of L<Capture::Tiny>. It is functionally
identical with the parent module, except for the differences documented in this
POD. Please see the documentation of L<Capture::Tiny> for details on standard
usage.

Please note that this can be considered an experimental module in some respects.
I am not as experienced with the subject matter (and in general) as David Golden
and mostly implemented these features here because i needed them fast and did
not have the time to spare to wait for them to get into L<Capture::Tiny>. If you
need capture functionality for mission-critical parts, consider whether
L<Capture::Tiny> might be enough for the job.

Of course I will however make all efforts to make this as stable and useful as
possible by keeping it up-to-date (as my time permits) with changes and bugfixes
applied to L<Capture::Tiny>, as well as responding and addressing and change
requests or bug reports for this module.

=for Pod::Coverage capture capture_merged tee tee_merged

=head1 DIFFERENCES

=head2 Capturing Return Values

When executing code within a capture you sometimes want to also keep the return
value, for example when capturing a system() call. In Capture::Tiny this has to
be done like this:

   use Capture::Tiny 'capture';
 
   my $res;
   my ( $out, $err ) = capture {
     $res = system( 'ls' );
   };

Capture::Tiny::Extended automatically captures return values and returns them
after the second return value (or first if you're using the merged functions).

   use Capture::Tiny::Extended 'capture';
 
   my ( $out, $err, $res ) = capture { system( 'ls' ) };

=head2 Teeing In Realtime

Sometimes you want to use Capture::Tiny to capture any and all output of an
action and dump it into a log file, while also displaying it on the screen and
then post-process the results later on (for example for sending status mails).
The only way to do this with Capture::Tiny is code like this:

   use Capture::Tiny 'capture';
   use File::Slurp;
 
   my $res;
   my ( $out, $err ) = capture {
     # lockfile and other processing here along with debug output
     $res = system( 'long_running_program' );
   };
 
   file_write 'out.log', $out;
   send_mail( $err ) if $res;

This has a very big disadvantage. If the long-running program runs too long, and
the perl script is started by something like crontab there is no way for you to
get at the log output. You will have to wait for it to complete before the
captured output is written to the file.

Capture::Tiny::Extended gives you the option to provide filenames for it to use
as capture buffers. This means the output from the captured code will appear on
the screen and in the file in realtime, and will afterwards be available to your
Perl script in the variables returned by the capture function:

   use Capture::Tiny::Extended 'capture';
 
   my ( $out, $err, $res ) = capture(
     sub {
       # lockfile and other processing here along with debug output
       return system( 'long_running_program' );
     },
     {
       stdout => 'out.log',
       stderr => 'err.log',
     }
   );
 
   send_mail( $err ) if $res;

=head2 capture_files

Since using hashes in that way breaks a bit of the syntax magic of the capture
functions (or makes them harder to read), there exists a sugar function to take
the file arguments and pass it on to the capture functions:

   use Capture::Tiny::Extended qw( capture capture_files );
 
   my ( $out, $err, $res ) = capture {
     # lockfile and other processing here along with debug output
     return system( 'long_running_program' );
   }
   capture_files {
     stdout => 'out.log',
     stderr => 'err.log',
   };
 
   send_mail( $err ) if $res;

=head2 Capture File Mode Options

For purposes of avoiding data loss, the default behavior is to append to the
specified files. The key 'new_files' can be set to a true value on the extra
file hash parameter to instruct Capture::Tiny::Extended to attempt to make
files. It will die however if the specified files already exist.

   use Capture::Tiny::Extended 'capture';
 
   my $out = capture_merged(
     sub { system( 'ls' ) },
     { stdout => 'out.log', new_files => 1 }
   );

If existing files should always be overwritten, no matter what, the key
'clobber' can be set instead:

   use Capture::Tiny::Extended 'capture';
 
   my $out = capture_merged(
     sub { system( 'ls' ) },
     { stdout => 'out.log', clobber => 1 }
   );

=head1 WHY A FORK?

The realtime teeing feature was very important for one of my current projects
and i needed it on CPAN to be able to easily distribute it to many systems.
I had provided a patch for the return value capturing on Github to David Golden
a long while ago, but due to being busy with real life, family and more
important projects than this he was not able to find time to proof and integrate
it and in the foreseeable future won't be able to either. At the same time i
lack the Perl file handle, descriptor and layer chops to take full
responsibility for Capture::Tiny itself. Usually i would have just written a
subclass of the original, but since Capture::Tiny is written in functional style
this was not possible.

As such a fork seemed to be the best option to get these features out there. I'd
be more than happy to see them integrated into C::T someday and will keep my git
repository in such a state as to make this as easy as possible. (Lots of
rebasing.)

=head1 ACKNOWLEDGEMENTS

Capture::Tiny is an invaluable tool that uses practically indecent amounts of
creativity to solve decidedly nontrivial problems and circumvents many cliffs
the ordinary coder (and most certainly me) would inevitably crash against.

Many thanks to David Golden for taking the time and braving all those traps of
insanity to create Capture::Tiny.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-capture-tiny-extended at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Capture-Tiny-Extended>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/capture-tiny>

  git clone https://github.com/wchristian/capture-tiny

=head1 AUTHORS

=over 4

=item *

Christian Walde <mithaldu@yahoo.de>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__


