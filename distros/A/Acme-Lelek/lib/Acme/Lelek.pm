use strict;
use warnings;

package Acme::Lelek;
{
    $Acme::Lelek::VERSION = '1.003';
}

# ABSTRACT: encode/decode text to lelek code.
use autobox::Core;
use Convert::BaseN;
use Const::Fast;
use Moo;

const my $lek_re => qr/^lek$/i;
const my @leks   => qw(lek leK lEk Lek lEK LeK LEk LEK);
const my %octals => map { $leks[$_] => $_ } 0 .. 7;

has base8 => (
    is       => 'ro',
    required => 1,
    default  => sub {
        Convert::BaseN->new( base => 8 );
    }
);

sub encode {
    my ( $self, $msg ) = @_;

    $self->base8->encode($msg)->split('')->grep(qr/[0-7]/)
      ->map( sub { $leks[$_] } )->unshift('AH Le')->join(' ');
}

sub decode {
    my ( $self, $msg ) = @_;

    $self->base8->decode(
        $msg->split(qr/\s+/)->grep($lek_re)->map(
            sub {
                $octals{$_};
            }
          )->join('')
    );
}

1;

__END__

=head1 NAME

Acme::Lelek - encode/decode text to lelek code.

=head1 SYNOPSYS

  use feature 'say';

  my $lek = Acme::Lelek->new;
  my $encoded = $lek->encode("LOL");

  say "encoded : $encoded";
  say "original: " . $lek->decode($encoded);
  
=head1 Methods

=head2 encode

Will encode the string in lelek code.
  
  $lek->encode("LOL");
  # returns : "AH Le lEk Lek lek lEK LEK LeK leK lEK"

=head2 decode

Will decode the lelek code

  $lek->decode("AH Le lEk Lek lek lEK LEK LeK leK lEK");
  # will return "LOL"
  
=head1 SEE ALSO

AH LELEK LEK LEK LEK LEK ( OFICIAL ) HD
L<http://www.youtube.com/watch?v=E1AC_k9izjY>

=cut
