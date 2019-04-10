use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('CommonMark', ':opt');
}

{
    my $filename = 't/files/test.md';
    my $file;

    open($file, '<', $filename) or die("$filename: $!");
    my $doc1 = CommonMark->parse_file($file);
    close($file);

    open($file, '<', $filename) or die("$filename: $!");
    my $doc2 = CommonMark->parse(file => $file);
    close($file);

    is($doc2->render_html, $doc1->render_html, 'parse works with file');
}

{
    my $md  = q{Pretty "smart" -- don't you think?};
    my $doc = CommonMark->parse(string => $md, smart => 1);
    my $expected_html = <<EOF;
<p>Pretty \x{201C}smart\x{201D} \x{2013} don\x{2019}t you think?</p>
EOF

    is($doc->render_html, $expected_html, 'parse works with string and smart');

    my $html = $doc->render(format => 'html');
    is($html, $expected_html, 'render works with HTML format');
}

{
    my $all_opts = CommonMark::_extract_opts({
        sourcepos     => 1,
        hardbreaks    => 'yes',
        safe          => 100,
        nobreaks      => 1,
        normalize     => '0e0',
        validate_utf8 => '1',
        smart         => 'true',
        unsafe        => 1,
    });
    my $expected = OPT_SOURCEPOS
                 | OPT_HARDBREAKS
                 | OPT_SAFE
                 | OPT_NOBREAKS
                 | OPT_NORMALIZE
                 | OPT_VALIDATE_UTF8
                 | OPT_SMART
                 | OPT_UNSAFE;
    is($all_opts, $expected, 'extracting options works');

    my $no_opts = CommonMark::_extract_opts({
        sourcepos     => undef,
        hardbreaks    => 0,
        safe          => -0.0,
        normalize     => 0e100,
        validate_utf8 => '0',
        smart         => '',
        unsafe        => 0,
    });
    is($no_opts, 0, 'extracting unset options works');
}

{
    my $doc = CommonMark->parse_document('test');

    for my $format (qw(html xml commonmark latex man)) {
        my $method   = "render_$format";
        my $expected = $doc->$method();
        my $got      = $doc->render(format => $format);
        is($got, $expected, "render format $format");
    }
}
