use Test::More;

use DBIx::SQLstate qw/:predicates/;

subtest "is_sqlstate_succes" => sub {
    
    ok(  is_sqlstate_succes('000001'),
        "SQL-state '00001' is     success"
    );
    
    ok( ! is_sqlstate_succes('01001'),
        "SQL-state '01001' is not success"
    );
    
    ok( ! is_sqlstate_succes('02001'),
        "SQL-state '02001' is not success"
    );
    
    ok( ! is_sqlstate_succes('03001'),
        "SQL-state '03001' is not success"
    );
    
    ok( ! is_sqlstate_succes('XX001'),
        "SQL-state 'XX001' is not success"
    );
    
};

subtest "is_sqlstate_warning" => sub {
    
    ok( ! is_sqlstate_warning('00002'),
        "SQL-state '00002' is not warning"
    );
    
    ok(   is_sqlstate_warning('01002'),
        "SQL-state '01002' is     warning"
    );
    
    ok( ! is_sqlstate_warning('02002'),
        "SQL-state '02002' is not warning"
    );
    
    ok( ! is_sqlstate_warning('03002'),
        "SQL-state '03002' is not warning"
    );
    
    ok( ! is_sqlstate_warning('XX002'),
        "SQL-state 'XX002' is not warning"
    );
    
};

subtest "is_sqlstate_no_data" => sub {
    
    ok( ! is_sqlstate_no_data('00003'),
        "SQL-state '00003' is not no_data"
    );
    
    ok( ! is_sqlstate_no_data('01003'),
        "SQL-state '01003' is not no_data"
    );
    
    ok(   is_sqlstate_no_data('02003'),
        "SQL-state '02003' is     no_data"
    );
    
    ok( ! is_sqlstate_no_data('03003'),
        "SQL-state '03003' is not no_data"
    );
    
    ok( ! is_sqlstate_no_data('XX003'),
        "SQL-state 'XX003' is not no_data"
    );
    
};

subtest "is_sqlstate_exception" => sub {
    
    ok( ! is_sqlstate_exception('00004'),
        "SQL-state '00004' is not exception"
    );
    
    ok( ! is_sqlstate_exception('01004'),
        "SQL-state '01004' is not exception"
    );
    
    ok( ! is_sqlstate_exception('02004'),
        "SQL-state '02004' is not exception"
    );
    
    ok(   is_sqlstate_exception('03004'),
        "SQL-state '03004' is     exception"
    );
    
    ok(   is_sqlstate_exception('XX004'),
        "SQL-state 'XX004' is     exception"
    );
    
};

done_testing;

