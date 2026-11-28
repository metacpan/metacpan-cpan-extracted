use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use File::Temp 'tempdir';
use JSON;
use Path::Tiny;
use URI;
use App::LinkSite;
use App::LinkSite::Link;

sub make_link {
    my (%args) = @_;
    return App::LinkSite::Link->new(title => 'Example', link => 'https://example.invalid/page', %args);
}

subtest 'tracking is opt-in and keeps the canonical link' => sub {
    my $url = 'https://Example.invalid/page?keep=a%20b#part';
    for my $utm (undef, 0, JSON::false) {
        is(make_link(link => $url, utm => $utm)->tracked_link, $url, 'disabled tracking leaves bytes unchanged');
    }
    my $link = make_link(utm => {});
    is($link->tracked_link,
        'https://example.invalid/page?utm_campaign=profile&utm_content=example&utm_medium=referral&utm_source=linksite',
        'empty object enables the defaults');
    is($link->link, 'https://example.invalid/page', 'canonical reader remains unchanged');
    like($link->mk_link, qr{href="https://example\.invalid/page\?utm_campaign=profile&amp;utm_content=example&amp;utm_medium=referral&amp;utm_source=linksite"},
        'tracked click destination is HTML-escaped');
    done_testing;
};

subtest 'content defaults to a title slug' => sub {
    for my $case (
        ["  My 'New' Newsletter & More!  ", 'my-new-newsletter-more'],
        ["Caf\x{e9} / \x{6771}\x{4eac}", 'caf%C3%A9-%E6%9D%B1%E4%BA%AC'],
        ['0', '0'],
        ['!!!', undef],
        ['', undef],
    ) {
        my ($title, $expected) = @$case;
        my $url = make_link(title => $title, utm => {})->tracked_link;
        if (defined $expected) {
            like($url, qr/(?:\?|&)utm_content=\Q$expected\E(?:&|\z)/,
                'title is lowercased and punctuation becomes trimmed hyphens');
        } else {
            unlike($url, qr/(?:\?|&)utm_content=/, 'an empty slug omits content');
        }
    }
    my $url = make_link(title => '!!!', utm => { utm_content => 'chosen value' })->tracked_link;
    like($url, qr/utm_content=chosen%20value/, 'explicit content overrides even an empty title slug');
    my %existing = URI->new(make_link(
        link => 'https://example.invalid/?utm_content=existing#part', utm => {},
    )->tracked_link)->query_form;
    is($existing{utm_content}, 'existing', 'existing URL content wins over the title slug');
    done_testing;
};

subtest 'overrides encode values and allow omitted parameters' => sub {
    my $link = make_link(utm => {
        utm_source => 'my page & "links"', utm_medium => '',
        utm_campaign => "caf\x{e9} / summer", utm_content => 0,
        utm_term => undef, utm_source_platform => 'profile',
    });
    is($link->tracked_link,
        'https://example.invalid/page?utm_campaign=caf%C3%A9%20%2F%20summer&utm_content=0&utm_source=my%20page%20%26%20%22links%22&utm_source_platform=profile',
        'values use UTF-8 percent encoding; empty/null values are omitted and zero is retained');
    is(make_link(utm => { utm_source => undef, utm_medium => '', utm_campaign => undef, utm_content => undef })->tracked_link,
        'https://example.invalid/page', 'no empty query is added when all parameters are omitted');
    done_testing;
};

subtest 'queries and fragments retain their original bytes' => sub {
    my $base = 'https://Example.invalid/path?keep=a%20b&duplicate=one&duplicate=two&%75tm_source=existing+source';
    my $tracked = make_link(link => "$base#part#second", utm => { utm_source => 'override' })->tracked_link;
    is($tracked, "$base&utm_campaign=profile&utm_content=example&utm_medium=referral#part#second",
        'existing encoded UTM keys win without rewriting queries or fragments');
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    for my $url ('https://example.invalid/?', 'https://example.invalid/?keep=x&',
        'https://example.invalid/?&&keep=x&') {
        my $prefix = $url;
        is(make_link(link => $url, utm => {})->tracked_link,
            $prefix . 'utm_campaign=profile&utm_content=example&utm_medium=referral&utm_source=linksite',
            'an existing separator is reused');
    }
    is(make_link(link => 'https://example.invalid/?utm_source', utm => {})->tracked_link,
        'https://example.invalid/?utm_source&utm_campaign=profile&utm_content=example&utm_medium=referral',
        'a bare existing UTM parameter is not duplicated');
    is_deeply(\@warnings, [], 'empty query components produce no warnings');
    done_testing;
};

subtest 'only absolute web URLs are tagged' => sub {
    for my $url ('mailto:me@example.invalid', 'tel:+441234', '#section', '/page',
        'relative/page', '//example.invalid/page', 'ftp://example.invalid/file', 'http:relative') {
        is(make_link(link => $url, utm => {})->tracked_link, $url, "$url is unchanged");
    }
    like(make_link(link => 'HTTP://Example.invalid/path#part', utm => {})->tracked_link,
        qr{\AHTTP://Example\.invalid/path\?utm_campaign=profile&utm_content=example&utm_medium=referral&utm_source=linksite#part\z},
        'HTTP is supported without normalizing the original URL');
    done_testing;
};

subtest 'invalid configuration gives a useful error' => sub {
    for my $case (
        ['yes', qr/utm must be an object or false/],
        [[], qr/utm must be an object or false/],
        [{ source => 'example' }, qr/Invalid UTM parameter 'source'/],
        [{ utm_campaign => [] }, qr/UTM parameter 'utm_campaign' must be/],
    ) {
        my ($utm, $expected) = @$case;
        my $ok = eval { make_link(utm => $utm); 1 };
        ok(!$ok, 'invalid configuration is rejected');
        like($@, $expected, 'error identifies the problem');
    }
    done_testing;
};

my $work = path(tempdir(CLEANUP => 1));
my $src = path($Bin)->parent->child('src');
my $build_count = 0;
sub build {
    my (%data) = @_;
    my $directory = $work->child(++$build_count);
    $directory->mkpath;
    my $input = $directory->child('links.json');
    $input->spew_raw(JSON->new->utf8->canonical->encode({
        name => "Caf\x{e9} \x{2603}", handle => 'example', desc => "Profil caf\x{e9}",
        image => '', og_image => '', site_url => 'https://example.invalid/',
        social => [], links => [], %data,
    }));
    my $out = $directory->child('public');
    my $app = App::LinkSite->new(file => "$input", src => "$src", out => "$out");
    $app->run;
    return ($app, $out->child('index.html')->slurp_utf8, $input, $out);
}

subtest 'global and per-link settings apply to flat and section links' => sub {
    my ($app, $html, $input, $out) = build(
        utm => { utm_source => 'my-profile', utm_campaign => "caf\x{e9}" },
        links => [
            { title => 'Inherited', link => 'https://example.invalid/inherited' },
            { title => 'Override', link => 'https://example.invalid/override',
                utm => { utm_campaign => 'special', utm_medium => undef } },
            { title => 'Disabled', link => 'https://example.invalid/disabled', utm => JSON::false },
            { title => 'Null opt-out', link => 'https://example.invalid/null', utm => undef },
        ],
        sections => [{ title => 'Section', links => [
            { title => 'Section link', link => 'https://example.invalid/section', utm => { utm_content => 'section' } },
        ] }],
        social => [{ service => 'github', handle => 'example' }],
    );
    my @links = $app->site->all_links;
    my %inherited = URI->new($links[0]->tracked_link)->query_form;
    is_deeply(\%inherited, { utm_source => 'my-profile', utm_medium => 'referral', utm_campaign => "caf\xc3\xa9", utm_content => 'inherited' },
        'global Unicode settings and defaults reach top-level links');
    my %override = URI->new($links[1]->tracked_link)->query_form;
    is_deeply(\%override, { utm_source => 'my-profile', utm_campaign => 'special', utm_content => 'override' },
        'per-link settings override and can omit an inherited parameter');
    is($links[$_]->tracked_link, $links[$_]->link, 'per-link opt-out leaves the URL unchanged') for 2, 3;
    my %section = URI->new($links[4]->tracked_link)->query_form;
    is($section{utm_source}, 'my-profile', 'section link inherits global source');
    is($section{utm_content}, 'section', 'section link receives its local override');
    like($html, qr/utm_campaign=caf%C3%A9&amp;utm_content=inherited&amp;utm_medium=referral&amp;utm_source=my-profile/,
        'rendered link uses the tracked destination');
    like($html, qr/Caf\x{e9} \x{2603}/, 'UTF-8 JSON text is written as UTF-8 HTML');
    like($html, qr/Profil caf\x{e9}/, 'non-ASCII visible description survives rendering');
    my $structured = JSON->new->decode($app->site->json_ld);
    is_deeply($structured->{relatedLink}, [map { $_->link } @links], 'JSON-LD retains canonical destinations');
    is_deeply($structured->{mainEntity}{sameAs}, ['https://github.com/example'], 'social URLs are not tagged');
    is($out->child('links.json')->slurp_raw, $input->slurp_raw, 'published input is unchanged');
    done_testing;
};

subtest 'global and per-link content settings override the title slug' => sub {
    my ($app) = build(utm => { utm_content => 'global-value' }, links => [
        { title => 'Global', link => 'https://example.invalid/global' },
        { title => 'Local', link => 'https://example.invalid/local', utm => { utm_content => 'local-value' } },
        { title => 'Empty', link => 'https://example.invalid/empty', utm => { utm_content => '' } },
        { title => 'Null', link => 'https://example.invalid/null', utm => { utm_content => undef } },
    ]);
    my @content = map { my %query = URI->new($_->tracked_link)->query_form; $query{utm_content} }
        $app->site->all_links;
    is_deeply(\@content, ['global-value', 'local-value', undef, undef],
        'global/local overrides and explicit omission take precedence over slugs');
    done_testing;
};

subtest 'individual links can opt in without global tracking' => sub {
    for my $global ({}, { utm => JSON::false }) {
        my ($app) = build(%$global, links => [
            { title => 'Plain', link => 'https://example.invalid/plain' },
            { title => 'Tracked', link => 'https://example.invalid/tracked', utm => {} },
        ]);
        my @links = $app->site->all_links;
        is($links[0]->tracked_link, $links[0]->link, 'ordinary link remains unchanged');
        like($links[1]->tracked_link, qr/utm_source=linksite/, 'individual empty object enables defaults');
    }
    done_testing;
};

done_testing;
