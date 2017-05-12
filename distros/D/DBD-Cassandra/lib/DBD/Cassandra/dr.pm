package DBD::Cassandra::dr;
use 5.010;
use strict;
use warnings;

use Cassandra::Client 0.10;

# "*FIX ME* Explain what the imp_data_size is, so that implementors aren't
#  practicing cargo-cult programming" - DBI::DBD docs
$DBD::Cassandra::dr::imp_data_size = 0;

sub connect {
    my ($drh, $dr_dsn, $user, $auth, $attr)= @_;

    # Iterate through the DSN, write to $attr
    my $driver_prefix= 'cass_';
    for my $var (split /;/, $dr_dsn) {
        my ($attr_name, $attr_val)= split '=', $var, 2;
        return $drh->set_err($DBI::stderr, "Can't parse DSN part '$var'")
            unless defined $attr_val;

        $attr_name= "cass_$attr_name" unless $attr_name =~ /\A$driver_prefix/o;

        $attr->{$attr_name}= $attr_val;
    }

    my $keyspace= delete $attr->{cass_database} || delete $attr->{cass_db} || delete $attr->{cass_keyspace};
    my $host= delete $attr->{cass_host} || delete $attr->{cass_hostname} || delete $attr->{cass_hosts} || delete $attr->{cass_hostnames} || 'localhost';
    my $hosts= [ grep $_, split /,/, $host ];
    my $port= delete $attr->{cass_port} || 9042;
    my $global_consistency= delete $attr->{cass_consistency};
    my $compression= delete $attr->{cass_compression};
    my $cql_version= delete $attr->{cass_cql_version};
    my $read_timeout= delete $attr->{cass_read_timeout};
    my $write_timeout= delete $attr->{cass_write_timeout};
    my $connect_timeout= delete $attr->{cass_connect_timeout}; #XXX
    my $request_timeout= delete $attr->{cass_request_timeout};
    my $tls= delete $attr->{cass_tls};
    if ($read_timeout || $write_timeout) {
        if ($request_timeout) {
            warn 'Ignoring read_timeout and write_timeout settings, as request_timeout is passed';
        } else {
            $request_timeout= ($read_timeout || 6) + ($write_timeout || 6);
        }
    }

    my $client= Cassandra::Client->new(
        contact_points => $hosts,
        port => $port,
        username => $user,
        password => $auth,
        keyspace => $keyspace,
        compression => $compression,
        default_consistency => $global_consistency,
        cql_version => $cql_version,
        request_timeout => $request_timeout,
        anyevent => 0,
        tls => $tls,
    );
    my ($error)= $client->call_connect;
    return $drh->set_err($DBI::stderr, "Can't connect to $dr_dsn: $error") if $error;

    my ($outer, $dbh)= DBI::_new_dbh($drh, { Name => $dr_dsn });

    $dbh->STORE('Active', 1);
    $dbh->{cass_client}= $client;

    return $outer;
}

sub data_sources {
    my ($drh, $attr)= @_;
    my @array= (qw/dbi:Cassandra/);
    return @array;
}

sub disconnect_all {
    # TODO: not needed?
}

1;
