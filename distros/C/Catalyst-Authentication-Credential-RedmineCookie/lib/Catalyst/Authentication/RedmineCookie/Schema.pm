use utf8;
package Catalyst::Authentication::RedmineCookie::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    default_resultset_class => "+DBIx::Class::ResultSet::HashRef",
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 15:50:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dHVAPbDcEF+upQSQ5OuNog

# find /usr/local/www/redmine/app/models -type f | sort | xargs greple -pe '^\s*(has_many|belongs_to|might_have|has_one|many_to_many|has_and_belongs_to_many) 

use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::GroupsUsers";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::MemberRoles";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::Members";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::Roles";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::RolesManagedRoles";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::UserPreferences";
use aliased "Catalyst::Authentication::RedmineCookie::Schema::Result::Users";

GroupsUsers->belongs_to( user  => Users, 'user_id'  );
GroupsUsers->belongs_to( group => Users, 'group_id' );

Members->belongs_to( user => Users, 'user_id' );
Members->has_many( member_role => MemberRoles, 'member_id' );

Users->has_many( groups_users => GroupsUsers, 'user_id' );
Users->many_to_many( groups => group_users => 'group' );

Users->has_many( members => Members, 'user_id' );
Users->many_to_many( member_roles => members => 'member_role' );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
