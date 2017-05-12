use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Business::OnlinePayment;
  
#########################################################################################################
# setup
#########################################################################################################
my $tx = new Business::OnlinePayment('Ogone');
   $tx->test_transaction(1);

sub new_test_tx {
    my $tx = new Business::OnlinePayment('Ogone');
    $tx->test_transaction(1);
    return $tx;
}

#########################################################################################################
# test setup
#########################################################################################################
isa_ok($tx,'Business::OnlinePayment');

#########################################################################################################
# test missing parameters
#########################################################################################################

my $ogone_required_parameters = [qw/PSPID login password orderid/];

# case1 empty #################################################################
$tx->content();
eval { $tx->submit() };
    like($@,qr/no action parameter defined in content/, "don't allow submitting without action");

# case2 with non existant action #####################################################
$tx = new_test_tx();

    $tx->content(action => 'non existant');

    eval { $tx->submit() }; my $warn_output2 = $@;

    ok($warn_output2 =~ m/unable to determine HTTP POST \@args/, 'croak if wrong action is supplied')
        or diag $warn_output2;
    

# case3 with query action #####################################################
$tx = new_test_tx();

    $tx->content(action => 'query');

    eval { $tx->submit() }; my $warn_output3 = $@;
    
    # expecting: missing required field(s): login, password, orderid at t/....
    my ($list) = ($warn_output3 =~ m/missing required args:\s*(.*?)\s*at/gsm);
    my @missing = split /\s*,\s*/, $list;
    cmp_deeply(\@missing,bag(qw/login password PSPID invoice_number/),"check if all required arguments are indeed missing");

done_testing();

