use Test::Most;
use Test::Moose;

use constant PACKAGE => 'Bible::OBML::Reference';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $self = PACKAGE->new;
    isa_ok( $self, PACKAGE );

    does_ok( $self, 'Throwable' );
    has_attribute_ok( $self, $_, qq{attribute "$_" exists} ) for ( qw( bible ) );
    can_ok( PACKAGE, $_ ) for ( qw( books acronyms parse ) );

    books($self);
    acronyms($self);
    parse($self);

    done_testing();
    return 0;
};

sub books {
    my ($self) = @_;

    is_deeply(
        [ $self->books ],
        [
            'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
            'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
            '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
            'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
            'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel',
            'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah',
            'Haggai', 'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John',
            'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
            'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
            '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
            'Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John',
            '3 John', 'Jude', 'Revelation'
        ],
        '$self->books',
    );

    for (
        [ 'Romans', 'Ro', 'Rom' ],
        [ '1 Timothy', '1Tm', '1 Tim' ],
        [ '2 Samuel', '2Sa', '2 Sam' ],
        [ 'Revelation', 'Rv', 'Rev' ],
    ) {
        my $key = shift @$_;
        is( $self->books($_), $key, "\$self->books('$_') eq '$key'" ) for ( @$_, $key );
    }

    return;
};

sub acronyms {
    my ($self) = @_;

    is_deeply(
        [ $self->acronyms ],
        [
            'Ge', 'Ex', 'Le', 'Nu', 'De', 'Jsh', 'Jdg', 'Ru', '1Sa', '2Sa', '1Ki',
            '2Ki', '1Ch', '2Ch', 'Er', 'Ne', 'Es', 'Jb', 'Ps', 'Prv', 'Ec', 'Sng',
            'Is', 'Je', 'Lm', 'Ek', 'Da', 'Ho', 'Jl', 'Am', 'Ob', 'Jnh', 'Mi',
            'Na', 'Hb', 'Zph', 'Hg', 'Zch', 'Ml', 'Mt', 'Mk', 'Lk', 'Jhn', 'Ac',
            'Ro', '1Co', '2Co', 'Ga', 'Eph', 'Php', 'Co', '1Th', '2Th', '1Tm',
            '2Tm', 'Ti', 'Phm', 'He', 'Ja', '1Pt', '2Pt', '1Jn', '2Jn', '3Jn',
            'Jud', 'Rv'
        ],
        '$self->acronyms',
    );

    is( $self->acronyms( $_->[0] ), $_->[1], "\$self->acronyms('$_->[0]') eq '$_->[1]'" ) for (
        [ 'Romans', 'Ro' ],
        [ '1 Timothy', '1Tm' ],
        [ '2 Samuel', '2Sa' ],
        [ 'Revelation', 'Rv' ],
    );

    return;
};

sub parse {
    my ($self) = @_;

    die_on_fail;
    is( join( '; ', @{ $self->parse( $_->[0] ) } ), $_->[1], "\$self->parse('$_->[0]') --> '$_->[1]'" ) for (
        [ 'Romans 1:15', 'Romans 1:15' ],
        [ '', '' ],
        [ 'Nothing to see 42', '' ],
        [ 'Rom 2:2-14, 15; Mk 5, John 3:16', 'Mark 5; John 3:16; Romans 2:2-14, 15' ],
        [ 'Mk 5, Rom 2:2-14, 15; John 3:16', 'Mark 5; John 3:16; Romans 2:2-14, 15' ],
        [ 'Mk 5, John 3:16, Rom 2:2-14, 15', 'Mark 5; John 3:16; Romans 2:2-14, 15' ],
        [ 'Lk 3:15-17, 18; 4:5-10', 'Luke 3:15-17, 18; Luke 4:5-10' ],
    );
    restore_fail;

    return;
};
