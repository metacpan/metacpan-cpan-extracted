use strict;
use warnings;

use Test::More;
use CSS;

my $css = CSS->new({ parser => 'CSS::Parse::Packed' });
$css->parse_string(<<'CSS');
body { background-color:#FFFFFF; }
body { padding:6px; }
CSS

my $body = $css->get_style_by_selector('body');
ok $body =~ /background-color:/ && $body =~ /padding:/;

done_testing;
