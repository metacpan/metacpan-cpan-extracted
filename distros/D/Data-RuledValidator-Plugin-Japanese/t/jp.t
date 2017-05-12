use Test::More 'no_plan';

BEGIN {
  use lib qw(t/lib/);
  use_ok('Data::RuledValidator');
  use_ok('Data::RuledValidator::Plugin::Japanese');
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
   'HIRAGANA                  is hiragana',
   'KATAKANA                  is katakana',
   'HIRAGANA_2                is hiragana',
   'JP_ZIP                    is jp_zip',
   'JP_PHONE_NUMBER           is jp_phone_number',
   'JP_MOBILE_EMAIL           is jp_mobile_email',
   'JP_MOBILE_EMAIL_WILLCOM   is jp_mobile_email',
   'JP_MOBILE_EMAIL_DOCOMO    is jp_imode_email',
   'JP_MOBILE_EMAIL_AU        is jp_ezweb_email',
   'JP_MOBILE_EMAIL_SOFTBANK  is jp_softbank_email',
   'JP_MOBILE_EMAIL_VODAFONE  is jp_vodafone_email',
   'JP_MOBILE_EMAIL_ANY       is jp_vodafone_email, jp_ezweb_email, jp_imode_email',
   'JP_LENGTH                 length_jp 6, 6',
   'JP_LENGTH_WITH_ASCII      length_jp 24, 24',
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
          HIRAGANA_is
          JP_LENGTH_WITH_ASCII_length_jp
          JP_LENGTH_length_jp
          JP_MOBILE_EMAIL_ANY_is
          JP_MOBILE_EMAIL_AU_is
          JP_MOBILE_EMAIL_DOCOMO_is
          JP_MOBILE_EMAIL_SOFTBANK_is
          JP_MOBILE_EMAIL_VODAFONE_is
          JP_MOBILE_EMAIL_is
          JP_PHONE_NUMBER_is
          JP_ZIP_is
          KATAKANA_is
          /
          ], 'failure keys');

# use Data::Dumper;
# print Dumper($failure);
