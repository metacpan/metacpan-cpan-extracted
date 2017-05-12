use Test::More;
use Data::FormValidator;
use DateTime;
use lib 't/lib';
use DFVCDT::Test::FlexYear;
use Data::FormValidator::Constraints::DateTime qw(:all);

use Carp qw(confess);
$SIG{__DIE__} = \*Carp::confess;

my $DFV_4 = $Data::FormValidator::VERSION =~ /^4\./ ? 1 : 0;
# only run these tests if we have D::FV 4.x
if( $DFV_4 ) {
    plan(tests => 6);
} else {
    plan(skip_all => 'D::FV 4.x not installed');
}

my $profile = {
    required                => [qw(good bad)],
    constraint_methods      => {
        good => to_datetime(DFVCDT::Test::FlexYear->new()),
        bad  => to_datetime(DFVCDT::Test::FlexYear->new()),
    },
    untaint_all_constraints => 1,
};


# with 'Y' format
my $data = {
    good => '11/07/2005',
    bad  => '2/31/1',
};

my $results = Data::FormValidator->check($data, $profile);
ok($results->valid('good'));
ok($results->invalid('bad'));
isa_ok($results->valid('good'), 'DateTime');

# with 'y' format
$data->{good} = '11/07/05';
$results = Data::FormValidator->check($data, $profile);
ok($results->valid('good'));
ok($results->invalid('bad'));
isa_ok($results->valid('good'), 'DateTime');

