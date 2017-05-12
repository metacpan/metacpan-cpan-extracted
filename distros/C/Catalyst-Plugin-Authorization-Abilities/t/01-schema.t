#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {

    $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1;

    eval {
        require DBD::SQLite;
        require SQL::Translator;
        require UNIVERSAL::require;
        require DBIx::Class::DateTime::Epoch;
        require DBIx::Class::EncodedColumn;
    } or plan 'skip_all' => "A bunch of plugins and modules are required for this test... Look in the source if you really care... $@";

}


use lib 't/lib';
use Schema::Utils;

my $conf = 't/conf/abilities.yml';
my $su = Schema::Utils->new(conf => $conf, ns_conf => 'Authorization::Abilities', debug => 0);
ok ( $su->conf eq $conf, "Conf: $conf");

# Delete sqlite file if exist
my $sqlite_file = $su->dsn;
$sqlite_file =~ s/.*:(.*)$/$1/;
ok(unlink ($sqlite_file), "delete $sqlite_file") if -e $sqlite_file;

ok( $su->init_schema(populate => 1), 'deploy and populate schema' );


# Add some datas
# Action create_Page, edit_Page ...
# Role admin (default), anonymous (default), member, moderator
# user admin (admin), joe (member, moderator)
my $schema = $su->schema;


#-------------------------------------#
#            Actions
#-------------------------------------#
my $actions = [ 'create_Page', 'edit_Page', 'view_Page', 'delete_Page',
                'create_Comment', 'edit_Comment', 'view_Comment', 'delete_Comment',
                'create_Tag', 'edit_Tag', 'view_Tag', 'delete_Tag' ];

foreach my $i ( @$actions ) {
  ok( my $row = $schema->resultset('Action')->create({
                                                      name   => $i,
                                                        }), "Create Action $i");
} ;


#-------------------------------------#
#            Roles
#             and
#        RoleAction
#-------------------------------------#
my $roles = [ 'admin', 'anonymous', 'member', 'moderator' ];

# no action ( but role admin = all roles see after )
my %actions_role;
$actions_role{admin}     = [  ];

# To move on site
$actions_role{anonymous} = [ 'view_Page',
                             'create_Comment', 'edit_Comment', 'view_Comment',
                             'view_Tag' ];

# To manage Page and move on site
$actions_role{member}    = [ 'create_Page', 'edit_Page', 'view_Page', 'delete_Page',
                             'create_Comment', 'edit_Comment', 'view_Comment',
                             'view_Tag' ];

# Just to manage Comment
$actions_role{moderator} = [ 'view_Page', 'create_Comment', 'edit_Comment', 'view_Comment', 'delete_Comment', 'view_Tag' ];

# Add roles and roleaction
foreach my $r ( @$roles ) {
  ok( my $role = $schema->resultset('Role')->find_or_create({
                                                             name   => $r,
                                                             active => 1,
                                                            }), "Find or Create Role $r");


  foreach my $p ( @{$actions_role{$r}} ) {
    ok( $role->add_to_actions({name => $p}),
        "Add action $p to role " . $role->name);
  }
} ;


# Admin role inherit all roles
foreach my $r ( qw / anonymous member moderator /){
  my $role = $schema->resultset('Role')->search({
                                               name   => $r,
                                              })->first;

  ok( my $rolerole = $schema->resultset('RoleRole')->create({
                                                             role_id => 1,
                                                             inherits_from_id   =>  $role->id,
                                                            }), "Admin role inherit $r");
}

#-------------------------------------#
#            Users
#-------------------------------------#
#
# Admin
#
ok( my $admin = $schema->resultset('User')->search({
                                                    username => 'admin'
                                                   })->first,
    "retrieve admin already in db"
);
my @admin_roles = map { $_->name } $admin->user_roles;
is_deeply( \@admin_roles, ['admin'], "admin have roles 'admin'");



#
# Anonymous
#
ok( my $anonymous = $schema->resultset('User')->search({
                                                        username => 'anonymous'
                                                       })->first,
    "retrieve anonymous already in db"
  );
my @anonymous_roles = map { $_->name } $anonymous->user_roles;
is_deeply( \@anonymous_roles, ['anonymous'], "anonymous have roles 'anonymous'");

#
# Create a user joe (roles: member, moderator)
#
ok( my $user = $schema->resultset('User')->create({
                                                   username => 'joe',
                                                   name     => 'Joe Dalton',
                                                   password => 'joe',
                                                   email    => 'joe@dalton.eu',
                                                   active   => 1,
                                                  }), "Add user 'joe'");

ok( $user->add_to_user_roles({ name => "member" }), "Add role 'member' to user joe");
ok( $user->add_to_user_roles({ name => "moderator" }), "Add role 'moderator' to user joe");
ok( $user->add_to_user_roles({ name => "justfortest" }), "Add role 'justfortest' to user joe");



my @user_roles = map { $_->name} $user->user_roles;
is_deeply( \@user_roles, ['member', 'moderator', 'justfortest'], 
           "\$user have 'member', 'moderator' and 'justfortest' roles");

# To test recursive roles
ok( my $r1 = $user->add_to_user_roles({ name => "r1" }), "Add role 'r1' to user joe");
ok( my $r2 = $r1->add_to_roles({ name => "r2" }), "Add role 'r2' to role r1");
ok( my $r3 = $r2->add_to_roles({ name => "r3" }), "Add role 'r3' to role r2");
ok( my $r4 = $r3->add_to_roles({ name => "r4" }), "Add role 'r4' to role r3");
ok( my $r5 = $r3->add_to_roles({ name => "r5" }), "Add role 'r5' to role r3");

ok( my $can_recursive_roles = $r4->add_to_actions({ name => "can_recursive_roles" }), "Add action 'can_recursive_roles' to role r4");



#
# Create user jack ( roles: member )
#
ok( my $user2 = $schema->resultset('User')->create({
                                                    username => 'jack',
                                                    name     => 'Jack Dalton',
                                                    password => 'jack',
                                                    email    => 'jack@dalton.eu',
                                                    active   => 1,
                                                   }), "Add user 'jack'");

# Add role 'member' with add_to_roles user method
ok( $user2->add_to_user_roles({ name => "moderator" }), "Add role 'moderator' to user jack");


my @user2_roles = map { $_->name} $user2->user_roles;
is_deeply( \@user2_roles, ['moderator'], "jack have just 'moderator' role");


#
# Delete justfortest role
#
ok( my $test_role = $schema->resultset('Role')->search({
                                                        name => 'justfortest'
                                                       })->first,
    "retrieve justfortest role" );

ok($test_role->delete, "Delete justfortest role");

@user_roles = map { $_->name} $user->user_roles;
is_deeply( \@user_roles, ['member', 'moderator', 'r1'],
           "Now joe  have 'member', 'moderator' and 'r1' roles");




#my @role_users = map {$_->username } $member_role->users;;
#is_deeply( \@role_users, ['joe', 'jack'], "users with role 'member' are joe and jack");


# user_action : nothing
# user admin : role admin
# user joe   : role member, moderator, r1
# user jack  : role moderator
# role admin :
# role anonymous : 'view_Page', 'create_Comment', 'edit_Comment', 'view_Comment', 'view_Tag'
# role member    : 'create_Page', 'edit_Page', 'view_Page', 'delete_Page', 'create_Comment', 'edit_Comment', 'view_Comment', 'view_Tag'
# role modertor  : 'view_Page', 'create_Comment', 'edit_Comment', 'view_Comment', 'delete_Comment', 'view_Tag'
# rolerole       : r1 <= r2
#                  r2 <= r3
# role_action    : r3 <= can_recursive_roles

done_testing();
