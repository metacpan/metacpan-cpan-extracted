# -*- cperl -*-
# ABSTRACT: Log


package BeamerReveal::Log::Win32;
our $VERSION = '20251230.2042'; # VERSION

use parent 'BeamerReveal::Log';
use Carp;


sub new {
  my $class =  shift;

  my $self = { @_ };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  eval { $self->_win_init(); 1 } or do {
    # fall back to Ansi if Win32 API not available;
    $BeamerReveal::Log::logger->log( 0, "- Did not find Win32 API, reverting to ANSI API" );
    return BeamerReveal::Log::Ansi->new( @_ );
  };
  
  return $self;
}

sub activate {
  my $self = shift;
  my $nofTasks = @{$self->{tasks}};
  # make initial drawing
  $self->{WCON}->Write( "\n" x $nofTasks );
  $self->{base_y} -= $nofTasks;
  for( my $i = 0; $i < $nofTasks; ++$i ) {
    $self->progress( $i, 0 );
  }
}

  
sub progress {
  my $self = shift;
  my ( $taskId, $progress, $activity, $total ) = @_;
  my $task = $self->{tasks}->[$taskId];
  $task->{total} = $total if defined( $total );
  $task->{activity} = $activity if defined( $activity );
  $task->{progress} = $progress;
  $self->_win_goto( $self->{base_x}, $self->{base_y} + $taskId );
  $self->_win_clr_eol();
  $self->{WCON}->Write( ' ' . BeamerReveal::Log::_bar_line( $task->{label}, $self->{labelsize},
							    $task->{activity}, $self->{activitysize},
							    $progress, $task->{total}, $self->{barsize} ) );
}

sub finalize {
  my $self = shift;
  $self->_win_goto( 0, $self->{base_y} + @{$self->{tasks}} );
  $self->{WCON}->Write( BeamerReveal::Log::_formatLines( $self->{closing}, $self->{termwidth}, $self->{extra} ) );
  $self->log( '0', 'Done' );
}


sub _win_init {
  my $self = shift;

  require Win32::Console;
  Win32::Console->import();
  
  #$self->{WCON} = Win32::Console->new( Win32::Console::STD_OUTPUT_HANDLE() );

  open my $CON, '>:raw', 'CONOUT$'
    or $self->fatal( 0, "Error: cant open CONOUT$: $!" );
  my $h = Win32API::File::GetOSFHandle( fileno( $CONN ) );
  $self->{WCON} = Win32::Console->new( $h );
  
  # Cursor AFTER reserving lines; region starts N lines above current cursor
  ( undef, $self->{base_y} ) = $self->{WCON}->Cursor();
  $self->{base_x} = 0;
}

sub _win_goto {
  my $self = shift;
  my ($x, $y) = @_;
  $self->{WCON}->Cursor($x, $y);
}

sub _win_clr_eol {
  my $self = shift;
  my ($cols, $rows) = $self->{WCON}->Size();
  my ($x, $y) = $self->{WCON}->Cursor();
  my $n = $cols - $x;
  $self->{WCON}->Write(' ' x $n);
  $self->{WCON}->Cursor($x, $y);
}

sub terminal_width {
  my $self = shift;
  my ($cols, $rows) = $self->{WCON}->Size();
  return $cols;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Log::Win32 - Log

=head1 VERSION

version 20251230.2042

=head1 SYNOPSIS

Logging facility for Win32 API

=head1 METHODS

=head2 new()

=head2 progress()

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
