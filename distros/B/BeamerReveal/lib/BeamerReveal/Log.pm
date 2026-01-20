# -*- cperl -*-
# ABSTRACT: Log


package BeamerReveal::Log;
our $VERSION = '20260119.1636'; # VERSION

use parent 'Exporter';
use Carp;

use BeamerReveal::Log::Ansi;

use IO::File;

our $logger;

sub max { $_[$_[0] < $_[1] ] }



sub new {
  $logger->fatal( "Error: internal error - attempt to create two logger objects\n" )
    if ( defined( $logger ) );
  my $class =  shift;
  my $args = { @_ };
  exists $args->{logfilename}
    and exists $args->{opening}
    and exists $args->{closing}
    and exists $args->{labelsize}
    and exists $args->{activitysize}
    or die( "Error: missing argument to (child of) BeamerReveal::Log::new()\n" );
  my $self = BeamerReveal::Log::Ansi->new( %$args );

  $self->{tasks} = [];

  $self->{termwidth} = $self->_terminal_width() - 2;
  $self->{barsize} = $self->{termwidth} - $self->{labelsize} - $self->{activitysize} - 12;
  
  $self->{logfile} = IO::File->new();
  $self->{logfile}->open( ">$self->{logfilename}" )
    or die( "Error cannot open log file $self->{logfilename}" );

  # build opening lines for logfile
  print {$self->{logfile}} _formatLines( $self->{opening}, 76 );
  # build opening lines for terminal
  print _formatLines( $self->{opening}, $self->{termwidth} );
  
  $logger = $self;
  
  return $self;
}


sub log {
  my $self = shift;
  my ( $indent, $message ) = @_;

  say {$self->{logfile}} ( ' ' x $indent ) . $message;
}

sub fatal {
  my $self = shift;
  my ( $message ) = @_;

  say {$self->{logfile}} $message;
  $self->{logfile}->close();
  
  die( "$message\n" .
       "Check the logfile $self->{logfilename} for more information.\n" );
}


sub registerTask {
  my $self = shift;
  my $args = { @_ };
  exists $args->{label}
    and exists $args->{progress}
    and exists $args->{total}
    or $self->fatal( "Error: missing argument to BeamerReveal::Log::registerTask\n" );
  # fill out default value for activity message
  $args->{activity} = '';
 
  my $index = @{$self->{tasks}};
  push @{$self->{tasks}}, $args;
  return $index;
}

sub activate {
  my $self = shift;
  $self->fatal( "Error: internal error - activation through BeamerReveal::Log base class\n" );
}

sub progress {
  my $self = shift;
  $self->fatal( "Error: internal error - progress reported through BeamerReveal::Log base class\n" );
}

sub finalize {
  my $self = shift;
  $self->fatal( "Error: internal error - finalization through BeamerReveal::Log base class\n" );
}

sub _bar_line {
  my ($label, $labelsize, $activity, $activitysize, $done, $total, $width) = @_;
  
  my $pct = $done / $total;
  $pct = 1 if $pct > 1;
  
  my $filled = int($pct * $width);
  my $empty  = $width - $filled;

  return sprintf("%-${labelsize}s: %-${activitysize}s [%s%s] %5.1f%%",
		 $label,
		 $activity,
		 '#' x $filled,
		 '-' x $empty,
		 $pct * 100
		);
}

sub _formatLines {
  my ( $linearrayref, $width, $extra ) = @_;
  $extra ||= '';
  my $openinglines;
  foreach my $line ( @{$linearrayref} ) {
    my ( $left, $right) = split( /\|/, $line );
    if( $left eq $right ) {
      $openinglines .= $extra . ( $left x $width ) . "\n";
    }
    else {
      my $llen = length( $left );
      my $rlen = length( $right );
      my $midspace = $width - $llen - $rlen;
      $openinglines .= $extra . $left . ( ' ' x $midspace ) . $right . "\n";
    }
  }
  return $openinglines;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Log - Log

=head1 VERSION

version 20260119.1636

=head1 SYNOPSIS

Logging facility

=head1 METHODS

=head2 new()

=head2 log()

=head2 registerTask()

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
