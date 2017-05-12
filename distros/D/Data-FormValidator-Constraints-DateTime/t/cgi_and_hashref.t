use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints::DateTime qw(ymd_to_datetime);
use CGI;

my $DFV_4 = $Data::FormValidator::VERSION =~ /^4\./ ? 1 : 0;

plan( tests => 4);

my %profile_4x = (
    untaint_all_constraints => 1,
    required => [qw(
        start_year
        start_month
        start_day
        end_year
        end_month
        end_day
    )],
    constraint_methods => {
        start_year => ymd_to_datetime(qw(start_year start_month start_day)),
        end_year   => ymd_to_datetime(qw(end_year end_month end_day)),
    },
);

my %profile_3x = (
    untaint_all_constraints => 1,
    validator_packages      => 'Data::FormValidator::Constraints::DateTime',
    required => [qw(
        start_year
        start_month
        start_day
        end_year
        end_month
        end_day
    )],
    constraints => {
        start_year => {
            constraint  => 'ymd_to_datetime',
            params      => [qw(start_year start_month start_day)],
        },
        end_year   => {
            constraint  => 'ymd_to_datetime',
            params      => [qw(end_year end_month end_day)],
        },
    },
);


my %data = (
    start_year  => '2005',
    start_month => '12',
    start_day   => '31',
    end_year    => '2112',
    end_month   => '1',
    end_day     => '1',
);
my $query = CGI->new(\%data);

# 3.x interface
# input as hashref
ok(Data::FormValidator->check(\%data, \%profile_3x), "3.x from hashref");
# input as cgi query object
ok(Data::FormValidator->check($query, \%profile_3x), "3.x from CGI query");

# skip these these unless we have 4.x installed
SKIP: {
    skip('D::FV 4.x not installed', 2) unless( $DFV_4 );
    # input as hashref
    ok(Data::FormValidator->check(\%data, \%profile_4x), "4.x from hashref");
    # input as cgi query object
    ok(Data::FormValidator->check($query, \%profile_4x), "4.x from CGI query");
};
        
