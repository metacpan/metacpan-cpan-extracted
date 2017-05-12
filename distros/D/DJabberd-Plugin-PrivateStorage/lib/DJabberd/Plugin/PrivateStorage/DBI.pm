package DJabberd::Plugin::PrivateStorage::DBI;
use strict;
use base 'DJabberd::Plugin::PrivateStorage';
use warnings;

use DBI;
use DJabberd::Log;
our $logger = DJabberd::Log->get_logger();


# TODO allow to set a different table name

=head2 set_config_datasource($self, $val)

Set the DBI datasource that will be used to connect.
'dbi:' is automatically added, see the documentation of DBI
for more information.

=cut

sub set_config_datasource {
    my ($self, $val) = @_;
    $self->{datasource} = $val;
}

=head2 set_config_username($self, $val)

Set the username used to connect to the database.

=cut

sub set_config_username {
    my ($self, $val) = @_;
    $self->{username} = $val;
}

=head2 set_config_password($self, $val)

Set the password used to connect to the database.

=cut

sub set_config_password {
    my ($self, $val) = @_;
    $self->{password} = $val;
}

=head2 finalize($self)

Check that plugin was correctly initialized.
Try to connect to the database and create the table.

=cut

sub finalize {
    my $self = shift;
    die "No 'Database' configured'" unless $self->{datasource};
    my $dbh = DBI->connect_cached("dbi:$self->{datasource}",$self->{username}, $self->{password}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $self->{dbh} = $dbh;
    $self->check_install_schema;
    $self->{sth} = $dbh->prepare('SELECT content FROM private_storage WHERE username = ? AND namespace = ?');
    return $self;
}


=head2 check_install_schema($self)

Create the needed table, if it doesn't exist. This requires the 
proper privileges to the database.

=cut

sub check_install_schema {
    my $self = shift;
    my $dbh = $self->{dbh};

    eval {
        # TODO create a primary key
        $dbh->do(qq{
            CREATE TABLE private_storage (
                                username TEXT NOT NULL,
                                namespace  TEXT NOT NULL,
                                content TEXT
                                 );});
    };
    if ($@ && $@ !~ /table \w+ already exists/) {
        $logger->logdie("SQL error $@");
        die "SQL error: $@\n";
    }

    $logger->info("Created all roster tables");
}

=head2 load_privatestorage($self, $user,  $element)

Load the element $element for $user from memory.

=cut

sub load_privatestorage {
    my ($self, $user,  $element) = @_;
    $self->{sth}->execute($user,$element);
    my ($content) = $self->{sth}->fetchrow_array();
    return $content;
}

=head2 store_privatestorage($self, $user,  $element, $content)

Store $content for $element and $user in memory.

=cut

sub store_privatestorage {
    my ($self, $user, $element, $content) = @_;
    $content = $content->as_xml;
    $self->{sth}->execute($user,$element);
    if ($self->{sth}->fetchrow_array()) {
        $self->{dbh}->do(qq{
            UPDATE private_storage SET content = ? WHERE namespace = ?
            AND username = ?;}, undef,  $content, $element, $user
        );

    } else {
        $self->{dbh}->do(qq{
            INSERT INTO private_storage (username, namespace, content) 
            VALUES (?,?,?)}, undef,  $user, $element, $content
        );

    }
}
1;

__END__

=head1 NAME

DJabberd::Plugin::PrivateStorage::DBI - implement private storage, stored in DBI backend

=head1 SYNOPSIS

  <Plugin DJabberd::Plugin::PrivateStorage::DBI>
      Datasource DBI:mysql:database=djabberd;host=localhost
      Username test
      Password test
  </Plugin>

=head1 DESCRIPTION

This plugin is derived from DJabberd::Plugin::PrivateStorage. It implement a backend for private storage
in a DBI compliant database. A table name called private_storage will be created if it doesn't exist, 
with a simple schema. It was tested with sqlite, but it should be ok on most DBMS ( if the DBMS support TEXT ).

=head1 COPYRIGHT

This module is Copyright (c) 2006 Michael Scherer
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Michael Scherer <misc@zarb.org>
