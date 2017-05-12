package Catalyst::Plugin::Session::Manager::Storage::CDBI;
use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Manager::Storage/;

use UNIVERSAL::require;
use Catalyst::Exception;
use MIME::Base64;
use Storable;

our $ID_FIELD      = "id";
our $STORAGE_FIELD = "storage";
our $EXPIRES       = 60 * 60;
our $EXPIRES_FIELD = "expires";

sub new {
    my $class = shift;
    bless { config => $_[0], _data => { } }, $class;
}

sub serialize {
    my ($self, $data) = @_;
    encode_base64(Storable::freeze($data));
}

sub deserialize {
    my ($self, $data) = @_;
    Storable::thaw(decode_base64($data));
}

sub set {
    my ( $self, $c ) = @_;
    my $sid  = $c->sessionid or return;
    my $session_class  = $self->{config}{session_class};
    my $sid_column     = $self->{config}{id_field}      || $ID_FIELD;
    my $storage_column = $self->{config}{storage_field} || $STORAGE_FIELD;
    my $expires        = $self->{config}{expires}       || $EXPIRES;
    my $expires_column = $self->{config}{expires_field} || $EXPIRES_FIELD;
    my $need_commit    = $self->{config}{need_commit}   || 0;
    $self->_verify_session_class($session_class);
    my $time  = time;
    my $table = $session_class->table;
    $session_class->db_Main->do(
        sprintf "DELETE FROM %s WHERE %s < %d",
                $table,
                $expires_column,
                $time
    );
    my $session = $session_class->find_or_create( $sid_column => $sid );
    $session->set( $storage_column, $self->serialize( $self->{_data} ) );
    $session->set( $expires_column, $time + $expires );
    $session->update;
    $session->dbi_commit if $need_commit;
    $self->{_data} = { };
}

sub get {
    my ( $self, $sid ) = @_;
    my $session_class  = $self->{config}{session_class};
    my $sid_column     = $self->{config}{id_field}      || $ID_FIELD;
    my $storage_column = $self->{config}{storage_field} || $STORAGE_FIELD;
    $self->_verify_session_class($session_class);
    my $record = $session_class->retrieve($sid);
    return $self->{_data} unless $record;
    my $data = $record->$storage_column;
    $self->{_data} = $self->deserialize($data);
    return $self->{_data};
}

sub _verify_session_class {
    my ($self, $session_class) = @_;
    $session_class->require;
    if ($@) {
        Catalyst::Exception->throw(qq/Failed to require "$session_class", "$@"/);
    }
    unless ($session_class->isa('Class::DBI')) {
        Catalyst::Exception->throw(qq/Session-Class should be made with Class::DBI./);
    }
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Storage::CDBI - stores session data with CDBI

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        storage => 'CDBI',
        session_class => 'MyApp::M::CDBI::Session',
        id_field      => 'id',
        storage_field => 'storage',
        expires_field => 'expires',
        expires       => 3600,
        need_commit   => 1,
    }

=head1 DESCRIPTION

This module allows you to handle session with database.
At first, you need to prepare the table for sessions.

Here's an example.

    create table session (
        id      varchar(50),
        storage mediumtext,
        expires integer,
        primary key(id)
    );


And you have to write the class mapped with this table.

    package MyApp::M::CDBI::Session;
    use base qw/MyApp::M::CDBI/;
    __PACKAGE__->table('session');
    __PACKAGE__->columns( Primary   => 'id' );
    __PACKAGE__->columns( Essential => qw/storage expires/ );

=head1 CONFIGURATION

=over 4

=item session_class

CDBI-subclass mapped with the table stores session-data.

=item id_field

'id' is set by default.

=item storage_field

'storage' is set by default.

=item expires_field

'expires' is set by default.

=item expires

3600 is set by default.

=item need_commit

When you handle CDBI as AutoCommit-off, set 1.
0 is set by default.

=back

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Session::Manager>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

