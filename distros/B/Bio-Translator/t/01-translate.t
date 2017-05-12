#!perl

use Test::More 'no_plan';

use Bio::Translator;

my $seq = 'CTGATATCATGCATGCCATTCTCGACCGCTATGCGCCTCCTGTTCCTCGTGGGCCCAAAA';

my $translator = new Bio::Translator();

is( ${ $translator->translate( \$seq ) },
    'MISCMPFSTAMRLLFLVGPK', 'Translate frame 1' );

is( ${ $translator->translate( \$seq, { lower => 1 } ) },
    '*YHACHSRPLCASCSSWAQ', 'Translate frame 2' );

is( ${ $translator->translate( \$seq, { lower => 2 } ) },
    'DIMHAILDRYAPPVPRGPK', 'Translate frame 3' );

is( ${ $translator->translate( \$seq, { strand => -1 } ) },
    'FWAHEEQEAHSGREWHA*YQ', 'Translate frame -1' );

is( ${ $translator->translate( \$seq, { strand => -1, upper => 59 } ) },
    'FGPTRNRRRIAVENGMHDI', 'Translate frame -2' );

is( ${ $translator->translate( \$seq, { strand => -1, upper => 58 } ) },
    'MGPRGTGGA*RSRMACMIS', 'Translate frame -3' );

is( ${ $translator->translate( \$seq, { start => 0 } ) },
    'LISCMPFSTAMRLLFLVGPK', q{Translate 5' partial frame 1} );

is(
    ${
        $translator->translate( \$seq,
            { strand => -1, upper => 58, start => 0 } )
      },
    'LGPRGTGGA*RSRMACMIS',
    q{Translate 5' partial frame -3}
);

is( ${ $translator->translate( \'NNN' ) }, 'X',
    q{Translate not found as 'X'} )
