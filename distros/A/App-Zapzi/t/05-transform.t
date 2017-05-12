#!perl
use Test::Most;
use utf8;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::FetchArticle;
use App::Zapzi::Transform;

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_text();
test_text_ws_long_lines();
test_html();
test_html_extractmain();
test_pod();
test_missing_transformer();
done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Transform',
            qw(raw_article to_readable readable_text) );
}

sub test_text
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.txt');
    ok( $f->fetch, 'Fetch text' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample text file' );
    ok( ! $tx->error, 'No error when transformer ran ok' );
    like( $tx->readable_text, qr/<p>No special formatting/,
          'Contents of text file OK' );
    like( $tx->title, qr/This is a sample text file/, 'Title of text file OK' );

    $f = App::Zapzi::FetchArticle->new(
        source => 't/testfiles/bad-markdown.txt');
    ok( $f->fetch, 'Fetch text' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform text file with bad markdown' );
    is( $@, "", "Error suppressed from bad markdown" );
    like( $tx->readable_text, qr/<p>Text::Markdown will report an error/,
          'Contents of text with bad markdown OK' );
}

sub test_text_ws_long_lines
{
    my $f = App::Zapzi::FetchArticle->new(source =>
                                          't/testfiles/ws-and-long-lines.txt');
    ok( $f->fetch, 'Fetch text' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform ws-and-long-lines.txt' );

    ok( length($tx->title) <= 80, 'Length of title OK' );
    like( $tx->title, qr/^This is an example/, 'Title without whitespace' );
}

sub test_html
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.html');
    ok( $f->fetch, 'Fetch HTML' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f,
                                        transformer => 'HTML');
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file' );
    like( $tx->readable_text, qr/<h1>Lorem/, 'Contents of HTML file OK' );
    unlike( $tx->readable_text, qr/<script>/,
            'Javascript stripped from HTML file' );
    unlike( $tx->readable_text, qr/<iframe/,
            'iframe stripped from HTML file' );
    like( $tx->readable_text, qr/Header!/,
          'Full HTML preserved with plain HTML transformer' );
    is( $tx->title, 'Sample “HTML” Document',
        'Title of HTML file OK with entity decoding' );
}

sub test_html_extractmain
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.html');
    ok( $f->fetch, 'Fetch HTML' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file' );
    like( $tx->readable_text, qr/<h1>Lorem/, 'Contents of HTML file OK' );
    unlike( $tx->readable_text, qr/<script>/,
            'Javascript stripped from HTML file' );
    unlike( $tx->readable_text, qr/Header!/,
            'Non-essential text stripped from HTML file' );
    is( $tx->title, 'Sample “HTML” Document',
        'Title of HTML file OK with entity decoding' );

    # Try an HTML file with no <title>
    $f = App::Zapzi::FetchArticle->new(
        source => 't/testfiles/html-no-title.html');
    ok( $f->fetch, 'Fetch HTML' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file' );
    like( $tx->title, qr/html-no-title/,
          'Title set for HTML file without <title>' );

    # Try an HTML file with two titles and leading/trailing whitespace
    $f = App::Zapzi::FetchArticle->new(
        source => 't/testfiles/html-two-titles.html');
    ok( $f->fetch, 'Fetch HTML with two title tags' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file' );
    is( $tx->title, 'Title 1',
        'Title selected from HTML extract with two title tags');

    # Try an HTML file with embedded font tags
    $f = App::Zapzi::FetchArticle->new(
        source => 't/testfiles/html-font.html');
    ok( $f->fetch, 'Fetch HTML with font tags' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file with font tags' );
    unlike( $tx->readable_text, qr/yellow/,
            'Font attributes removed from HTML');

    # Try an HTML file with links
    $f = App::Zapzi::FetchArticle->new(
        source => 't/testfiles/html-links.html');
    ok( $f->fetch, 'Fetch HTML with links' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file with links' );
    like( $tx->readable_text, qr|example.com/some-link|,
          'Links present in HTML');

    ok( App::Zapzi::UserConfig::set('deactivate_links', 'Yes'),
        'Can set deactivate_links' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file with links' );
    unlike( $tx->readable_text, qr|example.com/some-link|,
            'Links now not present in HTML');

    ok( App::Zapzi::UserConfig::set('deactivate_links', 'No'),
        'Can set deactivate_links off' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file with links' );
    like( $tx->readable_text, qr|example.com/some-link|,
          'Links present in HTML again');

    # Try an empty HTML file, which should return error
    $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/empty.html');
    ok( $f->fetch, 'Fetch HTML' );
    $tx = App::Zapzi::Transform->new(raw_article => $f,
                                     transformer => 'HTMLExtractMain');
    isa_ok( $tx, 'App::Zapzi::Transform' );
    is( $tx->to_readable, undef, 'Empty HTML file returns error' );
}

sub test_pod
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.pm');
    ok( $f->fetch, 'Fetch POD' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample file containing POD' );

    like( $tx->readable_text, qr/TESTING/s,
          'Headings in POD file OK' );
    like( $tx->readable_text, qr/<p>POD is transformed/s,
          'Text in POD file OK' );

    is( $tx->title, 'sample.pm',
        'Basename of file is used for POD title' );

    # Try a named module
    $f = App::Zapzi::FetchArticle->new(source => 'File::Basename');
    ok( $f->fetch, 'Fetch POD from module' );
    $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform module containing POD' );

    like( $tx->readable_text, qr/DESCRIPTION/s,
          'Headings in POD module OK' );

    is( $tx->title, 'File::Basename',
        'Module name is used for POD title' );
}

sub test_missing_transformer
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.html');
    ok( $f->fetch, 'Fetch HTML' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f,
                                        transformer => 'Nonesuch');
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( ! $tx->to_readable, 'Detected missing transformer' );
    ok( $tx->error, 'Error when missing transformer' );
}
