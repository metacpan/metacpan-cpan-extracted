package BBS::Universal::DB;
BEGIN { our $VERSION = '0.002'; }

sub db_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start DB Initialize']);
    $self->{'debug'}->DEBUG(['End DB Initialize']);
    return ($self);
} ## end sub db_initialize

sub db_connect {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start DB Connect']);
    my @dbhosts = split(/\s*,\s*/, $self->{'CONF'}->{'STATIC'}->{'DATABASE HOSTNAME'});
    my $errors  = '';
    foreach my $host (@dbhosts) {
        $errors = '';

        # This is for the brave that want to try SSL connections.
        #
        #    $self->{'dsn'} = sprintf('dbi:%s:database=%s;' .
        #        'host=%s;' .
        #        'port=%s;' .
        #        'mysql_ssl=%d;' .
        #        'mysql_ssl_client_key=%s;' .
        #        'mysql_ssl_client_cert=%s;' .
        #        'mysql_ssl_ca_file=%s',
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE TYPE'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE NAME'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE HOSTNAME'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE PORT'},
        #        TRUE,
        #        '/etc/mysql/certs/client-key.pem',
        #        '/etc/mysql/certs/client-cert.pem',
        #        '/etc/mysql/certs/ca-cert.pem'
        #    );
        $self->{'dsn'} = sprintf('dbi:%s:database=%s;' . 'host=%s;' . 'port=%s;', $self->{'CONF'}->{'STATIC'}->{'DATABASE TYPE'}, $self->{'CONF'}->{'STATIC'}->{'DATABASE NAME'}, $host, $self->{'CONF'}->{'STATIC'}->{'DATABASE PORT'},);
        $self->{'dbh'} = DBI->connect(
            $self->{'dsn'},
            $self->{'CONF'}->{'STATIC'}->{'DATABASE USERNAME'},
            $self->{'CONF'}->{'STATIC'}->{'DATABASE PASSWORD'},
            {
                'PrintError' => FALSE,
                'RaiseError' => TRUE,
                'AutoCommit' => TRUE,
            },
        ) or $errors = $DBI::errstr;
        last if ($errors eq '');
    } ## end foreach my $host (@dbhosts)
    if ($errors ne '') {
        $self->{'debug'}->ERROR(["Database Host not found!\n$errors"]);
        exit(1);
    }
    $self->{'debug'}->DEBUG(['End DB Connect']);
    return (TRUE);
} ## end sub db_connect

sub db_count_users {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start DB Count Users']);
    unless (exists($self->{'dbh'})) {
        $self->db_connect();
    }
    my $response = $self->{'dbh'}->do('SELECT COUNT(id) FROM users');
    $self->{'debug'}->DEBUG(['End DB Count Users']);
    return ($response);
} ## end sub db_count_users

sub db_disconnect {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start DB Disconnect']);
    $self->{'dbh'}->disconnect() if (defined($self->{'dbh'}));
    $self->{'debug'}->DEBUG(['End DB Disconnect']);
    return (TRUE);
} ## end sub db_disconnect
1;
