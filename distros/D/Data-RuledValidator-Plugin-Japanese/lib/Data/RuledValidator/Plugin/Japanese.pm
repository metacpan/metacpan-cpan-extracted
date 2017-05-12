package Data::RuledValidator::Plugin::Japanese;

use warnings;
use strict;
use Number::Phone::JP;

my @match_functions;

BEGIN{
  use Data::FormValidator::Constraints::Japanese ();
  @match_functions = map /^_match_(.+)$/ ? $1 : (), keys %Data::FormValidator::Constraints::Japanese::;
}

Data::RuledValidator->add_condition_operator
  (
   map {
     my $func = \&{$Data::FormValidator::Constraints::Japanese::{"_match_" . $_}};
     $_ =>
       sub{
         my($self, $v) = @_;
         return $func->($v) ? 1 : ()
       };
   } @match_functions
  );

# When Data::FormValidator::Constraints::Japanese supports softbank email,
# this code will not be needed.
if(not defined $Data::FormValidator::Constraints::Japanese::_match_jp_softbank_email){
  Data::RuledValidator->add_condition_operator
      (
       jp_softbank_email =>
       sub {
         my($self, $v) = @_;
         return Mail::Address::MobileJp::is_softbank($v) ? 1 : ();
       },
      );
}

Data::RuledValidator->add_condition_operator
  (
   jp_phone_number =>
   sub {
     my($self, $v) = @_;
     my $tel = Number::Phone::JP->new($v);
     return $tel->is_valid_number ? 1 : ();
   },
  );

Data::RuledValidator->add_operator
  (
   length_jp => 
   sub {
     my($key, $c, $op) = @_;
     my($start, $end) = split(/,/, $c);
     return
       sub {
         my($self, $v) = @_;
         return Data::FormValidator::Constraints::Japanese::_check_jp_length
           ($v->[0], defined $end ? ($start, $end) : $start) + 0;
       };
     }
  );

1;

=head1 NAME

Data::RuledValidator::Plugin::Japanese - Data::RuledValidator plugin for Japanese

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

In rule file;

   HIRAGANA                   is hiragana
   KATAKANA                   is katakana
   HIRAGANA_with_white_space  is hiragana
   KATAKANA_with_white_space  is katakana
   HIRAGANA_with_white_space2 is hiragana
   KATAKANA_with_white_space2 is katakana
   JP_ZIP                     is jp_zip
   JP_MOBILE_EMAIL            is jp_mobile_email
   JP_MOBILE_EMAIL_DOCOMO     is jp_mobile_email
   JP_MOBILE_EMAIL_AU         is jp_mobile_email
   JP_MOBILE_EMAIL_SOFTBANK   is jp_mobile_email
   JP_MOBILE_EMAIL_WILLCOM    is jp_mobile_email
   JP_MOBILE_EMAIL_VODAFONE   is jp_mobile_email
   JP_MOBILE_EMAIL_DOCOMO     is jp_imode_email
   JP_MOBILE_EMAIL_AU         is jp_ezweb_email
   JP_MOBILE_EMAIL_SOFTBANK   is jp_softbank_email
   JP_MOBILE_EMAIL_VODAFONE   is jp_vodafone_email
   JP_PHONE_NUMBER            is jp_phone_number
   JAPANESE_WORDS             length_jp 0, 10

=head1 PROVIDED CONDITIONS

This plugin provides the following Conditions.

=over 4

=item hiragana

 family_name_kana is hiragana

For hiragana.

=item katakana

 family_name_kana is katakana

For katakana

=item jp_phone_number

 zipcode is jp_phone_number

For Japanese phone number.

=item jp_zip

 zipcode is jp_zip

For Japanese zip code.
###-####.

=item jp_mobile_email

 mobile_mail is jp_mobile

For Japanese mobile mail address.
It allow many kinds of mobile email address.

If you want to check specified kinds of mail address,
use the following;

=back

=over 8

=item * jp_imode_email

=item * jp_ezweb_email

=item * jp_vodafone_email

=item * jp_softbank_email

=back

=head1 PROVIDED OPERATORS

This plugin provides the following Operator.

=over 4

=item length_jp #, #

 jp_words length_jp 0, 10

If the length of jp_words is from 0 to 10, it is valid.
The first number is min length, and the second number is max length.

You can write only one value.

 jp_words length_jp 5

This means length of jp_words lesser than 6.

=back

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-ruledvalidator-plugin-japanese at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RuledValidator-Plugin-Japanese>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::RuledValidator::Plugin::Japanese

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-RuledValidator-Plugin-Japanese>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-RuledValidator-Plugin-Japanese>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-RuledValidator-Plugin-Japanese>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-RuledValidator-Plugin-Japanese>

=back

=head1 SEE ALSO

=over 4

=item * Data::FormValidator::Constraints::Japanese

This plugin just uses functions of Data::FormValidator::Constraints::Japanese.

=item * Mail::Mobile::AddressJp

This module is used in Data::FormValidator::Constraints::Japanese.

=item * Number::Phone::JP

This module is used in Data::FormValidator::Constraints::Japanese.

=back

Thanks!

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::RuledValidator::Plugin::Japanese
