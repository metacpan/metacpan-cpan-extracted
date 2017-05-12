use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
plan(tests => 64);

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import();
my $format          = '%m-%d-%Y';
my $good_date       = '02-17-2005';
my $unreal_date     = '02-31-2005';
my $bad_date        = '0-312-005';
my $real_bad_date   = '2';
my @inputs          = qw(good bad realbad unreal);
my $profile         = {
    validator_packages      => ['Data::FormValidator::Constraints::DateTime'], 
    required                => \@inputs,
    untaint_all_constraints => 1,
};
my $DATA            = {
    good    => $good_date,
    unreal  => $unreal_date,
    bad     => $bad_date,
    realbad => $real_bad_date,
};

my $WITHOUT_PARAMS          = 0;
my $WITH_PARAMS             = 1;
my $WITH_PARAMS_METHOD      = 2;

my ($results, $date);

# test to see if we have DateTime::Format::MySQL
my $HAVE_DT_FORMAT_MYSQL = 0;
eval { require DateTime::Format::MySQL };
$HAVE_DT_FORMAT_MYSQL = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::MySQL not installed', 45)
        unless $HAVE_DT_FORMAT_MYSQL;

    # 2..16
    # to_mysql_datetime
    {
        # with params and without both as a constraint_method and as a constraint
        foreach my $option (
                    $WITHOUT_PARAMS, $WITH_PARAMS, $WITH_PARAMS_METHOD, 
        ) {
            $profile->{constraints} = _make_constraints('to_mysql_datetime', $option);
            my %data = %$DATA;
            $data{good} = '2005-02-17 00:00:00' if( $option == $WITHOUT_PARAMS );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_datetime expected valid');
            ok( $results->invalid('bad'), 'mysql_datetime expected invalid');
            ok( $results->invalid('realbad'), 'mysql_datetime expected invalid');
            ok( $results->invalid('unreal'), 'mysql_datetime expected invalid');
            $date = $results->valid('good');
            is($date, '2005-02-17 00:00:00', 'mysql_datetime correct format');
        }
    }
    
    # 17..31
    # to_mysql_date
    {
        # with params and without both as a constraint_method and as a constraint
        foreach my $option (
                    $WITHOUT_PARAMS, $WITH_PARAMS, $WITH_PARAMS_METHOD
        ) {
            $profile->{constraints} = _make_constraints('to_mysql_date', $option);
            my %data = %$DATA;
            $data{good} = '2005-02-17' if( $option == $WITHOUT_PARAMS );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_date expected valid');
            ok( $results->invalid('bad'), 'mysql_date expected invalid');
            ok( $results->invalid('realbad'), 'mysql_date expected invalid');
            ok( $results->invalid('unreal'), 'mysql_date expected invalid');
            $date = $results->valid('good');
            is($date, '2005-02-17', 'mysql_date correct format');
        }
    }
    
    # 32..46
    # to_mysql_timestamp
    {
        # with params and without both as a constraint_method and as a constraint
        foreach my $option (
                    $WITHOUT_PARAMS, $WITH_PARAMS, $WITH_PARAMS_METHOD
        ) {
            $profile->{constraints} = _make_constraints('to_mysql_timestamp', $option);
            my %data = %$DATA;
            $data{good} = '20050217000000' if( $option == $WITHOUT_PARAMS );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_timestamp expected valid');
            ok( $results->invalid('bad'), 'mysql_timestamp expected invalid');
            ok( $results->invalid('realbad'), 'mysql_timestamp expected invalid');
            ok( $results->invalid('unreal'), 'mysql_timestamp expected invalid');
            my $date = $results->valid('good');
            is($date, '20050217000000', 'mysql_timestamp correct format');
        }
    }
}

# 47..48
# let's remove DateTime::Format::MySQL from %INC (if it's there) and make 
# sure our constraints notice
{
    my @SAVED_INC = ();
    my ($module, $path);
    if( $HAVE_DT_FORMAT_MYSQL ) {
        @SAVED_INC = @INC;
        @INC = ();
        $module = 'DateTime/Format/MySQL.pm';
        $path = delete $INC{$module};
    }
    # mysql_datetime
    $profile->{constraints} = _make_constraints('to_mysql_datetime', $WITHOUT_PARAMS);
    eval { $results = Data::FormValidator->check($DATA, $profile, $WITHOUT_PARAMS) };
    like( $@, qr/DateTime::Format::MySQL is required/, 'missing module');

    # mysql_date
    $profile->{constraints} = _make_constraints('to_mysql_date', $WITHOUT_PARAMS);
    eval { $results = Data::FormValidator->check($DATA, $profile) };
    like( $@, qr/DateTime::Format::MySQL is required/, 'missing module');

    if( $HAVE_DT_FORMAT_MYSQL ) {
        @INC = @SAVED_INC;
        $INC{$module} = $path;
    }
}

# test to see if we have DateTime::Format::Pg
my $HAVE_DT_FORMAT_PG = 0;
eval { require DateTime::Format::Pg };
$HAVE_DT_FORMAT_PG = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::Pg not installed', 15)
        unless $HAVE_DT_FORMAT_PG;
    # 49..63
    # to_pg_datetime
    {
        # with params and without both as a constraint_method and as a constraint
        foreach my $option (
                    $WITHOUT_PARAMS, $WITH_PARAMS, $WITH_PARAMS_METHOD
        ) {
            my %data = %$DATA;
            $profile->{constraints} = _make_constraints('to_pg_datetime', $option);
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'pg_datetime expected valid');
            ok( $results->invalid('bad'), 'pg_datetime expected invalid');
            ok( $results->invalid('realbad'), 'pg_datetime expected invalid');
            ok( $results->invalid('unreal'), 'pg_datetime expected invalid');
            my $date = $results->valid('good');
            like($date, qr/2005-02-17 00:00:00(\.000000000\+0000)?/, 'pg_datetime correct format');
        }
    }
}

# 64
# let's remove DateTime::Format::Pg from %INC (if it's there) and make
# sure our constraints notice
{
    my @SAVED_INC = ();
    my ($module, $path);
    if( $HAVE_DT_FORMAT_PG ) {
        @SAVED_INC = @INC;
        @INC = ();
        $module = 'DateTime/Format/Pg.pm';
        $path = delete $INC{$module};
    }
    # pg_datetime
    $profile->{constraints} = _make_constraints('to_pg_datetime', $WITHOUT_PARAMS);
    eval { $results = Data::FormValidator->check($DATA, $profile, $WITHOUT_PARAMS) };
    like( $@, qr/DateTime::Format::Pg is required/, 'missing module');

    if( $HAVE_DT_FORMAT_PG ) {
        @INC = @SAVED_INC;
        $INC{$module} = $path;
    }
}


sub _make_constraints {
    my ($method, $option) = @_;
    my %constraints;

    foreach my $input (@inputs) {
        if( $option == $WITHOUT_PARAMS ) {
            $constraints{$input} = $method;
        } elsif( $option == $WITH_PARAMS ) {
            $constraints{$input} = {
                constraint  => $method,
                params      => [$input, \$format],
            };
        } elsif( $option == $WITH_PARAMS_METHOD ) {
            $constraints{$input} = {
                constraint_method   => $method,
                params              => [\$format],
            };
        }
    }
    return \%constraints;
};
