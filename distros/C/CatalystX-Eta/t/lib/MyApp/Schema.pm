use utf8;
package MyApp::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-28 10:35:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vx5kwwS5ZT7yqpah97dgDA

sub AUTOLOAD {
    ( my $name = our $AUTOLOAD ) =~ s/.*:://;
    no strict 'refs';

    # isso cria na hora a sub e não é recompilada \m/ perl nao é lindo?!
    *$AUTOLOAD = sub {
        my ( $self, @args ) = @_;
        my $res = eval {
            $self->storage->dbh->selectrow_hashref( "select * from $name ( " . substr( '?,' x @args, 0, -1 ) . ')',
                undef, @args );
        };
        do { print $@; return undef } if $@;
        return $res;
    };
    goto &$AUTOLOAD;
}

sub deploy_with_users {
    my ($self) = @_;

    $self->deploy;

    my $rolers = $self->resultset('Role');
    $rolers->create({name =>'superadmin'});
    $rolers->create({name =>'user'});

    my $userrs = $self->resultset('User');

    $userrs->create({
        id    => 1,
        name  => 'Admin',
        email => 'superadmin@email.com',
        password => '123'
    })->set_roles( { name => 'superadmin' } );
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
