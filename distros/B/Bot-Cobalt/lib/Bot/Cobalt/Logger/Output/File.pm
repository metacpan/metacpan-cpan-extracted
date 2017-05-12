package Bot::Cobalt::Logger::Output::File;
$Bot::Cobalt::Logger::Output::File::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Carp;

use Time::HiRes 'sleep';
use IO::File ();
use Fcntl qw/:DEFAULT :flock/;

# ... after which we fall back to warning on stderr with message included:
sub FLOCK_TIMEOUT () { 0.5 }


sub PATH   () { 0 }
sub HANDLE () { 1 }
sub MODE   () { 2 }
sub PERMS  () { 3 }
sub INODE  () { 4 }
sub RUNNING_IN_HELL () { 5 }

sub new {
  my $class = shift;

  my $self = [ 
    '',     ## PATH
    undef,  ## HANDLE
    undef,  ## MODE
    undef,  ## PERMS
    undef,  ## INODE
    0,      ## RUNNING_IN_HELL
  ];

  bless $self, $class;
  
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  confess "new() requires a 'file' argument"
    unless defined $args{file};

  $self->file( $args{file} );

  $self->mode( $args{mode} )
    if defined $args{mode};

  $self->perms( $args{perms} )
    if defined $args{perms};

  if ($^O eq 'MSWin32' or $^O eq 'VMS') {
    $self->[RUNNING_IN_HELL] = 1
  }

  ## Try to open/create file when object is constructed
  $self->_open or croak "Could not open specified file ".$args{file};
  $self->_close if $self->[RUNNING_IN_HELL];

  $self
}

sub file {
  my ($self, $file) = @_;

  if (defined $file) {
    $self->_close if $self->_is_open;
    
    # stringify a Path::Tiny ->
    $self->[PATH] = $file . '';
    
    $self->_open unless $self->[RUNNING_IN_HELL];
  }

  $self->[PATH]
}

sub mode {
  my ($self, $mode) = @_;
  
  return $self->[MODE] = $mode if defined $mode;
  
  $self->[MODE] //= O_WRONLY | O_APPEND | O_CREAT
}

sub perms {
  my ($self, $perms) = @_;
  
  return $self->[PERMS] = $perms if defined $perms;
  
  $self->[PERMS] //= 0666
}

sub _open {
  my ($self) = @_;

  my $fh;
  unless (sysopen($fh, $self->file, $self->mode, $self->perms) ) {
    warn(
      "Log file could not be opened: ", 
      join ' ', $self->file, $!
    );
    return
  }

  binmode $fh, ':utf8';
  $fh->autoflush;

  $self->[INODE] = ( stat $self->file )[1]
    unless $self->[RUNNING_IN_HELL];

  $self->[HANDLE] = $fh
}

sub _close {
  my ($self) = @_;
  
  return 1 unless $self->_is_open;
  
  close $self->[HANDLE];
  $self->[HANDLE] = undef;

  1
}

sub _is_open {
  my ($self) = @_;
  $self->[HANDLE]
}

sub _do_reopen {
  my ($self) = @_;

  ## Are we on a stupid system or dealing with a not-open file?
  return 1 unless $self->_is_open;

  unless ( $self->[RUNNING_IN_HELL] ) {
    ## Do the inodes match?
    return if -e $self->file
      and $self->[INODE] == ( stat $self->file )[1];
  }
  
  1
}

sub _write {
  my ($self, $str) = @_;

  if ($self->_do_reopen) {
    $self->_close;
    $self->_open or warn "_open failure" and return;
  }

  ## FIXME if flock fails, buffer and try next _write up to X items ?
  my $timer = 0;
  until ( flock($self->[HANDLE], LOCK_EX | LOCK_NB) ) {
    if ($timer > FLOCK_TIMEOUT) {
      warn "flock failure for '@{[$self->file]}' ('$str')";
      return
    }
    sleep 0.01;
    $timer += 0.01;
  }

  print { $self->[HANDLE] } $str;

  flock($self->[HANDLE], LOCK_UN);
  
  $self->_close if $self->[RUNNING_IN_HELL];

  1
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Logger::Output::File - Bot::Cobalt::Logger file output

=head1 SYNOPSIS

  $output_obj->add(
    'MyFile' => {
      type => 'File',

      ## Required:
      file => $path_to_log,
      
      ## Optional:
      # perms() defaults to 0666 and is modified by umask:
      perms => 0666,
      # mode() should be Fcntl constants suitable for sysopen()
      # defaults to O_WRONLY | O_APPEND | O_CREAT
      mode => O_WRONLY | O_APPEND | O_CREAT,
    },
  );

See L<Bot::Cobalt::Logger::Output>.

=head1 DESCRIPTION

This is a L<Bot::Cobalt::Logger::Output> writer for logging messages to a 
file.

The constructor requires a L</file> specification (the path to the actual 
file to write). L</perms> or </mode> can also be set at construction 
time but are optional.

The log file is kept open persistently, but closed and reopened if the 
file's inode has changed or the file has disappeared. This doesn't apply 
on Windows, which has no concept of inodes; an open-write-close cycle 
will be executed for each logged message on systems without useful inode 
details, in order to ensure messages are going to the expected file.

Attempts to lock the file for every write; if a lock cannot be obtained after
half a second, falls back to C<warn>ing with the log message included.

Expects UTF-8.

=head2 file

Retrieve or set the current file path.

=head2 perms

Retrieve or set the permissions passed to C<sysopen()>.

This should be an octal mode and will be modified by the current 
C<umask>. 

Defaults to 0666

=head2 mode

Retrieve or set the open mode passed to C<sysopen()>.

See L<Fcntl>.

Defaults to:

   O_WRONLY | O_APPEND | O_CREAT

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
