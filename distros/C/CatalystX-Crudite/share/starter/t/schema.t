use Test::More;
use strict;
use warnings;
use DBICx::TestDatabase;
use <% dist_module %>::Util::Primer qw(prime_database);
my $schema = DBICx::TestDatabase->new('<% dist_module %>::Schema');
prime_database($schema);
my $user_name  = 'Blue Ox';
my $order_name = 'New Yellow Drink';
subtest 'Create a user' => sub {
    my $created_user = $schema->resultset('User')
      ->create({ name => $user_name, password => 'blueox' });
    is $created_user->name, $user_name,
      'The user we created has the right name';
};
my $user;
subtest 'Find the user' => sub {
    $user =
      $schema->resultset('User')->find({ name => $user_name });
    is $user->name, $user_name, 'The user we found has the right name';
};
done_testing;
