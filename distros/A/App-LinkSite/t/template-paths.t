use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use JSON;
use Path::Tiny;
use App::LinkSite;

my $work = path(tempdir(CLEANUP => 1));
my $src = $work->child('templates');
my $out = $work->child('public');
my $input = $work->child('links.json');
$input->spew(encode_json({
    name => 'Path fixture', handle => 'example', desc => '',
    image => '', og_image => '', site_url => 'https://example.invalid/',
    social => [], links => [],
}));

my @pages = (
    ['index.html', 'Root'],
    ['news/index.html', 'News'],
    ['blog/index.html', 'Blog'],
    ['news/archive/article.html', 'Article'],
    ['archive.tt/index.html', 'Template-suffix directory'],
    ['guide.html.tt', 'Guide'],
);
for my $page (@pages) {
    my ($output_path, $label) = @$page;
    my $template = $src->child("$output_path.tt");
    $template->parent->mkpath;
    # Template Toolkit reads bytes; keep fixture newlines LF on Windows too.
    $template->spew_raw("$label: [% site.name %]\n");
}

my @assets = (
    ['assets/css/style.css', 'body { color: black; }'],
    ['news/readme.txt', 'News assets'],
    ['assets/icon.bin', "\x00\x01\x80\xff\r\n"],
);
for my $asset (@assets) {
    my ($relative_path, $content) = @$asset;
    my $file = $src->child($relative_path);
    $file->parent->mkpath;
    $file->spew_raw($content);
}

App::LinkSite->new(file => "$input", src => "$src", out => "$out")->run;

for my $page (@pages) {
    my ($output_path, $label) = @$page;
    my $generated = $out->child($output_path);
    is($generated->is_file ? $generated->slurp : undef,
        "$label: Path fixture\n", "$output_path is rendered with its own content");
}
ok(!$out->child('article.html')->exists, 'nested article is not flattened into the output root');

for my $asset (@assets) {
    my ($relative_path, $content) = @$asset;
    my $copied = $out->child($relative_path);
    is($copied->is_file ? $copied->slurp_raw : undef,
        $content, "$relative_path is copied without changes");
}
is($out->child('links.json')->slurp_raw, $input->slurp_raw,
    'input JSON is still copied to the output root');

done_testing;
