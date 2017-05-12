package # hide from PAUSE
    DBIC::Test::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes;

__PACKAGE__->mk_group_accessors('simple' => qw/current_user_id/);

sub dsn {
    return shift->storage->connect_info->[0];
}

1;
