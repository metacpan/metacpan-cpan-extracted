package CatalystX::Crudite::Schema::ResultBase;
use strict;
use warnings;
use parent 'DBIx::Class';
__PACKAGE__->load_components(qw(UUIDColumns TimeStamp Core));

sub common_setup {
    my $class = shift;
    $class->add_columns(
        id => {
            data_type         => 'int',
            is_nullable       => 0,
            is_numeric        => 1,
            is_auto_increment => 1
        },
        uuid    => { data_type => 'varchar', is_nullable => 0 },
        created => {
            data_type     => 'timestamp',
            default       => \'now()',
            set_on_create => 1
        },
        updated => {
            data_type     => 'timestamp',
            is_nullable   => 1,
            set_on_create => 1,
            set_on_update => 1
        },
    );
    $class->uuid_columns('uuid');
    $class->uuid_class('::Data::UUID');
    $class->set_primary_key('id');
    $class->resultset_attributes({ order_by => 'me.updated' });
}

sub setup_user_class {
    my $class  = shift;
    my $prefix = $class =~ s/.*\K::.*//r;
    $class->load_components(qw(PassphraseColumn));
    $class->table('users');
    $class->common_setup;
    $class->add_columns(
        name     => { data_type => 'varchar', is_nullable => 0 },
        password => {
            data_type        => 'text',
            passphrase       => 'rfc2307',
            passphrase_class => 'BlowfishCrypt',
            passphrase_args  => {
                cost        => 8,
                salt_random => 20,
            },
            passphrase_check_method => 'check_password',
        },
    );
    $class->add_unique_constraint([qw(name)]);
    $class->has_many(
        user_roles => "${prefix}::UserRole",
        'user_id',
        { cascade_delete => 1 },
    );
    $class->many_to_many('roles', 'user_roles', 'role');
}

sub setup_role_class {
    my $class = shift;
    $class->table('roles');
    $class->common_setup;
    $class->add_columns(
        name => {
            data_type   => 'varchar',
            size        => 32,
            is_nullable => 0,
        },
        display_name => {
            data_type   => 'varchar',
            size        => 32,
            is_nullable => 0,
        },
    );
    $class->add_unique_constraint([qw(name)]);
}

sub setup_user_role_class {
    my $class  = shift;
    my $prefix = $class =~ s/.*\K::.*//r;
    $class->table('user_roles');
    $class->common_setup;
    $class->auto_belongs_to(user => "${prefix}::User");
    $class->auto_belongs_to(role => "${prefix}::Role");
    $class->add_unique_constraint([qw(user_id role_id)]);
}

sub auto_belongs_to {
    my ($class, $accessor, $result_class) = @_;
    my $foreign_key_column_name = $accessor . '_id';
    $class->add_columns(
        $foreign_key_column_name => {
            data_type  => 'int',
            is_numeric => 1,
        },
    );
    $class->belongs_to(
        $accessor => $result_class,
        $foreign_key_column_name
    );
}
1;
