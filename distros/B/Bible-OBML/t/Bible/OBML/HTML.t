use Test::Most;
use Test::Moose;

use constant PACKAGE => 'Bible::OBML::HTML';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $self = PACKAGE->new;
    isa_ok( $self, PACKAGE );

    does_ok( $self, 'Throwable' );
    has_attribute_ok( $self, $_, qq{attribute "$_" exists} ) for ( qw( obml ) );
    can_ok( PACKAGE, $_ ) for ( qw( from_file from_obml from_data ) );

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

    my $html = join( "\n",
        q\<div class="obml">\,
        q\<div class="obml_title">Jude 1</div>\,
        q\<div class="obml_content">\,
        q\<div class="obml_scripture">\,
        q\<p> <sup class="obml_reference"><b>1</b></sup>Jude,<sup\,
        q\class="obml_footnote"><a href="#fn1" title="1: or Judas" >[1]</a></sup><sup class="obml_crossreference"><a\,
        q\href="#cr1" title="1: Mt 13:55; Mk 6:3; Jhn 14:22; Ac 1:13" >{1}</a></sup> a slave<sup\,
        q\class="obml_footnote"><a href="#fn2" title="2: or servant" >[2]</a></sup><sup class="obml_crossreference"><a\,
        q\href="#cr2" title="2: Ti 1:1" >{2}</a></sup> of Jesus Christ, and brother of James,<sup\,
        q\class="obml_footnote"><a href="#fn3" title="3: or Jacob" >[3]</a></sup> to those having been set apart<sup\,
        q\class="obml_footnote"><a href="#fn4" title="4: or loved or sanctified" >[4]</a></sup> in God <i>the</i>\,
        q\Father,<sup class="obml_crossreference"><a href="#cr3" title="3: Ro 1:6; Ro 1:7" >{3}</a></sup> and having\,
        q\been kept<sup class="obml_footnote"><a href="#fn5" title="5: or called" >[5]</a></sup> by<sup\,
        q\class="obml_footnote"><a href="#fn6" title="6: or for or in" >[6]</a></sup> Jesus Christ:<sup\,
        q\class="obml_crossreference"><a href="#cr4" title="4: Jhn 17:12; 1Pt 1:5" >{4}</a></sup> </p><p>\,
        q\</p> <div class="obml_header">The Sin and Punishment of the Ungodly</div>\,
        q\<p> <sup class="obml_reference"><b>14</b></sup>Enoch,<sup class="obml_crossreference"><a href="#cr5"\,
        q\title="5: Ge 5:18; Ge 5:21-24" >{5}</a></sup> <i>the</i> seventh from Adam, also prophesied to these saying:\,
        q\</p><p> <span class="obml_blockquote"> Behold, <i>the</i> Lord came with myriads of His saints<sup\,
        q\class="obml_footnote"><a href="#fn7" title="7: or holy ones" >[7]</a></sup><sup\,
        q\class="obml_crossreference"><a href="#cr6" title="6: De 33:2; Da 7:10; Mt 16:27; He 12:22" >{6}</a></sup>\,
        q\<sup class="obml_reference"><b>15</b></sup>to do judgment against all<sup\,
        q\class="obml_crossreference"><a href="#cr7" title="7: 2Pt 2:6-9" >{7}</a></sup> and to rebuke all the ungodly\,
        q\<i>because of</i><sup class="obml_footnote"><a href="#fn8" title="8: or concerning" >[8]</a></sup> all the\,
        q\ungodly works they did and about all the <i>harsh</i><sup class="obml_footnote"><a href="#fn9" title="9:\,
        q\literally hard" >[9]</a></sup> things which ungodly sinners spoke against Him.<sup class="obml_footnote"><a\,
        q\href="#fn10" title="10: taken from the Jewish First Book of Enoch written approximately in the first century\,
        q\B.C." >[10]</a></sup><sup class="obml_crossreference"><a href="#cr8" title="8: 1Tm 1:9" >{8}</a></sup>\,
        q\</span> </p><p>\,
        q\<sup class="obml_reference"><b>16</b></sup>These are murmurers,\,
        q\complainers,<sup class="obml_crossreference"><a href="#cr9" title="9: Nu 16:11; Nu 16:41; 1Co 10:10"\,
        q\>{9}</a></sup> following <i>after</i><sup class="obml_footnote"><a href="#fn11" title="11: or according to"\,
        q\>[11]</a></sup> their lusts,<sup class="obml_crossreference"><a href="#cr10" title="10: Jdg 1:18; 2Pt 2:10"\,
        q\>{10}</a></sup> and their mouths speak of proud things<sup class="obml_crossreference"><a href="#cr11"\,
        q\title="11: 2Pt 2:18" >{11}</a></sup> <i>showing admiration</i><sup class="obml_footnote"><a href="#fn12"\,
        q\title="12: literally admiring faces" >[12]</a></sup> to gain <i>an advantage</i>.<sup\,
        q\class="obml_footnote"><a href="#fn13" title="13: literally for the sake of you" >[13]</a></sup><sup\,
        q\class="obml_crossreference"><a href="#cr12" title="12: 2Pt 2:3" >{12}</a></sup> </p><p>\,
        q\</p> <div class="obml_header">Persevere in the Love of God</div> <p> <sup\,
        q\class="obml_reference"><b>17</b></sup>But beloved, remember the words spoken before by the apostles<sup\,
        q\class="obml_crossreference"><a href="#cr13" title="13: Eph 4:11" >{13}</a></sup> of our Lord, Jesus\,
        q\Christ,<sup class="obml_crossreference"><a href="#cr14" title="14: He 2:3; 2Pt 3:2" >{14}</a></sup>\,
        q\<sup class="obml_reference"><b>18</b></sup>because they told you that in\,
        q\the last <i>days</i><sup class="obml_footnote"><a href="#fn14" title="14: literally at the last time"\,
        q\>[14]</a></sup><sup class="obml_crossreference"><a href="#cr15" title="15: Ac 20:29; 1Tm 4:1; 2Tm 4:3; 2Pt\,
        q\3:3" >{15}</a></sup> <i>there</i> will be mockers following their own ungodly lusts.<sup\,
        q\class="obml_crossreference"><a href="#cr16" title="16: 2Pt 2:1; 2Pt 3:3" >{16}</a></sup> </p></div>\,
        q\</div>\,
        q\<div class="obml_notes_title">Notes</div>\,
        q\<div class="obml_notes">\,
        q\<p>\,
        q\There are\,
        q\footnotes\,
        q\and\,
        q\crossreferences\,
        q\for this chapter.\,
        q\</p>\,
        q\<div class="obml_footnote">\,
        q\<div class="obml_footnote_title">[Footnotes]</div>\,
        q\<ol>\,
        q\<li><a name="fn1">\,
        q\or\,
        q\<i>Judas</i>\,
        q\</a></li>\,
        q\<li><a name="fn2">\,
        q\or\,
        q\<i>servant</i>\,
        q\</a></li>\,
        q\<li><a name="fn3">\,
        q\or\,
        q\<i>Jacob</i>\,
        q\</a></li>\,
        q\<li><a name="fn4">\,
        q\or\,
        q\<i>loved</i>\,
        q\or\,
        q\<i>sanctified</i>\,
        q\</a></li>\,
        q\<li><a name="fn5">\,
        q\or\,
        q\<i>called</i>\,
        q\</a></li>\,
        q\<li><a name="fn6">\,
        q\or\,
        q\<i>for</i>\,
        q\or\,
        q\<i>in</i>\,
        q\</a></li>\,
        q\<li><a name="fn7">\,
        q\or\,
        q\<i>holy ones</i>\,
        q\</a></li>\,
        q\<li><a name="fn8">\,
        q\or\,
        q\<i>concerning</i>\,
        q\</a></li>\,
        q\<li><a name="fn9">\,
        q\literally\,
        q\<i>hard</i>\,
        q\</a></li>\,
        q\<li><a name="fn10">\,
        q\taken from the Jewish\,
        q\<i>First Book of Enoch</i>\,
        q\written approximately in the first century B.C.\,
        q\</a></li>\,
        q\<li><a name="fn11">\,
        q\or\,
        q\<i>according to</i>\,
        q\</a></li>\,
        q\<li><a name="fn12">\,
        q\literally\,
        q\<i>admiring faces</i>\,
        q\</a></li>\,
        q\<li><a name="fn13">\,
        q\literally\,
        q\<i>for the sake of you</i>\,
        q\</a></li>\,
        q\<li><a name="fn14">\,
        q\literally\,
        q\<i>at the last time</i>\,
        q\</a></li>\,
        q\</ol>\,
        q\</div>\,
        q\<div class="obml_crossreference">\,
        q\<div class="obml_crossreference_title">{Crossreferences}</div>\,
        q\<ol>\,
        q\<li><a name="cr1">Mt 13:55; Mk 6:3; Jhn 14:22; Ac 1:13</a></li>\,
        q\<li><a name="cr2">Ti 1:1</a></li>\,
        q\<li><a name="cr3">Ro 1:6; Ro 1:7</a></li>\,
        q\<li><a name="cr4">Jhn 17:12; 1Pt 1:5</a></li>\,
        q\<li><a name="cr5">Ge 5:18; Ge 5:21-24</a></li>\,
        q\<li><a name="cr6">De 33:2; Da 7:10; Mt 16:27; He 12:22</a></li>\,
        q\<li><a name="cr7">2Pt 2:6-9</a></li>\,
        q\<li><a name="cr8">1Tm 1:9</a></li>\,
        q\<li><a name="cr9">Nu 16:11; Nu 16:41; 1Co 10:10</a></li>\,
        q\<li><a name="cr10">Jdg 1:18; 2Pt 2:10</a></li>\,
        q\<li><a name="cr11">2Pt 2:18</a></li>\,
        q\<li><a name="cr12">2Pt 2:3</a></li>\,
        q\<li><a name="cr13">Eph 4:11</a></li>\,
        q\<li><a name="cr14">He 2:3; 2Pt 3:2</a></li>\,
        q\<li><a name="cr15">Ac 20:29; 1Tm 4:1; 2Tm 4:3; 2Pt 3:3</a></li>\,
        q\<li><a name="cr16">2Pt 2:1; 2Pt 3:3</a></li>\,
        q\</ol>\,
        q\</div>\,
        q\</div>\,
        q\</div>\,
    );

    is( $self->from_data($data), $html, '$self->from_data($data)' );
    is( $self->from_obml($content), $html, '$self->from_obml($content)' );

    done_testing();
    return 0;
};
