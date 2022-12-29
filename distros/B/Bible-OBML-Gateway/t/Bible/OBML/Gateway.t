use Test2::V0;
use Bible::OBML::Gateway;
use Mojo::Collection;
use Mojo::DOM;

my $self = Bible::OBML::Gateway->new;
isa_ok( $self, 'Bible::OBML::Gateway' );

can_ok( $self, $_ ) for ( qw(
    translation url ua reference
    translations structure fetch parse get
) );

is( $self->translation, 'NIV', 'default translation' );
isa_ok( $self->url, 'Mojo::URL' );
is( $self->url->to_string, 'https://www.biblegateway.com/passage/', 'default url' );
isa_ok( $self->ua, 'Mojo::UserAgent' );
isa_ok( $self->reference, 'Bible::Reference' );
is( $self->reference->bible, 'Protestant', 'default reference bible' );

my $ua = mock( 'Mojo::UserAgent',
    override => [
        get    => sub { $_[0] },
    ],
    add => [
        result => sub { $_[0] },
        json   => sub { { data => [ { answer => 42 } ] } },
    ],
);

is( $self->structure, { answer => 42 }, 'structure' );

$ua->add(
    dom  => sub { $_[0] },
    find => sub { Mojo::Collection->new(
        mock( 'obj', set => [
            attr => 'lang',
            text => '---English (EN)---',
        ] ),
        mock( 'obj', set => [
            attr => '',
            text => 'New International Version (NIV)',
        ] ),
    ) },
);

is( $self->translations, [ {
    acronym      => 'EN',
    language     => 'English',
    translations => [ {
        acronym     => 'NIV',
        translation => 'New International Version',
    } ],
} ], 'translations' );

my $body = join( '', <DATA> );
$ua->add( body => sub { $body } );
$ua->add( at => sub { 0 } );

my $obml = mock( 'Bible::OBML',
    set => [
        new  => sub { $_[0] },
        html => sub { $_[1] },
    ]
);

my $re = join( '\s*',
    q{<obml>},
    q{<reference>}, q{Romans 12:1-3}, q{</reference>},
    q{<header>}, q{A Living Sacrifice}, q{</header>},
    q{<p>},
    q{<verse_number>}, q{1}, q{</verse_number>},
    q{Therefore, I urge you,},
    q{<crossref>}, q{Ep 4:1; 1Pt 2:11}, q{</crossref>},
    q{brothers and sisters[^<]+sacrifice,},
    q{<crossref>}, q{Ro 6:13, 16, 19; 1Co 6:20; 1Pt 2:5}, q{</crossref>},
    q{holy and pleasing[^<]+proper worship.},
    q{<verse_number>}, q{2}, q{</verse_number>},
    q{Do not conform},
    q{<crossref>}, q{1Pt 1:14}, q{</crossref>},
    q{to the pattern of this world,},
    q{<crossref>}, q{1Co 1:20; 2Co 10:2; 1Jn 2:15}, q{</crossref>},
    q{but be transformed by the renewing of your mind.},
    q{<crossref>}, q{Ep 4:23}, q{</crossref>},
    q{Then you will be able to test and approve what Gods will is},
    q{<crossref>}, q{Ep 5:17}, q{</crossref>},
    q{-his good, pleasing},
    q{<crossref>}, q{1Ti 5:4}, q{</crossref>},
    q{and perfect will.},
    q{</p>},
    q{<header>}, q{Humble Service in the Body of Christ}, q{</header>},
    q{<p>},
    q{<verse_number>}, q{3}, q{</verse_number>},
    q{For by the grace given me},
    q{<crossref>}, q{Ro 15:15; 1Co 15:10; Ga 2:9; Ep 3:7; 4:7; 1Pt 4:10-11}, q{</crossref>},
    q{I say to every one of you[^<]+each of you.},
    q{</p>},
    q{</obml>},
);

like(
    $self->get('Rom 12:1-3'),
    qr/$re/,
    'get() with valid reference and source',
);

done_testing;

__DATA__
<div class="passage-col passage-col-mobile version-NIV" data-translation="NIV"><h1 class="passage-display">
<div class="bcv"><div class="dropdown-display-text">Romans 12:1-3</div></div>
<div class="translation"><div class="dropdown-display-text">New International Version</div></div>
<div class="passage-text">
<div class="passage-content passage-class-0"><div class="version-NIV result-text-style-normal text-html">
<div class="std-text"> <h3><span id="en-NIV-28247" class="text Rom-12-1">A Living Sacrifice</span></h3><p class="chapter-2"><span class="text Rom-12-1"><span class="chapternum">12&nbsp;</span>Therefore, I urge you,<sup class="crossreference" data-cr="#cen-NIV-28247A" data-link="(<a href=&quot;#cen-NIV-28247A&quot; title=&quot;See cross-reference A&quot;>A</a>)">(<a href="#cen-NIV-28247A" title="See cross-reference A">A</a>)</sup> brothers and sisters, in view of God's mercy, to offer your bodies as a living sacrifice,<sup class="crossreference" data-cr="#cen-NIV-28247B" data-link="(<a href=&quot;#cen-NIV-28247B&quot; title=&quot;See cross-reference B&quot;>B</a>)">(<a href="#cen-NIV-28247B" title="See cross-reference B">B</a>)</sup> holy and pleasing to God-this is your true and proper worship.</span> <span id="en-NIV-28248" class="text Rom-12-2"><sup class="versenum">2&nbsp;</sup>Do not conform<sup class="crossreference" data-cr="#cen-NIV-28248C" data-link="(<a href=&quot;#cen-NIV-28248C&quot; title=&quot;See cross-reference C&quot;>C</a>)">(<a href="#cen-NIV-28248C" title="See cross-reference C">C</a>)</sup> to the pattern of this world,<sup class="crossreference" data-cr="#cen-NIV-28248D" data-link="(<a href=&quot;#cen-NIV-28248D&quot; title=&quot;See cross-reference D&quot;>D</a>)">(<a href="#cen-NIV-28248D" title="See cross-reference D">D</a>)</sup> but be transformed by the renewing of your mind.<sup class="crossreference" data-cr="#cen-NIV-28248E" data-link="(<a href=&quot;#cen-NIV-28248E&quot; title=&quot;See cross-reference E&quot;>E</a>)">(<a href="#cen-NIV-28248E" title="See cross-reference E">E</a>)</sup> Then you will be able to test and approve what Gods will is<sup class="crossreference" data-cr="#cen-NIV-28248F" data-link="(<a href=&quot;#cen-NIV-28248F&quot; title=&quot;See cross-reference F&quot;>F</a>)">(<a href="#cen-NIV-28248F" title="See cross-reference F">F</a>)</sup>-his good, pleasing<sup class="crossreference" data-cr="#cen-NIV-28248G" data-link="(<a href=&quot;#cen-NIV-28248G&quot; title=&quot;See cross-reference G&quot;>G</a>)">(<a href="#cen-NIV-28248G" title="See cross-reference G">G</a>)</sup> and perfect will.</span></p> <h3><span id="en-NIV-28249" class="text Rom-12-3">Humble Service in the Body of Christ</span></h3><p><span class="text Rom-12-3"><sup class="versenum">3&nbsp;</sup>For by the grace given me<sup class="crossreference" data-cr="#cen-NIV-28249H" data-link="(<a href=&quot;#cen-NIV-28249H&quot; title=&quot;See cross-reference H&quot;>H</a>)">(<a href="#cen-NIV-28249H" title="See cross-reference H">H</a>)</sup> I say to every one of you: Do not think of yourself more highly than you ought, but rather think of yourself with sober judgment, in accordance with the faith God has distributed to each of you.</span> </p></div><div class="il-text"></div><a class="full-chap-link" href="/passage/?search=Romans+12&amp;version=NIV" title="View Full Chapter">Read full chapter</a>
<div class="crossrefs hidden">
<h4>Cross references</h4><ol><li id="cen-NIV-28247A"><a href="#en-NIV-28247" title="Go to Romans 12:1">Romans 12:1</a> : <a class="crossref-link" href="/passage/?search=Ephesians+4%3A1%2C1+Peter+2%3A11&amp;version=NIV" data-bibleref="Ephesians 4:1, 1 Peter 2:11">Eph 4:1; 1Pe 2:11</a></li>

<li id="cen-NIV-28247B"><a href="#en-NIV-28247" title="Go to Romans 12:1">Romans 12:1</a> : <a class="crossref-link" href="/passage/?search=Romans+6%3A13%2CRomans+6%3A16%2CRomans+6%3A19%2C1+Corinthians+6%3A20%2C1+Peter+2%3A5&amp;version=NIV" data-bibleref="Romans 6:13, Romans 6:16, Romans 6:19, 1 Corinthians 6:20, 1 Peter 2:5">Ro 6:13, 16, 19; 1Co 6:20; 1Pe 2:5</a></li>

<li id="cen-NIV-28248C"><a href="#en-NIV-28248" title="Go to Romans 12:2">Romans 12:2</a> : <a class="crossref-link" href="/passage/?search=1+Peter+1%3A14&amp;version=NIV" data-bibleref="1 Peter 1:14">1Pe 1:14</a></li>

<li id="cen-NIV-28248D"><a href="#en-NIV-28248" title="Go to Romans 12:2">Romans 12:2</a> : <a class="crossref-link" href="/passage/?search=1+Corinthians+1%3A20%2C2+Corinthians+10%3A2%2C1+John+2%3A15&amp;version=NIV" data-bibleref="1 Corinthians 1:20, 2 Corinthians 10:2, 1 John 2:15">1Co 1:20; 2Co 10:2; 1Jn 2:15</a></li>

<li id="cen-NIV-28248E"><a href="#en-NIV-28248" title="Go to Romans 12:2">Romans 12:2</a> : <a class="crossref-link" href="/passage/?search=Ephesians+4%3A23&amp;version=NIV" data-bibleref="Ephesians 4:23">Eph 4:23</a></li>

<li id="cen-NIV-28248F"><a href="#en-NIV-28248" title="Go to Romans 12:2">Romans 12:2</a> : <a class="crossref-link" href="/passage/?search=Ephesians+5%3A17&amp;version=NIV" data-bibleref="Ephesians 5:17">S Eph 5:17</a></li>

<li id="cen-NIV-28248G"><a href="#en-NIV-28248" title="Go to Romans 12:2">Romans 12:2</a> : <a class="crossref-link" href="/passage/?search=1+Timothy+5%3A4&amp;version=NIV" data-bibleref="1 Timothy 5:4">S 1Ti 5:4</a></li>

<li id="cen-NIV-28249H"><a href="#en-NIV-28249" title="Go to Romans 12:3">Romans 12:3</a> : <a class="crossref-link" href="/passage/?search=Romans+15%3A15%2C1+Corinthians+15%3A10%2CGalatians+2%3A9%2CEphesians+3%3A7%2CEphesians+4%3A7%2C1+Peter+4%3A10%2C1+Peter+4%3A11&amp;version=NIV" data-bibleref="Romans 15:15, 1 Corinthians 15:10, Galatians 2:9, Ephesians 3:7, Ephesians 4:7, 1 Peter 4:10, 1 Peter 4:11">Ro 15:15; 1Co 15:10; Gal 2:9; Eph 3:7; 4:7; 1Pe 4:10, 11</a></li>

</ol></div> <!--end of crossrefs-->
</div>
</div>
</div>
</div>
