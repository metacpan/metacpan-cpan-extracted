package Data::Transpose::Validator::CreditCard;

use strict;
use warnings;
use Business::CreditCard;
use Moo;
extends 'Data::Transpose::Validator::Base';
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator::CreditCard - Validator for CC numbers

=head1 SYNOPSIS

From inside L<Data::Transpose::Validator>

  $dtv->prepare(
                cc_number => {
                              validator => {
                                            class => 'CreditCard',
                                            options => {
                                                        types => [ "visa card",
                                                                  "mastercard",
                                                                  "American Express card",
                                                                  "Discover card" ],
                                                        country => 'DE',
                                                       },
                                           },
                              required => 1,
                             },
                cc_month => {
                             validator => {
                                           class => 'NumericRange',
                                           options => {
                                                       min => 1,
                                                       max => 12,
                                                      },
                                          },
                             required => 1,
                            },
                cc_year => {
                            validator => {
                                          class => 'NumericRange',
                                          options => {
                                                      min => 2013,
                                                      max => 2023,
                                                     },
                                         },
                            required => 1,
                           }
               );
  my $form = {
              cc_number => ' 4111111111111111 ',
              cc_month => '12',
              cc_year => '2014',
             };
  
  my $clean = $dtv->transpose($form);
  
  ok($clean, "validation ok");
  
Or, as stand-alone module:

  my $v = Data::Transpose::Validator::CreditCard->new(country => 'DE',
                                                      types => ["visa card",
                                                                "mastercard"]);
  ok($v->is_valid("4111111111111111"));
  ok(!$v->is_valid("4111111111111112"));


=head1 DESCRIPTION

This module wraps L<Business::CreditCard> to validate a credit card
number.

=head2 new(country => 'de', types => ['VISA card', 'MasterCard', ... ])

Constructor. The options as the following:

=over 4

=item country 

Two letters country code (for card type detection purposes). Defaults
to "US" (as per L<Business::CreditCard> defaults).

=item types

List of accepted CC type. The string is case insensitive, but must
match the following recognized types. It's unclear how much reliable
is this, so use with caution. Recognized types:

  American Express card
  BankCard
  China Union Pay
  Discover card
  Isracard
  JCB
  Laser
  MasterCard
  Solo
  Switch
  VISA card

=back

=cut

sub _recognized_types {
    my @types = (
                 'American Express card',
                 'BankCard',
                 'China Union Pay',
                 'Discover card',
                 'Isracard',
                 'JCB',
                 'Laser',
                 'MasterCard',
                 'Solo',
                 'Switch',
                 'VISA card',
                );
    return @types;
}

has country => (is => 'rw',
                isa => Str,
                default => sub { 'US' },
               );
has types => (is => 'rw',
              isa => sub {
                  my $list = $_[0];
                  die "Not an arrayref" unless is_ArrayRef($list);
                  my %types = map { lc($_) => 1 } __PACKAGE__->_recognized_types;
                  foreach my $type (@$list) {
                      die "$type is not recognized" unless $types{lc($type)}
                  }
              },
              default => sub { [] });



=head2 is_valid

Check with C<ref> if the argument is a valid credit card and return it
on success (without whitespace).

=cut

sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    if (validate($string)) {
        $string =~ s/\s//g;
    }
    else {
        $self->error(["invalid_cc", cardtype($string) . " (invalid)"]);
    }
    if (!$self->error) {
        if (my @types = @{$self->types}) {
            $Business::CreditCard::Country = uc($self->country);
            my $cardtype = cardtype($string);
            unless (grep { lc($_) eq lc($cardtype) } @types) {
                $self->error(["cc_not_accepted",
                              "$cardtype not in " . join(", ", @types)]);
            }
        }
    }
    $self->error ? return 0 : return $string;
}


=head2 test_cc_numbers

For testing (and validation) purposes, this method returns an hashref
with the test credit card numbers for each provider (as listed by
Business::CreditCard::cardtype()).

=cut

sub test_cc_numbers {
    my $self = shift;
    my $nums = {
                "VISA card" => [
                                '4111111111111111',
                                '4222222222222',
                                '4012888888881881',
                               ],

                "MasterCard" => [
                                 '5555555555554444',
                                 '5105105105105100',
                                ],


                "Discover card" => [
                                     '6011111111111117',
                                     '6011000990139424',

                                     # these should be JCB but are reported as JCB
                                     '3530111333300000',
                                     '3566002020360505'
                                   ],

                "American Express card" => [ "378282246310005",
                                             "371449635398431",
                                             "378734493671000",
                                           ],

                "JCB" => [  ],
                "enRoute" => [ ],
                "BankCard" => ['5610591081018250'],
                "Switch" => [ ],
                "Solo" => [ ],
                "China Union Pay" => [ ],
                "Laser" => [ ],
                "Isracard" => [ ],

                "Unknown" => [
                              '5019717010103742',
                              '6331101999990016', # actually it's Switch/Solo
                             ],
               };
    return $nums;
}

# Local Variables:
# tab-width: 4
# End:

1;
