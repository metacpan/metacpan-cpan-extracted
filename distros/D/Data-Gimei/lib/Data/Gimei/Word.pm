package Data::Gimei::Word;

use warnings;
use v5.22;

use Class::Tiny qw (
  kanji
  hiragana
  katakana
  romaji
);

sub BUILDARGS {
    my $class = shift;

    my %args;
    if ( 'ARRAY' eq ref $_[0] ) {
        %args = (
            kanji    => $_[0]->[0],
            hiragana => $_[0]->[1],
            katakana => $_[0]->[2],
            romaji   => $_[0]->[3]
        );
    } else {
        %args = @_;
    }
    $args{'romaji'} = ucfirst( $args{'romaji'} ) if $args{'romaji'};

    return \%args;
}

1;
