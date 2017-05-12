# $Id: all.t,v 1.1 2005/03/25 15:28:53 danielr Exp $
# all undistinguished tests 
# basic, insufficient, ...
use strict;
use warnings;
use Test::More 'tests' => 5;
use DBIx::AbstractStatement qw(sql sql_join);

sub _sql {
    sql("SELECT * FROM customer WHERE :where")
      ->bind_param(":where" => sql_join(' AND ',   
        sql("customer_id = :customer_id"),
        sql("created >= :created"),
        sql("deleted is null")));
}

my $sql = _sql();
diag($sql->text);
    
ok($sql->has_param(':created'),  'Existence of unbound parameter');
ok($sql->text =~ /:customer_id/, 'Existence of substring in SQL text');

$sql->bind_param(':created', sql('sysdate'));
ok($sql->text !~ /:created/s, 'Nonexistence of bound parameter');

$sql->bind_param(':customer_id', 2377);

my $new_name  = $sql->get_param_name(':customer_id');
diag(':customer_id =>'. $new_name);
ok($sql->has_param($new_name), 'Existence of bound parameter');

$sql = _sql();
$sql->bind_param(':customer_id' => 72);
$sql->bind_param(':created'     => '2005-03-23');
$sql->_renumber_params;
diag($sql->text);
ok(grep(1, $sql->text =~ /(\?)/g) == 2, 'Question mark counting');



