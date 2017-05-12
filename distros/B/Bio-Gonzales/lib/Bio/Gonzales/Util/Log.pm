package Bio::Gonzales::Util::Log;

# shamelessly stolen from Mojo::Log, thanks to Sebastian Riedel & contributors for creating it.
use Moo;

use Carp qw(croak confess);
use Fcntl ':flock';
use POSIX qw/strftime/;

use warnings;
use strict;

use 5.010;

our $VERSION = '0.062'; # VERSION

# Supported log level
my $LEVEL = { debug => 1, info => 2, warn => 3, error => 4, fatal => 5 };
my $is_thread = eval '$threads::threads';

has path       => ( is => 'rw' );
has level      => ( is => 'rw', default => sub {'debug'} );
has namespace  => ( is => 'rw' );
has _fh        => ( is => 'lazy' );
has tee_stderr => ( is => 'rw' );

has append => ( is => 'rw', default => 1 );

sub _build__fh {
  my $self = shift;

  # File
  if ( my $path = $self->path ) {
    my $mode = $self->append ? '>>' : '>';

    croak qq{Can't open log file "$path": $!}
      unless open( my $fh, $mode, $path );
    return $fh;
  }

  # STDERR
  $self->tee_stderr(0);
  return \*STDERR;
}

sub debug { shift->log( debug => @_ ) }
sub error { shift->log( error => @_ ) }
sub warn  { shift->log( warn  => @_ ) }
sub fatal { shift->log( fatal => @_ ) }

sub fatal_confess { shift->log( fatal => @_ ) and confess(@_) }
sub fatal_die     { shift->log( fatal => @_ ) and die(@_) }
sub fatal_croak   { shift->log( fatal => @_ ) and croak(@_) }

sub format {
  my ( $self, $level, @lines ) = @_;

  @lines = map { split /\n/, $_ } @lines;

  my $txt = strftime( "[%d %b %H:%M:%S]", localtime ) . " [" . uc($level) . "]";
  $txt .= " " . $self->namespace       if ( $self->namespace );
  $txt .= ' (t' . threads->tid() . ')' if ($is_thread);
  $txt .= ": ";

  $txt .= join( ( "\n" . ( " " x length($txt) ) ), @lines );
  $txt .= "\n";
  return $txt;
}

sub info { shift->log( info => @_ ) }

sub is_debug { shift->is_level('debug') }
sub is_error { shift->is_level('error') }
sub is_fatal { shift->is_level('fatal') }
sub is_info  { shift->is_level('info') }
sub is_warn  { shift->is_level('warn') }

sub is_level {
  my ( $self, $level ) = @_;
  croak "level not specified" unless ($level);
  return $LEVEL->{ lc $level } >= $LEVEL->{ $ENV{GONZALES_LOG_LEVEL} || $self->level };
}

sub log {
  my ( $self, $level ) = ( shift, shift );

  return unless $self->is_level($level) && ( my $handle = $self->_fh );

  my $msg = $self->format( $level, @_ );

  _print( $handle, $msg );
  _print( \*STDERR, $msg ) if ( $self->tee_stderr );
  return $self;
}

sub _print {
  my ( $handle, $msg ) = ( shift, shift );

  flock $handle, LOCK_EX;
  $handle->print($msg) or croak "Can't write to log: $!";
  $handle->flush;
  flock $handle, LOCK_UN;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Util::Log - basic logging for Bio::Gonzales

=head1 SYNOPSIS

    # logs to stderr by default
    my $l = Bio::Gonzales::Util::Log->new();
    $l->info("started application");

=head1 DESCRIPTION

First of all: Shamelessly stolen from Mojo::Log, thanks to Sebastian Riedel & contributors for creating it.

=head1 METHODS

=over 4

=item B<< $log->path($file) >>

Sets or gets the log file path. If not set, STDERR is used.

=item B<< $log->level($level) >>

Sets or gets the threshold level for logging. Everything lower than this level will not be logged. By default C<debug>.

=item B<< $log->namespace($namespace) >>

Sets or gets the namespace of the logger.

=item B<< $log->tee_stderr($bool) >>

Log to file and STDERR. If no path is set, setting this option has no effect.

=item B<< $log->append($bool) >>

If 1, the logger appends the log output to the log file.

=item B<< $log->debug(@lines) >>

Log debug message.

=item B<< $log->error(@lines) >>

Log error message.

=item B<< $log->warn(@lines) >>

Log warning message.

=item B<< $log->fatal(@lines) >>

Log fatal message.

=item B<< $log->info(@lines) >>

Log info message.

=item B<< $log_text = $log->format($level, @lines) >>

Format C<@lines> and return the formatted text.

=item B<< $log->is_debug >>

Return true if log level is debug.

=item B<< $log->is_error >>

Return true if log level is error.

=item B<< $log->is_fatal >>

Return true if log level is fatal.

=item B<< $log->is_info >>

Return true if log level is info.

=item B<< $log->is_warn >>

Return true if log level is warn.

=item B<< $log->is_level($level) >>

Return true if log level is C<$level>

=item B<< $log->log($level, @lines) >>

Logs C<$lines> with C<$level> to log destination.

=back

=head1 SEE ALSO

L<Mojo::Log>

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
