use Test2::V0;
use Bible::OBML;

my $self = Bible::OBML->new;
isa_ok( $self, 'Bible::OBML' );

can_ok( $self, $_ ) for ( qw(
    html bible acronyms refs
    read_file write_file parse render canonicalize smartify desmartify
) );

parse_render($self);
smartify($self);
done_testing;

sub parse_render {
    my ($self) = @_;

    my $test = sub {
        my ( $content, $data, $name ) = @_;

        is( $self->parse($content), $data, '$self->parse; # ' . $name );
        is( $self->render($data), $content, '$self->render; # ' . $name );
    };

    $test->(
        join( "\n",
            q\~ Jude 1 ~\,
            q\\,
            q\|1| Jude, a slave of Jesus Christ, and brother of James, to those having been\,
            q\set apart in God ^the^ Father, and having been kept by Jesus Christ.\,
            q\\,
        ),
        [
            {
                'reference' => {
                    'book'    => 'Jude',
                    'chapter' => '1',
                    'verse'   => '1'
                },
                'content' => [
                    'Jude, a slave of Jesus Christ, and brother of James, to those having been set apart in God',
                    [
                        'italic',
                        'the'
                    ],
                    'Father, and having been kept by Jesus Christ.'
                ]
            }
        ],
        'Simple single verse with italic',
    );

    $test->(
        join( "\n",
            q\~ Jude 1 ~\,
            q\\,
            q\|1| Jude, [or ^Judas^] {Mt 13:55; Mk 6:3; Joh 14:22; Ac 1:13} a slave [or\,
            q\^servant^] {Ti 1:1} of Jesus Christ, and brother of James, [or ^Jacob^] to\,
            q\those having been set apart [or ^loved^ or ^sanctified^] in God ^the^ Father,\,
            q\{Ro 1:6-7} and having been kept [or ^called^] by [or ^for^ or ^in^] Jesus\,
            q\Christ: {Joh 17:12; 1Pt 1:5}\,
            q\\,
        ),
        [ {
            'reference' => { 'verse' => '1', 'book' => 'Jude', 'chapter' => '1' },
            'content' => [
                'Jude,', [ 'footnote', 'or', [ 'italic', 'Judas' ] ], [
                'crossreference', [ 'Mt 13:55', 'Mk 6:3', 'Joh 14:22', 'Ac 1:13' ] ],
                'a slave', [ 'footnote', 'or', [ 'italic', 'servant' ] ], [ 'crossreference', [
                'Ti 1:1' ] ], 'of Jesus Christ, and brother of James,', [ 'footnote', 'or', [
                'italic', 'Jacob' ] ], 'to those having been set apart', [ 'footnote', 'or', [
                'italic', 'loved' ], 'or', [ 'italic', 'sanctified' ] ], 'in God', [ 'italic',
                'the' ], 'Father,', [ 'crossreference', [ 'Ro 1:6-7' ] ],
                'and having been kept', [ 'footnote', 'or', [ 'italic', 'called' ] ], 'by',
                [ 'footnote', 'or', [ 'italic', 'for' ], 'or', [ 'italic', 'in' ] ], 'Jesus Christ:',
                [ 'crossreference', [ 'Joh 17:12', '1Pt 1:5' ] ]
            ]
        } ],
        'Complex single verse with footnotes and crossreferences',
    );

    $test->(
        join( "\n",
            q\~ Jude 1 ~\,
            q\\,
            q\= Header Alpha =\,
            q\\,
            q\|1| Jude, a slave of Jesus Christ, and brother of James, to those having been\,
            q\set apart in God ^the^ Father, and having been kept by Jesus Christ. |2| This\,
            q\is a second verse, but it's fake.\,
            q\\,
            q\= Header Beta =\,
            q\\,
            q\|3| This is a third verse, also fake.\,
            q\\,
        ),
        [
            {
                'header' => [ 'Header Alpha' ], 'content' => [
                'Jude, a slave of Jesus Christ, and brother of James, to those having been set apart in God',
                [ 'italic', 'the' ], 'Father, and having been kept by Jesus Christ.' ], 'reference' => {
                'book' => 'Jude', 'verse' => '1', 'chapter' => '1' }
            },
            {
                'reference' => {
                'book' => 'Jude', 'chapter' => '1', 'verse' => '2' }, 'content' =>
                [ 'This is a second verse, but it\'s fake.', [ 'paragraph' ] ]
            },
            {
                'header' => [ 'Header Beta' ], 'reference' => { 'book' => 'Jude', 'chapter' =>
                '1', 'verse' => '3' }, 'content' => [ 'This is a third verse, also fake.' ]
            }
        ],
        '3 simple verses with 2 headers',
    );

    $test->(
        join( "\n",
            q\~ Romans 12 ~\,
            q\\,
            q\|14| These are words.\,
            q\\,
            q\    Behold, these are more words\,
            q\      and another line of words.\,
            q\    |15| For he who |16| reads lines\,
            q\      shall |17| have words.\,
            q\\,
            q\|18| Then there's more.\,
            q\\,
        ),
        [
            { 'reference' => { 'verse' => '14', 'chapter' => '12', 'book' =>
            'Romans' }, 'content' => [ 'These are words.', [ 'paragraph' ], [ 'blockquote', 'Behold, these are more words' ],
            [ 'break' ], [ 'blockquote_indent', 'and another line of words.' ], [
            'break' ] ] }, { 'content' => [ [ 'blockquote', 'For he who' ] ], 'reference' => { 'verse' =>
            '15', 'chapter' => '12', 'book' => 'Romans' } }, { 'content' => [ [ 'blockquote', 'reads lines' ], [ 'break' ],
            [ 'blockquote_indent', 'shall' ] ], 'reference' => { 'book' => 'Romans',
            'chapter' => '12', 'verse' => '16' } }, { 'content' => [ [ 'blockquote_indent', 'have words.' ], [
            'paragraph' ] ], 'reference' => { 'verse' => '17', 'chapter' => '12',
            'book' => 'Romans' } }, { 'content' => [ 'Then there\'s more.' ],
            'reference' => { 'chapter' => '12', 'verse' => '18', 'book' => 'Romans' } }
        ],
        'Blockquote and indented blockquote run with trailing verse',
    );

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
