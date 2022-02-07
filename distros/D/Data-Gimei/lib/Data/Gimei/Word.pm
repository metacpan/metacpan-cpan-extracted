package Data::Gimei::Word;

use English;
use utf8;
use feature ':5.12';

use Moo;
use namespace::clean;

has kanji    => ( is => 'ro' );
has hiragana => ( is => 'ro' );
has katakana => ( is => 'ro' );
has romaji   => ( is => 'ro' );

around BUILDARGS => sub {
    my $orig  = shift;
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
    return $class->$orig(%args);
};

1;
