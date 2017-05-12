#!perl

use Test::More 'no_plan';

use Bio::Translator;

my $translator;

ok(
    $translator = custom Bio::Translator(
        \'{
name "Standard" ,
name "SGC0" ,
id 1 ,
ncbieaa  "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
sncbieaa "---M---------------M---------------M----------------------------"
-- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
-- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
-- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
}'
    ),
    'Custom translation table loaded'
);

ok(
    $translator->table->string (), 'Table string'
);