use warnings;
use strict;

if("$]" < 5.007002) {
	require Test::More;
	Test::More::plan(skip_all =>
		"require override can't work acceptably on this perl");
} elsif("$]" >= 5.007002 && "$]" < 5.008009) {
	require Test::More;
	Test::More::plan(skip_all =>
		"require override can't be dodged on this perl");
}

no warnings "once";
*CORE::GLOBAL::require = sub { require $_[0] };

do "./t/upo.t" or die $@ || $!;

1;
