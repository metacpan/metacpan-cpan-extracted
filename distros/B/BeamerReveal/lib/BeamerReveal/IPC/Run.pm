# -*- cperl -*-
# ABSTRACT: IPC::Run


package BeamerReveal::IPC::Run;
our $VERSION = '20260120.1958'; # VERSION

use strict;
use warnings;

use IPC::Run qw(harness start pump finish);

use File::chdir;


sub run {
  my ( $cmd, $coreId, $indent, $dir ) = @_;
  my ( $out, $err );

  my $logger = $BeamerReveal::Log::logger;
  
  my $r;
  eval {
    if( defined $dir ) {
      local $CWD = $dir;
      $r = IPC::Run::run( $cmd, \undef, \$out, \$err );
    }
    else {
      $r = IPC::Run::run( $cmd, \undef, \$out, \$err );
    }
  };
    
  if ( !defined( $r ) ) {
    $logger->fatal( "Error: $@\n" );
  }
  else {
    if ( $r ) {
      $logger->log( $indent, "- $cmd->[0] run in thread no $coreId finished" );
    }
    else {
      $logger->fatal( "- $cmd->[0] run in thread no $coreId failed (check log file)\n" );
    }
  }
}

sub runsmart {
  my ( $cmd, $mode, $regexp, $subroutine, $coreId, $indent, $dir ) = @_;
  my ( $in, $out, $err ) = ( '', undef, undef );

  # the stream to read the progress info from is set by $mode
  my $progress = ( $mode == 2 ) ? \$err : \$out;

  # get the logger
  my $logger = $BeamerReveal::Log::logger;

  # run the process until finish
  local $CWD = $dir if defined( $dir );
  my $h = harness $cmd, \$in, \$out, \$err;
  start $h;
  while( $h->pumpable ) {
    pump $h;
    my @matches = $$progress =~ $regexp;
    if ( scalar @matches ) {
      $subroutine->( @matches );
      $$progress = '';
    }
  }
  finish $h or $logger->fatal( "Error: subprocess $cmd->[0] returned $?\n$err" );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::IPC::Run - IPC::Run

=head1 VERSION

version 20260120.1958

=head1 SYNOPSIS

helper package to encapsulate calls to IPC::Run::run(). Do not use directly.

=head1 METHODS

=head2 run()

  BeamerReveal::IPC::Run::run( $cmd, $coreId, $indent, $dir )

Runs a command and collects stdout and stderror (which are discarded).

=over 4

=item . C<$cmd>

reference to array containing the command and its arguments

=item . C<$coreId>

number of the thread the command wil run in

=item . C<$indent>

indent level for error messages

=item . C<$dir>

directory to run the command from

=back

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
