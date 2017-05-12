package DBIC::Test::Service::User;

use strict;
use warnings;

use base qw(DBIx::Class::Service);

sub add_user: Transaction {
    my ($class, $schema, $args) = @_;

    my $rs = $schema->resultset('User');

    my $user;

    $user = $rs->create({
        user_seq => undef,
        user_id => $args->{user_id},
        password_digest => crypt($args->{password}, $args->{user_id}),
    });

    $user->create_related('profiles', {
        name => $args->{name},
        nickname => $args->{nickname},
    });

    return $user;
}

sub authenticate: DataSource {
    my ($class, $schema, $user_id, $password) = @_;

    my $rs = $schema->resultset('User');
    return $rs->find({ user_id => $user_id, password_digest => crypt($password, $user_id) });
}

sub add_diary: Transaction {
    my ($class, $schema, $user_id, $title, $content) = @_;

    my $rs = $schema->resultset('User');

    my $diary = $rs->find({ user_id => $user_id })->create_related('diaries', {
        title => $title,
        content => $content,
    });

    return $diary;
}

1;

__END__
