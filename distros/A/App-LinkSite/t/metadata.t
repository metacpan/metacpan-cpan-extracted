use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Path::Tiny;
use Template;
use App::LinkSite::Site;

my $tt = Template->new({ INCLUDE_PATH => path($Bin)->parent->child('src')->stringify });

sub render {
    my (%data) = @_;
    my $site = App::LinkSite::Site->new(
        name => 'Example', handle => 'example', image => '', desc => '',
        og_image => '', site_url => 'https://example.invalid/', %data,
    );
    my $html = '';
    $tt->process('index.html.tt', { site => $site, ga4 => '', version => 'test' }, \$html)
        or die $tt->error;
    return $html;
}

subtest 'metadata preserves quotes, ampersands, and markup as text' => sub {
    my $html = render(
        name => q{Pat "P" O'Neil & Co}, handle => q{pat"&team},
        desc => "I've built \"Things\" & <em>more</em>\nSecond line",
        site_url => q{https://example.invalid/?a=1&b="two"/},
        og_image => q{preview&"card".png},
    );
    my $metadata = join "\n", grep { /<meta / } split /\n/, $html;
    # Both forms are valid in double quotes; newer TT versions encode apostrophes.
    $metadata =~ s/&#39;/'/g;
    for my $expected (
        q{<meta property="og:title" content="Pat &quot;P&quot; O'Neil &amp; Co / @pat&quot;&amp;team">},
        q{<meta property="og:description" content="I've built &quot;Things&quot; &amp; &lt;em&gt;more&lt;/em&gt; Second line">},
        q{<meta property="og:image" content="https://example.invalid/?a=1&amp;b=&quot;two&quot;/img/preview&amp;&quot;card&quot;.png">},
        q{<meta property="og:url" content="https://example.invalid/?a=1&amp;b=&quot;two&quot;/">},
        q{<meta name="description" content="A page of links for Pat &quot;P&quot; O'Neil &amp; Co (@pat&quot;&amp;team)">},
    ) {
        like($metadata, qr/\Q$expected\E/, 'metadata attribute escapes its full value');
    }
    like($html, qr{<div id="desc">I've built "Things" & <em>more</em><br>Second line</div>},
        'visible description retains simple HTML and newline conversion');
    done_testing;
};

subtest 'plain metadata and optional fields' => sub {
    my $html = render;
    like($html, qr{<meta property="og:title" content="Example / \@example">},
        'ordinary title is unchanged');
    like($html, qr{<meta property="og:url" content="https://example\.invalid/">},
        'ordinary site URL is unchanged');
    unlike($html, qr{property="og:(?:description|image)"},
        'empty description and image metadata are omitted');
    done_testing;
};

done_testing;
