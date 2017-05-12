package Schema::Abilities;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-17 10:52:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nwxdx90gkk/IhnU3OQ2q5w

our $VERSION = 1;

=head1 METHODS


=cut

sub populate_schema {
  my $schema = shift;


  $schema->populate('User', [
        [ qw/id username     name                password email created active / ],
        [    1, 'admin',     'Gaston Lagaffe',   'd033e22ae348aeb5660fc2140aec35850c4da997', 'admin@mysite.eu', '', 1],
        [    2, 'anonymous', 'Anonymous Coward', '',     'anonymous.coward@localhost' , '', 1 ],
    ]);

  $schema->populate('Role', [
        [ qw/id  name        active/ ],
        [    1, 'admin',     1       ],
        [    2, 'anonymous', 1       ],
    ]);

  $schema->populate('UserRole', [
        [ qw/ user_id role_id / ],
        [     1,   1      ],
        [     2,   2      ],
    ]);

}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
