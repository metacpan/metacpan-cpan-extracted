#!perl -w

use strict;
use Data::Microformat::hCard::type;

use Test::More tests => 18;

#Basic type taken from the microformats wiki: http://microformats.org/wiki/hcard
my $simple = << 'EOF';
<span class="tel">
	<span class="type">Home</span>
	<span class="value">+1.415.555.1212</span>
</span>
EOF

ok(my $type = Data::Microformat::hCard::type->parse($simple));

is($type->kind, "tel");
is($type->type, "Home");
is($type->value, "+1.415.555.1212");

my $comparison = << 'EOF';
<div class="tel">
	<div class="value">+1.415.555.1212</div>
	<div class="type">Home</div>
</div>
EOF
is ($type->to_hcard, $comparison);

my $text_comparison = << 'EOF';
tel: 
	value: +1.415.555.1212
	type: Home
EOF
is($type->to_text, $text_comparison);

my $medium = << 'EOF';
<span class="email"><span class="type">Work</span> test@example.com</span>
EOF

ok($type = Data::Microformat::hCard::type->parse($medium));

is($type->kind, "email");
is($type->type, "Work");
is($type->value, 'test@example.com');

$comparison = << 'EOF';
<div class="email">
	<div class="value">test@example.com</div>
	<div class="type">Work</div>
</div>
EOF

is($type->to_hcard, $comparison);

$text_comparison = << 'EOF';
email: 
	value: test@example.com
	type: Work
EOF
is($type->to_text, $text_comparison);

my $hard = << 'EOF';
<a class="email" href="mailto:test@example.com">Email</a>
EOF

ok($type = Data::Microformat::hCard::type->parse($hard));

is ($type->value, 'test@example.com');

$comparison = << 'EOF';
<div class="email">
	<div class="value">test@example.com</div>
</div>
EOF

is($type->to_hcard, $comparison);

$text_comparison = << 'EOF';
email: 
	value: test@example.com
EOF
is($type->to_text, $text_comparison);

# Psychotic test brought to you by http://hcard.geekhood.net/encode/
my $psychotic = << 'EOF';
<a 
class='email
href="mailto:me"
' 
href 
= '	
&#x20;&#109;a&#x69;&#x6C;to&#x3a;&#x20;&#x74;&#101;s&#x25;&#x37;&#x34;%&#52;0&#x65;&#x78;&#37;&#x36;&#49;&#109;&#x70;&#x6c;e&#x25;&#x32;&#x65;c%&#x36;&#102;&#x6D;?
'>&#x74;&#x65;&#115;t@&#x65;&#x78;a<!--
mailto:abuse@hotmail.com
</a>
-->&shy;&#x6D;&#112;le&#x2e;com</a>
EOF

ok($type = Data::Microformat::hCard::type->parse($psychotic));

is ($type->value, 'test@example.com');
