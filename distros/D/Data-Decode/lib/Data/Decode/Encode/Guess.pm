# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode/Encode/Guess.pm 4834 2007-11-03T09:22:42.139028Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Encode::Guess;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Encode();
use Encode::Guess();

__PACKAGE__->mk_accessors($_) for qw(encodings);

sub new
{
    my $class = shift;
    my %args  = @_;
    $args{encodings} ||= [];
    $class->SUPER::new(\%args);
}

sub decode
{
    my ($self, $decoder, $string, $hints) = @_;

    local $Encode::Guess::NoUTFAutoGuess = 1;
    my $guess = Encode::Guess::guess_encoding(
        $string,
        @{ $self->encodings }
    );

    if (! ref $guess) {
        Data::Decode::Exception::Deferred->throw($guess);
    }

    return eval { $guess->decode( $string ) } ||
        Data::Decode::Exception::Deferred->throw("Failed to decode string from " . $guess->name . ": $@")
    ;
}

1;

__END__

=head1 NAME

Data::Decode::Encode::Guess - Generic Encode::Guess Decoder

=head1 SYNOPSIS

  Data::Decode->new(
    strategy => Data::Decode::Encode::Guess->new(
      encodings => [ $enc1, $enc2, $enc3 ]
    )
  );

=head1 METHODS

=head2 new

=head2 decode

=cut
