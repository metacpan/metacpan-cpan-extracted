use strict;
use warnings;
no warnings 'uninitialized';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;

HR_connect;

# auto_update through meta surgery
HR            ->metadm->{auto_update_columns}{user_id} = sub {'USER'};
HR::Department->metadm->{auto_update_columns}{user_id} = sub {'USER2'};
HR::Activity  ->metadm->{auto_update_columns}{user_id} = undef;

# auto_update from schema
HR::Employee->insert({emp_id => 1, lastname => 'Bach'});
sqlLike('INSERT INTO T_Employee (emp_id, lastname, user_id) VALUES (?, ?, ?)',
        [1, 'Bach', 'USER'],
        'insert Employee with auto_update');

# overridden auto_update 
HR::Department->insert({dpt_id => 1});
sqlLike('INSERT INTO T_Department (dpt_id, user_id) VALUES (?, ?)',
        [1, 'USER2'],
        'insert Department with overridden auto_update');

# cancelled auto_update 
HR::Activity->insert({act_id => 1, emp_id => 1});
sqlLike('INSERT INTO T_Activity (act_id, emp_id) VALUES (?, ?)',
        [1, 1],
        'insert Activity without auto_update');



done_testing;


