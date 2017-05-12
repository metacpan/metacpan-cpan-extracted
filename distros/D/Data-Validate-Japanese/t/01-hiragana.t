use strict;
use Test::More qw(no_plan);
use Encode;

BEGIN
{
    use_ok("Data::Validate::Japanese");
}

my $dvj = Data::Validate::Japanese->new;
ok($dvj, "object created");
isa_ok($dvj, 'Data::Validate::Japanese', "object isa Data::Validate::Japanese");

my @positives = map { decode_utf8($_) } qw(
    ひらがな
    あいうえお
    ぁぃぅぇぉ
);

my @negatives = map { decode_utf8($_) } qw(
    カタカナ
    漢字唯
    ascii_is_what_I_like_012345
);

foreach my $positive (@positives) {
    ok($dvj->is_hiragana($positive), "Positively hiragana");
}

foreach my $negative (@negatives) {
    ok(! $dvj->is_hiragana($negative), "Positively NOT hiragana");
}