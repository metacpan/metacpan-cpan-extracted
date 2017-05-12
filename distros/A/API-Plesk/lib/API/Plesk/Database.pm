
package API::Plesk::Database;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub add_db {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(webspace-id name type));
     
    return $bulk_send ? \%params : 
        $self->plesk->send('database', 'add-db', \%params);
}

sub del_db {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('database', 'del-db', $data);
}

sub add_db_user {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(db-id login password));

    my $data = $self->sort_params(\%params, qw(db-id login password));
 
    return $bulk_send ? $data : 
        $self->plesk->send('database', 'add-db-user', $data);
}

sub del_db_user {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('database', 'del-db-user', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Database -  Managing databases.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->database->add_db(..);
    $response = $api->database->del_db(..);
    $response = $api->database->add_db_user(..);
    $response = $api->database->del_db_user(..);

=head1 DESCRIPTION

Module manage databases and database users.

=head1 METHODS

=over 3

=item add_db(%params)

=item del_db(%params)

=item add_db_user(%params)

=item del_db_user(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
