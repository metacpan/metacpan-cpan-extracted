package Card::Magnetic;

use strict;
use warnings;

# ABSTRACT: Magnetic Stripe parser


sub new {
    my ( $class ) = @_;

    my $self = { stripe => undef };

    return bless $self, $class;
}

sub stripe{
    my ( $self , $stripe ) = @_;

    return $self->{ stripe } if ! $stripe;

    $self->{ stripe } = $stripe;
}

sub parse{
    my ( $self ) = @_;

    my $stripe = $self->{ stripe };

    #track1
    if ( $stripe =~ /^%[\w|\^]+\?\n/ ){
        my $track1 = $&;
        $stripe = $` . $';
        $self->{ track1 }{ track } = $track1;
        chomp $track1;
        if( $track1 =~ /^%(\w)(\d+)\^(\w+)\^(\d{4})(\d{3})(\d{5})(\d{3})/ ) {
            $self->{ track1 } = {
                FORMAT_CODE     => $1,
                PAN             => $2,
                NAME            => $3,
                EXPIRATION_DATE => $4,
                SERVICE_CODE    => $5,
                PVV             => $6,
                CVV             => $7,
            };
        }
        $self->{ tracks }[0] = $track1;
    }
    #track2
    if( $stripe =~ /\;[\w\^]+\?\n/ and ( length $& < 39 ) ){  # stripe...
        my $track2 =  $&;
        $stripe = $` . $';
        $self->{ track2 }{ track } = $track2;
        chomp $track2;
        if( $track2 =~ /(\d+)\^(\d{4})(\d{3})(\d{5})(\d{3})/ ) {
            $self->{ track2 } = {
                PAN             => $1,
                EXPIRATION_DATE => $2,
                SERVICE_CODE    => $3,
                PVV             => $4,
                CVV             => $5,
            };
        }
        $self->{ tracks }[1] = $track2;
    }
    #track3
    if( $stripe =~ /\;[\w\^]+\?\n/ ){
        my $track3 = $&;
        $stripe = $` . $';
        $self->{ track3 }{ track } = $track3;
        chomp $track3;
        if( $track3 =~ /
            (?<fc>\d{2})
            (?<pan>\d+)\^
            (?<cc>\d{3})
            (?<cur>\d{3})
            (?<amountauth>\d{4})
            (?<amountremaining>\d{4})
            (?<cyclebegin>\d{4})
            (?<cyclelenght>\d{2})
            (?<retrycount>\d{1})
            (?<pincp>\d{6})
            (?<interchange>\d{1})
            (?<pansr>\d{2})
            (?<san1>\d{2})
            (?<san2>\d{2})
            (?<expirationdate>\d{4})
            (?<cardsequence>\d{1})
            (?<cardsecurity>\d{9})
            (?<relaymarker>\d{1})
            (?<cryptocheck>\d{6})
            /x){
            $self->{ track3 } = {
                FORMAT_CODE     => $+{fc},
                PAN             => $+{pan},
                COUNTRY_CODE    => $+{cc},
                CURRENCY_CODE   => $+{cur},
                AMOUNTAUTH      => $+{amountauth},
                AMOUNTREMAINING => $+{amountremaining},
                CYCLE_BEGIN     => $+{cyclebegin},
                CYCLE_LENGHT    => $+{cyclelenght},
                RETRY_COUNT     => $+{retrycount},
                PINCP           => $+{pincp},
                INTERCHANGE     => $+{interchange},
                PANSR           => $+{pansr},
                SAN1            => $+{san1},
                SAN2            => $+{san2},
                EXPIRATION_DATE => $+{expirationdate},
                CARD_SEQUENCE   => $+{cardsequence},
                CARD_SECURITY   => $+{cardsecurity},
                RELAY_MARKER    => $+{relaymarker},
                CRYPTO_CHECK    => $+{cryptocheck},
           };
        }
        $self->{ tracks }[2] = $track3;
    }
}

sub track1 {
    my ( $self ) = @_;
    return defined $self->{ tracks }[ 0 ]? $self->{ tracks }[ 0 ] : undef;
}

sub track2 {
    my ( $self ) = @_;
    return defined $self->{ tracks }[ 1 ]? $self->{ tracks }[ 1 ] : undef;
}

sub track3 {
    my ( $self ) = @_;
    return defined $self->{ tracks }[ 2 ]? $self->{ tracks }[ 2 ] : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Card::Magnetic - Magnetic Stripe parser

=head1 VERSION

version 0.003

=head1 SYNOPSIS

This module is a parser to the contents of the magnetic stripe from cards that follow the ISO 7810 norm.

It will build a object that has the ISO 7813 tracks exploded as a hash, with each track, track1, track2
with a hashref with the fields defined by the norm.

Is also possible have cards that has only the track 1 and 2, 2 and 3 or any combination.

    use Card::Magnetic;

    my $card = Card::Magnetic->new();
    $card->stripe( "stripe content" );
    $card->parse();

=head1 NAME

Card::Magnetic - Magnetic stripe parser

=head1 SUBROUTINES/METHODS

=head2 new

Instanciate a new card

=head2 stripe

Stripe accessor

=head2 parse

Parse the stripe and create a internal hash hashref structure with the exploded layout of the card.

    {
        stripe => "full stripe content",
        tracks => [ ], #array with the tracks on the strip
        track1 => { }, # hash with the fields on track 1
        track2 => { }, # Same as track 1, will have a hash with the track2 fields
        track3 => { }, # Track3 
    }

=head2 track1

Return the string of the track, 

=head2 track2

Return the string of the track, 

=head2 track3

Return the string of the track, 

=head1 AUTHOR

Frederico Recsky <recsky@cpan.org>

=SUPPORT

You can find the source code and more details about magnetic cards
on the links above:

=over 4

=item GitHub FredericoRecsky/Card
L<https://github.com/fredericorecsky/card>

=item ISO 7813 Explanation
L<http://www.gae.ucm.es/~padilla/extrawork/tracks.html>

=LICENSE AND COPYRIGHT

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederico Recsky <cartas@frederico.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Frederico Recsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
