package Config::From::Backend;
$Config::From::Backend::VERSION = '0.08';

use utf8;
use Moose;

has 'debug' => (
                is       => 'rw',
               );

has 'name'  => (
                is       => 'rw',
                isa      => 'Str',
            );


sub _log{
  my ($self, $msg ) = @_;

  return if ! $self->debug;

  say STDERR "[debug] $msg";
}

=head1 NAME

Config::From::Backend -  Base Backend

=head1 VERSION

version 0.08

=head1 SUBROUTINES/METHODS



=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=cut


1;
