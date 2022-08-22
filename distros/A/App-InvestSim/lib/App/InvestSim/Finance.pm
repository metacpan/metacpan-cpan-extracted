# Financial computations for the simulation, based on all the values set in the
# UI. The fiscal rules implemented are believed to be correct as of 2020-01,
# although not every details of the rules is implemented (particularly, tax
# deduction for losses is not yet there).

package App::InvestSim::Finance;

use 5.022;
use strict;
use warnings;

use App::InvestSim::Config ':modes';
use App::InvestSim::LiteGUI ':all';
use App::InvestSim::Values ':all';
use List::Util qw(min);

sub pinel_rent_cap {
  return '+inf' unless $values{pinel_duration};
  my $rent_cap_per_sqm;
  if ($values{pinel_zone} == 0) {
    $rent_cap_per_sqm = 17.17;
  } elsif ($values{pinel_zone} == 1) {
    $rent_cap_per_sqm = 12.75;
  } elsif ($values{pinel_zone} == 2) {
    $rent_cap_per_sqm = 10.28;
  } elsif ($values{pinel_zone} == 3) {
    $rent_cap_per_sqm = 8.93;
  } else {
    message_and_die(
       "Erreur interne: valeur de zone Pinel invalide", $values{pinel_zone});
  }
  return $rent_cap_per_sqm * (0.7 + 19 / $values{surface}) * $values{surface};
}

sub pinel_investment_value {
  if ($values{pinel_duration}) {
    return min(300000, $values{invested}, $values{surface} * 5500);
  } else {
    return $values{invested};
  }
}

sub total_rent {
  my $net_rent = $values{base_rent} * 12 * (1 - $values{rent_charges} / 100);
  my $rent_duration = $values{duration} - $values{rent_delay};
  if ($values{rent_increase} == 0) {
    return $net_rent * $rent_duration;
  }
  $net_rent *= (1 + $values{rent_increase} / 100) ** $values{rent_delay};
  return $net_rent * ((1 + $values{rent_increase} / 100) ** $rent_duration - 1) / ($values{rent_increase} / 100);
}

sub notary_fees {
  return $values{invested} * $values{notary_fees} / 100;
}

sub total_invested {
  return $values{invested} + notary_fees();
}

# Takes a yearly loan interest rate as a percentage value (e.g. 2.0 for 2%) and
# returns the monthly interest rate.
sub monthly_rate {
  my ($yearly_rate) = @_;
  # Or should it be: (1 + yearly_rate) ** (1/12) - 1 ?
  # That calculation is more correct but it seems that real loans are using the
  # approximate value.
  my $ir = $yearly_rate / 100 / 12;  
}

# Payment par term for a loan.
# Args:
# - ir => yearly interest rate.
# - np => number of payments.
# - pv => present value.
sub monthly_payment {
  my (%args) = @_;
  # Or should it be (1 + ir / 100) ** (1/12) - 1 which is the correct value (but
  # it seems that real loan uses the approximate one)?
  my $ir = monthly_rate($args{ir});
  my $a = (1 + $ir) ** (0 - $args{np});
  my $denominator = 1 - $a;
  my $numerator   = $args{pv} * $ir;
  my $result = eval { $numerator / $denominator };
  return $@ ? 0 : $result;
}

# In addition to the arguments, all the content of the
# %App::InvestSim::Values::values hash is available to the computation.
sub calculate {
  my ($loan_amount, $loan_duration, $loan_rate) = @_;

  # The idea of the simulation is that you start with a sum of cash equal to the
  # value of the good to buy. You buy that good and also take a loan. So the
  # available cash at the beginning of the simulation is the amoun of the loan.
  my $starting_cash = $loan_amount;
  # 'application_fees' is the "frais de dossier".
  # 'mortgage_fees' is the "Frais d'hypothèque".
  my $loan_fee = $loan_amount > 0 ? $values{application_fees} + $loan_amount * $values{mortgage_fees} / 100 : 0;
  my $initial_cost = $loan_fee + notary_fees();
  # Yearly cost of the loan insurance.
  my $yearly_loan_insurance = $loan_amount * $values{loan_insurance} / 100;
  # The monthly gross rent. The rent is increased each year, even during the
  # initial rent delay period, if any.
  my $current_gross_rent = $values{base_rent};
  # Monthly loan payment during the loan duration.
  my $core_loan_payment = monthly_payment(ir => $loan_rate, np => $loan_duration * 12, pv => $loan_amount);
  # Amount that is still due on the loan (starting with the full loan).
  my $remaining_loan = $loan_amount;
  # The total cost of the loan (will be summed in the computation below).
  my $total_loan_cost = $loan_fee;
  # Duration of the loan, including the startup delay.
  my $total_loan_duration = $loan_duration + $values{loan_delay};
  # Value of the investment that can be used for the "Loi Pinel" tax deduction.
  my $pinel_value = min(300000, $values{invested}, $values{surface} * 5500);
  
  # Cash balance for the duration of the loan and afterward, per year.
  my ($mean_balance_loan_duration, $mean_balance_afterward) = (0, 0);
  
  # Total cash flow
  my ($total_gained, $total_spent) = ($values{invested}, $values{invested} - $loan_amount + $initial_cost);
  
  # The cost of the loan can be deducted, not the notary fees.
  my $postponed_deficit = $loan_fee;
  
  my $cash = $starting_cash - $initial_cost;
  my @starting_table_value = (0, 0, 0, 0, $loan_fee, 0, $postponed_deficit, notary_fees(), -$initial_cost, $cash);
  my @table = (\@starting_table_value);
  # Total will sum all the values from @table, except the $cash column.
  my @total = @starting_table_value[0..$#starting_table_value - 1];
  for my $y (1..$values{duration}) {
    # The net revenue from the rent (can be undef).
    my $gross_rent = $y > $values{rent_delay} ? $current_gross_rent * 12 : 0;
    my $rent_charges = $gross_rent * $values{rent_charges} / 100;
    my $net_rent = $gross_rent - $rent_charges;
    $current_gross_rent *= 1 + $values{rent_increase} / 100;

    # Revenue from other investments.
    my $other_revenue = $cash * $values{other_rate} / 100;
    
    # Loan reimbursements, calculated monthly for the duration of the loan.
    # The loan cost is the interest + the insurance.
    my ($paid_capital, $paid_interest, $loan_insurance) = (0, 0, 0);
    if ($y <= $total_loan_duration) {
      $loan_insurance = $yearly_loan_insurance;
      $total_loan_cost += $yearly_loan_insurance;
      for my $m (0..11) {
        my $monthly_interest = $remaining_loan * monthly_rate($loan_rate);
        my $monthly_capital = $core_loan_payment - $monthly_interest if $y > $values{loan_delay};
        $paid_capital += $monthly_capital // 0;
        $paid_interest += $monthly_interest;
        $remaining_loan -= $monthly_capital // 0;
        $total_loan_cost += $monthly_interest;
      }
    }
    
    my $taxable_income = $net_rent - $paid_interest - $loan_insurance - $postponed_deficit;
    if ($taxable_income < 0) {
      # The rent charges can be deducted directly from the taxes, the rest can
      # be postponed for the following years.
      my $deducted = min(-$taxable_income, $rent_charges);
      $postponed_deficit = -$taxable_income - $deducted;
      $taxable_income = -$deducted;
    } else {
      $postponed_deficit = 0;
    }
    my $taxes = ($taxable_income + $other_revenue) * ($values{tax_rate} + $values{social_tax}) / 100;
    
    my $pinel_year = $y - $values{loan_delay};
    if ($pinel_year > 0 && $pinel_year <= $values{pinel_duration} && $pinel_year <= 9) {
      $taxes -= $pinel_value * 0.02;
    } elsif ($pinel_year > 0 && $pinel_year <= $values{pinel_duration} && $pinel_year <= 12 ) {
      $taxes -= $pinel_value * 0.01;
    }
    
    # We're removing the taxes here rather than adding it to the "spent" total
    # as that taxe money was never ours.
    $total_gained += $gross_rent + $other_revenue - $taxes;
    $total_spent += $rent_charges + $paid_interest + $loan_insurance + $paid_capital;
    my $balance = $net_rent + $other_revenue - $paid_capital - $paid_interest - $loan_insurance - $taxes;
    $cash += $balance;
    
    if ($y <= $total_loan_duration) {
      $mean_balance_loan_duration += $balance;
    } else {
      $mean_balance_afterward += $balance;
    }
  
    my @table_row = ($net_rent // 0, $other_revenue, $paid_capital, $paid_interest, $loan_insurance, $taxable_income, $postponed_deficit, $taxes, $balance, $cash);
    # We don't sum the cash column, this would be meaningless
    for my $i (0..$#table_row - 1) {
      $total[$i] += $table_row[$i];
    }
    push @table, \@table_row;
  }
  if (abs($remaining_loan) > 1) {
    print "Erreur: emprunt restant (${remaining_loan}) > 0\n";
  }
  
  my @output;
  $output[MONTHLY_PAYMENT] = $core_loan_payment  + $yearly_loan_insurance / 12;
  $output[LOAN_COST] = $total_loan_cost;
  # This value is calculated using the first year rent (which is the lowest).
  $output[YEARLY_RENT_AFTER_LOAN] = ($values{base_rent} * (1 - $values{rent_charges} / 100) - $core_loan_payment) * 12 - $yearly_loan_insurance;
  $output[MEAN_BALANCE_LOAN_DURATION] = $mean_balance_loan_duration / 12 / $total_loan_duration if $total_loan_duration;
  $output[MEAN_BALANCE_OVERALL] = ($mean_balance_loan_duration + $mean_balance_afterward) / 12 / $values{duration};
  $output[NET_GAIN] = $total_gained - $total_spent;
  $output[INVESTMENT_RETURN] = ($total_gained - $total_spent) / $total_spent * 100;
  $output[TABLE_DATA] = \@table;
  $output[TABLE_TOTAL] = \@total;
  return @output;
}

1;
