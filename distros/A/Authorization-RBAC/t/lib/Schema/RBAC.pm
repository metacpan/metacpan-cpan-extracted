package Schema::RBAC;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

our $VERSION = 1;

__PACKAGE__->load_namespaces;

=head1 NAME

Schema::RBAC.

=head1 SYNOPSIS

    my $schema = $rbac->schema;
    $schema->deploy;
    $schema->populate_schema;

=head1 DESCRIPTION

TODO

=head1 METHODS


=head2 populate_schema

    $schema->populate_schema;

This method creates and populate a fresh test database.

=cut


sub populate_schema {
    my $schema = shift;

    $schema->populate('User', [
        [ qw/id username     name                password email created active / ],
        [    1, 'admin',     'Gaston Lagaffe',   'd033e22ae348aeb5660fc2140aec35850c4da997', 'admin@mysite.eu', '', 1],
        [    2, 'anonymous', 'Anonymous Coward', '',     'anonymous.coward@localhost' , '', 1 ],
    ]);

  my $roles = $schema->populate('Role', [
        [ qw/id  name        active/ ],
        [    1, 'admin',     1       ],
        [    2, 'anonymous', 1       ],
        [    3, 'member',    1       ],
    ]);
  my $roles_id = { map { $_->name => $_->id } $schema->resultset('Role')->search };


  $schema->populate('UserRole', [
        [ qw/ user_id role_id / ],
        [     1,   1      ],
        [     2,   2      ],
    ]);

  my $operations = $schema->populate('Operation', [
        [ qw/id  name                 active/ ],
        [    1, 'inheritable',  1       ],
        [    2, 'view_Page',          1       ],
        [    3, 'create_Page',        1       ],
        [    4, 'edit_Page',          1       ],
        [    5, 'view_Comment',       1       ],
        [    6, 'view_Tag',           1       ],
    ]);
  my $operations_id = { map { $_->name => $_->id  } $schema->resultset('Operation')->search};

  my $typeobjs = $schema->populate('Typeobj', [
        [ qw/id  name       active/ ],
        [    1, 'Page',     1       ],
        [    2, 'Tag',      1       ],
        [    3, 'Comment',  1       ],
    ]);
  my $typeobjs_id = { map { $_->name => $_->id } $schema->resultset('Typeobj')->search };

  my $pages = $schema->populate('Page', [
        [ qw/id  name              parent_id  active/ ],
        [    1, '/',               0,         1       ],
        [    2, 'admin',           1,         1       ],
        [    3, 'user',            2,         1       ],
        [    4, 'add',             3,         1       ], # /admin/user/add
        [    5, 'login',           1,         1       ],
        [    6, 'access_denied',   1,         1       ],
        [    7, 'add',             2,         1       ], # /admin/add
        [    8, 'A',               1,         1       ], # /A
        [    9, 'B',               8,         1       ], # /A/B
        [   10, 'C',               9,         1       ], # /A/B/C
        [   11, 'D',              10,         1       ], # /A/B/C/D
    ]);

  my $comments = $schema->populate('Comment', [
        [ qw/id   body     page_id active/ ],
        [    1,  'bla',    11,      1       ],
        [    2,  'bla bla',1,      1       ],
    ]);

  my $tags = $schema->populate('Tag', [
        [ qw/id  name      active/ ],
        [    1,  'Perl',   1       ],
        [    2,  'Camel',  1       ],
    ]);

  # Objects are protected by operations
  my $objoperations = $schema->populate('ObjOperation', [
      [ qw/typeobj_id  obj_id   operation_id/ ],
      [    1,          1,       2             ], # Page /               view_Page
      [    1,          2,       2             ], # Page /admin          view_Page
      [    1,          4,       3             ], # Page /admin/user     create_Page
      [    1,          5,       2             ], # Page /admin/user/add create_Page
      [    1,         11,       4             ], # Page /A/B/C/D        edit_Page
      [    3,          1,       5             ], # Comment 1            view_Comment
      [    3,          2,       5             ], # Comment 2            view_Comment
      [    2,          1,       6             ], # Tag Perl             view_Tag
  ]);

  my $perms = [
             [ 'admin',     'Page', '/',               'create_Page',   1, 1 ],
             [ 'admin',     'Page', '/',               'view_Page',     1, 1 ],
             [ 'admin',     'Page', '/',               'view_Comment',  1, 1 ],
             [ 'admin',     'Page', 'D',               'edit_Page',     1, 1 ],
             [ 'admin',     'Page', 'login',           'view_Page',     0,   ],
             [ 'admin',     'Page', 'admin',           'view_Page',     1, 1 ],
             [ 'admin',     'Tag',  'Perl',            'view_Tag' ,     1    ],
             [ 'admin',     'Tag',  'Camel',           'view_Page',     1    ],

             [ 'anonymous', 'Page', '/',               'view_Page',     1, 1 ],
             [ 'anonymous', 'Page', 'login',           'view_Page',     1,   ],
             [ 'anonymous', 'Page', 'admin',           'view_Page',     0, 1 ],
             [ 'anonymous', 'Tag',  'Perl',            'view_Page',     1    ],
             [ 'anonymous', 'Tag',  'Camel',           'view_Page',     1    ],

             [ 'member',    'Page', '/',               'view_Page',     1, 1 ],
             [ 'member',    'Page', '/',               'create_Page',   1, 1 ],
             [ 'member',    'Page', 'D',               'edit_Page',     1, 1 ],
             [ 'member',    'Page', 'login',           'view_Page',     0,   ],
             [ 'member',    'Page', 'admin',           'view_Page',     0, 1 ],
             [ 'member',    'Tag',  'Perl',            'view_Page',     1    ],
             [ 'member',    'Tag',  'Camel',           'view_Page',     1    ]
            ];


    my $n = 0;
    my $permissions = [[qw/id role_id typeobj_id obj_id operation_id value inheritable/]];
    foreach my $p (@$perms) {
        my ( $role, $typeobj, $obj_id, $op, $val, $to_children ) = @$p;
        $n++;

        # Search if object in db
        my $obj = $schema->resultset($typeobj)->search({ name => $obj_id })->first;

        push (@$permissions,
              [ $n, $roles_id->{$role}, $typeobjs_id->{$typeobj}, $obj->id, $operations_id->{$op}, $val, $to_children ]);

    }

    $schema->populate('Permission', $permissions);
}


=head1 NAME

Schema::RBAC - L<DBIx::Class::Schema>

=head1 SYNOPSIS

See L<DB>

=head1 DESCRIPTION

L<Schema::RBAC> is used to test L<Authorization::RBAC>

=head1 AUTHOR

Daniel Brosseau <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
