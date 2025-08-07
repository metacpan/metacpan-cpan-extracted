use strict;
use warnings;

use Test::More;
use Test::Spelling;
use Pod::Wordlist;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

$ENV{LANG} = 'en_US';

add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );


__DATA__

ACKNOWLEDGEMENTS
Nguyen
Oanh
Rindfrey
oanhnn

