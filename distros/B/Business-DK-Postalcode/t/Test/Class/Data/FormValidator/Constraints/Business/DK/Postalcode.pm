package Test::Class::Data::FormValidator::Constraints::Business::DK::Postalcode;

# $Id$

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Taint;
use Data::FormValidator;

use lib qw(lib);

sub startup : Test(startup => 2) {
    my $self = shift;

    taint_checking_ok('Is taint checking on?')
        or $self->BAILOUT('We are not running under taint flag');

    use_ok( 'Data::FormValidator::Constraints::Business::DK::Postalcode',
    qw(postalcode valid_postalcode) );
};

sub setup : Test(setup) {
    my $self = shift;
    
    $self->{valid_data} = '2300';
    $self->{invalid_data} = '0000';
    
    return $self;
};

sub invalid_data : Test(5) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        }
    };

    my $input_hash = {
        postalcode  => $self->{invalid_data},
    };

    ok(! (my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    )), 'the result of check is fail');
    
    ok( !$result->success, 'The data was not conforming to the profile' );    
    
    ok( $result->has_invalid,  'Checking that we have invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
};

sub invalid_data2 : Test(5) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraints => {
            postalcode => valid_postalcode(),
        }
    };

    my $input_hash = {
        postalcode  => $self->{invalid_data},
    };

    ok(! (my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    )), 'the result of check is fail');
    
    ok( !$result->success, 'The data was not conforming to the profile' );    
    
    ok( $result->has_invalid,  'Checking that we have invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
};

sub valid_postalcode_valid_data : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        }
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
    
    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );    
    
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );

    tainted_ok( $result->valid('postalcode'), 'Checking that our data are tainted' );
};

sub valid_postalcode_valid_data2 : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraints => {
            postalcode => valid_postalcode(),
        }
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );

    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );    
    
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );

    tainted_ok( $result->valid('postalcode'), 'Checking that our data are tainted' );
};


sub postalcode_valid_data : Test(5) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => postalcode(),
        }
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };

    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );    
    
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
};

sub valid_postalcode_tainted_data : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        },
        untaint_constraint_fields => [qw(postalcode)],
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
    
    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );      
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
    
    untainted_ok( $result->valid('postalcode'), 'Checking that our data are untainted' );
};

sub postalcode_tainted_data : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => postalcode(),
        },
        untaint_constraint_fields => [qw(postalcode)],
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
    
    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );      
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
    
    untainted_ok( $result->valid('postalcode'), 'Checking that our data are untainted' );
};

sub valid_postalcode_tainted_data_untaint_all : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        },
        untaint_all_constraints => 1,
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
    
    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );  
    
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
    
    untainted_ok( $result->valid('postalcode'), 'Checking that our data are untainted' );
};

sub postalcode_tainted_data_untaint_all : Test(8) {
    my $self = shift;
    
    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => postalcode(),
        },
        untaint_all_constraints => 1,
    };

    my $input_hash = {
        postalcode  => $self->{valid_data},
    };
    taint_deeply($input_hash);
    tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
    
    ok(my $result = Data::FormValidator->check(
        $input_hash, $dfv_profile
    ), 'Calling check');
    
    ok( $result->success, 'The data was conforming with the profile' );  
    
    ok( !$result->has_invalid, 'Checking that we have no invalids' );
    ok( !$result->has_unknown, 'Checking that we have no unknowns' );
    ok( !$result->has_missing, 'Checking that we have no missings' );
    
    untainted_ok( $result->valid('postalcode'), 'Checking that our data are untainted' );
};


1;
