package App::InvestSim::Config;

use 5.022;
use strict;
use warnings;

use Exporter 'import';

my @array_export = qw(NUM_LOAN_DURATION NUM_LOAN_AMOUNT);
my @modes_export = qw(MONTHLY_PAYMENT LOAN_COST YEARLY_RENT_AFTER_LOAN MEAN_BALANCE_LOAN_DURATION MEAN_BALANCE_OVERALL NET_GAIN INVESTMENT_RETURN MAX_MODE TABLE_DATA TABLE_TOTAL);

our @EXPORT = ();
our @EXPORT_OK = (@array_export, @modes_export);
our %EXPORT_TAGS = (all => \@EXPORT_OK, array => \@array_export, modes => \@modes_export);

# The dimensions of the main tables displayed in the program. These are not pure
# GUI configuration value because they also impact the simulation values.
#
# When these values are updated, the default values for the arrays in
# $App::InvestSim::Values::values_config should be updated too.
use constant NUM_LOAN_DURATION => 6;
use constant NUM_LOAN_AMOUNT => 7;


# Constants for each computation type that can be displayed.
use constant MONTHLY_PAYMENT =>              0;
use constant LOAN_COST =>                    1;
use constant YEARLY_RENT_AFTER_LOAN =>       2;
use constant MEAN_BALANCE_LOAN_DURATION =>   3;
use constant MEAN_BALANCE_OVERALL =>         4;
use constant NET_GAIN =>                     5;
use constant INVESTMENT_RETURN =>            6;

use constant MAX_MODE => INVESTMENT_RETURN;
use constant TABLE_DATA => MAX_MODE + 1;
use constant TABLE_TOTAL => MAX_MODE + 2;

1;
