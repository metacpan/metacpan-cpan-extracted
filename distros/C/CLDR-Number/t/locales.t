use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 24;
use Test::Warn;
use CLDR::Number;

my $cldr = CLDR::Number->new;

# conversion
$cldr->locale('zh_Hant_HK');
is $cldr->locale, 'zh-Hant-HK', 'convert undercore to dash';

$cldr->locale('ZH-Hant-HK');
is $cldr->locale, 'zh-Hant-HK', 'convert language to lowercase';

$cldr->locale('zh-hANT-hk');
is $cldr->locale, 'zh-Hant-HK', 'convert script to titlecase';

$cldr->locale('zh-Hant-hk');
is $cldr->locale, 'zh-Hant-HK', 'convert region to uppercase';

$cldr->locale('AST');
is $cldr->locale, 'ast', 'convert 3-letter language to lowercase';

$cldr->locale('en-');
is $cldr->locale, 'en', 'allow trailing dash and remove';

$cldr->locale('fr_');
is $cldr->locale, 'fr', 'allow trailing underscore and remove';

# BCP 47 conversion
$cldr->locale('und');
is $cldr->locale, 'root', 'und → root';

# Unicode locale extensions
TODO: {
    local $TODO = 'Unicode locale extensions not currently retained';
    $cldr->locale('ja-u-nu-fullwide-cu-jpy');
    is $cldr->locale, 'ja-u-cu-jpy-nu-fullwide', 'sort keywords';
};

# defaults
$cldr = CLDR::Number->new;
is $cldr->locale, 'root', 'locale is root when undefined with no default';
ok !$cldr->default_locale, 'no default for the default locale';

$cldr->locale('xx');
is $cldr->locale, 'root', 'locale is root when invalid with no default';

warning_is {
    $cldr = CLDR::Number->new(default_locale => 'xx');
    ok !$cldr->default_locale, 'default locale does not fallback like locale';
} q{default_locale 'xx' is unknown};

$cldr = CLDR::Number->new(default_locale => 'en-GB');
is $cldr->default_locale, 'en-GB', 'default locale is set';
is $cldr->locale, 'en-GB', 'locale is default when undefined with default';

$cldr->locale('xx');
is $cldr->locale, 'en-GB', 'locale is default when invalid with default';

# fallbacks
$cldr = CLDR::Number->new;
$cldr->locale('en-XX');
is $cldr->locale, 'en', 'locale is language when invalid country';

$cldr->locale('eo-IR');
is $cldr->locale, 'eo', 'locale is language when unavailable country';

$cldr->locale('en-Xxxx');
is $cldr->locale, 'en', 'locale is language when invalid script';

$cldr->locale('zh-Latn');
is $cldr->locale, 'zh', 'locale is language when unavailable script';

$cldr->locale('zh-Hant-GB');
is $cldr->locale, 'zh-Hant', 'locale is language-script when unavailable country';

$cldr->locale('en-Hant-GB');
is $cldr->locale, 'en-GB', 'locale is language-country when unavailable script';

$cldr->locale('es-419');
is $cldr->locale, 'es-419', 'numeric regions are supported';
