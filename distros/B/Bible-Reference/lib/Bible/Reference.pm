package Bible::Reference;
# ABSTRACT: Simple Bible reference parser, tester, and canonicalizer

use 5.012;
use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Privacy;
use Readonly;

our $VERSION = '1.01'; # VERSION

has 'acronyms',             is => 'rw', isa => 'Bool', default => 0;
has 'sorting',              is => 'rw', isa => 'Bool', default => 1;
has 'require_verse_match',  is => 'rw', isa => 'Bool', default => 0;
has 'require_book_ucfirst', is => 'rw', isa => 'Bool', default => 0;

Readonly my %_bibles => (
    'Protestant' => [
        [ 'Genesis',               'Ge',   'Gn',    'Gen'          ],
        [ 'Exodus',                'Ex',   'Exo'                   ],
        [ 'Leviticus',             'Lv',   'Lev'                   ],
        [ 'Numbers',               'Nu',   'Nm',    'Num'          ],
        [ 'Deuteronomy',           'Dt',   'Deu'                   ],
        [ 'Joshua',                'Jsh',  'Jos',   'Josh'         ],
        [ 'Judges',                'Jdg',  'Judg'                  ],
        [ 'Ruth',                  'Ru',   'Rut'                   ],
        [ '1 Samuel',              '1Sa',  '1Sm',   '1Sam'         ],
        [ '2 Samuel',              '2Sa',  '2Sm',   '2Sam'         ],
        [ '1 Kings',               '1Ki',  '1Kg',   '1Kin'         ],
        [ '2 Kings',               '2Ki',  '2Kg',   '2Kin'         ],
        [ '1 Chronicles',          '1Ch',  '1Cr',   '1Chr'         ],
        [ '2 Chronicles',          '2Ch',  '2Cr',   '2Chr'         ],
        [ 'Ezra',                  'Ezr'                           ],
        [ 'Nehemiah',              'Ne',   'Neh'                   ],
        [ 'Esther',                'Est',  'Esth'                  ],
        [ 'Job',                   'Jb',   'Jo',    'Job'          ],
        [ 'Psalms',                'Ps',   'Psa'                   ],
        [ 'Proverbs',              'Pr',   'Prv',   'Pro',  'Prov' ],
        [ 'Ecclesiastes',          'Ec',   'Ecc',   'Eccl'         ],
        [ 'Song of Solomon',       'SS',   'Son',   'Song'         ],
        [ 'Isaiah',                'Is',   'Isa'                   ],
        [ 'Jeremiah',              'Jr',   'Jer'                   ],
        [ 'Lamentations',          'Lm',   'La',    'Lam'          ],
        [ 'Ezekiel',               'Ezk',  'Ez',    'Eze',  'Ezek' ],
        [ 'Daniel',                'Da',   'Dn',    'Dan'          ],
        [ 'Hosea',                 'Ho',   'Hs',    'Hos'          ],
        [ 'Joel',                  'Jl',   'Joe',   'Joel'         ],
        [ 'Amos',                  'Am',   'Amo'                   ],
        [ 'Obadiah',               'Ob',   'Oba'                   ],
        [ 'Jonah',                 'Jnh',  'Jon',   'Jona'         ],
        [ 'Micah',                 'Mi',   'Mic'                   ],
        [ 'Nahum',                 'Na',   'Nah'                   ],
        [ 'Habakkuk',              'Hab'                           ],
        [ 'Zephaniah',             'Zp',   'Zep',   'Zph',  'Zeph' ],
        [ 'Haggai',                'Hg',   'Hag'                   ],
        [ 'Zechariah',             'Zec',  'Zch',   'Zech'         ],
        [ 'Malachi',               'Ml',   'Mal'                   ],
        [ 'Matthew',               'Mt',   'Mat',   'Matt'         ],
        [ 'Mark',                  'Mk',   'Mr',    'Mc',   'Mark' ],
        [ 'Luke',                  'Lk',   'Lu',    'Luk'          ],
        [ 'John',                  'Joh'                           ],
        [ 'Acts',                  'Ac',   'Act'                   ],
        [ 'Romans',                'Ro',   'Rm',    'Rom'          ],
        [ '1 Corinthians',         '1Co',  '1Cor'                  ],
        [ '2 Corinthians',         '2Co',  '2Cor'                  ],
        [ 'Galatians',             'Ga',   'Gl',    'Gal'          ],
        [ 'Ephesians',             'Ep',   'Eph'                   ],
        [ 'Philippians',           'Php',  'Phil'                  ],
        [ 'Colossians',            'Cl',   'Col'                   ],
        [ '1 Thessalonians',       '1Th',  '1The'                  ],
        [ '2 Thessalonians',       '2Th',  '2The'                  ],
        [ '1 Timothy',             '1Ti',  '1Tm',   '1Tim'         ],
        [ '2 Timothy',             '2Ti',  '2Tm',   '2Tim'         ],
        [ 'Titus',                 'Ti',   'Tt'                    ],
        [ 'Philemon',              'Phm',  'Phile'                 ],
        [ 'Hebrews',               'He',   'Heb'                   ],
        [ 'James',                 'Jam',  'Jms'                   ],
        [ '1 Peter',               '1Pt',  '1Pe',   '1Pet'         ],
        [ '2 Peter',               '2Pt',  '2Pe',   '2Pet'         ],
        [ '1 John',                '1Jn',  '1Jo',   '1Joh'         ],
        [ '2 John',                '2Jn',  '2Jo',   '2Joh'         ],
        [ '3 John',                '3Jn',  '3Jo',   '3Joh'         ],
        [ 'Jude',                  'Jud',  'Jude'                  ],
        [ 'Revelation',            'Rv',   'Rev'                   ],
    ],
    'Catholic' => [
        [ 'Genesis',               'Ge',   'Gn',    'Gen'          ],
        [ 'Exodus',                'Ex',   'Exo'                   ],
        [ 'Leviticus',             'Lv',   'Lev'                   ],
        [ 'Numbers',               'Nu',   'Nm',    'Num'          ],
        [ 'Deuteronomy',           'Dt',   'Deu'                   ],
        [ 'Joshua',                'Jsh',  'Jos',   'Josh'         ],
        [ 'Judges',                'Jdg',  'Judg'                  ],
        [ 'Ruth',                  'Ru',   'Rut'                   ],
        [ '1 Samuel',              '1Sa',  '1Sm',   '1Sam'         ],
        [ '2 Samuel',              '2Sa',  '2Sm',   '2Sam'         ],
        [ '1 Kings',               '1Ki',  '1Kg',   '1Kin'         ],
        [ '2 Kings',               '2Ki',  '2Kg',   '2Kin'         ],
        [ '1 Chronicles',          '1Ch',  '1Cr',   '1Chr'         ],
        [ '2 Chronicles',          '2Ch',  '2Cr',   '2Chr'         ],
        [ 'Ezra',                  'Ezr'                           ],
        [ 'Nehemiah',              'Ne',   'Neh'                   ],
        [ 'Tobit',                 'Tb',   'Tob'                   ],
        [ 'Judith',                'Judi'                          ],
        [ 'Esther',                'Est',  'Esth'                  ],
        [ '1 Maccabees',           '1Ma',  '1Mac'                  ],
        [ '2 Maccabees',           '2Ma',  '2Mac'                  ],
        [ 'Job',                   'Jb',   'Jo',    'Job'          ],
        [ 'Psalms',                'Ps',   'Psa'                   ],
        [ 'Proverbs',              'Pr',   'Prv',   'Pro',  'Prov' ],
        [ 'Ecclesiastes',          'Ec',   'Ecc',   'Eccl'         ],
        [ 'Song of Songs',         'SS',   'Son',   'Song'         ],
        [ 'Wisdom',                'Wi',   'Ws',    'Wis'          ],
        [ 'Sirach',                'Si',   'Sr',    'Sir'          ],
        [ 'Isaiah',                'Is',   'Isa'                   ],
        [ 'Jeremiah',              'Jr',   'Jer'                   ],
        [ 'Lamentations',          'Lm',   'La',    'Lam'          ],
        [ 'Baruch',                'Ba',   'Br',    'Bar'          ],
        [ 'Ezekiel',               'Ezk',  'Ez',    'Eze',  'Ezek' ],
        [ 'Daniel',                'Da',   'Dn',    'Dan'          ],
        [ 'Hosea',                 'Ho',   'Hs',    'Hos'          ],
        [ 'Joel',                  'Jl',   'Joe',   'Joel'         ],
        [ 'Amos',                  'Am',   'Amo'                   ],
        [ 'Obadiah',               'Ob',   'Oba'                   ],
        [ 'Jonah',                 'Jnh',  'Jon',   'Jona'         ],
        [ 'Micah',                 'Mi',   'Mic'                   ],
        [ 'Nahum',                 'Na',   'Nah'                   ],
        [ 'Habakkuk',              'Hab'                           ],
        [ 'Zephaniah',             'Zp',   'Zep',   'Zph',  'Zeph' ],
        [ 'Haggai',                'Hg',   'Hag'                   ],
        [ 'Zechariah',             'Zec',  'Zch',   'Zech'         ],
        [ 'Malachi',               'Ml',   'Mal'                   ],
        [ 'Matthew',               'Mt',   'Mat',   'Matt'         ],
        [ 'Mark',                  'Mk',   'Mr',    'Mc',   'Mark' ],
        [ 'Luke',                  'Lk',   'Lu',    'Luk'          ],
        [ 'John',                  'Joh'                           ],
        [ 'Acts',                  'Ac',   'Act'                   ],
        [ 'Romans',                'Ro',   'Rm',    'Rom'          ],
        [ '1 Corinthians',         '1Co',  '1Cor'                  ],
        [ '2 Corinthians',         '2Co',  '2Cor'                  ],
        [ 'Galatians',             'Ga',   'Gl',    'Gal'          ],
        [ 'Ephesians',             'Ep',   'Eph'                   ],
        [ 'Philippians',           'Php',  'Phil'                  ],
        [ 'Colossians',            'Cl',   'Col'                   ],
        [ '1 Thessalonians',       '1Th',  '1The'                  ],
        [ '2 Thessalonians',       '2Th',  '2The'                  ],
        [ '1 Timothy',             '1Ti',  '1Tm',   '1Tim'         ],
        [ '2 Timothy',             '2Ti',  '2Tm',   '2Tim'         ],
        [ 'Titus',                 'Ti',   'Tt'                    ],
        [ 'Philemon',              'Phm',  'Phile'                 ],
        [ 'Hebrews',               'He',   'Heb'                   ],
        [ 'James',                 'Jam',  'Jms'                   ],
        [ '1 Peter',               '1Pt',  '1Pe',   '1Pet'         ],
        [ '2 Peter',               '2Pt',  '2Pe',   '2Pet'         ],
        [ '1 John',                '1Jn',  '1Jo',   '1Joh'         ],
        [ '2 John',                '2Jn',  '2Jo',   '2Joh'         ],
        [ '3 John',                '3Jn',  '3Jo',   '3Joh'         ],
        [ 'Jude',                  'Jud',  'Jude'                  ],
        [ 'Revelation',            'Rv',   'Rev'                   ],
    ],
    'Vulgate' => [
        [ 'Genesis',               'Ge',   'Gn',    'Gen'          ],
        [ 'Exodus',                'Ex',   'Exo'                   ],
        [ 'Leviticus',             'Lv',   'Lev'                   ],
        [ 'Numbers',               'Nu',   'Nm',    'Num'          ],
        [ 'Deuteronomy',           'Dt',   'Deu'                   ],
        [ 'Joshua',                'Jsh',  'Jos',   'Josh'         ],
        [ 'Judges',                'Jdg',  'Judg'                  ],
        [ 'Ruth',                  'Ru',   'Rut'                   ],
        [ '1 Kings',               '1Ki',  '1Kg',   '1Kin'         ],
        [ '2 Kings',               '2Ki',  '2Kg',   '2Kin'         ],
        [ '3 Kings',               '3Ki',  '3Kg',   '3Kin'         ],
        [ '4 Kings',               '4Ki',  '4Kg',   '4Kin'         ],
        [ '1 Paralipomenon',       '1Pa',  '1Par'                  ],
        [ '2 Paralipomenon',       '2Pa',  '2Par'                  ],
        [ '1 Esdras',              '1Esd'                          ],
        [ '2 Esdras',              '2Esd'                          ],
        [ '3 Esdras',              '3Esd'                          ],
        [ '4 Esdras',              '4Esd'                          ],
        [ 'Tobias',                'Tb',   'Tob'                   ],
        [ 'Judith',                'Judi'                          ],
        [ 'Esther',                'Est',  'Esth'                  ],
        [ '1 Maccabees',           '1Ma',  '1Mac'                  ],
        [ '2 Maccabees',           '2Ma',  '2Mac'                  ],
        [ 'Job',                   'Jb',   'Jo',    'Job'          ],
        [ 'Psalms',                'Ps',   'Psa'                   ],
        [ 'Prayer of Manasseh',    'PM',   'Pra',   'Man'          ],
        [ 'Proverbs',              'Pr',   'Prv',   'Pro',  'Prov' ],
        [ 'Ecclesiastes',          'Ec',   'Ecc',   'Eccl'         ],
        [ 'Canticle of Canticles', 'CC',   'Can'                   ],
        [ 'Wisdom',                'Wi',   'Ws',    'Wis'          ],
        [ 'Ecclesiasticus',        'Ecu',  'Eclu'                  ],
        [ 'Isaias',                'Is',   'Isa'                   ],
        [ 'Jeremias',              'Jr',   'Jer'                   ],
        [ 'Lamentations',          'Lm',   'La',    'Lam'          ],
        [ 'Baruch',                'Ba',   'Br',    'Bar'          ],
        [ 'Ezekiel',               'Ezk',  'Ez',    'Eze',  'Ezek' ],
        [ 'Daniel',                'Da',   'Dn',    'Dan'          ],
        [ 'Osee',                  'Os',   'Ose'                   ],
        [ 'Joel',                  'Jl',   'Joe',   'Joel'         ],
        [ 'Amos',                  'Am',   'Amo'                   ],
        [ 'Abdias',                'Ab',   'Abd'                   ],
        [ 'Jonas',                 'Jns',  'Jon',   'Jona'         ],
        [ 'Micheas',               'Mi',   'Mic'                   ],
        [ 'Nahu',                  'Na',   'Nah'                   ],
        [ 'Habacuc',               'Hab'                           ],
        [ 'Sophonias',             'So',   'Sop',   'Sph'          ],
        [ 'Aggeus',                'Ag',   'Agg '                  ],
        [ 'Zacharias',             'Zec',  'Zch',   'Zech'         ],
        [ 'Malachias',             'Ml',   'Mal'                   ],
        [ 'Matthew',               'Mt',   'Mat',   'Matt'         ],
        [ 'Mark',                  'Mk',   'Mr',    'Mc',   'Mark' ],
        [ 'Luke',                  'Lk',   'Lu',    'Luk'          ],
        [ 'John',                  'Joh'                           ],
        [ 'Acts',                  'Ac',   'Act'                   ],
        [ 'Romans',                'Ro',   'Rm',    'Rom'          ],
        [ '1 Corinthians',         '1Co',  '1Cor'                  ],
        [ '2 Corinthians',         '2Co',  '2Cor'                  ],
        [ 'Galatians',             'Ga',   'Gl',    'Gal'          ],
        [ 'Ephesians',             'Ep',   'Eph'                   ],
        [ 'Philippians',           'Php',  'Phil'                  ],
        [ 'Colossians',            'Cl',   'Col'                   ],
        [ '1 Thessalonians',       '1Th',  '1The'                  ],
        [ '2 Thessalonians',       '2Th',  '2The'                  ],
        [ '1 Timothy',             '1Ti',  '1Tm',   '1Tim'         ],
        [ '2 Timothy',             '2Ti',  '2Tm',   '2Tim'         ],
        [ 'Titus',                 'Ti',   'Tt'                    ],
        [ 'Philemon',              'Phm',  'Phile'                 ],
        [ 'Hebrews',               'He',   'Heb'                   ],
        [ 'James',                 'Jam',  'Jms'                   ],
        [ '1 Peter',               '1Pt',  '1Pe',   '1Pet'         ],
        [ '2 Peter',               '2Pt',  '2Pe',   '2Pet'         ],
        [ '1 John',                '1Jn',  '1Jo',   '1Joh'         ],
        [ '2 John',                '2Jn',  '2Jo',   '2Joh'         ],
        [ '3 John',                '3Jn',  '3Jo',   '3Joh'         ],
        [ 'Jude',                  'Jud',  'Jude'                  ],
        [ 'Revelation',            'Rv',   'Rev'                   ],
    ],
    'Orthodox' => [
        [ 'Genesis',               'Ge',   'Gn',    'Gen'          ],
        [ 'Exodus',                'Ex',   'Exo'                   ],
        [ 'Leviticus',             'Lv',   'Lev'                   ],
        [ 'Numbers',               'Nu',   'Nm',    'Num'          ],
        [ 'Deuteronomy',           'Dt',   'Deu'                   ],
        [ 'Joshua',                'Jsh',  'Jos',   'Josh'         ],
        [ 'Judges',                'Jdg',  'Judg'                  ],
        [ 'Ruth',                  'Ru',   'Rut'                   ],
        [ '1 Samuel',              '1Sa',  '1Sm',   '1Sam'         ],
        [ '2 Samuel',              '2Sa',  '2Sm',   '2Sam'         ],
        [ '1 Kings',               '1Ki',  '1Kg',   '1Kin'         ],
        [ '2 Kings',               '2Ki',  '2Kg',   '2Kin'         ],
        [ '1 Chronicles',          '1Ch',  '1Cr',   '1Chr'         ],
        [ '2 Chronicles',          '2Ch',  '2Cr',   '2Chr'         ],
        [ '1 Esdras',              '1Esd'                          ],
        [ 'Ezra',                  'Ezr'                           ],
        [ 'Nehemiah',              'Ne',   'Neh'                   ],
        [ 'Tobit',                 'Tb',   'Tob'                   ],
        [ 'Judith',                'Judi'                          ],
        [ 'Esther',                'Est',  'Esth'                  ],
        [ '1 Maccabees',           '1Ma',  '1Mac'                  ],
        [ '2 Maccabees',           '2Ma',  '2Mac'                  ],
        [ '3 Maccabees',           '3Ma',  '3Mac'                  ],
        [ '4 Maccabees',           '4Ma',  '4Mac'                  ],
        [ 'Job',                   'Jb',   'Jo',    'Job'          ],
        [ 'Psalms',                'Ps',   'Psa'                   ],
        [ 'Prayer of Manasseh',    'PM',   'Pra',   'Man'          ],
        [ 'Proverbs',              'Pr',   'Prv',   'Pro',  'Prov' ],
        [ 'Ecclesiastes',          'Ec',   'Ecc',   'Eccl'         ],
        [ 'Song of Songs',         'SS',   'Son',   'Song'         ],
        [ 'Wisdom',                'Wi',   'Ws',    'Wis'          ],
        [ 'Sirach',                'Si',   'Sr',    'Sir'          ],
        [ 'Isaiah',                'Is',   'Isa'                   ],
        [ 'Jeremiah',              'Jr',   'Jer'                   ],
        [ 'Lamentations',          'Lm',   'La',    'Lam'          ],
        [ 'Baruch',                'Ba',   'Br',    'Bar'          ],
        [ 'Letter of Jeremiah',    'LJ',   'Let'                   ],
        [ 'Ezekiel',               'Ezk',  'Ez',    'Eze',  'Ezek' ],
        [ 'Daniel',                'Da',   'Dn',    'Dan'          ],
        [ 'Hosea',                 'Ho',   'Hs',    'Hos'          ],
        [ 'Joel',                  'Jl',   'Joe',   'Joel'         ],
        [ 'Amos',                  'Am',   'Amo'                   ],
        [ 'Obadiah',               'Ob',   'Oba'                   ],
        [ 'Jonah',                 'Jnh',  'Jon',   'Jona'         ],
        [ 'Micah',                 'Mi',   'Mic'                   ],
        [ 'Nahum',                 'Na',   'Nah'                   ],
        [ 'Habakkuk',              'Hab'                           ],
        [ 'Zephaniah',             'Zp',   'Zep',   'Zph',  'Zeph' ],
        [ 'Haggai',                'Hg',   'Hag'                   ],
        [ 'Zechariah',             'Zec',  'Zch',   'Zech'         ],
        [ 'Malachi',               'Ml',   'Mal'                   ],
        [ 'Matthew',               'Mt',   'Mat',   'Matt'         ],
        [ 'Mark',                  'Mk',   'Mr',    'Mc',   'Mark' ],
        [ 'Luke',                  'Lk',   'Lu',    'Luk'          ],
        [ 'John',                  'Joh'                           ],
        [ 'Acts',                  'Ac',   'Act'                   ],
        [ 'Romans',                'Ro',   'Rm',    'Rom'          ],
        [ '1 Corinthians',         '1Co',  '1Cor'                  ],
        [ '2 Corinthians',         '2Co',  '2Cor'                  ],
        [ 'Galatians',             'Ga',   'Gl',    'Gal'          ],
        [ 'Ephesians',             'Ep',   'Eph'                   ],
        [ 'Philippians',           'Php',  'Phil'                  ],
        [ 'Colossians',            'Cl',   'Col'                   ],
        [ '1 Thessalonians',       '1Th',  '1The'                  ],
        [ '2 Thessalonians',       '2Th',  '2The'                  ],
        [ '1 Timothy',             '1Ti',  '1Tm',   '1Tim'         ],
        [ '2 Timothy',             '2Ti',  '2Tm',   '2Tim'         ],
        [ 'Titus',                 'Ti',   'Tt'                    ],
        [ 'Philemon',              'Phm',  'Phile'                 ],
        [ 'Hebrews',               'He',   'Heb'                   ],
        [ 'James',                 'Jam',  'Jms'                   ],
        [ '1 Peter',               '1Pt',  '1Pe',   '1Pet'         ],
        [ '2 Peter',               '2Pt',  '2Pe',   '2Pet'         ],
        [ '1 John',                '1Jn',  '1Jo',   '1Joh'         ],
        [ '2 John',                '2Jn',  '2Jo',   '2Joh'         ],
        [ '3 John',                '3Jn',  '3Jo',   '3Joh'         ],
        [ 'Jude',                  'Jud',  'Jude'                  ],
        [ 'Revelation',            'Rv',   'Rev'                   ],
    ],
);

subtype 'BibleType',
    as 'Str',
    where {
        my $type = $_;
        grep { $type eq $_ } keys %_bibles;
    },
    message {'Could not determine a valid Bible type from input'};

coerce 'BibleType',
    from 'Str',
    via {
        my $input = lc( substr( $_ || '', 0, 1 ) );
        my ($type) = grep { lc( substr( $_, 0, 1 ) ) eq $input } keys %_bibles;
        return $type;
    };

has 'bible',
    is      => 'rw',
    isa     => 'BibleType',
    default => 'Protestant',
    coerce  => 1,
    trigger => sub { shift->_build_bible_data };

sub BUILD {
    shift->_build_bible_data;
}

private_method _simple_text => sub {
    my ( $self, $text ) = @_;
    ( $text = lc $text ) =~ s/\s+//g;
    return $text;
};

has '_bible_data', is => 'rw', isa => 'HashRef', traits => ['Private'];

private_method _build_bible_data => sub {
    my ($self) = @_;

    my $bible_data;
    for my $book_data ( @{ $_bibles{ $self->bible } } ) {
        my ( $book, @acronyms ) = @$book_data;

        $bible_data->{simple_book_to_book}{ $self->_simple_text($book) } = $book;
        $bible_data->{book_to_acronym}{$book} = $acronyms[0];
        push( @{ $bible_data->{simple_books} }, $self->_simple_text($book) );
        push( @{ $bible_data->{books} }, $book );

        for (@acronyms) {
            $bible_data->{simple_acronym_to_book}{ $self->_simple_text($_) } = $book;
            push( @{ $bible_data->{simple_acronyms} }, $self->_simple_text($_) );
        }
    }

    my $book_count;
    $bible_data->{book_order} = { map { $_ => ++$book_count } @{ $bible_data->{books} } };

    $self->_bible_data($bible_data);
    return;
};

has '_in',
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Private'],
    default => sub { [] };

sub in {
    my $self = shift;
    return $self->_in unless (@_);

    my $book_re   = ( $self->require_book_ucfirst ) ? qr/[A-Z][A-z]*/     : qr/[A-z]+/;
    my $verses_re = ( $self->require_verse_match )  ? qr/[\d:\-,;\s]+\d+/ : qr/(?:[\d:\-,;\s]+\d+)?/;
    my $tail_re   = qr/
        (?<book_suffix>\.?\s+)
        (?<numbers_prefix>[cC]{1}h(?:apter)?(?:s)?\.?\s)?
        (?<numbers>\d+$verses_re)
        (?<post_text>.*)
    /x;

    my $ref_single_re = qr/
        (?<pre_text>.*)\b
        (?<block_text>
            (?<book>$book_re)
            $tail_re
        )
    /x;

    my $ref_multi_re = qr/
        (?<pre_text>.*)\b
        (?<block_text>
            (?<book>
                (?:[123]|[Ii]{1,3})\s*
                $book_re
            )
            $tail_re
        )
    /x;

    my $bible_data = $self->_bible_data;
    my $match      = sub {
        my ( $re, $text ) = @_;
        my @sub_parts;

        while ( $text =~ s/$re// ) {
            my %ref_bits = %+;
            my ( $match, $match_type );

            $ref_bits{book} =~ s/^(i{1,3})\s/length($1)/ie;
            my $in_book_simple = $self->_simple_text( $ref_bits{book} );

            # is "book" in the list of known full book names
            if ( ($match) = grep { $in_book_simple eq $_ } @{ $bible_data->{simple_books} } ) {
                $match_type = 'book';
            }

            # is "book" in the list of known acronyms
            elsif ( ($match) = grep { $in_book_simple eq $_ } @{ $bible_data->{simple_acronyms} } ) {
                $match_type = 'acronym';
            }

            # does "book" =~ /^book_full_names/
            elsif ( ($match) = grep { /^$in_book_simple/ } @{ $bible_data->{simple_books} } ) {
                $match_type = 'book';
            }

            # does "book" =~ /^acronyms/
            elsif ( ($match) = grep { /^$in_book_simple/ } @{ $bible_data->{simple_acronyms} } ) {
                $match = $bible_data->{'simple_acronym_to_book'}{$match};
            }

            unless ($match) {
                my $pattern = join( '.*', split( '', $in_book_simple ) );

                # does "book" =~ /^b.*o.*o.*k.*s/
                if ( ($match) = grep { /^$pattern/ } @{ $bible_data->{simple_books} } ) {
                    $match_type = 'book';
                }

                # does "book" =~ /^a.*c.*r.*o.*n.*y.*m.*s/
                elsif ( ($match) = grep { /^$pattern/ } @{ $bible_data->{simple_acronyms} } ) {
                    $match_type = 'acronym';
                }
            }

            if ($match) {
                # fixup matched "book" to canonical book or acronym
                $match = $bible_data->{
                    ( $match_type eq 'book' ) ? 'simple_book_to_book' : 'simple_acronym_to_book'
                }{$match};

                # parse chapters and verses numbers
                my @numbers_by_chapter;
                for ( split( /\b(?=\d+\s*:\s*\d+)/, $ref_bits{numbers} ) ) {
                    my ( $chapter, $verses ) = split( ':', $_, 2 );

                    if ( length $verses ) {
                        $chapter =~ s/\D+//g;
                        push( @numbers_by_chapter, [$chapter] );
                    }
                    else {
                        # break up ranges into individual chapter numbers
                        $chapter =~ s/(\d+)\s*\-\s*(\d+)/ join( ',', $1 .. $2 ) /e;
                        push( @numbers_by_chapter, map { [$_] } sort { $a <=> $b } split( /\D+/, $chapter ) );
                    }

                    if ( length $verses ) {
                        # break up ranges into individual verse numbers
                        $verses =~ s/(\d+)\s*\-\s*(\d+)/ join( ',', $1 .. $2 ) /e;
                        push( @{ $numbers_by_chapter[-1] }, [ sort { $a <=> $b } split( /\D+/, $verses ) ] );
                    }
                }

                unshift( @sub_parts, [ $match, \@numbers_by_chapter ], $ref_bits{post_text} );
            }
            else {
                unshift( @sub_parts, $ref_bits{block_text} );
            }

            $text = $ref_bits{pre_text};
        }

        return grep { defined and length } $text, @sub_parts;
    };

    push( @{ $self->_in }, map {
        my @parts = map {
            (ref) ? $_ : $match->( $ref_single_re, $_ );
        } $match->( $ref_multi_re, $_ );

        for ( my $i = @parts - 1; $i > 0; $i-- ) {
            if ( not ref $parts[ $i - 1 ] and not ref $parts[$i] ) {
                $parts[ $i - 1 ] = $parts[ $i - 1 ] . splice( @parts, $i, 1 );
            }
        }

        \@parts;
    } @_ );

    return $self;
}

sub clear {
    my ($self) = @_;
    $self->_in([]);
    return $self;
}

sub books {
    my ($self) = @_;
    return (wantarray) ? @{ $self->_bible_data->{books} } : $self->_bible_data->{books};
}

private_method _as_hashref => sub {
    my $self = shift;

    my %refs;
    for my $ref (@_) {
        my $book = $ref->[0];

        for my $chapter_block ( @{ $ref->[1] } ) {
            my $chapter = $chapter_block->[0];

            $refs{$book}{$chapter} //= [];
            if ( $chapter_block->[1] ) {
                my %verses = map { $_ => 1 } @{ $refs{$book}{$chapter} }, @{ $chapter_block->[1] };
                $refs{$book}{$chapter} = [ sort { $a <=> $b } keys %verses ];
            }
        }
    }

    return \%refs;
};

has '_manual_in_refs', is => 'rw', isa => 'ArrayRef', traits => ['Private'], default => sub { [] };

private_method _in_refs => sub {
    my ($self) = @_;

    unless ( @{ $self->_manual_in_refs } ) {
        return grep { ref } map { @$_ } @{ $self->_in };
    }
    else {
        my $refs = $self->_manual_in_refs;
        $self->_manual_in_refs([]);
        return @$refs;
    }
};

sub as_hash {
    my ($self) = @_;
    my $refs = $self->_as_hashref( $self->_in_refs );

    if ( $self->acronyms ) {
        my $book_to_acronym = $self->_bible_data->{book_to_acronym};
        $refs->{ $book_to_acronym->{$_} } = delete $refs->{$_} for ( keys %$refs );
    }

    return (wantarray) ? %$refs : $refs;
}

private_method _sort => sub {
    my $self       = shift;
    my $book_order = $self->_bible_data->{book_order};
    my $refs       = $self->_as_hashref(@_);

    return
        map {
            my $book = $_->[1];
            [
                $book,
                [
                    map {
                        ( @{ $refs->{$book}{$_} } ) ? [ $_, $refs->{$book}{$_} ] : [$_]
                    } sort { $a <=> $b } keys %{ $refs->{$book} }
                ],
            ];
        }
        sort { $a->[0] <=> $b->[0] }
        map { [ $book_order->{$_}, $_ ] }
        keys %$refs;
};

sub as_array {
    my ($self) = @_;

    my @refs = $self->_in_refs;
    @refs = $self->_sort(@refs) if ( $self->sorting );

    if ( $self->acronyms ) {
        my $book_to_acronym = $self->_bible_data->{book_to_acronym};
        @refs = map { $_->[0] = $book_to_acronym->{ $_->[0] }; $_ } @refs;
    }

    return (wantarray) ? @refs : \@refs;
}

sub as_verses {
    my ($self) = @_;

    my @refs;
    for my $ref ( $self->as_array ) {
        my $book = $ref->[0];

        for my $part ( @{ $ref->[1] } ) {
            my $chapter = $part->[0];

            if ( $part->[1] ) {
                push( @refs, "$book $chapter:$_" ) for ( @{ $part->[1] } );
            }
            else {
                push( @refs, "$book $chapter" );
            }
        }
    }

    return (wantarray) ? @refs : \@refs;
}

private_method _compress_range => sub {
    my $self = shift;

    my ( $last, @items, @range );

    my $flush_range = sub {
        if (@range) {
            pop @items;
            push( @items, join( '-', $range[0], $range[-1] ) );
            @range = ();
        }
    };

    for my $item (@_) {
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

    return join( ', ', @items );
};

sub as_books {
    my ($self) = @_;
    my ( @refs, @chapters, $last_book );

    my $flush_chapters = sub {
        if (@chapters) {
            my ($book) = @_;
            push( @refs, "$book " . $self->_compress_range(@chapters) );
            @chapters = ();
        }
    };

    for my $ref ( $self->as_array ) {
        my $book = $ref->[0];

        for my $part ( @{ $ref->[1] } ) {
            my $chapter = $part->[0];

            if ( $part->[1] ) {
                $flush_chapters->($book);

                if ( not $last_book or $last_book ne $book ) {
                    push( @refs, "$book $chapter:" . $self->_compress_range( @{ $part->[1] } ) );
                }
                else {
                    $refs[-1] .= ", $chapter:" . $self->_compress_range( @{ $part->[1] } );
                }
            }
            else {
                push( @chapters, $chapter );
            }
        }

        $flush_chapters->($book);
        $last_book = $book;
    }

    return (wantarray) ? @refs : \@refs;
}

sub refs {
    my ($self) = @_;
    return join( '; ', $self->as_books );
}

sub as_text {
    my ($self) = @_;

    my @buffer;
    my $flush_buffer = sub {
        if (@buffer) {
            $self->_manual_in_refs( [@buffer] );
            @buffer = ();
            return $self->refs;
        }
        else {
            return undef;
        }
    };

    my @text = map {
        my @nodes;
        for my $node (@$_) {
            unless ( ref $node ) {
                push( @nodes, $flush_buffer->(), $node );
            }
            else {
                push( @buffer, $node );
            }
        }
        push( @nodes, $flush_buffer->() );

        join( '', grep { defined } @nodes );
    } @{ $self->_in };

    return
        ( @text > 1 and wantarray )     ? @text :
        ( @text > 1 and not wantarray ) ? \@text : join( ' ', @text );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::Reference - Simple Bible reference parser, tester, and canonicalizer

=head1 VERSION

version 1.01

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bible-Reference.svg)](https://travis-ci.org/gryphonshafer/Bible-Reference)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bible-Reference/badge.png)](https://coveralls.io/r/gryphonshafer/Bible-Reference)

=head1 SYNOPSIS

    use Bible::Reference;

    my $r = Bible::Reference->new;
    $r = Bible::Reference->new(
        bible    => 'Protestant', # or "Orthodox" or "Catholic" or "Vulgate"
        acronyms => 0,            # or 1
        sorting  => 1,            # or 0 to preserve input order
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

    $r->bible('Vulgate');        # switch to the Vulgate Bible
    $r->acronyms(1);             # output acronyms instead of full book names
    $r->sorting(0);              # deactivate sorting of references
    $r->require_verse_match(1);  # require verses in references for matching
    $r->require_book_ucfirst(1); # require book names to be ucfirst for matching

=head1 DESCRIPTION

This module is intended to address Bible reference canonicalization. Given some
input, the module will search for Bible references, canonicalize them, and
return them in various forms desired. It can return the canonicalized within
the context of the input string or strings as well.

The module supports the Protestant Bible by default and by configuration
setting also the Orthodox Bible, the current Catholic Bible, and the Vulgate.

There are also some potentially useful helper methods.

=head1 METHODS

=head2 new

A typical instantiation method that accepts some settings, all of which can
later be fetched and changed with accessors.

    my $r = Bible::Reference->new(
        bible    => 'Protestant', # or "Orthodox" or "Catholic" or "Vulgate"
        acronyms => 0,            # or 1
        sorting  => 1,            # or 0 to preserve input order
    );

See the below accessor methods for details on these settings.

=head2 bible

This accessor method gets and sets the current Bible to use. By default, the
Bible is the Protestant Bible (since this is most common). Other Bibles
supported are the Orthodox, current Catholic, and Vulgate Bibles.

You can set the value to any substring of the name.

    $r->bible('c'); # sets Bible to "Catholic"

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

=head1 HANDLING MATCHING ERRORS

By default, the module does its best to find things that look like valid
references inside text. However, this can result in the occational matching
error. For example, consider the following text input:

    This is an example of the 1 time it might break.
    It also breaks if you mention number 7 from a list of things.
    Legal opinions of judges 3 times said this would break.

With this, we'd falsely match: Thessalonians 1, Numbers 7, and Judges 3.

There are a couple things you can do to reduce this problem. You can optionally
set C<require_verse_match> to a true value. This will cause the matching
algorithm to only work on reference patterns that contain what look to be
verses.

You can optionally set C<require_book_ucfirst> to a true value. This will cause
the matching algorithm to only work on reference patterns that contain what
looks like a book that starts with a capital letter (instead of the default of
any case).

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bible-Reference>

=item *

L<CPAN|http://search.cpan.org/dist/Bible-Reference>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bible::Reference>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bible-Reference>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bible-Reference>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bible-Reference>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-Reference>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-Reference.html>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
