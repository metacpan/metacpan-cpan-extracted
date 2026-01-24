# -*- cperl -*-
# ABSTRACT: Log::Ansi


package BeamerReveal::Log::Ansi;
our $VERSION = '20260123.1702'; # VERSION

use parent 'BeamerReveal::Log';
use Carp;
use Term::ReadKey;


sub new {
  my $class =  shift;
  my $self = { @_ };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;
  return $self;
}


sub activate {
  my $self = shift;
  my $nofTasks = @{$self->{tasks}};
  # make initial drawing
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
  _ansi_down( $taskId ) if( $taskId ); _ansi_clr_eol();
  print BeamerReveal::Log::_bar_line( $task->{label}, $self->{labelsize},
				      $task->{activity}, $self->{activitysize},
				      $progress, $task->{total}, $self->{barsize} );
  print "\n";
  _ansi_up( $taskId + 1 );
}

sub finalize {
  my $self = shift;
  _ansi_down( scalar @{$self->{tasks}} );
  print BeamerReveal::Log::_formatLines( $self->{closing}, $self->{termwidth}, $self->{extra} );
  $self->log( '0', 'Done' );
}

sub _ansi_up        { print "\e[" . $_[0] . "A"; }
sub _ansi_down      { print "\e[" . $_[0] . "B"; }
sub _ansi_cr        { print "\r"; }
sub _ansi_clr_eol   { print "\e[K"; }

sub _terminal_width {
  my $self = shift;
  my ($cols, $rows) = Term::ReadKey::GetTerminalSize();
  return $cols;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Log::Ansi - Log::Ansi

=head1 VERSION

version 20260123.1702

=head1 SYNOPSIS

Logging facility for Ansi terminal

=head1 METHODS

=head2 new()

=head2 activate()

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
