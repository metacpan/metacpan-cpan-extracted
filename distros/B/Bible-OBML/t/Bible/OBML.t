use Test::Most;
use Test::Moose;

use constant PACKAGE => 'Bible::OBML';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $self = PACKAGE->new;
    isa_ok( $self, PACKAGE );

    does_ok( $self, 'Throwable' );
    has_attribute_ok( $self, $_, qq{attribute "$_" exists} ) for ( qw( reference html ) );
    can_ok( PACKAGE, $_ ) for ( qw(
        read_file write_file parse render canonicalize smartify desmartify
    ) );

    parse_render($self);
    smartify($self);

    done_testing();
    return 0;
};

sub parse_render {
    my ($self) = @_;

    my $content = join( "\n",
        q\~ Jude 1 ~\,
        q\\,
        q\|1| Jude, [or ^Judas^] {Mt 13:55; Mk 6:3; Jhn 14:22; Ac 1:13} a slave [or\,
        q\^servant^] {Ti 1:1} of Jesus Christ, and brother of James, [or ^Jacob^] to\,
        q\those having been set apart [or ^loved^ or ^sanctified^] in God ^the^ Father,\,
        q\{Ro 1:6; Ro 1:7} and having been kept [or ^called^] by [or ^for^ or ^in^] Jesus\,
        q\Christ: {Jhn 17:12; 1Pt 1:5}\,
        q\\,
        q\= The Sin and Punishment of the Ungodly =\,
        q\\,
        q\|14| Enoch, {Ge 5:18; Ge 5:21-24} ^the^ seventh from Adam, also prophesied to\,
        q\these saying:\,
        q\\,
        q\    Behold, ^the^ Lord came with myriads of His saints [or ^holy ones^] {De\,
        q\    33:2; Da 7:10; Mt 16:27; He 12:22} |15| to do judgment against all {2Pt\,
        q\    2:6-9} and to rebuke all the ungodly ^because of^ [or ^concerning^] all\,
        q\    the ungodly works they did and about all the ^harsh^ [literally ^hard^]\,
        q\    things which ungodly sinners spoke against Him. [taken from the Jewish\,
        q\    ^First Book of Enoch^ written approximately in the first century B.C.]\,
        q\    {1Tm 1:9}\,
        q\\,
        q\|16| These are murmurers, complainers, {Nu 16:11; Nu 16:41; 1Co 10:10}\,
        q\following ^after^ [or ^according to^] their lusts, {Jdg 1:18; 2Pt 2:10} and\,
        q\their mouths speak of proud things {2Pt 2:18} ^showing admiration^ [literally\,
        q\^admiring faces^] to gain ^an advantage^. [literally ^for the sake of you^]\,
        q\{2Pt 2:3}\,
        q\\,
        q\= Persevere in the Love of God =\,
        q\\,
        q\|17| But beloved, remember the words spoken before by the apostles {Eph 4:11}\,
        q\of our Lord, Jesus Christ, {He 2:3; 2Pt 3:2} |18| because they told you that in\,
        q\the last ^days^ [literally ^at the last time^] {Ac 20:29; 1Tm 4:1; 2Tm 4:3; 2Pt\,
        q\3:3} ^there^ will be mockers following their own ungodly lusts. {2Pt 2:1; 2Pt\,
        q\3:3}\,
        q\\,
    );

    my $data = [
        {
            'reference' => { 'verse' => '1', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                'Jude,', [ 'footnote', 'or', [ 'italic', 'Judas' ] ], [
                'crossreference', [ 'Mt 13:55', 'Mk 6:3', 'Jhn 14:22', 'Ac 1:13' ]
                ], 'a slave', [ 'footnote', 'or', [ 'italic', 'servant' ] ], [
                'crossreference', [ 'Ti 1:1' ] ],
                'of Jesus Christ, and brother of James,', [ 'footnote', 'or',
                [ 'italic', 'Jacob' ] ], 'to those having been set apart',
                [ 'footnote', 'or', [ 'italic', 'loved' ],
                'or', [ 'italic', 'sanctified' ] ], 'in God', [ 'italic', 'the' ],
                'Father,', [ 'crossreference', [ 'Ro 1:6', 'Ro 1:7' ] ],
                'and having been kept', [ 'footnote', 'or', [ 'italic', 'called'
                ] ], 'by', [
                'footnote', 'or', [ 'italic', 'for' ], 'or', [ 'italic', 'in' ] ],
                'Jesus Christ:', [ 'crossreference', [ 'Jhn 17:12', '1Pt 1:5' ] ], [
                'paragraph' ]
            ]
        },
        {
            'reference' => { 'verse' => '14', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                'Enoch,', [ 'crossreference', [ 'Ge 5:18', 'Ge 5:21-24' ] ], [
                'italic', 'the' ],
                'seventh from Adam, also prophesied to these saying:',
                [ 'paragraph' ], [ 'blockquote', 'Behold,', [ 'italic',
                'the' ], 'Lord came with myriads of His saints', [ 'footnote', 'or',
                [ 'italic', 'holy ones' ] ], [ 'crossreference', [ 'De 33:2',
                'Da 7:10', 'Mt 16:27', 'He 12:22' ] ] ]
            ],
            'header' => [ 'The Sin and Punishment of the Ungodly' ]
        },
        {
            'reference' => { 'verse' => '15', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                [ 'blockquote', 'to do judgment against all' ], [ 'crossreference',
                [ '2Pt 2:6-9' ] ], 'and to rebuke all the ungodly', [ 'italic',
                'because of' ], [ 'footnote', 'or', [ 'italic', 'concerning' ] ],
                'all the ungodly works they did and about all the', [ 'italic',
                'harsh' ], [ 'footnote', 'literally', [ 'italic', 'hard' ] ],
                'things which ungodly sinners spoke against Him.', [ 'footnote',
                'taken from the Jewish', [ 'italic', 'First Book of Enoch' ],
                'written approximately in the first century B.C.' ], [
                'crossreference', [ '1Tm 1:9' ] ], [ 'paragraph' ]
            ]
        },
        {
            'reference' => { 'verse' => '16', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                'These are murmurers, complainers,', [ 'crossreference', [
                'Nu 16:11', 'Nu 16:41', '1Co 10:10' ] ], 'following', [ 'italic',
                'after' ], [ 'footnote', 'or', [ 'italic', 'according to' ] ],
                'their lusts,', [ 'crossreference', [ 'Jdg 1:18', '2Pt 2:10' ] ],
                'and their mouths speak of proud things', [ 'crossreference', [
                '2Pt 2:18' ] ], [ 'italic', 'showing admiration' ], [ 'footnote',
                'literally', [ 'italic', 'admiring faces' ] ], 'to gain', [
                'italic', 'an advantage' ], '.', [ 'footnote', 'literally', [
                'italic', 'for the sake of you' ] ], [ 'crossreference', [ '2Pt 2:3'
                ] ], [ 'paragraph' ]
            ]
        },
        {
            'reference' => { 'verse' => '17', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                'But beloved, remember the words spoken before by the apostles', [
                'crossreference', [ 'Eph 4:11' ] ], 'of our Lord, Jesus Christ,', [
                'crossreference', [ 'He 2:3', '2Pt 3:2' ] ]
            ],
            'header' => [ 'Persevere in the Love of God' ]
        },
        {
            'reference' => { 'verse' => '18', 'chapter' => '1', 'book' => 'Jude' },
            'content' => [
                'because they told you that in the last', [ 'italic', 'days' ], [
                'footnote', 'literally', [ 'italic', 'at the last time' ] ], [
                'crossreference', [ 'Ac 20:29', '1Tm 4:1', '2Tm 4:3', '2Pt 3:3' ] ],
                [ 'italic', 'there' ],
                'will be mockers following their own ungodly lusts.',
                [ 'crossreference', [ '2Pt 2:1', '2Pt 3:3' ] ]
            ]
        }
    ];

    is_deeply( $self->parse($content), $data, '$self->parse($content)' );
    is_deeply( $self->render($data), $content, '$self->render($data)' );

    return;
}

sub smartify {
    my ($self) = @_;

    my $content =
        q{A "test" of module's "awesome 'perfect' } .
        q{cool" smarts. It's "not" awesome.};
    my $smart_content =
        qq{A \x{201c}test\x{201d} of module\x{2019}s \x{201c}awesome \x{2018}perfect\x{2019} } .
        qq{cool\x{201d} smarts. It\x{2019}s \x{201c}not\x{201d} awesome.};

    is( $self->smartify($content), $smart_content, '$self->smartify($content)' );
    is( $self->desmartify($smart_content), $content, '$self->desmartify($smart_content)' );

    return;
}
