use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use AmberDB::Locale;

subtest 'Turkish to_ascii & Slug' => sub {
    my $tr = AmberDB::Locale->new('tr');
    is( $tr->to_ascii('Türkçe karakterler: ç, ğ, ı, ö, ş, ü'), 'Turkce karakterler c, g, i, o, s, u', 'to_ascii normal' );
    is( $tr->to_ascii('IĞDIR', 1), 'igdir', 'to_ascii slug: IĞDIR -> igdir' );
    is( $tr->to_ascii('Çok Özel Ürün & Fiyat!', 1), 'cok-ozel-urun-fiyat', 'to_ascii slug formatting' );
    is( $tr->to_ascii('catalog_product dosyası içeriği', 1), 'catalog_product-dosyasi-icerigi', 'preserves existing underscore while converting spaces to hyphens' );
};

subtest 'German & Spanish to_ascii' => sub {
    my $de = AmberDB::Locale->new('de');
    is( $de->to_ascii('Größenmaß & Bären'), 'Groessenmass & Baeren', 'de to_ascii DIN 5007-2' );
    is( $de->to_ascii('KÖLN', 1), 'koeln', 'de to_ascii slug' );

    my $es = AmberDB::Locale->new('es');
    is( $es->to_ascii('El niño y la niña'), 'El nino y la nina', 'es to_ascii ñ -> n' );
};

done_testing();
