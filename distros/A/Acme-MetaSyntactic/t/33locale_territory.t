use Test::More;
use strict;
use lib 't/lib';
use NoLang;
use Acme::MetaSyntactic;

my %tests = (
    'en'               => ['seventy'],
    'fr_BE.iso-8859-1' => ['septante'],
    'fr_be'            => ['septante'],
    'fr_BE'            => ['septante'],
    'fr_BE_zlonk.utf8' => ['septante'],
    'fr_CH'            => [ 'septante', 'soixante_dix' ],
    'fr_FR.iso-8859-1' => ['soixante_dix'],
    'fr.utf8'          => [ 'septante', 'soixante_dix' ],
    'it_no'            => ['seventy'],
    ''                 => ['seventy'],
);

plan tests => scalar keys %tests;

END {
    for my $t ( sort keys %tests ) {
        $ENV{LANG} = $t;
        my $meta = Acme::MetaSyntactic::test_ams_digits->new();
        is_deeply( [ sort $meta->name(0) ],
            $tests{$t}, "$t => @{[$meta->lang]}" );
    }
}

package Acme::MetaSyntactic::test_ams_digits;
use Acme::MetaSyntactic::Locale;
our @ISA = ('Acme::MetaSyntactic::Locale');
__PACKAGE__->init();
1;

__DATA__
# default
en
# names en
seventy
# names fr fr
soixante_dix
# names fr be
septante
