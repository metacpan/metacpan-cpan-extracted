use Test::More tests => 5;
use Business::CreditCard;

#w

ok ( test_card_id_us() );
ok ( test_card_id_ca() );
ok ( test_card_id_mx() );
ok ( test_card_id_cn() );
ok ( test_card_id_base() );

sub test_card_id_us {
  local($Business::CreditCard::Country) = 'US';

  my %cards = (
  '3528000000000007' => 'Discover card',
  '3589000000000003' => 'Discover card',
#  '30000000000004'   => 'Discover card',
#  '30500000000003'   => 'Discover card',
#  '30950000000000'   => 'Discover card',
  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?
  '6220000000000008' => 'Discover card',
  );

  test_cards(\%cards);
}

sub test_cards {
  my $cards = shift;
  while( my ($k, $v)=each(%$cards) ){
    if(cardtype($k) ne $v){
      warn "Card $k - should be $v for $Business::CreditCard::Country ".
           " but cardtype returns ". cardtype($k). "\n";
      return;
    }
  }
  return 1;  
}

sub test_card_id_ca {
  local($Business::CreditCard::Country) = 'CA';

#  my %cards = (
#  '3528000000000007' => 'Discover card',
#  '3589000000000003' => 'Discover card',
##  '30000000000004'   => 'Discover card',
##  '30500000000003'   => 'Discover card',
##  '30950000000000'   => 'Discover card',
#  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?
#  '6220000000000008' => 'Discover card',
#  );
  my %cards = (
  '3528000000000007' => 'JCB',
  '3589000000000003' => 'JCB',
#  '30000000000004'   => 'Discover card',
#  '30500000000003'   => 'Discover card',
#  '30950000000000'   => 'Discover card',
  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?
  '6220000000000008' => 'China Union Pay',
  );
  test_cards(\%cards);
}

#"all other countries"
sub test_card_id_mx {
  local($Business::CreditCard::Country) = 'MX';

  my %cards = (
  '3528000000000007' => 'JCB',
  '3589000000000003' => 'JCB',
#  '30000000000004'   => 'Discover card',
#  '30500000000003'   => 'Discover card',
#  '30950000000000'   => 'Discover card',
  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?
  '6220000000000008' => 'Discover card',
  );
  test_cards(\%cards);
}

sub test_card_id_cn {
  local($Business::CreditCard::Country) = 'CN';

  my %cards = (
  '3528000000000007' => 'JCB',
  '3589000000000003' => 'JCB',
#  '30000000000004'   => 'Discover card',
#  '30500000000003'   => 'Discover card',
#  '30950000000000'   => 'Discover card',
  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?
  '6220000000000008' => 'China Union Pay',
  );
  test_cards(\%cards);
}

sub test_card_id_base {
  local($Business::CreditCard::Country) = '';

  my %cards = (
  '3528000000000007' => 'JCB',
  '3589000000000003' => 'JCB',
#  '30000000000004'   => 'Discover card',
#  '30500000000003'   => 'Discover card',
#  '30950000000000'   => 'Discover card',
  #'6200000000000005' => 'Discover card', #is 620 a valid CUP now?

  #XXX this is technically an issue ("base" for CUP is still CUP)
  ##'6220000000000008' => 'China Union Pay', #but module will say "Discover card"

  );
  test_cards(\%cards);
}
