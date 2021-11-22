use warnings;
use strict;
use Test::More;
use App::SpamcupNG::HTMLParse qw(find_spam_header);
use File::Spec;

my $raw = <<'DATA';

From: Alon Elkin &lt;alon.elkien@gmail.com&gt; (<strong>PHD. Hebrew to English and German Translator</strong>)<br>
&nbsp;------=_NextPart_001_1B4D_3C042781.4D516F77<br>&nbsp;Content-Type: multipart/alternative;<br>

DATA

my $parsed   = find_spam_header($raw);
my $expected = [
    'From: Alon Elkin <alon.elkien@gmail.com> (',
    'PHD. Hebrew to English and German Translator',
    ')',
    '------=_NextPart_001_1B4D_3C042781.4D516F77',
    'Content-Type: multipart/alternative;'
];

is( ref($parsed), 'ARRAY',
    'result from find_spam_header is an array reference' );

is_deeply( $parsed, $expected, 'result has the expected structure' )
    or diag( explain($parsed) );

done_testing;
