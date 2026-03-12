use strict;
use warnings;

use Test2::V0;
use Try::Tiny;
use File::Path  qw(rmtree);

use lib qw(lib t);
use DBD::Mock::Session::GenerateFixtures;


subtest 'execute an plsql/ script using mocked data with named params and cursors' => sub {

       my $sql = <<"SQL";
DECLARE
    v_cursor SYS_REFCURSOR;
    v_id     NUMBER;
    v_login  DATE;
BEGIN
    pr_user_login_history(
        p_id => :user_id,
        p_app_id => :app_id,
        p_day => :day, 
        p_month => :month 
    );

    LOOP
        FETCH v_cursor INTO v_id, v_login;
        EXIT WHEN v_cursor%NOTFOUND;

    END LOOP;

    CLOSE v_cursor;
END
SQL

    my $fixtures = [
        {
            "results"      => [ [ 2, "netflix" ], [ 1, "prime" ] ],
            "col_names"    => [ "id",           "chanell" ],
            "bound_params" => [ 2,              1, '<CURSOR>', '<CURSOR>'],
            "statement"    => "DECLARE v_cursor SYS_REFCURSOR; v_id NUMBER; v_login DATE; BEGIN pr_user_login_history( p_id => :user_id, p_app_id => :app_id, p_day => :day, p_month => :month ); LOOP FETCH v_cursor INTO v_id, v_login; EXIT WHEN v_cursor%NOTFOUND; END LOOP; CLOSE v_cursor; END",

        },
    ];

     my $dbh = DBD::Mock::Session::GenerateFixtures->new( { data => $fixtures } )->get_dbh();
     my $params = {
        ':user_id' => 2,
        ':app_id' => 1,
     };

    my $out = {
        ':day' => 1,
        ':month' => 1,
     };

    my $sth = $dbh->prepare($sql);
    while ( my ( $key, $val ) = each %{$params} ) {
        $sth->bind_param( $key => $val );
    }
    while ( my ( $key, $val ) = each %{$out} ) {
        $sth->bind_param_inout($key, \$val,  2);
    }
        $sth->execute();
    my $got = [];
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is(
        $got,
        [
          {
            'chanell' => 'netflix',
            'id' => 2
          },
          {
            'id' => 1,
            'chanell' => 'prime'
          }
        ]
    )
};

subtest 'execute an plsql/ script using mocked data with positional and cursors' => sub {
       my $sql = <<"SQL";
DECLARE
    v_cursor SYS_REFCURSOR;
    v_id     NUMBER;
    v_login  DATE;
BEGIN
    pr_user_login_history(
        p_id => ?,
        p_app_id => ?,
        p_day => ?, 
        p_month => ? 
    );

    LOOP
        FETCH v_cursor INTO v_id, v_login;
        EXIT WHEN v_cursor%NOTFOUND;

    END LOOP;

    CLOSE v_cursor;
END
SQL

   my $fixtures = [
        {
            "results"      => [ [ 2, "netflix" ], [ 1, "prime" ] ],
            "col_names"    => [ "id",           "chanell" ],
            "bound_params" => [ 2,              1, '<CURSOR>', '<CURSOR>'],
            "statement"    => "DECLARE v_cursor SYS_REFCURSOR; v_id NUMBER; v_login DATE; BEGIN pr_user_login_history( p_id => ?, p_app_id => ?, p_day => ?, p_month => ? ); LOOP FETCH v_cursor INTO v_id, v_login; EXIT WHEN v_cursor%NOTFOUND; END LOOP; CLOSE v_cursor; END",

        },
    ];
   
     my $dbh = DBD::Mock::Session::GenerateFixtures->new( { data => $fixtures } )->get_dbh();
     my $sth =  $dbh->prepare( $sql );
     my $ref;
     $sth->bind_param(1, 2);
     $sth->bind_param(2, 1);
     $sth->bind_param_inout(3, \$ref, 1);
     $sth->bind_param_inout(4, \$ref, 1);
     $sth->execute();
   

     
    my $got = [];
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

     is(
        $got,
        [
          {
            'chanell' => 'netflix',
            'id' => 2
          },
          {
            'id' => 1,
            'chanell' => 'prime'
          }
        ]
    );
};

rmtree 't/db_fixtures';
done_testing();