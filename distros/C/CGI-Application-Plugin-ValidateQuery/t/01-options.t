    use FindBin '$Bin';
    use lib "$Bin/../lib";
    use lib "$Bin";

    use Test::More 'no_plan';

    use TestAppWithLogger;
    use TestAppWithoutLogger;

    use strict;
    use warnings;

    my $t_obj = TestAppWithLogger->new();
    $t_obj->validate_query_config(
        log_level =>  'critical',
        error_mode => 'fail'
    );

    ok($t_obj->{__CAP_VALQUERY_LOG_LEVEL}, '__CAP_VALQUERY_LOG_LEVEL defined');
    is($t_obj->{__CAP_VALQUERY_LOG_LEVEL}, 'critical', 
        '__CAP_VALQUERY_LOG_LEVEL is correct');

    ok($t_obj->{__CAP_VALQUERY_ERROR_MODE}, '__CAP_VALQUERY_ERROR_MODE defined');
    is($t_obj->{__CAP_VALQUERY_ERROR_MODE}, 'fail',
        '__CAP_VALQUERY_ERROR_MODE is correct');

    eval {
        $t_obj->validate_query_config(
            incorrect => 'invalid'
        );
    };

    like($@, qr/Invalid option\(s\)/, 'invalid option - without valids');

    $t_obj = TestAppWithLogger->new();
    eval {
        $t_obj->validate_query_config(
            incorrect => 'invalid',
            log_level => 'critical',
            error_mode => 'fail'
        );
    };

    like($@, qr/Invalid option\(s\)/, 'invalid option - with valids');

    $t_obj = TestAppWithLogger->new();
    $t_obj->validate_query_config();
    is($t_obj->{__CAP_VALQUERY_LOG_LEVEL }, undef, 'default -- log_level');
    is($t_obj->{__CAP_VALQUERY_ERROR_MODE}, 'validate_query_error_mode', 'default -- error_mode');

    $t_obj = TestAppWithoutLogger->new();
    eval {
        $t_obj->validate_query_config(log_level=>'Supplied level');
    };

    like($@, qr/no logging interface/, 'Log level given but no logger');
