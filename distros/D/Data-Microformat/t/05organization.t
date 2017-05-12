#!perl -w

use strict;
use Data::Microformat::hCard::organization;

use Test::More tests => 9;

my $simple = << 'EOF';
<span class="org">
	<span class="organization-name">Zaphod for President</span>
	<span class="organization-unit">Dirty Tricks</span>
</span>
EOF

ok(my $org = Data::Microformat::hCard::organization->parse($simple));

is($org->organization_name, "Zaphod for President");
is($org->organization_unit, "Dirty Tricks");

my $comparison = << 'EOF';
<div class="org">
	<div class="organization-name">Zaphod for President</div>
	<div class="organization-unit">Dirty Tricks</div>
</div>
EOF

is($org->to_hcard, $comparison);

my $text_comparison = << 'EOF';
org: 
	organization-name: Zaphod for President
	organization-unit: Dirty Tricks
EOF
is($org->to_text, $text_comparison);

my $medium = << 'EOF';
<span class="org">Zaphod for President</span>

EOF

ok($org = Data::Microformat::hCard::organization->parse($medium));

is($org->organization_name, "Zaphod for President");

$comparison = << 'EOF';
<div class="org">
	<div class="organization-name">Zaphod for President</div>
</div>
EOF

is($org->to_hcard, $comparison);

$text_comparison = << 'EOF';
org: 
	organization-name: Zaphod for President
EOF
is($org->to_text, $text_comparison);