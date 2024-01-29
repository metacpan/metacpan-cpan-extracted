package Data::Gimei::Word;

use 5.010;
use strict;
use warnings;

use Class::Tiny qw (
  kanji
  hiragana
  katakana
  romaji
);

sub BUILDARGS {
    my ( $class, $aref ) = @_;

    my %args = (
        kanji    => $aref->[0],
        hiragana => $aref->[1],
        katakana => $aref->[2],
    );
    $args{romaji} = ucfirst( $aref->[3] ) if ( $aref->[3] );

    return \%args;
}

sub to_s {
    my $self = shift;

    return sprintf( "%s, %s, %s, %s",
        $self->kanji, $self->hiragana, $self->katakana, $self->romaji );
}
1;
