use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
my $DFV_4 = $Data::FormValidator::VERSION =~ /^4\./ ? 1 : 0;
# only run these tests if we have D::FV 4.x
if( $DFV_4 ) {
    plan(tests => 44);
} else {
    plan(skip_all => 'D::FV 4.x not installed');
}

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import(':all');
my $format          = '%m-%d-%Y';
my $good_date       = '02-17-2005';
my $unreal_date     = '02-31-2005';
my $bad_date        = '0-312-005';
my $real_bad_date   = '2';
my @inputs          = qw(good bad realbad unreal);
my $profile         = {
    required                => \@inputs,
    untaint_all_constraints => 1,
};
my $DATA            = {
    good    => $good_date,
    unreal  => $unreal_date,
    bad     => $bad_date,
    realbad => $real_bad_date,
};

my ($results, $date);

# test to see if we have DateTime::Format::MySQL
my $HAVE_DT_FORMAT_MYSQL = 0;
eval { require DateTime::Format::MySQL };
$HAVE_DT_FORMAT_MYSQL = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::MySQL not installed', 30)
        unless $HAVE_DT_FORMAT_MYSQL;

    # 2..11
    # to_mysql_datetime
    {
        # without a format param
        $profile->{constraint_methods} = { 
            good    => to_mysql_datetime(),
            unreal  => to_mysql_datetime(),
            bad     => to_mysql_datetime(),
            realbad => to_mysql_datetime(),
        };

        # use local data
        my %data = %$DATA;
        $data{good} = '2005-02-17 00:00:00';

        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_datetime expected valid');
        ok( $results->invalid('bad'), 'mysql_datetime expected invalid');
        ok( $results->invalid('realbad'), 'mysql_datetime expected invalid');
        ok( $results->invalid('unreal'), 'mysql_datetime expected invalid');
        $date = $results->valid('good');
        is($date, '2005-02-17 00:00:00', 'mysql_datetime correct format');

        # with a format param
        $profile->{constraint_methods} = {
            good    => to_mysql_datetime($format),
            unreal  => to_mysql_datetime($format),
            bad     => to_mysql_datetime($format),
            realbad => to_mysql_datetime($format),
        };

        %data = %$DATA;
        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_datetime expected valid');
        ok( $results->invalid('bad'), 'mysql_datetime expected invalid');
        ok( $results->invalid('realbad'), 'mysql_datetime expected invalid');
        ok( $results->invalid('unreal'), 'mysql_datetime expected invalid');
        $date = $results->valid('good');
        is($date, '2005-02-17 00:00:00', 'mysql_datetime correct format');

    }
    
    # 12..21
    # to_mysql_date
    {
        # without a format param
        $profile->{constraint_methods} = {
            good    => to_mysql_date(),
            unreal  => to_mysql_date(),
            bad     => to_mysql_date(),
            realbad => to_mysql_date(),
        };
        # use local data
        my %data = %$DATA;
        $data{good} = '2005-02-17';

        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_date expected valid');
        ok( $results->invalid('bad'), 'mysql_date expected invalid');
        ok( $results->invalid('realbad'), 'mysql_date expected invalid');
        ok( $results->invalid('unreal'), 'mysql_date expected invalid');
        $date = $results->valid('good');
        is($date, '2005-02-17', 'mysql_date correct format');

        # with a format param
        $profile->{constraint_methods} = {
            good    => to_mysql_date($format),
            unreal  => to_mysql_date($format),
            bad     => to_mysql_date($format),
            realbad => to_mysql_date($format),
        };

        %data = %$DATA;
        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_date expected valid');
        ok( $results->invalid('bad'), 'mysql_date expected invalid');
        ok( $results->invalid('realbad'), 'mysql_date expected invalid');
        ok( $results->invalid('unreal'), 'mysql_date expected invalid');
        $date = $results->valid('good');
        is($date, '2005-02-17', 'mysql_date correct format');
    }
    
    # 22..31
    # to_mysql_timestamp
    {
        # without a format param
        $profile->{constraint_methods} = {
            good    => to_mysql_timestamp(),
            unreal  => to_mysql_timestamp(),
            bad     => to_mysql_timestamp(),
            realbad => to_mysql_timestamp(),
        };

        # use local data
        my %data = %$DATA;
        $data{good} = '20050217000000';

        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_timestamp expected valid');
        ok( $results->invalid('bad'), 'mysql_timestamp expected invalid');
        ok( $results->invalid('realbad'), 'mysql_timestamp expected invalid');
        ok( $results->invalid('unreal'), 'mysql_timestamp expected invalid');
        my $date = $results->valid('good');
        is($date, '20050217000000', 'mysql_timestamp correct format');

        # with a format param
        $profile->{constraint_methods} = {
            good    => to_mysql_timestamp($format),
            unreal  => to_mysql_timestamp($format),
            bad     => to_mysql_timestamp($format),
            realbad => to_mysql_timestamp($format),
        };

        %data = %$DATA;
        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'mysql_timestamp expected valid');
        ok( $results->invalid('bad'), 'mysql_timestamp expected invalid');
        ok( $results->invalid('realbad'), 'mysql_timestamp expected invalid');
        ok( $results->invalid('unreal'), 'mysql_timestamp expected invalid');
        $date = $results->valid('good');
        is($date, '20050217000000', 'mysql_timestamp correct format');
    }
}

# 32..33
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
    $profile->{constraint_methods} = { good => to_mysql_datetime() };
    eval { $results = Data::FormValidator->check($DATA, $profile) };
    like( $@, qr/DateTime::Format::MySQL is required/, 'missing module');

    # mysql_date
    $profile->{constraint_methods} = { good => to_mysql_date() };
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
    skip('DateTime::Format::Pg not installed', 10)
        unless $HAVE_DT_FORMAT_PG;
    # 34..43
    # to_pg_datetime
    {
        # without a format param
        $profile->{constraint_methods} = {
            good    => to_pg_datetime(),
            unreal  => to_pg_datetime(),
            bad     => to_pg_datetime(),
            realbad => to_pg_datetime(),
        };
        # use local data
        my %data = %$DATA;

        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'pg_datetime expected valid');
        ok( $results->invalid('bad'), 'pg_datetime expected invalid');
        ok( $results->invalid('realbad'), 'pg_datetime expected invalid');
        ok( $results->invalid('unreal'), 'pg_datetime expected invalid');
        my $date = $results->valid('good');
        like($date, qr/2005-02-17 00:00:00(\.000000000\+0000)?/, 'pg_datetime correct format');

        # with a format param
        $profile->{constraint_methods} = {
            good    => to_pg_datetime($format),
            unreal  => to_pg_datetime($format),
            bad     => to_pg_datetime($format),
            realbad => to_pg_datetime($format),
        };

        $results = Data::FormValidator->check(\%data, $profile);
        ok( $results->valid('good'), 'pg_datetime expected valid');
        ok( $results->invalid('bad'), 'pg_datetime expected invalid');
        ok( $results->invalid('realbad'), 'pg_datetime expected invalid');
        ok( $results->invalid('unreal'), 'pg_datetime expected invalid');
        $date = $results->valid('good');
        like($date, qr/2005-02-17 00:00:00(\.000000000\+0000)?/, 'pg_datetime correct format');
    }
}

# 44
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
    $profile->{constraint_methods} = { good => to_pg_datetime() };
    eval { $results = Data::FormValidator->check($DATA, $profile) };
    like( $@, qr/DateTime::Format::Pg is required/, 'missing module');

    if( $HAVE_DT_FORMAT_PG ) {
        @INC = @SAVED_INC;
        $INC{$module} = $path;
    }
}

