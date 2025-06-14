package Bible::Reference;
# ABSTRACT: Simple Bible reference parser, tester, and canonicalizer

use 5.022;

use exact;
use exact::class;

our $VERSION = '1.19'; # VERSION

has acronyms              => 0;
has sorting               => 1;
has require_chapter_match => 0;
has require_verse_match   => 0;
has require_book_ucfirst  => 0;
has minimum_book_length   => 3;
has add_detail            => 0;
has simplify              => 0;

my $bibles = {
    ESV => [
        [
            [ 'Genesis',         'Ge',  'Gn',   'Gen'           ],
            [ 'Exodus',          'Ex',  'Exo'                   ],
            [ 'Leviticus',       'Lv',  'Lev'                   ],
            [ 'Numbers',         'Nu',  'Nm',   'Num'           ],
            [ 'Deuteronomy',     'Dt',  'Deu'                   ],
            [ 'Joshua',          'Jsh', 'Jos',  'Josh'          ],
            [ 'Judges',          'Jdg', 'Judg'                  ],
            [ 'Ruth',            'Ru',  'Rut'                   ],
            [ '1 Samuel',        '1Sa', '1Sm',  '1Sam'          ],
            [ '2 Samuel',        '2Sa', '2Sm',  '2Sam'          ],
            [ '1 Kings',         '1Ki', '1Kg',  '1Kgs', '1Kin'  ],
            [ '2 Kings',         '2Ki', '2Kg',  '2Kgs', '2Kin'  ],
            [ '1 Chronicles',    '1Ch', '1Cr',  '1Chr'          ],
            [ '2 Chronicles',    '2Ch', '2Cr',  '2Chr'          ],
            [ 'Ezra',            'Ezr'                          ],
            [ 'Nehemiah',        'Ne',  'Neh'                   ],
            [ 'Esther',          'Est', 'Esth'                  ],
            [ 'Job',             'Jb',  'Jo',   'Job'           ],
            [ 'Psalm',           'Ps',  'Psa',  'Psalms'        ],
            [ 'Proverbs',        'Pr',  'Prv',  'Pro',  'Prov'  ],
            [ 'Ecclesiastes',    'Ec',  'Ecc',  'Eccl'          ],
            [ 'Song of Solomon', 'SS',  'SoS',  'Song of Songs' ],
            [ 'Isaiah',          'Is',  'Isa'                   ],
            [ 'Jeremiah',        'Jr',  'Jer'                   ],
            [ 'Lamentations',    'Lm',  'La',   'Lam'           ],
            [ 'Ezekiel',         'Ezk', 'Ez',   'Eze',  'Ezek'  ],
            [ 'Daniel',          'Da',  'Dn',   'Dan'           ],
            [ 'Hosea',           'Ho',  'Hs',   'Hos'           ],
            [ 'Joel',            'Jl',  'Joe',  'Joel'          ],
            [ 'Amos',            'Am',  'Amo'                   ],
            [ 'Obadiah',         'Ob',  'Oba'                   ],
            [ 'Jonah',           'Jnh', 'Jon',  'Jona'          ],
            [ 'Micah',           'Mi',  'Mic'                   ],
            [ 'Nahum',           'Na',  'Nah'                   ],
            [ 'Habakkuk',        'Hab'                          ],
            [ 'Zephaniah',       'Zp',  'Zep',  'Zph',  'Zeph'  ],
            [ 'Haggai',          'Hg',  'Hag'                   ],
            [ 'Zechariah',       'Zec', 'Zch',  'Zech'          ],
            [ 'Malachi',         'Ml',  'Mal'                   ],
            [ 'Matthew',         'Mt',  'Mat',  'Matt'          ],
            [ 'Mark',            'Mk',  'Mr',   'Mc',   'Mark'  ],
            [ 'Luke',            'Lk',  'Lu',   'Luk'           ],
            [ 'John',            'Joh'                          ],
            [ 'Acts',            'Ac',  'Act'                   ],
            [ 'Romans',          'Ro',  'Rm',   'Rom',  'Roms'  ],
            [ '1 Corinthians',   '1Co', '1Cor'                  ],
            [ '2 Corinthians',   '2Co', '2Cor'                  ],
            [ 'Galatians',       'Ga',  'Gl',   'Gal'           ],
            [ 'Ephesians',       'Ep',  'Eph'                   ],
            [ 'Philippians',     'Php', 'Phil'                  ],
            [ 'Colossians',      'Cl',  'Col'                   ],
            [ '1 Thessalonians', '1Th', '1The'                  ],
            [ '2 Thessalonians', '2Th', '2The'                  ],
            [ '1 Timothy',       '1Ti', '1Tm',  '1Tim'          ],
            [ '2 Timothy',       '2Ti', '2Tm',  '2Tim'          ],
            [ 'Titus',           'Ti',  'Tt'                    ],
            [ 'Philemon',        'Phm', 'Phlm', 'Phile'         ],
            [ 'Hebrews',         'He',  'Heb'                   ],
            [ 'James',           'Jam', 'Jms',  'Jas'           ],
            [ '1 Peter',         '1Pt', '1Pe',  '1Pet'          ],
            [ '2 Peter',         '2Pt', '2Pe',  '2Pet'          ],
            [ '1 John',          '1Jn', '1Jo',  '1Joh'          ],
            [ '2 John',          '2Jn', '2Jo',  '2Joh'          ],
            [ '3 John',          '3Jn', '3Jo',  '3Joh'          ],
            [ 'Jude',            'Jud', 'Jude'                  ],
            [ 'Revelation',      'Rv',  'Rev'                   ],
        ],
        [
            [
                31, 25, 24, 26, 32, 22, 24, 22, 29, 32, 32, 20, 18, 24, 21, 16, 27, 33, 38, 18, 34, 24, 20,
                67, 34, 35, 46, 22, 35, 43, 55, 32, 20, 31, 29, 43, 36, 30, 23, 23, 57, 38, 34, 34, 28, 34,
                31, 22, 33, 26,
            ],
            [
                22, 25, 22, 31, 23, 30, 25, 32, 35, 29, 10, 51, 22, 31, 27, 36, 16, 27, 25, 26, 36, 31, 33,
                18, 40, 37, 21, 43, 46, 38, 18, 35, 23, 35, 35, 38, 29, 31, 43, 38,
            ],
            [
                17, 16, 17, 35, 19, 30, 38, 36, 24, 20, 47, 8, 59, 57, 33, 34, 16, 30, 37, 27, 24, 33, 44,
                23, 55, 46, 34,
            ],
            [
                54, 34, 51, 49, 31, 27, 89, 26, 23, 36, 35, 16, 33, 45, 41, 50, 13, 32, 22, 29, 35, 41, 30,
                25, 18, 65, 23, 31, 40, 16, 54, 42, 56, 29, 34, 13,
            ],
            [
                46, 37, 29, 49, 33, 25, 26, 20, 29, 22, 32, 32, 18, 29, 23, 22, 20, 22, 21, 20, 23, 30, 25,
                22, 19, 19, 26, 68, 29, 20, 30, 52, 29, 12,
            ],
            [
                18, 24, 17, 24, 15, 27, 26, 35, 27, 43, 23, 24, 33, 15, 63, 10, 18, 28, 51, 9, 45, 34, 16,
                33,
            ],
            [ 36, 23, 31, 24, 31, 40, 25, 35, 57, 18, 40, 15, 25, 20, 20, 31, 13, 31, 30, 48, 25 ],
            [ 22, 23, 18, 22 ],
            [
                28, 36, 21, 22, 12, 21, 17, 22, 27, 27, 15, 25, 23, 52, 35, 23, 58, 30, 24, 42, 15, 23, 29,
                22, 44, 25, 12, 25, 11, 31, 13,
            ],
            [
                27, 32, 39, 12, 25, 23, 29, 18, 13, 19, 27, 31, 39, 33, 37, 23, 29, 33, 43, 26, 22, 51, 39,
                25,
            ],
            [ 53, 46, 28, 34, 18, 38, 51, 66, 28, 29, 43, 33, 34, 31, 34, 34, 24, 46, 21, 43, 29, 53 ],
            [
                18, 25, 27, 44, 27, 33, 20, 29, 37, 36, 21, 21, 25, 29, 38, 20, 41, 37, 37, 21, 26, 20, 37,
                20, 30,
            ],
            [
                54, 55, 24, 43, 26, 81, 40, 40, 44, 14, 47, 40, 14, 17, 29, 43, 27, 17, 19, 8, 30, 19, 32,
                31, 31, 32, 34, 21, 30,
            ],
            [
                17, 18, 17, 22, 14, 42, 22, 18, 31, 19, 23, 16, 22, 15, 19, 14, 19, 34, 11, 37, 20, 12, 21,
                27, 28, 23, 9, 27, 36, 27, 21, 33, 25, 33, 27, 23,
            ],
            [ 11, 70, 13, 24, 17, 22, 28, 36, 15, 44 ],
            [ 11, 20, 32, 23, 19, 19, 73, 18, 38, 39, 36, 47, 31 ],
            [ 22, 23, 15, 17, 14, 14, 10, 17, 32, 3 ],
            [
                22, 13, 26, 21, 27, 30, 21, 22, 35, 22, 20, 25, 28, 22, 35, 22, 16, 21, 29, 29, 34, 30, 17,
                25, 6, 14, 23, 28, 25, 31, 40, 22, 33, 37, 16, 33, 24, 41, 30, 24, 34, 17,
            ],
            [
                6, 12, 8, 8, 12, 10, 17, 9, 20, 18, 7, 8, 6, 7, 5, 11, 15, 50, 14, 9, 13, 31, 6,
                10, 22, 12, 14, 9, 11, 12, 24, 11, 22, 22, 28, 12, 40, 22, 13, 17, 13, 11, 5, 26, 17, 11,
                9, 14, 20, 23, 19, 9, 6, 7, 23, 13, 11, 11, 17, 12, 8, 12, 11, 10, 13, 20, 7, 35, 36,
                5, 24, 20, 28, 23, 10, 12, 20, 72, 13, 19, 16, 8, 18, 12, 13, 17, 7, 18, 52, 17, 16, 15,
                5, 23, 11, 13, 12, 9, 9, 5, 8, 28, 22, 35, 45, 48, 43, 13, 31, 7, 10, 10, 9, 8, 18,
                19, 2, 29, 176, 7, 8, 9, 4, 8, 5, 6, 5, 6, 8, 8, 3, 18, 3, 3, 21, 26, 9, 8,
                24, 13, 10, 7, 12, 15, 21, 10, 20, 14, 9, 6,
            ],
            [
                33, 22, 35, 27, 23, 35, 27, 36, 18, 32, 31, 28, 25, 35, 33, 33, 28, 24, 29, 30, 31, 29, 35,
                34, 28, 28, 27, 28, 27, 33, 31,
            ],
            [ 18, 26, 22, 16, 20, 12, 29, 17, 18, 20, 10, 14 ],
            [ 17, 17, 11, 16, 16, 13, 13, 14 ],
            [
                31, 22, 26, 6, 30, 13, 25, 22, 21, 34, 16, 6, 22, 32, 9, 14, 14, 7, 25, 6, 17, 25, 18,
                23, 12, 21, 13, 29, 24, 33, 9, 20, 24, 17, 10, 22, 38, 22, 8, 31, 29, 25, 28, 28, 25, 13,
                15, 22, 26, 11, 23, 15, 12, 17, 13, 12, 21, 14, 21, 22, 11, 12, 19, 12, 25, 24,
            ],
            [
                19, 37, 25, 31, 31, 30, 34, 22, 26, 25, 23, 17, 27, 22, 21, 21, 27, 23, 15, 18, 14, 30, 40,
                10, 38, 24, 22, 17, 32, 24, 40, 44, 26, 22, 19, 32, 21, 28, 18, 16, 18, 22, 13, 30, 5, 28,
                7, 47, 39, 46, 64, 34,
            ],
            [ 22, 22, 66, 22, 22 ],
            [
                28, 10, 27, 17, 17, 14, 27, 18, 11, 22, 25, 28, 23, 23, 8, 63, 24, 32, 14, 49, 32, 31, 49,
                27, 17, 21, 36, 26, 21, 26, 18, 32, 33, 31, 15, 38, 28, 23, 29, 49, 26, 20, 27, 31, 25, 24,
                23, 35,
            ],
            [ 21, 49, 30, 37, 31, 28, 28, 27, 27, 21, 45, 13 ],
            [ 11, 23, 5, 19, 15, 11, 16, 14, 17, 15, 12, 14, 16, 9 ],
            [ 20, 32, 21 ],
            [ 15, 16, 15, 13, 27, 14, 17, 14, 15 ],
            [ 21 ],
            [ 17, 10, 10, 11 ],
            [ 16, 13, 12, 13, 15, 16, 20 ],
            [ 15, 13, 19 ],
            [ 17, 20, 19 ],
            [ 18, 15, 20 ],
            [ 15, 23 ],
            [ 21, 13, 10, 14, 11, 15, 14, 23, 17, 12, 17, 14, 9, 21 ],
            [ 14, 17, 18, 6 ],
            [
                25, 23, 17, 25, 48, 34, 29, 34, 38, 42, 30, 50, 58, 36, 39, 28, 27, 35, 30, 34, 46, 46, 39,
                51, 46, 75, 66, 20,
            ],
            [ 45, 28, 35, 41, 43, 56, 37, 38, 50, 52, 33, 44, 37, 72, 47, 20 ],
            [
                80, 52, 38, 44, 39, 49, 50, 56, 62, 42, 54, 59, 35, 35, 32, 31, 37, 43, 48, 47, 38, 71, 56,
                53,
            ],
            [ 51, 25, 36, 54, 47, 71, 53, 59, 41, 42, 57, 50, 38, 31, 27, 33, 26, 40, 42, 31, 25 ],
            [
                26, 47, 26, 37, 42, 15, 60, 40, 43, 48, 30, 25, 52, 28, 41, 40, 34, 28, 41, 38, 40, 30, 35,
                27, 27, 32, 44, 31,
            ],
            [ 32, 29, 31, 25, 21, 23, 25, 39, 33, 21, 36, 21, 14, 23, 33, 27 ],
            [ 31, 16, 23, 21, 13, 20, 40, 13, 27, 33, 34, 31, 13, 40, 58, 24 ],
            [ 24, 17, 18, 18, 21, 18, 16, 24, 15, 18, 33, 21, 14 ],
            [ 24, 21, 29, 31, 26, 18 ],
            [ 23, 22, 21, 32, 33, 24 ],
            [ 30, 30, 21, 23 ],
            [ 29, 23, 25, 18 ],
            [ 10, 20, 13, 18, 28 ],
            [ 12, 17, 18 ],
            [ 20, 15, 16, 16, 25, 21 ],
            [ 18, 26, 17, 22 ],
            [ 16, 15, 15 ],
            [ 25 ],
            [ 14, 18, 19, 16, 14, 20, 28, 13, 28, 39, 40, 29, 25 ],
            [ 27, 26, 18, 17, 20 ],
            [ 25, 25, 22, 19, 14 ],
            [ 21, 22, 18 ],
            [ 10, 29, 24, 21, 21 ],
            [ 13 ],
            [ 15 ],
            [ 25 ],
            [ 20, 29, 22, 11, 14, 17, 17, 13, 21, 11, 19, 17, 18, 20, 8, 21, 18, 24, 21, 15, 27, 21 ],
        ],
    ],
};

sub _build_bible_template ( $source_name, $new_name, $bibles, $books_cb = undef, $verses_cb = undef ) {
    $bibles->{$new_name} = [ map { [ map { [@$_] } @$_ ] } @{ $bibles->{$source_name} } ];
    $books_cb->( $bibles->{$new_name}[0] ) if ($books_cb);
    $verses_cb->( $bibles->{$new_name}[1] ) if ($verses_cb);
    return;
}

_build_bible_template(
    'ESV' => 'RSVCE',
    $bibles,
    sub ($books) {
        splice( @$books, 25, 0,
            [ 'Baruch', 'Ba', 'Br', 'Bar' ],
        );

        splice( @$books, 22, 0,
            [ 'Wisdom', 'Wi', 'Ws', 'Wis' ],
            [ 'Sirach', 'Si', 'Sr', 'Sir' ],
        );

        splice( @$books, 17, 0,
            [ '1 Maccabees', '1Ma', '1Mac' ],
            [ '2 Maccabees', '2Ma', '2Mac' ],
        );

        splice( @$books, 16, 0,
            [ 'Tobit',  'Tb', 'Tob' ],
            [ 'Judith', 'Judi'      ],
        );
    },
    sub ($verses) {
        push( @{ $verses->[26] }, 64, 42 );
        splice( @$verses, 25, 0, [ 21, 35, 37, 37, 9, 73 ] );
        splice( @$verses, 22, 0,
            [ 16, 24, 19, 20, 23, 25, 30, 21, 18, 21, 26, 27, 19, 31, 19, 29, 21, 25, 22 ],
            [
                30, 18, 31, 31, 15, 37, 36, 19, 18, 31, 34, 18, 26, 27, 20, 30, 32, 33, 30, 31, 28, 27, 27,
                34, 26, 29, 30, 26, 28, 25, 31, 24, 31, 26, 20, 26, 31, 34, 35, 30, 23, 25, 33, 23, 26, 20,
                25, 25, 16, 29, 30,
            ],
        );
        splice( @$verses, 16, 1,
            [ 22, 14, 17, 21, 22, 17, 18, 21, 6, 12, 19, 22, 18, 15 ],
            [ 16, 28, 10, 15, 24, 21, 32, 36, 14, 23, 23, 20, 20, 19, 13, 25 ],
            [ 22, 23, 15, 19, 14, 14, 10, 17, 32, 1 ],
            [ 64, 70, 60, 61, 68, 63, 50, 32, 73, 89, 74, 53, 53, 49, 41, 24 ],
            [ 36, 32, 40, 50, 27, 31, 42, 36, 29, 38, 38, 45, 26, 46, 39 ],
        );
    },
);

_build_bible_template(
    'ESV' => 'RSV',
    $bibles,
    sub ($books) {
        push( @$books,
            [ 'Tobit',                       'Tb',    'Tob'                                            ],
            [ 'Judith',                      'Judi',  'Jdt'                                            ],
            [ 'Greek Esther',                'GkEsth'                                                  ],
            [ 'Wisdom',                      'Wi',    'Ws',    'Wis', 'Wisdom of Solomon'              ],
            [ 'Sirach',                      'Si',    'Sr',    'Sir', 'Ben Sira', 'Wisdom of Ben Sira' ],
            [ 'Baruch',                      'Ba',    'Br',    'Bar'                                   ],
            [ 'Letter of Jeremiah',          'LJ',    'Let',   'EpJer'                                 ],
            [ 'Song of the Three Young Men', 'SgThr', 'Three', 'Prayer of Azariah'                     ],
            [ 'Susanna',                     'Sus'                                                     ],
            [ 'Bel and the Dragon',          'Bel'                                                     ],
            [ '1 Maccabees',                 '1Ma',   '1Mac',  '1Macc'                                 ],
            [ '2 Maccabees',                 '2Ma',   '2Mac',  '2Macc'                                 ],
            [ '1 Esdras',                    '1Es',   '1Esd',  '1Esdr'                                 ],
            [ 'Prayer of Manasseh',          'PM',    'Pra',   'Man', 'PrMan'                          ],
            [ 'Psalm 151',                   'Ps151', 'Psa151'                                         ],
            [ '3 Maccabees',                 '3Ma',   '3Mac',  '3Macc'                                 ],
            [ '2 Esdras',                    '2Es',   '2Esd',  '2Esdr'                                 ],
            [ '4 Maccabees',                 '4Ma',   '4Mac',  '4Macc'                                 ],
        );
    },
    sub ($verses) {
        push( @$verses,
            [ 22, 14, 17, 21, 21, 17, 18, 21, 6, 12, 19, 22, 18, 15 ],
            [ 16, 28, 10, 15, 24, 21, 32, 36, 14, 23, 23, 20, 20, 19, 13, 25 ],
            [ 22, 23, 15, 19, 14, 14, 10, 17, 32, 1 ],
            [ 16, 24, 19, 20, 23, 25, 30, 21, 18, 21, 26, 27, 19, 31, 19, 29, 21, 25, 22 ],
            [
                30, 18, 31, 31, 15, 37, 36, 19, 18, 31, 34, 18, 26, 27, 20, 30, 32, 33, 30, 31, 28, 27, 27,
                34, 26, 29, 30, 26, 28, 25, 31, 24, 31, 26, 20, 26, 31, 34, 35, 30, 23, 25, 33, 23, 26, 20,
                25, 25, 16, 29, 30,
            ],
            [ 21, 35, 37, 37, 9 ],
            [ 73 ],
            [ 68 ],
            [ 64 ],
            [ 42 ],
            [ 64, 70, 60, 61, 68, 63, 50, 32, 73, 89, 74, 53, 53, 49, 41, 24 ],
            [ 36, 32, 40, 50, 27, 31, 42, 36, 29, 38, 38, 45, 26, 46, 39 ],
            [ 58, 30, 24, 63, 73, 34, 15, 96, 55 ],
            [ 15 ],
            [ 7 ],
            [ 29, 33, 30, 21, 51, 41, 23 ],
            [ 40, 48, 36, 52, 56, 59, 140, 63, 47, 59, 46, 51, 58, 48, 63, 78 ],
            [ 35, 24, 21, 26, 38, 35, 23, 29, 32, 21, 27, 19, 27, 20, 32, 25, 24, 24 ],
        );
    },
);

$bibles->{Protestant} = $bibles->{ESV};
$bibles->{Catholic}   = $bibles->{RSVCE};
$bibles->{Orthodox}   = $bibles->{RSV};

has _bible      => 'Protestant';
has _bible_data => sub { {} };
has _data       => sub { [] };
has _cache      => sub { {} };
has _bibles     => sub {
    return { map { $_ => [ map { [ map { [ @$_] } @$_ ] } @{ $bibles->{$_} } ] } keys %$bibles };
};

sub bible ( $self, $name = undef ) {
    return $self->_bible unless ($name);

    my $input   = lc( $name || '' );
    my ($bible) = grep { lc $_ eq $input } keys %{ $self->_bibles };

    croak "Could not determine a valid Bible type from input" unless ($bible);
    $self->_bible($bible);

    my $books = [ map { [@$_] } @{ $self->_bibles->{ $self->_bible }[0] } ];

    my $bible_data;
    for my $book_data (@$books) {
        my ( $book, @acronyms ) = @$book_data;

        $bible_data->{book_to_acronym}{$book} = $acronyms[0];
        push( @{ $bible_data->{books} }, $book );
    }
    my $book_count;
    $bible_data->{book_order} = { map { $_ => ++$book_count } @{ $bible_data->{books} } };

    my $canonical = [ map { $_->[0] } @$books ];
    my $options   = { map { shift @$_ => $_ } @$books };
    my $re_map    = { map {
        my $book     = $_;
        my $book_str = $_;
        my @prefix   = (
            ( $book_str =~ s/^(\d)\s// ) ? (
                (
                    (
                        ( $1 == 1 ) ? ( qw( I   First  ) ) :
                        ( $1 == 2 ) ? ( qw( II  Second ) ) :
                        ( $1 == 3 ) ? ( qw( III Third  ) ) :
                        ( $1 == 4 ) ? ( qw( IV  Fourth ) ) : ()
                    ),
                    $1 . '*',
                ),
                $1,
            ) : ()
        );

        my @letters = split( '', $book_str );
        my $unique;
        while (@letters) {
            $unique .= shift @letters;
            last if (
                length $unique >= $self->minimum_book_length
                and (
                    not @prefix and
                        scalar( grep { index( $_, $unique ) == 0 } @$canonical ) == 1 or
                    @prefix and
                        scalar( grep { index( $_, $prefix[-1] . ' ' . $unique ) == 0 } @$canonical ) == 1
                )
            );
        }

        my @matches = $unique;
        push( @matches, $unique .= shift @letters ) while (@letters);

        @matches = map {
            my $match = $_;

            $match .= ')i?(';
            $match =~ s/^(\w)/$1)i-?(/;

            (@prefix) ? ( map { ')' . $_ . ':i?(' . ' ' . $match } @prefix ) : $match;
        } @matches;

        map {
            my $re = reverse $_;

            $re =~ s/\*/'[A-z]+'/ge;
            $re =~ s/\s+/'[\s_]*'/ge;

            $re => $book;
        } @matches, @{ $options->{$book} };
    } @$canonical };

    my @re_parts = sort { length $b <=> length $a } keys %$re_map;

    my $re_refs     = '(?i:[\d:,;\s\-]|\bdna\b|\bro\b|&)*\.?';
    my $re_refs_req =
        '(?i:[\d:,;\s\-]|\bdna\b|\bro\b|&)*' .
        '(?:\d\s*:\s*\d)' .
        '(?i:[\d:,;\s\-]|\bdna\b|\bro\b|&)*\.?';

    my $re_refs_string     = '\b(' . join( '|', map { $re_refs     . $_ } @re_parts ) . ')\b';
    my $re_refs_req_string = '\b(' . join( '|', map { $re_refs_req . $_ } @re_parts ) . ')\b';

    $bible_data->{re_refs_s}  = qr/$re_refs_string/;
    $bible_data->{re_refs_sr} = qr/$re_refs_req_string/;
    $bible_data->{re_books_s} = [ map { [ qr/\b$_\b/, $re_map->{$_} ] } @re_parts ];

    $re_refs_string     =~ s/\(\?\-?i\)//g;
    $re_refs_req_string =~ s/\(\?\-?i\)//g;

    $bible_data->{re_refs_i}  = qr/$re_refs_string/i;
    $bible_data->{re_refs_ir} = qr/$re_refs_req_string/i;
    $bible_data->{re_books_i} = [ map {
        my $this_book = $re_map->{$_};
        s/\(\?\-?i\)//g;
        [ qr/\b$_\b/i, $this_book ];
    } @re_parts ];

    $bible_data->{lengths} = {
        map {
            $bible_data->{books}[$_] => [ @{ $self->_bibles->{$bible}[1][$_] } ]
        } 0 .. @{ $bible_data->{books} } - 1
    };

    $self->_bible_data($bible_data);
    return $bible;
}

sub new ( $self, %params ) {
    $self = $self->SUPER::new(%params);
    $self->bible( $params{bible} || $self->_bible );
    return $self;
}

sub _list ( $start, $stop ) {
    $start++ if ( $start == 0 );
    $stop++  if ( $stop  == 0 );

    my ( $x,  $y ) = sort { $a <=> $b } $start, $stop;
    my @list = $x .. $y;
    @list = reverse(@list) if ( $x < $start );

    return @list;
};

sub expand_ranges ( $self, $book, $text, $compress = 0 ) {
    my $expand = sub ( $start, $stop ) {
        my $start_ch = ( $start =~ s/(\d+):// ) ? $1 : 0;
        my $stop_ch  = ( $stop  =~ s/(\d+):// ) ? $1 : 0;

        if ( not $start_ch and $stop_ch and $start > $stop_ch ) {
            # A: "5-3:4" = translated to "5:1-3:4"

            $start_ch = $start;
            $start    = 1;
        }

        my $skip_chapter_assumption_check = 0;
        if ( $start_ch and $stop_ch and $start and $stop and $start_ch == $stop_ch ) {
            if ( $start <= $stop ) {
                # B: "3:4-3:7" = translated to "3:4-7"

                $stop_ch = 0;
            }
            else {
                # Q: "3:37-3:4" is the reverse of 3:4-3:37

                $stop_ch = 0;
                $skip_chapter_assumption_check = 1;
            }
        }

        my $expance = '';

        if ( not $start_ch and not $stop_ch ) {
            # C: "3-3" = consider as "3"
            # D: "3-5" = consider as a simple range
            # E: "5-3" = consider as a simple reversed range

            $expance = join( ',', _list( $start, $stop ) );
        }

        elsif ( $start_ch and not $stop_ch ) {
            # F: "1:3-15" = consider 3-15 as verses
            # G: "1:15-3" = consider 3 a chapter
            # H: "1:3-3"  = consider the second 3 a chapter
            # I: "3:2-3"  = consider 2-3 as verses
            # J: "3:3-2"  = consider 3-2 as verses

            if ( $start >= $stop and $stop > $start_ch and not $skip_chapter_assumption_check ) {
                $stop_ch = $stop;
                $stop    = $self->_bible_data->{lengths}{$book}[ $start_ch - 1 ];
            }

            $expance = join( ';', grep { defined }
                $start_ch . ':' . join( ',', _list( $start, $stop ) ),
                ( ($stop_ch) ? join( ';', _list( $start_ch + 1, $stop_ch ) ) : undef ),
            );
        }

        elsif ( not $start_ch and $stop_ch ) {
            # K: "3-5:2" = 3-4 are full chapters; plus 5:1-5:2
            # L: "3-3:2" = interpretted as "3:1-2"

            $start_ch = $start;
            $start    = 1;

            $expance = join( ':',
                join( ';', _list( $start_ch, $stop_ch ) ),
                join( ',', _list( $start, $stop ) ),
            );
        }

        elsif ( $start_ch and $stop_ch ) {
            # M: "3:4-4:7" becomes "3:4-*;4:1-7"
            # N: "4:7-3:4" becomes reverse of "3:4-*;4:1-7"
            # O: "3:4-5:2" becomes "3:4-*;4;5:1-2"
            # P: "5:2-3:4" becomes reverse of "3:4-*;4;5:2-*"

            my $reversed = 0;
            if ( $start_ch >= $stop_ch ) {
                ( $start_ch, $stop_ch, $start, $stop ) = ( $stop_ch, $start_ch, $stop, $start );
                $reversed = 1;
            }

            my $reverse = sub { ($reversed) ? reverse(@_) : @_ };

            $expance = join( ';', grep { defined }
                $reverse->(
                    $start_ch . ':' . join( ',', $reverse->( _list(
                        $start,
                        $self->_bible_data->{lengths}{$book}[ $start_ch - 1 ],
                    ) ) ),
                    (
                        ( $stop_ch - $start_ch > 1 )
                            ? join( ',', $reverse->( _list( $start_ch + 1, $stop_ch - 1 ) ) )
                            : undef
                    ),
                    $stop_ch . ':' . join( ',', $reverse->( _list( 1, $stop ) ) ),
                ),
            );
        }

        $expance;
    };

    $text =~ s/[\s,]+/,/g;
    $text =~ s/^,//g;
    $text =~ s/(\d+(?::\d+)?)\-(\d+(?::\d+)?)/ $expand->( $1, $2 ) /ge;
    $text =~ s/([,;])/$1 /g unless $compress;

    return $text;
};

sub in ( $self, @input ) {
    return $self unless (@input);

    my $re_refs = $self->_bible_data->{
        're_refs_' .
        ( ( $self->require_book_ucfirst ) ? 's' : 'i' ) .
        ( ( $self->require_verse_match  ) ? 'r' : ''  )
    };

    my $re_books = ( $self->require_book_ucfirst )
        ? $self->_bible_data->{re_books_s}
        : $self->_bible_data->{re_books_i};

    for my $string (@input) {
        $string = scalar( reverse $string // '' );
        my @processed;
        while (1) {
            my ( $pre, $ref, $post ) = split( /$re_refs/, $string, 2 );
            last unless ($ref);

            $ref =~ s/(\d)([[:alpha:]])/$1 $2/;

            $string = $post;

            my $space = ( $ref =~ s/^((?i:\W|\bdna\b|\bro\b|&)+)// ) ? $1 : '';
            $ref =~ s/\s+/ /g;
            $pre = $pre . $space;
            push( @processed, $pre );

            my $orig_ref = $ref;

            my $book;
            for (@$re_books) {
                if ( $ref =~ /$_->[0]/ ) {
                    $book = $_->[1];
                    last;
                }
            }

            my $ref_out = [$book];
            my $numbers = [];

            $ref =~ s/(?:\bdna\b|\bro\b|&)/,/g;
            $ref = scalar reverse $ref;

            if ( $ref =~ /([\d:,;\s\-]+)$/ ) {
                my $range = $self->expand_ranges( $book, $1, 1 );

                my $verse_context = 0;
                my $last_d        = 0;

                while ( $range =~ s/^(\d+)([:,;]?)\D*//g ) {
                    my ( $d, $s ) = ( $1, $2 || '' );

                    $verse_context = 0 if ( $s eq ':' or $d <= $last_d );

                    unless ($verse_context) {
                        push( @$numbers, [$d] );
                    }
                    else {
                        push( @{ $numbers->[-1] }, [] ) unless ( @{ $numbers->[-1] } > 1 );
                        push( @{ $numbers->[-1][-1] }, $d );
                    }

                    $last_d = ($verse_context) ? $d : 0;

                    $verse_context = 1 if ( $s eq ':' );
                    $verse_context = 0 if ( $s eq ';' );
                }
            }

            if ( @$numbers or not $self->require_chapter_match ) {
                push( @$ref_out, $numbers ) if (@$numbers);
                push( @processed, $ref_out );
            }
            else {
                $processed[-1] .= $orig_ref;
            }
        }

        push( @processed, $string );
        push(
            @{ $self->_data },
            [ grep { length } map { ( ref $_ ) ? $_ : scalar reverse $_ } reverse @processed ],
        );
    }

    return $self;
}

sub clear ($self) {
    $self->_data([]);
    return $self;
}

sub books ($self) {
    return (wantarray) ? @{ $self->_bible_data->{books} } : $self->_bible_data->{books};
}

sub as_array ( $self, $data = undef ) {
    if (
        $data or
        not $self->_cache->{data} or
        not (
            $self->_cache->{sorting}  and $self->_cache->{sorting}  == $self->sorting and
            $self->_cache->{acronyms} and $self->_cache->{acronyms} == $self->acronyms
        )
    ) {
        $data //= [ map { grep { ref } @$_ } @{ $self->_data } ];
        $data = [
            map { [
                map {
                    ( ref $_ ) ? [
                        map {
                            ( ref $_ ) ? [
                                map {
                                    ( ref $_ ) ? [
                                        @$_
                                    ] : $_
                                } @$_
                            ] : $_
                        } @$_
                    ] : $_
                } @$_
            ] }
            @$data
        ];

        $data = [ map {
            my $book = $_->[0];

            if ( ref $_->[1] ) {
                $_->[1] = [ map {
                    $_->[1] //= [ 1 .. ( $self->_bible_data->{lengths}{$book}[ $_->[0] - 1 ] || 0 ) ];
                    $_;
                } @{ $_->[1] } ];
            }
            else {
                my $chapter;
                $_->[1] = [ map { [ ++$chapter, [ 1 .. $_ ] ] } @{ $self->_bible_data->{lengths}{$book} } ];
            }

            $_;
        } @$data ] if ( $self->add_detail );

        if ( $self->sorting ) {
            my $data_by_book = {};
            push( @{ $data_by_book->{ $_->[0] } }, @{ $_->[1] || [] } ) for (@$data);

            $data = [
                map {
                    my $book = [ $_->[1] ];

                    my $dedup;
                    for my $chapter ( @{ $data_by_book->{ $_->[1] } } ) {
                        $dedup->{ $chapter->[0] } //= {};
                        $dedup->{ $chapter->[0] }{$_} = 1 for ( @{ $chapter->[1] } );
                    }

                    my $chapters = [
                        map {
                            my $chapter = [$_];
                            my @verses = keys %{ $dedup->{$_} };
                            push( @$chapter, [ sort { $a <=> $b } @verses ] ) if @verses;
                            $chapter;
                        }
                        sort { $a <=> $b }
                        keys %$dedup
                    ];

                    push( @$book, $chapters ) if (@$chapters);

                    $book;
                }
                sort { $a->[0] <=> $b->[0] }
                map { [ $self->_bible_data->{book_order}{$_}, $_ ] }
                keys %$data_by_book
            ];
        }

        $data = [ map {
            my $book = $_->[0];

            if ( my $chapters = $_->[1] ) {
                for my $chapter (@$chapters) {
                    pop @$chapter if (
                        $chapter->[1] and
                        join( ',', @{ $chapter->[1] } ) eq
                        join( ',', 1 .. ( $self->_bible_data->{lengths}{$book}[ $chapter->[0] - 1 ] || 0 ) )
                    );
                }

                pop @$_ if (
                    join( ',', map { $_->[0] } grep { @$_ == 1 } @$chapters ) eq
                    join( ',', 1 .. scalar @{ $self->_bible_data->{lengths}{$book} } )
                );
            }

            $_;
        } @$data ] if ( $self->simplify );

        if ( $self->acronyms ) {
            for (@$data) {
                $_->[0] = $self->_bible_data->{book_to_acronym}{ $_->[0] };
            }
        }

        $self->_cache->{data} = $data;
    }

    return (wantarray) ? @{ $self->_cache->{data} } : $self->_cache->{data};
}

sub as_hash ( $self, $data = undef ) {
    my $build = {};

    for my $book_block ( $self->as_array($data) ) {
        my ( $book_name, $chapters ) = @$book_block;

        $build->{$book_name} = {};
        for (@$chapters) {
            push( @{ $build->{$book_name}{ $_->[0] } }, @{ $_->[1] || [] } );
        }
    }

    return (wantarray) ? %$build : $build;
}

sub _compress_range ( $items = [] ) {
    my ( $last, @items, @range );

    my $flush_range = sub {
        if (@range) {
            pop @items;
            push( @items, join( '-', $range[0], $range[-1] ) );
            @range = ();
        }
    };

    for my $item (@$items) {
        if ( not $last or $last + 1 != $item ) {
            $flush_range->();
            push( @items, $item );
        }
        else {
            push( @range, $last, $item );
        }

        $last = $item;
    }
    $flush_range->();

    return (wantarray) ? @items : join( ', ', @items );
}

sub _as_type ( $self, $type, $data = undef ) {
    $data = $self->as_array($data);

    return [
        map {
            my $book = $_->[0];

            if ( $_->[1] ) {
                my ( @build, @buffer );

                my $flush_buffer = sub {
                    if (@buffer) {
                        push( @build, join( '; ', _compress_range(\@buffer) ) );
                        @buffer = ();
                    }
                };

                for ( @{ $_->[1] } ) {
                    my $chapter = $_->[0];

                    if ( $_->[1] ) {
                        if ( $type eq 'verses' ) {
                            push( @build, map { "$book $chapter:$_" } @{ $_->[1] } );
                        }
                        elsif ( $type eq 'runs' ) {
                            push( @build, map { "$book $chapter:$_" } _compress_range( $_->[1] ) );
                        }
                        elsif ( $type eq 'chapters' ) {
                            push( @build, "$book $chapter:" . join( ', ', _compress_range( $_->[1] ) ) );
                        }
                        else {
                            $flush_buffer->();
                            push( @build, $chapter . ':' . join( ', ', _compress_range( $_->[1] ) ) );
                        }
                    }
                    else {
                        unless ( $type eq 'books' ) {
                            push( @build, "$book $chapter" );
                        }
                        else {
                            push( @buffer, $chapter );
                        }
                    }
                }

                unless ( $type eq 'books' ) {
                    @build;
                }
                else {
                    $flush_buffer->();
                    $book . ' ' . join( '; ', @build );
                }
            }
            else {
                $book;
            }
        } @$data
    ];
}

sub as_verses ( $self, $data = undef ) {
    my $items = $self->_as_type( 'verses', $data );
    return (wantarray) ? @$items : $items;
}

sub as_runs ( $self, $data = undef ) {
    my $items = $self->_as_type( 'runs', $data );
    return (wantarray) ? @$items : $items;
}

sub as_chapters ( $self, $data = undef ) {
    my $items = $self->_as_type( 'chapters', $data );
    return (wantarray) ? @$items : $items;
}

sub as_books ( $self, $data = undef ) {
    my $items = $self->_as_type( 'books', $data );
    return (wantarray) ? @$items : $items;
}

sub refs ( $self, $data = undef ) {
    return join( '; ', $self->as_books($data) );
}

sub as_text ($self) {
    my @text = map {
        join( '', map { ( ref $_ ) ? $self->refs([$_]) : $_ } @$_ );
    } @{ $self->_data };

    return
        ( @text > 1 and wantarray )     ? @text :
        ( @text > 1 and not wantarray ) ? \@text : join( ' ', @text );
}

sub set_bible_data ( $self, $bible = undef, $book_data = undef, $verse_data = undef ) {
    croak 'First argument to set_bible_data() must be a Bible name string'
        unless ( $bible and not ref $bible and length $bible > 0 );
    croak 'Second argument to set_bible_data() must be an arrayref of arrayrefs'
        unless ( $book_data and ref $book_data eq 'ARRAY' );

    for (@$book_data) {
        croak 'Second argument to set_bible_data() does not appear valid' unless (
            ref $_ eq 'ARRAY' and
            not ref $_->[0] and length $_->[0] > 0 and
            not ref $_->[1] and length $_->[1] > 0
        );
    }

    unless ($verse_data) {
        _build_bible_template( 'Orthodox' => $bible, $self->_bibles );
        $self->_bibles->{$bible}[0] = $book_data;
    }
    else {
        $self->_bibles->{$bible}[0] = $book_data;
        $self->_bibles->{$bible}[1] = $verse_data;
    }

    $self->bible($bible);
    return $self;
}

sub get_bible_structure ( $self, $bible = undef ) {
    $self->bible($bible) if ($bible);
    return [ map { [ $_, $self->_bible_data->{lengths}{$_} ] } @{ $self->_bible_data->{books} } ];
}

sub identify_bible ( $self, @books ) {
    croak('No books supplied; must supply at least 1 input') unless (@books);

    my $obj    = $self->new( minimum_book_length  => $self->minimum_book_length );
    my $bibles = [
        sort { $b->{count} <=> $a->{count} }
        map {
            $obj->bible($_);
            my $books = scalar( $obj->clear->in(@books)->as_books );
            {
                name  => $_,
                books => $books,
                count => scalar(@$books),
            };
        }
        keys %{ $obj->_bibles }
    ];

    $bibles = [ grep { $bibles->[0]{count} == $_->{count} } @$bibles ]
        if ( $bibles->[0]{count} != $bibles->[-1]{count} );

    return $bibles;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::Reference - Simple Bible reference parser, tester, and canonicalizer

=head1 VERSION

version 1.19

=for markdown [![test](https://github.com/gryphonshafer/Bible-Reference/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bible-Reference/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bible-Reference/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bible-Reference)

=head1 SYNOPSIS

    use Bible::Reference;

    my $r = Bible::Reference->new;

    $r = Bible::Reference->new(
        bible                 => 'Protestant', # or "Orthodox" or "Catholic"
        acronyms              => 0,            # return full book names
        sorting               => 1,            # sort by reference
        require_chapter_match => 0,            # don't require chapters in references for matching
        require_verse_match   => 0,            # don't require verses in references for matching
        require_book_ucfirst  => 0,            # don't require book names to be ucfirst for matching
        minimum_book_length   => 3,
        add_detail            => 0,
        simplify              => 0,
    );

    $r = $r->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.');

    my $refs = $r->refs;
    # 'Romans 12:13-14, 17; 1 Peter 3:16'

    my $books = $r->as_books;
    # [ 'Romans 12:13-14, 17', '1 Peter 3:16' ]

    my $verses = $r->as_verses;
    # [ 'Romans 12:13', 'Romans 12:14', 'Romans 12:17', '1 Peter 3:16' ]

    my $hash = $r->as_hash;
    # { 'Romans' => { 12 => [ 13, 14, 17 ] }, '1 Peter' => { 3 => [16] } }

    my $array = $r->as_array;
    # [[ 'Romans', [[ 12, [ 13, 14, 17 ]]]], [ '1 Peter', [[ 3, [16] ]]]]

    my $text = $r->as_text;
    # 'Text with 1 Peter 3:16 and Romans 12:13-14, 17 references in it.'

    $r = $r->in('More text with Romans 12:16, 13:14-15 in it.'); # appends "in"
    $r = $r->clear; # clears "in" data but not anything else

    my @books  = $r->books;
    my @sorted = $r->sort( 'Romans', 'James 1:5', 'Romans 5' );

    $r->bible('Orthodox');        # switch to the Orthodox Bible
    $r->acronyms(1);              # output acronyms instead of full book names
    $r->sorting(0);               # deactivate sorting of references
    $r->require_chapter_match(1); # require chapters in references for matching
    $r->require_verse_match(1);   # require verses in references for matching
    $r->require_book_ucfirst(1);  # require book names to be ucfirst for matching
    $r->minimum_book_length(4);   # set minimum book length to 4
    $r->add_detail(1);            # turn on adding chapter and verse detail
    $r->simplify(1);              # turn on simplifying if possible the ranges

=head1 DESCRIPTION

This module is intended to address Bible reference canonicalization. Given some
input, the module will search for Bible references, canonicalize them, and
return them in various forms desired. It can return the canonicalized within
the context of the input string or strings as well.

The module supports the Protestant Bible by default and by configuration
setting also the Orthodox Bible and the current Catholic Bible.

There are also some potentially useful helper methods.

=head1 METHODS

=head2 new

A typical instantiation method that accepts some settings, all of which can
later be fetched and changed with accessors.

    my $r = Bible::Reference->new(
        bible    => 'Protestant', # or "Orthodox" or "Catholic"
        acronyms => 0,            # or 1
        sorting  => 1,            # or 0 to preserve input order
    );

See the below accessor methods for details on these settings.

=head2 bible

This accessor method gets and sets the current Bible to use. By default, the
Bible is the Protestant Bible. Other Bibles supported are the Orthodox and
Catholic Bibles.

You can set the value via a case-insensitive setting.

    $r->bible('catholic'); # sets Bible to "Catholic"

=head2 acronyms

This accessor method gets and sets the boolean setting of whether to return
full book names (which is the default) or acronyms.

    $r->acronyms(0);         # default
    $r->in('Rom 1:1')->refs; # returns "Romans 1:1"

    $r->acronyms(1);
    $r->in('Rom 1:1')->refs; # returns "Ro 1:1"

=head2 sorting

This accessor method gets and sets the boolean setting of whether or not to
return references sorted (which is the default) or in their input order.

    $r->sorting(1);                   # default
    $r->in('Jam 1:1; Rom 1:1')->refs; # returns "Romans 1:1; James 1:1"

    $r->sorting(0);
    $r->in('Jam 1:1; Rom 1:1')->refs; # returns "James 1:1; Romans 1:1"

Note that within a single given reference, chapters and verses will always be
returned sorted and canonicalized.

=head2 in

This method accepts string input that will get parsed and canonicalized by the
module. The method returns a reference to the object.

    $r = $r->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.');

The method is also additive, in that if you call it multiple times or with a
list of input strings, the object stores them all (until you call C<clear>).

    $r->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.');
    $r->in('More text with Roms 12:16, 13:14-15 in it.');
    $r->in(
        'Even more text with Jam 1:5 in it.',
        'And one last bit of text with 1 Cor 12:8-12 in it.',
    );

=head2 clear

This method clears all input provided via C<in> and returns a reference to the
object.

    $r = $r->clear; # clears "in" data but not anything else

=head2 refs

This method returns all references found within the input. It does so as a
single string using canonical reference format.

    my $refs = $r->refs;
    # 'Romans 12:13-14, 17; 1 Peter 3:16'

The "canonical reference format" is as follows: Book names are proper-noun cased
followed by a single space. If the book name has a number prefix, it is in
numeric form followed by a single space. Chapter numbers are next, followed by a
":" and verses. For uninterrupted ranges of verses, the "-" character is used.
Interrupted verses (i.e. "14, 17") are displayed with a comma and space between
them.

Multiple book references are separated by a ";" and space. Multiple chapters
within the same book are separated by a space and comma: "Romans 12:14, 17:18; 1
Peter 3:16" Therefore, whole chapters that follow chapters with verses will
repeat of the book name (for disambiguation). Whole chapters that only follow
whole chapters will not repeat the book name.

=head2 as_books

This method is the same as C<refs> except that it returns a list or arrayref
(depending on context) of canonicalized references by book.

    my $books = $r->as_books;
    # [ 'Romans 12:13-14, 17', '1 Peter 3:16' ]

    my @books = $r->as_books;
    # 'Romans 12:13-14, 17', '1 Peter 3:16'

=head2 as_chapters

This method is the same as C<as_books> except that it returns a list or arrayref
(depending on context) of canonicalized references by book and chapter.

=head2 as_runs

This method is the same as C<as_chapters> except that it returns a list or
arrayref (depending on context) of canonicalized references by verse run. A
"verse run" is a set of verses in an unbroken list together.

    my $books = $r->as_runs;
    # [ 'Romans 12:13-14', 'Romans 12:17', '1 Peter 3:16' ]

=head2 as_verses

This method is the same as C<as_books> except that it returns a list or arrayref
of independent verses,

    my $verses = $r->as_verses;
    # [ 'Romans 12:13', 'Romans 12:14', 'Romans 12:17', '1 Peter 3:16' ]

    my @verses = $r->as_verses;
    # 'Romans 12:13', 'Romans 12:14', 'Romans 12:17', '1 Peter 3:16'

=head2 as_hash

This method returns the references output like C<refs> would except that the
output is a hash or hashref (depending on context) of a tree of data.

    my $hash = $r->as_hash;
    # { 'Romans' => { 12 => [ 13, 14, 17 ] }, '1 Peter' => { 3 => [16] } }

    my %hash = $r->as_hash;
    # 'Romans' => { 12 => [ 13, 14, 17 ] }, '1 Peter' => { 3 => [16] }

=head2 as_array

This method is the same as C<as_hash> except that the output is an array or
arrayref (depending on context) of a tree of data.

    my $array = $r->as_array;
    # [[ 'Romans', [[ 12, [ 13, 14, 17 ]]]], [ '1 Peter', [[ 3, [16] ]]]]

    my @array = $r->as_array;
    # [ 'Romans', [[ 12, [ 13, 14, 17 ]]]], [ '1 Peter', [[ 3, [16] ]]]

=head2 as_text

This method returns a text string or, if there were multiple calls to C<in>, an
array or arrayref of text strings (depending on context), of the input string or
strings with the references found therein canonicalized.

    my $text = $r->as_text;
    # 'Text with 1 Peter 3:16 and Romans 12:13-14, 17 references in it.'

    $r->clear;
    $r->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.');
    $r->in('More text with Roms 12:16, 13:14-15 in it.');
    $r->in(
        'Even more text with Jam 1:5 in it.',
        'And one last bit of text with 1 Cor 12:8-12 in it.',
    );

    my @text = $r->as_text;
    # 'Text with 1 Peter 3:16 and Romans 12:13-14, 17 references in it.',
    # 'More text with Romans 12:16, 13:14-15 in it.',
    # 'Even more text with James 1:5 in it.',
    # 'And one last bit of text with 1 Corinthians 12:8-12 in it.',

=head2 books

This method returns a list or arrayref (depending on the context) of books of
the Bible, in order.

    my @books = $r->books;
    my $books = $r->books;

=head2 set_bible_data

If the preset Bibles are not going to cover your own needs, you can set your own
Bible data for use within the module with this method. It returns the
instantiated object, so you can chain it like so:

    my $r = Bible::Reference->new->set_bible_data(
        'Special' => [
            [ 'Genesis',     'Ge', 'Gn', 'Gen' ],
            [ 'Exodus',      'Ex', 'Exo'       ],
            [ 'Leviticus',   'Lv', 'Lev'       ],
            [ 'Numbers',     'Nu', 'Nm', 'Num' ],
            [ 'Deuteronomy', 'Dt', 'Deu'       ],
        ],
    );

The method expects two inputs: a string that will be used as the label for the
Bible and an arrayref of arrayrefs. Each sub-arrayref must contain at least 2
strings: the first being the full-name of the book, and the second the
canonical acronym. Subsequent matching acronyms can optionally be added. These
are acronyms that if found will match to the book, in addition to the canoniocal
acronym.

When you call this method with good input, it will save the new Bible and
internally call C<bible()> to set the new Bible as active.

You may optionally provide an additional arrayref of arrayrefs containing the
maximum verse number for each chapter of a book. This is useful only if you
need to call C<expand_ranges>. If you don't pass this data, a best-guess of the
data will be used.

=head2 expand_ranges

This is a helper method. It's called automatically if C<add_detail> is set to a
true value. The method requires 2 strings: a book name and a chapter/verse
ranges string. It will return a string represented the "expanded" chapter/verse
range.

    $r->expand_ranges( 'Mark', '1:3-7' );
    # returns "1:3, 4, 5, 6, 7"

    $r->expand_ranges( 'Mark', '4:37-5:9' );
    # returns "4:37, 38, 39, 40, 41; 5:1, 2, 3, 4, 5, 6, 7, 8, 9"

=head2 get_bible_structure

This method will return an arrayref containing an arrayref per book (in order)
that contains two elements: the name of the book and an arrayref of the maximum
verse number per chapter.

=head2 identify_bible

This method is to help identify which Bible to use if you aren't sure. It
requires a list of strings as input, each string representing a book from the
Bible you're trying to identify. This method will then try to match these book
names across all Bibles and will return an array of the most likely Bibles for
your inputs.

For example:

    my $bibles = $r->identify_bible( 'Gen', 'Lev', '3 Mac' );

The above will return:

    [
        {
            name  => 'Orthodox',
            count => 3,
            books => [ 'Genesis', 'Leviticus', '3 Maccabees' ],
        },
    ],

=head1 HANDLING MATCHING ERRORS

By default, the module does its best to find things that look like valid
references inside text. However, this can result in the occational matching
error. For example, consider the following text input:

    This is an example of the 1 time it might break.
    It also breaks if you mention number 7 from a list of things.
    Legal opinions of judges 3 times said this would break.

With this, we'd falsely match: Thessalonians 1, Numbers 7, and Judges 3.

There are a few things you can do to reduce this problem. You can optionally set
C<require_chapter_match> or C<require_verse_match> to true values. These will
cause the matching algorithm to only work on reference patterns that contain
what look to be chapter numbers and/or verse numbers.

You can optionally set C<require_book_ucfirst> to a true value. This will cause
the matching algorithm to only work on reference patterns that contain what
looks like a book that starts with a capital letter (instead of the default of
any case).

Another option to consider is adjusting the C<minimum_book_length> value. It
sets the minimum length of characters to match a book name. It's default set to
3. Given a book like "Genesis", this will mean "Gen" and "Gene" and "Genes"
matches, but "Ge" won't.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bible-Reference>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bible::Reference>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bible-Reference/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bible-Reference>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-Reference>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-Reference.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
