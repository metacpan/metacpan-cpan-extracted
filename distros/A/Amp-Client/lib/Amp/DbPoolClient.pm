package Amp::DbPoolClient;
use Moo;
use Amp::Util::Strings;
use Try::Catch;
use Carp;
use Data::Dumper;
use REST::Client;
use Sys::Hostname;
use feature 'say';

BEGIN{
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

has config => (is => 'rw', required => 1);
has host => (is => 'rw');
has url => (is => 'rw');
has instanceName => (is => 'rw');
has resultSet => (is => 'rw');
has payload => (is => 'rw', default => sub {{}});
has retries => (is => 'rw', default => 10);
has timeout => (is => 'rw', default => 30);
has retriesAttempted => (is => 'rw', default => 0);
has type => (is => 'rw', default => 'master');

sub getSqlRow {
    my $self = shift;
    my ($sql) = @_;
    my $results = $self->query($sql);
    if (defined $results) {
        return $results->[0];
    }
}

sub getSqlRows {
    my $self = shift;
    my ($sql) = @_;
    return $self->query($sql);
}

sub getSqlValue {
    my $self = shift;
    my ($sql) = @_;
    $self->payload->{getSqlValue} = 1;
    my $results = $self->query($sql);
    if (defined $results) {
        return $results->[0];
    }
}

sub getSqlValues {
    my $self = shift;
    my ($sql) = @_;
    $self->payload->{getSqlValues} = 1;
    my $results = $self->query($sql);
    if (defined $results) {
        return $results;
    }
}

sub getSqlRowHashref {
    my $self = shift;
    my ($sql) = @_;
    return $self->getSqlRow($sql);
}

sub getSqlRowsColumns {
    my $self = shift;
    my ($sql) = @_;
    $self->payload->{getSqlRowsColumns} = 1;
    my $results = $self->query($sql);
    if (defined $results) {
        return ($results->{rows}, $results->{columns});
    }
}

sub query {
    my $self = shift;
    my $sql = shift;
    $self->payload->{sql} = $sql;
    return $self->__exec();
}

sub queryUserData {
    my $self = shift;
    my $user = shift;
    $self->payload->{user} = $user;
    return $self->__exec();
}

sub getUser {
    my $self = shift;
    my $user = shift;
    return $self->queryUserData($user);
}

sub getEnvConfig {
    my $self = shift;
    $self->payload->{envconfig} = 1;
    return $self->__exec();
}

sub do {
    my $self = shift;
    my ($sql, $options, @params) = @_;
    $self->payload->{sql} = $sql;
    if (scalar(@params)) {
        $self->__prepateStatement($sql, @params);
    }
    return $self->__exec() if !$options->{execute};
}

sub prepare {
    my $self = shift;
    my $sql = shift;
    # Return a new instance to handle this transaction
    my $sth = getDashDbPoolHandle();
    $sth->payload->{sql} = $sql;
    return $sth;
}

sub execute {
    my $self = shift;
    $self->do($self->payload->{sql}, { execute => 1 }, @_);
}

sub fetchrow_array {
    my $self = shift;
    if (!$self->resultSet && $self->payload->{sql}) {
        $self->resultSet($self->getSqlValues($self->payload->{sql}));
    }
    my $val = shift @{$self->resultSet};
    return $val;
}

sub fetchrow_hashref {
    my $self = shift;
    if (!$self->resultSet && $self->payload->{sql}) {
        $self->resultSet($self->getSqlRows($self->payload->{sql}));
    }
    my $val = shift @{$self->resultSet};
    return $val;
}

sub statement {
    my $self = shift;
    return $self->payload->{sql};
}

sub finish {
    return 0;
}

sub __prepateStatement {
    my $self = shift;
    my $sql = shift;
    my (@params) = @_;
    my @replacements;

    # find all the ? positions to replace
    while ($sql =~ m/\?/g) {
        push @replacements, pos($sql);
    }

    # validate the params given match the number of ? to replace
    if (scalar(@replacements) != scalar(@params)) {
        die "SQL has " . scalar(@replacements) . " parameters but " . scalar(@params) . " were given\n";
    }

    # Set the index mark to match the size of the @params for iterating through the replacements
    my $i = (scalar(@params) - 1);
    for my $pos (reverse @replacements) {
        my $val = $self->quote($params[$i]);
        substr($sql, $pos - 1, 1, $val);
        $i--;
    }
    $self->payload->{sql} = $sql;
    $self->{Statement} = $sql;
    return $sql;
}

sub __exec {
    my $self = shift;

    if ($self->type && $self->type =~ m/^(readonly|any|master)$/) {
        $self->payload->{handleType} = $self->type;
    }

    delete $self->{mysql_insertid} if $self->{mysql_insertid};

    # Trim all the values to remove whitespace at beginning and end
    for (keys %{$self->payload}) {$self->payload->{$_} = Amp::Util::Strings->clean($self->payload->{$_});}

    my $data = $self->__sendRequest();

    # Reset the payload hash
    $self->payload({});

    if (ref($data) eq 'HASH' && $data->{error}) {
        print STDERR $data->{error};
        return;
    }
    if (ref($data) eq 'HASH' && $data->{mysql_insertid}) {
        $self->{mysql_insertid} = $data->{mysql_insertid};
    }
    return $data;
}

sub __sendRequest {
    my $self = shift;
    my $client = $self->client;
    my $attempts = $self->retriesAttempted();
    my $retryIfNeeded = $attempts < $self->retries;
    $client->POST($self->url, Amp::Util::Strings->json_encode($self->payload));
    my $data;

    my $warning = sub {
        warn("[" . $self->host . "] " . $client->responseCode() . " " . $client->responseContent());
        return [];
    };

    if ($client->responseCode() == 200) {
        $data = Amp::Util::Strings->json_decode($client->responseContent());
    }
    elsif ($client->responseCode() == 500 && $retryIfNeeded) {
        if ($client->responseContent() =~ m/Server closed connection without sending any data back/) {
            return $warning->();
        }
        elsif ($client->responseContent() =~ m/Transaction Error:/) {
            return $warning->();
        }
        else {
            $self->retriesAttempted($attempts + 1);
            print STDERR "Retrying query to " . $self->host . $self->url . " in 1 second\n";
            sleep 1;
            return $self->__sendRequest();
        }
    }
    else {
        return $warning->();
    }
    $self->retriesAttempted(0);
    return $data;
}

sub addSql {
    my $self = shift;
    my $sql = shift;
    $self->payload->{sql} = $sql;
}

sub addParam {
    my $self = shift;
    my $param = shift;
    push(@{$self->payload->{params}}, $param)
}

sub addOnUpdate {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->payload->{onUpdate}->{$key} = $value;
}

sub quote {
    my $self = shift;
    my $param = shift;

    return Amp::Util::Strings->quote($param);
}

sub ping {
    my $self = shift;

    # nothing to do here since an existing connection is used
    return 1;
}

sub client {
    my $self = shift;
    # Check to see if an instance name was provided and setup the host/url
    $self->checkForRemotePoolConnection();
    # Setup the pool client
    my $client = REST::Client->new();
    $client->setTimeout($self->timeout);
    $client->addHeader('AMP-API-KEY', $self->config->key);
    $client->setHost($self->host);

    return $client;
}

sub checkForRemotePoolConnection {
    my $self = shift;
    if ($self->instanceName()) {
        # If not found by instance name, try the name field which is sometimes different
        my $address = $self->config->getEnv($self->instanceName);
        $self->host($address);
        $self->url('/db-pool-svc');
    }
    elsif ($self->host) {
        $self->url('/db-pool-svc');
    }
    else {
        # Query to the local host at specific port. This query will work on non-apache hosts running the
        # dbpool server
        $self->host('http://0.0.0.0:9395');
        $self->url('/');
    }
}

1;