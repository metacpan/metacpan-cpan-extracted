#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Authorization::RBAC;
use lib 't/lib';
use Schema::RBAC;

my $schema = Schema::RBAC->connect(
  'dbi:SQLite:dbname=:memory:',
);

print "schema=$schema\n";
my $roles =                                   [ 'anonymous', 'admin', 'member' ];
my $can_access =  {
                   '/'                     => [  1,          1,        1,      ],
                   '/login'                => [  1,          0,        0,      ],
                   '/admin'                => [  0,          1,        0,      ],
                   '/admin/user'           => [  0,          1,        0,      ],
                   '/admin/user/add'       => [  0,          1,        0,      ],
                   '/access_denied'        => [  1,          1,        1,      ],
                   '/A/B/C/D'              => [  0,          1,        1,      ],
                  };


#-------------------------------------#
#     And now test all permissions
#-------------------------------------#
#     With field_unique = path
#-------------------------------------#
my $confs = [ 't/conf/permsfromdb.yml'];
my $rbac;
foreach my $conf ( @$confs ){

  ok( $rbac = Authorization::RBAC->new(  conf  => $conf, schema => $schema  ),
    "Create RBAC (conf: $conf)");

  my $schema = $rbac->schema;
  $schema->deploy;
  $schema->populate_schema;

  my $backend = $rbac->config->{backend}->{name};
  ok($rbac->can('get_permission'), "Backend $backend provide get_permission");

  my $count = 0;
  foreach my $role ( @$roles) {
  my $role_rs = $schema->resultset('Role')->search( { name => $role })->single;
    foreach my $path ( sort keys %$can_access) {
      my $can  = ${$can_access->{$path}}[$count];
      ok( my $objects = $schema->resultset('Page')->retrieve_pages_from_path($path), "retrieve pages from path $path");
      $can ? &is_allowed([$role_rs], $objects, $path ) : &is_denied([$role_rs], $objects, $path);
    }
    $count++;
  }



  my $inexistant_path = '/another/inexistant/page';
  ok( my $objects = $schema->resultset('Page')->retrieve_pages_from_path($inexistant_path), "retrieve pages from path $inexistant_path");
  ok( my $anonymous_role = $schema->resultset('Role')->search( { name => 'anonymous' })->single, "retrieve role 'anonymous'");
  ok ( ! $rbac->can_access([ $anonymous_role ], $objects, ['create_Page']), "Role 'anonymous' cannot view/create Page $inexistant_path");

  ok( my $admin_role = $schema->resultset('Role')->search( { name => 'admin' })->single, "retrieve role 'admin'");
  ok ( $rbac->can_access([ $admin_role ], $objects, ['create_Page']), "Role 'admin' can view/create Page $inexistant_path");
  ok ( $rbac->can_access([ $anonymous_role,$admin_role ], $objects, ['create_Page']), "Role ['anonymous', 'admin'] can view/create Page $inexistant_path");


  # test access to a comment attached to a page
  ok( my $comment1 = $schema->resultset('Comment')->find(1), "retrieve first 'Comment'");
  ok ( $rbac->can_access([ $admin_role ], [ $comment1 ]), "Role 'admin' can view_Comment (first comment)");

  ok( my $comment2 = $schema->resultset('Comment')->find(2), "retrieve second 'Comment'");
  ok( ! $rbac->can_access([ $anonymous_role ], [ $comment2 ]), "Role 'anonyme' can not view_Comment (second comment)");

  ok( my $tagPerl = $schema->resultset('Tag')->search({name => 'Perl'})->first, "retrieve Perl 'Tag'");
  ok( ! $rbac->can_access([ $anonymous_role ], [ $tagPerl ]), "Role 'anonyme' can not view_Tag Perl");
  ok(   $rbac->can_access([ $admin_role ], [ $tagPerl ]), "Role 'admin' can view_Tag Perl");
}
# End of tests


sub is_allowed {
  my ($roles, $objects, $path ) = @_;
  my @roles_name = map { $_->name} @$roles;
  ok ($rbac->can_access($roles, $objects), "Role @roles_name can access to $path");
}

sub is_denied {
  my ($roles, $objects, $path) = @_;
  my @roles_name = map { $_->name} @$roles;
  ok (! $rbac->can_access($roles, $objects), "Role @roles_name cannot access to $path");
}
