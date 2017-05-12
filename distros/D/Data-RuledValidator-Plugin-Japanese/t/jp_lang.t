use Test::More 'no_plan';

BEGIN {
  use lib qw(t/lib/);
  use Data::RuledValidator import_erro => 2;
  use_ok('Data::RuledValidator::Language::Japanese');
}

use strict;

my $q = bless
  {
   HIRAGANA                  => ['あいうえおかきくけこ'],
   KATAKANA                  => ['アイウエオカキクケコ'],
   HIRAGANA_2                => ['あいうえおかきくけこ', 'さしすせそたちつてと'],
   JP_ZIP                    => ['111-2222'],
   JP_PHONE_NUMBER           => ['001 12345678'],
   JP_MOBILE_EMAIL           => ['example@docomo.ne.jp'],
   JP_MOBILE_EMAIL_DOCOMO    => ['example@docomo.ne.jp'],
   JP_MOBILE_EMAIL_AU        => ['example@ezweb.ne.jp'],
   JP_MOBILE_EMAIL_SOFTBANK  => ['example@softbank.ne.jp'],
   JP_MOBILE_EMAIL_VODAFONE  => ['example@t.vodafone.ne.jp'],
   JP_MOBILE_EMAIL_WILLCOM   => ['example@di.pdx.ne.jp'],
   JP_MOBILE_EMAIL_ANY       => ['example@ezweb.ne.jp'],
   JP_LENGTH                 => ['日本語の長さ'],
   JP_LENGTH_WITH_ASCII      => ['日本語の長さ + length of ascii'],
   SUJI                      => ['1234'],
   EIGO                      => ['abcd'],
   EISUJI                    => ['abcd1234abc'],
  }, 'main';

sub p{
  my($self, $k, @v) = @_;
  if(@_ >= 3){
    $self->{$k} = \@v;
  }
  if(@_ == 1){
    return keys %$self;
  }else{
    wantarray ? @{$self->{$k} || []} : @{$self->{$k}}[0];
  }
}

my $v = Data::RuledValidator->new(obj => $q, method => 'p');

my @sentence =
  (
   'HIRAGANA は ひらがな',
   'KATAKANA は カタカナ',
   'HIRAGANA_2 は ひらがな',
   'JP_ZIP は 郵便番号',
   'JP_PHONE_NUMBER は 電話番号',
   'JP_MOBILE_EMAIL は 携帯メール',
   'JP_MOBILE_EMAIL_WILLCOM は 携帯メール',
   'JP_MOBILE_EMAIL_DOCOMO は DoCoMoメール',
   'JP_MOBILE_EMAIL_AU は AUメール',
   'JP_MOBILE_EMAIL_SOFTBANK は Softbankメール',
   'JP_MOBILE_EMAIL_VODAFONE は Vodafoneメール',
   'JP_MOBILE_EMAIL_ANY は Vodafoneメール, AUメール, DoCoMoメール',
   'JP_LENGTH の長さは 6, 6',
   'JP_LENGTH_WITH_ASCII の長さは 24, 24',
   'SUJI は 数字',
   'EISUJI は 英数字',
   'EIGO は 英語',
  );

ok(ref $v, 'Data::RuledValidator');

# correct rule
ok($v->by_sentence(@sentence), 'right values');
ok($v, 'right values');

# use Data::Dumper;
# print Dumper($v->failure);

$v->reset;

# wrong values
%$q =
  (
   HIRAGANA                  => ['アイウエオカキクケコ'],
   HIRAGANA_2                => ['あいうえおかきくけこ', 'さしすせそたちつてと'],
   KATAKANA                  => ['あいうえおかきくけこ'],
   JP_ZIP                    => ['1111-222'],
   JP_PHONE_NUMBER           => ['00201 12345678'],
   JP_MOBILE_EMAIL           => ['example@example.com'],
   JP_MOBILE_EMAIL_DOCOMO    => ['example@ezweb.ne.jp'],
   JP_MOBILE_EMAIL_AU        => ['example@softbank.ne.jp'],
   JP_MOBILE_EMAIL_SOFTBANK  => ['example@di.pdx.ne.jp'],
   JP_MOBILE_EMAIL_WILLCOM   => ['example@t.vodafone.ne.jp'],
   JP_MOBILE_EMAIL_VODAFONE  => ['example@ezweb.ne.jp'],
   JP_MOBILE_EMAIL_ANY       => ['example@di.pdx.ne.jp'],
   JP_LENGTH                 => ['日本語の長さ + length of ascii + ほげ'],
   JP_LENGTH_WITH_ASCII      => ['日本語の長さ + ほげ'],
  );

ok(! $v->by_sentence(@sentence), 'wrong values');
ok(! $v, 'wrong values');

my $failure = $v->failure;

is_deeply(
          [sort {$a cmp $b} keys %$failure],
          [sort {$a cmp $b} qw/
          HIRAGANA_は
          JP_LENGTH_WITH_ASCII_の長さは
          JP_LENGTH_の長さは
          JP_MOBILE_EMAIL_ANY_は
          JP_MOBILE_EMAIL_AU_は
          JP_MOBILE_EMAIL_DOCOMO_は
          JP_MOBILE_EMAIL_SOFTBANK_は
          JP_MOBILE_EMAIL_VODAFONE_は
          JP_MOBILE_EMAIL_は
          JP_PHONE_NUMBER_は
          JP_ZIP_は
          KATAKANA_は
          /
          ], 'failure keys');

# use Data::Dumper;
# print Dumper($failure);
