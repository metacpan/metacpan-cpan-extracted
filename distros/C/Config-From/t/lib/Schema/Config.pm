use utf8;
package Schema::Config;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema';

our $VERSION = 1;

__PACKAGE__->load_namespaces;

# toto:
#   titi: dbix1
#   tete: dbix2
# tata: dbix3
# titi: dbix4
# abc:
#   def:
#     ghi: dbix5

sub _populate {
  my $self = shift;

  my @configs = $self->populate(
        'Config',
        [
            [ qw/ id  parent_id  name    value    /],
            [     1,  0,         'toto',   ,       ],
            [     2,  1,         'titi',   'dbix1' ],
            [     3,  1,         'tete',   'dbix2' ],
            [     4,  0,         'tata',   'dbix3' ],
            [     5,  0,         'titi',   'dbix4' ],
            [     6,  0,         'abc',    ,       ],
            [     7,  6,         'def',    ,       ],
            [     8,  7,         'ghi',    'dbix5' ],
        ]
    );
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
