package Acme::Vuvuzela;
$Acme::Vuvuzela::VERSION = '0.04';
# ABSTRACT: the glorious sound of the vuvuzela

use strict;
use warnings;
use vars qw[$PID];

BEGIN {

  $PID = fork();

  if ( defined $PID and $PID == 0 ) {
    print STDERR 'B';
    while (1) {
      print STDERR 'ZZzz';
      sleep 1;
      exit 0 if $ENV{HARNESS_ACTIVE};
    }
  }

}

sub KILL {
  kill 9, $PID;
}

qq[bzzzzzzzzzzzzzzzzzz];

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Vuvuzela - the glorious sound of the vuvuzela

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Acme::Vuvuzela;

=head1 DESCRIPTION

Acme::Vuvuzela adds the glorious sound of the vuvuzela to your perl programs.

Simply load the module into your scripts for instant vuvuzela experience.

=head1 FUNCTIONS

In case the vuvuzela experience is too much, there is a handy function available:

=over

=item C<KILL>

Stops the vuvuzela dead.

  Acme::Vuvuzela::KILL;

=back

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Vuvuzela>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
