#!perl -T

use Test::More tests => 12;

BEGIN {
    use_ok( 'CSS' );
	use_ok( 'CSS::Adaptor::Whitelist' );
}

my $css = CSS->new({ adaptor => 'CSS::Adaptor::Whitelist' });
is((ref $css), 'CSS', 'Created a CSS object');

my ($filtered, $parsed);

# safe CSS
$parsed = $css->parse_string( <<EOCSS );
body {
    background: #EEDDFF url(http://example.com/img.jpg) repeat scroll left -2px;
    padding: 5px 3px 0;
}
.highlighted {
    background-color: yellow;
    font-weight: bold;
}
EOCSS
ok(defined($parsed), 'Parsed safe CSS');
$filtered = $css->output;
is($filtered, <<EOCSS, 'Left safe CSS alone');
body {
    background: #EEDDFF url(http://example.com/img.jpg) repeat scroll left -2px;
    padding: 5px 3px 0;
}
.highlighted {
    background-color: yellow;
    font-weight: bold;
}
EOCSS
$css->purge;

# one unrecognized property
$parsed = $css->parse_string( <<EOCSS );
.foo {
    margin-left: 2px;
    content-after: 'GENERATED CONTENT';
    margin-right: 0.5pt;
}
#main.blurry {
    text-shadow: 1px -2px 2px gray;
}
EOCSS
ok(defined($parsed), 'Parsed CSS with unrecognized property');
$filtered = $css->output;
is($filtered, <<EOCSS, 'Filtered out unrecognized property');
.foo {
    margin-left: 2px;
    margin-right: 0.5pt;
}
#main.blurry {
    text-shadow: 1px -2px 2px gray;
}
EOCSS
$css->purge;

is ($CSS::Adaptor::Whitelist::message_log[0]{message}, 'filtered out property: content-after;', 'Logged about filtered property');

# one disallowed value
$parsed = $css->parse_string( <<EOCSS );
a.icon.button.cancel {
    padding: 10px 4px;
    border-radius: 5px;
    color: VeryBlackOrange;
}
EOCSS
ok(defined($parsed), 'Parsed CSS with disallowed value');
$filtered = $css->output;
is($filtered, <<EOCSS, 'Filtered out disallowed value');
a.icon.button.cancel {
    padding: 10px 4px;
    border-radius: 5px;
}
EOCSS
$css->purge;

is ($CSS::Adaptor::Whitelist::message_log[-1]{message}, 'filtered out value: color: VeryBlackOrange;', 'Logged about filtered value');

# one disallowed value
eval { $parsed = $css->parse_string( <<EOCSS ) };
div#top-bar h1 span.imgcover {
    display { block }
    background-image { url(http://example.com/image.png) }
}
EOCSS
ok((not $parsed), 'Failed to parse syntactically incorrect CSS');
