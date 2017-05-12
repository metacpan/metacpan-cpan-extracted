# $Id: valid_cvr.t,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use warnings;
use Test::More tests => 10;

use Data::FormValidator;

use_ok('Data::FormValidator::Constraints::Business::DK::CVR', qw(valid_cvr));

my $dfv_profile = {
    required => [qw(cvr)],
    constraint_methods => {
        cvr => valid_cvr(),
    }
};

my $input_hash;
my $result;

$input_hash = {
    cvr  => 99999999,
};

$result = Data::FormValidator->check($input_hash, $dfv_profile);

ok(! $result->success);

ok($result->has_invalid);
ok(! $result->has_unknown);
ok(! $result->has_missing);

#use Data::Dumper;
#print STDERR Dumper $result;

$input_hash = {
    cvr => 27355021,
};

ok($result = Data::FormValidator->check($input_hash, $dfv_profile));

ok(! $result->has_invalid);
ok(! $result->has_unknown);
ok(! $result->has_missing);

$dfv_profile = {
    required => [qw(cvr)],
    constraint_methods => {
        cvr => valid_cvr(),
    },
    untaint_all_constraints => 1,
};

ok($result = Data::FormValidator->check($input_hash, $dfv_profile));
