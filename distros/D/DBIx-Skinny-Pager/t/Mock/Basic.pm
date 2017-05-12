package Mock::Basic;
use DBIx::Skinny connect_info => +{};
use DBIx::Skinny::Mixin modules => [qw(Pager SearchWithPager)];

my $table = 'mock_basic';
sub setup_test_db {
    my $self = shift;
    if ( $self->dbd->isa("DBIx::Skinny::DBD::MySQL") ) {
        $self->do(qq{
            CREATE TABLE IF NOT EXISTS $table (
                id   INT auto_increment,
                name INT NOT NULL,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
    } else {
        $self->do(qq{
            CREATE TABLE IF NOT EXISTS $table (
                id   INT auto_increment,
                name INT NOT NULL,
                PRIMARY KEY  (id)
            )
        });
    }
    $self->delete($table, {});
}

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}
