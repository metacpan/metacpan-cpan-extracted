package Data::RuledValidator::Language::Japanese;

use strict;
use Data::RuledValidator;

my %operator =
  (
   'は'       => 'is'       ,
   'の長さは' => 'length_jp',
  );

my %condition =
  (
   'ひらがな'       => 'hiragana'          ,
   '平仮名'         => 'hiragana'          ,
   'カタカナ'       => 'katakana'          ,
   'かたかな'       => 'katakana'          ,
   '片仮名'         => 'katakana'          ,
   '郵便番号'       => 'jp_zip'            ,
   '電話番号'       => 'jp_phone_number'   ,
   '携帯メール'     => 'jp_mobile_email'   ,
   'DoCoMoメール'   => 'jp_imode_email'    ,
   'AUメール'       => 'jp_ezweb_email'    ,
   'Softbankメール' => 'jp_softbank_email' ,
   'Vodafoneメール' => 'jp_vodafone_email' ,
   '数字'           => 'number'            ,
   '英語'           => 'alpha'             ,
   '英数字'         => 'alphanum'          ,
   '単語'           => 'word'              ,
   '単文'           => 'words'             ,
   '必須'           => 'not_null'          ,
  );

for my $jp_name (keys %operator){
  Data::RuledValidator->__operator
      (
       $jp_name => Data::RuledValidator->__operator($operator{$jp_name})
      );
}

for my $jp_name (keys %condition){
  Data::RuledValidator->__condition
      (
       $jp_name => Data::RuledValidator->__condition($condition{$jp_name})
      );
}

1;

=encoding utf-8

=head1 NAME

Data::RuledValidator::Language::Japanese - Data::RuledValidator usign rule written in Japanese

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

In rule file;

   HIRAGANA                   は ひらがな
   KATAKANA                   は カタカナ
   # thease(_with_with_space) faile
   HIRAGANA_with_white_space  は ひらがな
   KATAKANA_with_white_space  は カタカナ
   HIRAGANA_with_white_space2 は ひらがな
   KATAKANA_with_white_space2 は カタカナ

   JP_ZIP                     は 郵便番号
   JP_MOBILE_EMAIL            は 携帯メール
   JP_MOBILE_EMAIL_DOCOMO     は 携帯メール
   JP_MOBILE_EMAIL_AU         は 携帯メール
   JP_MOBILE_EMAIL_SOFTBANK   は 携帯メール
   JP_MOBILE_EMAIL_WILLCOM    は 携帯メール
   JP_MOBILE_EMAIL_VODAFONE   は 携帯メール
   JP_MOBILE_EMAIL_DOCOMO     は DoCoMoメール
   JP_MOBILE_EMAIL_AU         は AUメール
   JP_MOBILE_EMAIL_SOFTBANK   は Softbankメール
   JP_MOBILE_EMAIL_VODAFONE   は Vodafoneメール
   JP_PHONE_NUMBER            は 電話番号
   JAPANESE_WORDS             の長さは 0, 10

=head1 PROVIDED CONDITIONS

This plugin provides the following Conditions.

=over 4

=item 数字

 number は 数字

For number

=item 英語

 alphabet は 英語

For alphabet

=item 英数字

 alphanum は 英数字

For alphanum

=item 単語

 word は 単語

For word

=item 単文

 words は 単文

For words

=item ひらがな,平仮名

 family_name_kana は ひらがな

For hiragana.

=item かたかな,片仮名,カタカナ

 family_name_kana は かたかな

For katakana

=item 電話番号

 zipcode は 電話番号

For Japanese phone number.

=item 郵便番号

 zipcode is 郵便場号

For Japanese zip code.
###-####.

=item 携帯メール

 mobile_mail is 携帯メール

For Japanese mobile mail address.
It allow many kinds of mobile email address.

If you want to check specified kinds of mail address,
use the following;

=back

=over 8

=item * DoCoMoメール

=item * AUメール

=item * Vodafoneメール

=item * Softbankメール

=back

=head1 PROVIDED OPERATORS

This plugin provides the following Operator.

=over 4

=item は

 hiragana は 平仮名

This is same as normal operator C<is>.

=item の長さは #, #

 jp_words の長さは 0, 10

If the length of jp_words is from 0 to 10, it is valid.
The first number is min length, and the second number is max length.

You can write only one value.

 jp_words の長さは 5

This means length of jp_words lesser than 6.

=back

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-ruledvalidator-plugin-japanese at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RuledValidator-Language-Japanese>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::RuledValidator::Plugin::Japanese

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-RuledValidator-Language-Japanese>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-RuledValidator-Language-Japanese>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-RuledValidator-Language-Japanese>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-RuledValidator-Language-Japanese>

=back

=head1 SEE ALSO

=over 4

=item * L<Data/RuledVadalitor>

=item * L<Data/RuledVadliator/Plugin/Japanese>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::RuledValidator::Language::Japanese


