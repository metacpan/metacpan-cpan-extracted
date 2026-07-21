use strict;
use warnings;
no warnings 'once';
use Test::More;
use File::Temp qw(tempdir);

use_ok('Chandra::Markdown');

# ---------------------------------------------------------------
# Mock helpers
# ---------------------------------------------------------------

sub mock_app {
    my $mock = bless {
        _css => [], _evals => [], _routes => [],
        _binds => [], _dispatch_evals => [],
    }, 'MockChandraMD';
    no strict 'refs';
    no warnings 'redefine';
    *MockChandraMD::css           = sub { push @{$_[0]{_css}},            $_[1]; $_[0] };
    *MockChandraMD::eval          = sub { push @{$_[0]{_evals}},          $_[1]; $_[0] };
    *MockChandraMD::route         = sub { push @{$_[0]{_routes}},  [$_[1], $_[2]]; $_[0] };
    *MockChandraMD::bind          = sub { push @{$_[0]{_binds}},   [$_[1], $_[2]]; $_[0] };
    *MockChandraMD::dispatch_eval = sub { push @{$_[0]{_dispatch_evals}}, $_[1]; $_[0] };
    *MockChandraMD::navigate      = sub { $_[0] };
    return $mock;
}

sub mock_renderer {
    my $mock = bless {}, 'MockRenderer';
    no strict 'refs';
    no warnings 'redefine';
    *MockRenderer::render = sub { "<p>$_[1]</p>" };
    return $mock;
}

# ---------------------------------------------------------------
# Construction
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app);
    ok($md, 'new() returns object');
    isa_ok($md, 'Chandra::Markdown');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, gfm => 0);
    is($md->gfm, 0, 'gfm => 0 stored');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, hard_breaks => 1);
    is($md->hard_breaks, 1, 'hard_breaks => 1 stored');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, id => 'my-md');
    is($md->id, 'my-md', 'custom id stored');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    is(scalar @{$app->{_css}}, 0, 'css => 0 skips inject_css');
}

{
    my $app = mock_app();
    Chandra::Markdown->new(app => $app, css => 1);
    is(scalar @{$app->{_css}}, 1, 'css => 1 calls inject_css');
}

# ---------------------------------------------------------------
# CSS injection content
# ---------------------------------------------------------------

{
    my $app = mock_app();
    Chandra::Markdown->new(app => $app);
    my $css = $app->{_css}[0];
    ok(defined $css && length $css, 'inject_css receives non-empty string');
    like($css, qr/\.chandra-markdown/, 'CSS contains .chandra-markdown');
    like($css, qr/font-family/,        'CSS contains font-family');
    like($css, qr/pre/,                'CSS contains pre');
}

# ---------------------------------------------------------------
# render()
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $html = $md->render("# hello");
    like($html, qr/<h1>/i, 'render basic markdown returns H1 HTML');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    like($md->render("**bold**"), qr/<strong>/i, 'render **bold** -> <strong>');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    like($md->render("# heading"), qr/<h1>/i, 'render # heading -> <h1>');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $table_md = "| a | b |\n|---|---|\n| 1 | 2 |\n";
    like($md->render($table_md), qr/<table>/i, 'render GFM table -> <table>');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    like($md->render("~~strike~~"), qr/<del>/i, 'render GFM strikethrough -> <del>');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    like($md->render("- [x] done\n- [ ] todo"), qr/type="checkbox"/i,
        'render task list -> checkbox');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    like($md->render("```perl\nmy \$x = 1;\n```"), qr/<code/i,
        'render fenced code block -> <code');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $out = $md->render('');
    is($out, '<div id="_e_8" class="chandra-markdown"></div>', 'render empty string returns empty string');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0, gfm => 0);
    my $table_md = "| a | b |\n|---|---|\n| 1 | 2 |\n";
    unlike($md->render($table_md), qr/<table>/i, 'gfm => 0 disables tables');
}

# ---------------------------------------------------------------
# set()
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->_renderer(mock_renderer());
    my $ret = $md->set("hello");
    is($ret, $md, 'set() returns $self');
    is(scalar @{$app->{_evals}}, 1, 'set() calls eval on app');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->_renderer(mock_renderer());
    $md->set("hello");
    like($app->{_evals}[0], qr/chandra-markdown/, 'set() targets default container id');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0, id => 'my-content');
    $md->_renderer(mock_renderer());
    $md->set("hello");
    like($app->{_evals}[0], qr/my-content/, 'set() uses custom id');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->_renderer(mock_renderer());
    $md->set("hello");
    like($app->{_evals}[0], qr/innerHTML\s*=\s*'/, 'set() JS uses innerHTML assignment');
}

# ---------------------------------------------------------------
# append()
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->_renderer(mock_renderer());
    $md->append("hello");
    like($app->{_evals}[0], qr/innerHTML\s*\+=\s*'/, 'append() JS uses += on innerHTML');
}

# ---------------------------------------------------------------
# render_dir()
# ---------------------------------------------------------------

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/alpha.md", "# Alpha Title\nSome content.");
    _write_file("$dir/beta.md",  "# Beta Title\nOther content.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir);

    ok(defined $nav && length $nav, 'render_dir returns HTML string');
   like($nav, qr/<nav/,  'render_dir return contains <nav>');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/guide.md", "# The Guide\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir);

    like($nav, qr/The Guide/, 'render_dir extracts # heading as link text');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/my-guide.md", "no heading here\njust text.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir);

    like($nav, qr/my guide/i, 'render_dir falls back to filename with hyphens replaced');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/some_doc.md", "");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir);

    like($nav, qr/some doc/i, 'render_dir filename with underscores -> spaces in title');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    is(scalar @{$app->{_routes}}, 1, 'render_dir registers a route per file on the app');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, base_route => '/docs');

    like($app->{_routes}[0][0], qr{^/docs}, 'render_dir route path uses base_route prefix');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    like($app->{_routes}[0][0], qr{^/docs}, 'render_dir default base_route is /docs');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, base_route => '/help');

    like($app->{_routes}[0][0], qr{^/help}, 'render_dir custom base_route option works');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir, nav_id => 'my-nav');

    like($nav, qr/id="my-nav"/, 'render_dir custom nav_id appears in <nav id=...>');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/b_page.md", "# B");
    _write_file("$dir/a_page.md", "# A");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $nav = $md->render_dir($dir, sort => 'alpha');

    my @hrefs = ($nav =~ /href="([^"]+)"/g);
    ok($hrefs[0] lt $hrefs[1], 'render_dir sort => alpha orders files alphabetically');
}

{
    my $dir    = tempdir(CLEANUP => 1);
    my $subdir = "$dir/sub";
    mkdir $subdir;
    _write_file("$dir/top.md",     "# Top");
    _write_file("$subdir/deep.md", "# Deep");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, recursive => 0);

    is(scalar @{$app->{_routes}}, 1, 'render_dir recursive => 0 ignores subdirectories');
}

{
    my $dir    = tempdir(CLEANUP => 1);
    my $subdir = "$dir/sub";
    mkdir $subdir;
    _write_file("$dir/top.md",     "# Top");
    _write_file("$subdir/deep.md", "# Deep");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, recursive => 1);

    is(scalar @{$app->{_routes}}, 2, 'render_dir recursive => 1 includes subdir files');
}

{
    my $dir    = tempdir(CLEANUP => 1);
    my $subdir = "$dir/api";
    mkdir $subdir;
    _write_file("$subdir/intro.md", "# Intro");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, base_route => '/docs', recursive => 1);

    like($app->{_routes}[0][0], qr{/docs/api/intro},
        'render_dir subdir file route uses relative path');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Real Content");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $cb   = $app->{_routes}[0][1];
    my $html = $cb->();
    like($html, qr/Real Content/, 'render_dir registered route callback renders file content');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/index.md", "# Home");
    _write_file("$dir/page.md",  "# Page");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir, base_route => '/docs');

    my %routes = map { $_->[0] => 1 } @{$app->{_routes}};
    ok(exists $routes{'/docs'}, 'render_dir index.md becomes base_route (not /docs/index)');
}

# ---------------------------------------------------------------
# search()
# ---------------------------------------------------------------

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/cats.md",  "# Cats\nCats are furry animals that meow.");
    _write_file("$dir/dogs.md",  "# Dogs\nDogs are loyal animals that bark.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $results = $md->search("cats meow");
    ok(ref $results eq 'ARRAY', 'search returns arrayref');
    ok(scalar @$results > 0,    'search returns results for matching query');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/cats.md", "# Cats\nCats are furry animals that meow.");
    _write_file("$dir/dogs.md", "# Dogs\nDogs are loyal animals that bark.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $results = $md->search("cats meow");
    my $hit = $results->[0];
    ok(exists $hit->{route},   'search result has route');
    ok(exists $hit->{title},   'search result has title');
    ok(exists $hit->{score},   'search result has score');
    ok(exists $hit->{snippet}, 'search result has snippet');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/cats.md", "# Cats\nCats are furry animals that meow.");
    _write_file("$dir/dogs.md", "# Dogs\nDogs are loyal animals that bark.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $results = $md->search("cats meow");
    is($results->[0]{title}, 'Cats', 'search returns best matching doc first');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nSome content here.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $results = $md->search("xyzzy plugh frobble");
    is(scalar @$results, 0, 'search returns empty arrayref for no match');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $results = $md->search("anything");
    is(scalar @$results, 0, 'search on empty index returns []');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);

    my $results = $md->search("page content", 1);
    ok(scalar @$results <= 1, 'search respects limit argument');
}

# ---------------------------------------------------------------
# search_widget()
# ---------------------------------------------------------------

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);
    my $widget = $md->search_widget;

    ok(defined $widget && length $widget, 'search_widget returns HTML');
    like($widget, qr/type="search"/, 'search_widget HTML contains search input');
    like($widget, qr/__chandra_md_search/, 'search_widget JS references invoke name');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);
    $md->search_widget;

    is(scalar @{$app->{_binds}}, 1, 'search_widget registers a bind handler');
    is($app->{_binds}[0][0], '__chandra_md_search', 'bind uses __chandra_md_search name');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/cats.md", "# Cats\nCats meow and purr.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);
    $md->search_widget;

    # Invoke the bound handler directly
    my $cb = $app->{_binds}[0][1];
    $cb->('cats meow');

    is(scalar @{$app->{_dispatch_evals}}, 1, 'search handler calls dispatch_eval');
    like($app->{_dispatch_evals}[0], qr/chandra-content/, 'dispatch_eval targets chandra-content');
    like($app->{_dispatch_evals}[0], qr/Cats/, 'dispatch_eval includes matching result title');
}

{
    my $dir = tempdir(CLEANUP => 1);
    _write_file("$dir/page.md", "# Page\nContent.");

    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    $md->render_dir($dir);
    my $widget = $md->search_widget(placeholder => 'Find something...');

    like($widget, qr/Find something/, 'search_widget uses custom placeholder');
}

# ---------------------------------------------------------------
# highlight attribute
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app);
    is($md->highlight, 1, 'highlight defaults to 1');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, highlight => 0);
    is($md->highlight, 0, 'highlight => 0 stored');
}

# ---------------------------------------------------------------
# highlight rendering — flag on (default)
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $out = $md->render("```perl\nmy \$x = 1;\n```\n");
    like($out, qr{<span class="esh-k">my</span>},   'highlight on: perl keyword my');
    like($out, qr{<span class="esh-v">\$x</span>},  'highlight on: perl variable $x');
    like($out, qr{<span class="esh-n">1</span>},     'highlight on: number 1');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $out = $md->render("```c\nint main(void) { return 0; }\n```\n");
    like($out, qr{<span class="esh-k">int</span>},    'highlight on: c keyword int');
    like($out, qr{<span class="esh-k">return</span>}, 'highlight on: c keyword return');
}

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $out = $md->render("```js\nconst x = null;\n```\n");
    like($out, qr{<span class="esh-k">const</span>}, 'highlight on: js keyword const');
    like($out, qr{<span class="esh-k">null</span>},  'highlight on: js keyword null');
}

# ---------------------------------------------------------------
# highlight rendering — flag off
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0, highlight => 0);
    my $out = $md->render("```perl\nmy \$x = 1;\n```\n");
    unlike($out, qr{<span},          'highlight off: no spans emitted');
    like($out,   qr{my \$x = 1;},    'highlight off: content still present');
}

# ---------------------------------------------------------------
# fenced block with no language: plain passthrough regardless of flag
# ---------------------------------------------------------------

{
    my $app = mock_app();
    my $md  = Chandra::Markdown->new(app => $app, css => 0);
    my $out = $md->render("```\nplain code\n```\n");
    unlike($out, qr{<span},           'no lang tag: no spans even with highlight on');
    like($out,   qr{plain code},      'no lang tag: content preserved');
}

# ---------------------------------------------------------------
# highlight CSS is injected
# ---------------------------------------------------------------

{
    my $app = mock_app();
    Chandra::Markdown->new(app => $app, css => 1);
    my $css = $app->{_css}[0];
    like($css, qr/\.esh-k/,  'injected CSS contains .esh-k rule');
    like($css, qr/\.esh-s/,  'injected CSS contains .esh-s rule');
    like($css, qr/\.esh-c/,  'injected CSS contains .esh-c rule');
    like($css, qr/\.esh-n/,  'injected CSS contains .esh-n rule');
    like($css, qr/\.esh-v/,  'injected CSS contains .esh-v rule');
    like($css, qr/\.esh-g/,  'injected CSS contains .esh-g rule');
    like($css, qr/--esh-keyword/, 'CSS uses CSS custom properties for theming');
}

done_testing;

sub _write_file {
    my ($path, $content) = @_;
    open my $fh, '>:utf8', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}
