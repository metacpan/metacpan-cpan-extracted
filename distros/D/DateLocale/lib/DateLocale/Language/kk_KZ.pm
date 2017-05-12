package DateLocale::Language::kk_KZ;

#use utf8;
use strict;
use Locale::Messages qw(:locale_h :libintl_h);

sub format_OB {
	return dcgettext "perl-DateLocale", "mon".($_[4]+1), LC_TIME();
}

sub format_B {
	return dcgettext "perl-DateLocale", "mon".($_[4]+1)."g", LC_TIME();
}

1;

