# -*- cperl -*-
# ABSTRACT: IPC::Run


package BeamerReveal::IPC::Run;
our $VERSION = '20251226.2107'; # VERSION

use strict;
use warnings;

use IPC::Run;
use File::chdir;


sub run {
  my ( $cmd, $coreId, $indent, $dir ) = @_;
  my ( $in, $out, $err );
  my $r;
  eval {
    if( defined $dir ) {
      local $CWD = $dir;
      $r = IPC::Run::run( $cmd, \$in, \$out, \$err );
    }
    else {
      $r = IPC::Run::run( $cmd, \$in, \$out, \$err );
    }
  };
    
  if ( !defined( $r ) ) {
    die( "Error: $@\n" );
  }
  else {
    if ( $r ) {
      say STDERR "@{[' ' x $indent]}- $cmd->[0] run in thread no $coreId finished";
    }
    else {
      die( "@{[' ' x $indent]}- $cmd->[0] run in thread no $coreId failed (check log file)\n" );
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::IPC::Run - IPC::Run

=head1 VERSION

version 20251226.2107

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
