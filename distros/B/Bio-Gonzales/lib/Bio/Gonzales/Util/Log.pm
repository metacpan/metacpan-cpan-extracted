package Bio::Gonzales::Util::Log;

# shamelessly stolen from Mojo::Log, thanks to Sebastian Riedel & contributors for creating it.
use Moo;

use Carp 'croak';
use Fcntl ':flock';
use POSIX qw/strftime/;

use warnings;
use strict;

use 5.010;

our $VERSION = '0.0546'; # VERSION

# Supported log level
my $LEVEL = { debug => 1, info => 2, warn => 3, error => 4, fatal => 5 };
my $is_thread = eval '$threads::threads';

has path  => ( is => 'rw' );
has level => ( is => 'rw', default => sub {'debug'} );
has namespace => (is => 'rw');
has _fh   => ( is => 'lazy' );
has tee_stderr => (is => 'rw');

sub _build__fh {
  my $self = shift;

  # File
  if ( my $path = $self->path ) {
    croak qq{Can't open log file "$path": $!}
      unless open my $file, '>>', $path;
    return $file;
  }

  # STDERR
  $self->tee_stderr(0);
  return \*STDERR;
}

sub debug { shift->log( debug => @_ ) }
sub error { shift->log( error => @_ ) }
sub warn  { shift->log( warn  => @_ ) }
sub fatal { shift->log( fatal => @_ ) }

sub format {
  my ( $self, $level, @lines ) = @_;


  my $txt = '[' . strftime("%Y-%m-%d %H:%M:%S", localtime) . "] [" . uc($level) . "]";
  $txt .= " " . $self->namespace . ":" if ( $self->namespace );
  $txt .= ' [t' . threads->tid() .']' if($is_thread);
  $txt .= " " . join( "\n", @lines, '' );
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
  return $LEVEL->{ lc $level } >= $LEVEL->{ $ENV{GONZALES_LOG_LEVEL} || $self->level };
}

sub log {
  my ( $self, $level ) = ( shift, shift );

  return unless $self->is_level($level) && ( my $handle = $self->_fh );

  my $msg =  $self->format( $level, @_ ) ;

  _print($handle, $msg);
  _print(\*STDERR, $msg) if($self->tee_stderr);
}

sub _print {
  my ($handle, $msg) = (shift, shift);

  flock $handle, LOCK_EX;
  $handle->print($msg) or croak "Can't write to log: $!";
  $handle->flush;
  flock $handle, LOCK_UN;
}

1;

__END__

=head1 NAME



=head1 SYNOPSIS


=head1 DESCRIPTION

First of all: Shamelessly stolen from Mojo::Log, thanks to Sebastian Riedel & contributors for creating it.

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

L<Mojo::Log>

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
