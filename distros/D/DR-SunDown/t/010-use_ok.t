#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 19;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::SunDown';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname';
}

my $ifile = catfile dirname(dirname __FILE__), 'sundown', 'README.markdown';
ok -f $ifile, "-f $ifile";

ok open(my $fh, '<:encoding(UTF-8)', $ifile), 'opened file';
local $/;
my $data = <$fh>;

my $html = markdown2html $data;
like $html, qr{<h1>.*</h1>}s, 'h1';
like $html, qr{<h2>.*</h2>}s, 'h2';
like $html, qr{<a.*?>.*</a>}s, 'a';
like $html, qr{<ul>.*</ul>}s, 'ul';
like $html, qr{<p>.*</p>}s, 'p';
like $html, qr{<li>.*</li>}s, 'li';
like $html, qr{<em>.*</em>}s, 'em';
like $html, qr{<code>.*</code>}s, 'code';
like $html, qr{<strong>.*</strong>}s, 'strong';

is markdown2html(''), '', "markdown2html('')";
is markdown2html(undef), undef, 'markdown2html(undef)';

like markdown2html('# привет'), qr{<h1>\s*привет\s*</h1>}, 'utf8 strings';
$data = encode utf8 => '## медвед';
like markdown2html($data), eval { no utf8; qr{<h2>\s*медвед\s*</h2>} },
    'no utf8 strings';
unlike markdown2html($data), qr{<h2>\s*медвед\s*</h2>}, 'no utf8 strings';
