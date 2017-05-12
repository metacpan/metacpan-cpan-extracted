use strict;
use warnings;
use ArangoDB;

my $db = ArangoDB->new();

my $users = $db->('users');

$users->save({ user => { name => 'John', age => 42 } });
$users->save({ user => { name => 'Joe', age => 20 } });
$users->save({ user => { name => 'Alice', age => 10 } });

my $docs = $db->query(
    'FOR u IN users FILTER u.user.age >= @age SORT u.user.name RETURN u'
)->bind( age => 18 )->execute->all;

for my $doc ( @$docs ){
    print $doc->content->{user}{name}, "\n";
}

