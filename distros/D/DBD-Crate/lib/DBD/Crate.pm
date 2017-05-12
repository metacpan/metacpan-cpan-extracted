package DBD::Crate;
use strict;
use DBI;
use HTTP::Tiny;
use JSON::MaybeXS;
use vars qw($VERSION $REVISION);
use vars qw($err $errstr $state $drh);
$VERSION = "0.0.3";

$err     = 0;
$errstr  = "";
$state   = "";
$drh     = undef;
my $methods_are_installed = 0;
my ($HTTP, $JSON);

sub driver {
    return $drh if $drh;
    my ($class, $attr) = @_;
    $class .= "::dr";
    $drh = DBI::_new_drh($class, {
        'Name'        => 'Crate',
        'Version'     => $VERSION,
        'Err'         => \$err,
        'Errstr'      => \$errstr,
        'State'       => \$state,
        'Attribution' => 'DBD::Crate by Mamod Mehyar',
        'AutoCommit'  => 1
    }) or return undef;
    return $drh;
}

sub http { $HTTP }
sub json { $JSON }

#====================================================================
# DBD::Crate::dr
#====================================================================
package DBD::Crate::dr; {
    use strict;
    use DBI qw(:sql_types);
    use vars qw($imp_data_size);
    use Carp qw(carp croak);
    use Data::Dumper;
    use DBI;

    $imp_data_size = 0;

    sub connect {
        my ($drh, $dburl, $user, $pass, $attr) = @_;
        my $UTF8 = defined $attr->{utf8} ?
                        $attr->{utf8} : 1;

        $JSON = JSON::MaybeXS->new({ utf8 => $UTF8 });
        $HTTP = HTTP::Tiny->new( keep_alive => 1 );

        my @addresses = ($dburl);
        my @addr;
        if ($dburl =~ s/^\[(.*?)\]$/$1/){
            @addresses = split ',', $dburl;
        }

        foreach my $addr (@addresses){
            $addr =~ s/\s+//;
            if (!$addr){
                $addr = 'http://localhost:4200';
            }

            if ($addr !~ /^http/){
                $addr = 'http://' . $addr;
            }

            if ($user || $pass){
                my $auth = ($user || '') . ':' . ($pass || '');
                $addr =~ s/^(http(?:.)?:\/\/)(.*?)/$1$auth\@$2/;
            }
            push @addr, $addr;
        }

        my ($t, $dbh) = DBI::_new_dbh($drh, {
            'Name'   => \@addr
        });

        return $dbh;
    }

    sub data_sources { return "Cratedb" }
    sub disconnect_all { 1 }
};

#====================================================================
# DBD::Crate::db
#====================================================================
package DBD::Crate::db; {
    use strict;
    use base qw(DBD::_::db);
    use vars qw($imp_data_size);
    use Data::Dumper;
    use DBI;
    use Digest::SHA1  qw(sha1_hex);

    $imp_data_size = 0;

    sub prepare {
        my ($dbh, $statement, @attr) = @_;
        my $sth = DBI::_new_sth($dbh, {
            'Statement'      => $statement,
            'ConnectionHOST' => $dbh->{Name}
        });
        return $sth;
    }

    #=============================================================
    # blob methods
    #=============================================================
    sub crate_blob_insert {
        my ($dbh, $table, $digest, $content) = @_;

        if (!$content){
            $content = $digest;
            $digest = sha1_hex($content);
        }

        my $path = "/_blobs/$table/" . $digest;
        my $sth = DBI::_new_sth($dbh, {
            'REQUEST_PATH'   => $path,
            'REQUEST_METHOD' => 'PUT',
            'Statement'      => $content,
            'ConnectionHOST' => $dbh->{Name},
            'BLOB'           => 1,
            'DIGEST'         => $digest
        });

        return $sth->execute();
    };

    sub crate_blob_get {
        my ($dbh, $table, $digest) = @_;

        if (!$digest){
            $dbh->set_err(-1, "BLOB sha1 digest required");
            return;
        }

        $digest ||= '';

        my $path = "/_blobs/$table/" . $digest;
        my $sth = DBI::_new_sth($dbh, {
            'REQUEST_PATH'   => $path,
            'REQUEST_METHOD' => 'GET',
            'Statement'      => '',
            'ConnectionHOST' => $dbh->{Name},
            'BLOB'           => 1,
            'DIGEST'         => $digest
        });
        return $sth->execute();
    }

    sub crate_blob_delete {
        my ($dbh, $table, $digest) = @_;

        if (!$digest){
            $dbh->set_err(-1, "BLOB sha1 digest required");
            return;
        }

        my $path = "/_blobs/$table/" . $digest;
        my $sth = DBI::_new_sth($dbh, {
            'REQUEST_PATH'   => $path,
            'REQUEST_METHOD' => 'DELETE',
            'Statement'      => '',
            'ConnectionHOST' => $dbh->{Name},
            'BLOB'           => 1,
            'DIGEST'         => $digest
        });

        return $sth->execute();
    }

    #=============================================================
    # table info methods
    #=============================================================
    #return columns information of provided table
    sub crate_table_columns {
        my ($dbh, $table) = @_;
        my $sth = $dbh->prepare(qq~
            select column_name, data_type, ordinal_position
            from information_schema.columns
            where schema_name = 'doc'
            AND table_name = ?
        ~);

        return $dbh->selectall_arrayref( $sth,
            { Slice => {} },
            $table);
    }

    #list all tables with information
    sub crate_tables_list {
        my $dbh = shift;
        my $schema = shift || 'doc';
        my $sth = $dbh->prepare(qq~
            select number_of_replicas, partitioned_by, blobs_path, schema_name,
                   table_name, number_of_shards, clustered_by
                   from information_schema.tables
                   where schema_name = ?
        ~);

        return $dbh->selectall_arrayref( $sth,
            { Slice => {} },
            $schema);
    }

    #get table info
    sub crate_table_info {
        my $dbh   = shift;
        my $table = shift;
        my $sth = $dbh->prepare(qq~
            select number_of_replicas, partitioned_by, blobs_path, schema_name,
                   table_name, number_of_shards, clustered_by
                   from information_schema.tables
                   where schema_name = 'doc'
                   AND table_name = ?
        ~);

        return $dbh->selectrow_hashref( $sth,
            undef,
            $table);
    }

    #==================================================
    # These should be removed once we get crate name
    # space registered with DBI
    #==================================================
    *DBI::db::crate_blob_insert   = \&crate_blob_insert;
    *DBI::db::crate_blob_get      = \&crate_blob_get;
    *DBI::db::crate_blob_delete   = \&crate_blob_delete;
    *DBI::db::crate_table_columns = \&crate_table_columns;
    *DBI::db::crate_tables_list   = \&crate_tables_list;
    *DBI::db::crate_table_info    = \&crate_table_info;
};

#====================================================================
# DBD::Crate::st
#====================================================================
package DBD::Crate::st; {
    use strict;
    use base qw(DBD::_::st);
    use vars qw($imp_data_size);
    use Data::Dumper;
    use DBI;

    $imp_data_size = 0;

    sub _fetch_data {
        my $sth       = shift;
        my $statement = shift;
        my $method    = shift || 'POST';
        my $path      = shift || '/_sql';

        my @hosts = @{ $sth->{ConnectionHOST} };

        TRYAGAIN :
        my $host = shift @hosts;
        my $ret = DBD::Crate::http->request($method, $host . $path, {
            content => $statement,
            # headers => {'Content-Type' => 'application/json'}
        });

        if ( $ret->{status} == 599 && scalar @hosts){
            my $i = 0;
            for (@{ $sth->{ConnectionHOST} }){
                #put failing address to the end of hosts
                #this will work only on persistant environments
                if ( $host eq $_ ){
                    splice @{ $sth->{ConnectionHOST} }, $i, 1;
                    push @{ $sth->{ConnectionHOST} }, $_;
                }
                $i++;
            }
            goto TRYAGAIN;
        }

        if (!$ret->{success}){
            my $olderr = $@;
            my $data = eval { DBD::Crate::json->decode($ret->{content}) };
            $@ = $olderr;

            my $error = ref $data eq 'HASH' && ref $data->{error} ? $data->{error} : {
                code    => ref $data ? $data->{status} : $ret->{status},
                message => ref $data ? $data->{error}  : ($ret->{content} || $ret->{reason})
            };

            $sth->set_err($error->{code}, $error->{message});
            return;
        }

        return $ret;
    }

    sub execute {
        my $sth = shift;
        my $statement = $sth->{Statement};
        my $ret;
        if ($sth->{BLOB}){
            if (!$sth->{DIGEST}){
                $sth->set_err(-1, "BLOB sha1 digest required");
                return;
            }

            $ret = _fetch_data($sth, $statement,
                                $sth->{REQUEST_METHOD},
                                $sth->{REQUEST_PATH}) or return;
        } else {
            my $hash = {stmt => $statement };
            if (@_){ $hash->{args} = \@_; }
            my $json = DBD::Crate::json->encode($hash);
            $ret = _fetch_data($sth, $json, 'POST', '/_sql') or return;
        }

        $sth->{'driver_raw_data'} = $ret->{content};
        if ($sth->{BLOB}){
            if ($ret->{status} == 201){ # put success
                return $sth->{DIGEST};
            } elsif ($ret->{status} == 200){ #get success
                return $ret->{content};
            } elsif ($ret->{status} == 204){ #delete success
                return 1;
            }
        }

        my $olderr = $@;
        my $data = eval { DBD::Crate::json->decode($ret->{content}) };
        if (!$data){
            my $error = $@;
            $@ = $olderr;
            $sth->set_err(-1, $error);
            return;
        }


        $sth->{'driver_data'} = $data->{rows};
        $sth->{'driver_rows'} =  $data->{rowcount};

        $sth->{'NAME'} = $data->{cols};
        $sth->STORE('NUM_OF_FIELDS', scalar @{ $data->{cols} });
        return $data->{rowcount} || '0E0';
    }

    *fetch = \&fetchrow_arrayref;
    sub fetchrow_arrayref {
        my $sth = shift;
        my $data = $sth->FETCH('driver_data');
        my $row = shift @$data or return;
        return $sth->_set_fbav($row);
    }

    sub raw {
        my $sth = shift;
        my $data = $sth->FETCH('driver_raw_data');
        return $data;
    }

    *DBI::st::raw = \&raw;

    #Nothing to close, crate is stateless
    sub close {}
};


1;

__END__

=head1 NAME

DBD::Crate - DBI driver for Crate db

=head1 SYNOPSIS

    use DBI;
    my $dbh = DBI->connect('dbi:Crate:' );
    my $sth = $dbh->prepare( 'SELECT id, content FROM articles WHERE id > 2' );
    my $res = $sth->execute;

    $sth->bind_columns (\my ($id, $content));
    while ($sth->fetch) {
        print "id: $id, content: $content\n";
    }

    print "Toatal ", $res, "\n";

=head1 DESCRIPTION

DBD::Crate is a DBI driver for L<Crate DB|https://Crate.io>, DBD::Crate is still
in early development so any feedback is much appreciated.

=head1 ABOUT CRATE

If you haven't heard of Crate I suggest you to give it a try, it's a is a
distributed data store With SQL query support, and fulltext seach based
on Elasticsearch, please read this L<overview|https://crate.io/overview/>

=head1 Methods

=over

=item B<connect>

    use DBI;

    my $dbh = DBI->connect(DBI:Crate:"); #<- [localhost:4200] defaults
    my $dbh = DBI->connect("DBI:Crate:localhost:5000"); #<-- localhost port 5000
    my $dbh = DBI->connect("DBI:Crate:", '', '', { utf8 => [0|1] });

IP:PORT address of Crate server to which you need to connect to, if not available,
localhost and default port [4200] will be used.

Crate does't have builtin user permissions or ACL concept, but some times you may
use it behind a proxy with user authintication

    my $dsn = DBI->connect("DBI:Crate:123.99.76.3:5000", 'user', 'pass');

This will issue a request with Basic-style user:pass authintication, in the example
folder you can find a plack proxy example with basic authintication, you can also
read Crate post on how to set a proxy behind ngix L<here|https://crate.io/blog/readonly-crate-with-nginx-and-lua/>

B<DBD::Crate> has a simple fail over setup with multi servers

    my $dbh = DBI->connect("DBI:Crate:[localhost:4200, localhost:42001, ...]");

Since Crate DB will handle distributing the job to the best available server for you, we only
implement a simple fail over process, it check if the first connection failed, we will try
the next one and append the failed host to the end of the list.

=item B<raw>

Sometimes you need to get raw json data, maybe to send as jsonp response

    $sth->raw;

The returned data will be of json format as the following

    {"cols" : ["id","content"], "duration" : 0, "rows" : [ [1, "content"], ... ], "rowcount" : 2}

=back

=head1 BLOB Methods

Crate includes support to store binary large objects (L<BLOBS|https://crate.io/docs/stable/blob.html>)

=over

=item B<crate_blob_insert>

    $dbh->crate_blob_insert("blobtable", [sh1-digest], data);

C<crate_blob_insert> accepts three arguments, blob table name, sha1 hex digest of data, and data tp store.
sha1 hex digest argument is optional in which DBD::Crate will create the digest for you

    my $digest = $dbh->crate_blob_insert("blobtable", data);

C<crate_blob_insert> returns the sha1 hex digest of the data stored on success or undef on failure
and set C<$dbh-E<gt>errstr> & C<$dbh-E<gt>err>

=item B<crate_blob_get>

    $dbh->crate_blob_get("blobtable", "sha1 digest");

returns stored data, in C<blobtable> with C<sha1 digest> previously used to store data, on error
returns undef, and set C<$dbh-E<gt>errstr> & C<$dbh-E<gt>err>

=item B<crate_blob_delete>

    $dbh->crate_blob_delete("blobtable", "sha1 digest");

Delete blob, returns true on success, undef on failure and set C<$dbh-E<gt>errstr> & C<$dbh-E<gt>err>

=back

=head1 Table Info Method

    my $tables = $dbh->crate_tables_list();
    my $table = $dbh->crate_table_info("tablename");
    my $columns = $dbh->crate_table_columns("tablename");

=over

=item B<crate_tables_list>

    $dbh->crate_tables_list(schema);

Accepts table schema argument [optional] if not provided will fetch tables from default
C<doc> schema, to get blobs tables list, use C<blob> schema

    $dbh->crate_tables_list("blob");

return a list of tables under schema with information

    [
        {
            'number_of_replicas' => '0-all',
            'partitioned_by' => undef,
            'blobs_path' => undef,
            'schema_name' => 'doc',
            'table_name' => 'articles',
            'number_of_shards' => 5,
            'clustered_by' => 'id'
        },
        {
            ...
        }
    ];

=item B<crate_table_info>

    $dbh->crate_table_info("tablename");

Same as C<crate_tables_list> but returns single hash ref reult for the C<tablename>

=item B<crate_table_columns>

    my $columns = $dbh->crate_table_columns("tablename");

returns list of table columns

    [
      {
        'data_type' => 'string',
        'column_name' => 'content',
        'ordinal_position' => 1
      },
      {
        'data_type' => 'string',
        'column_name' => 'description',
        'ordinal_position' => 2
      },
      {
        'data_type' => 'integer',
        'column_name' => 'id',
        'ordinal_position' => 3
      }
    ]

=back

=head1 IMPORTANT NOTES

=head2 Pimary keys

Crate doesn't auto generate primary keys, you need to provide a unique key by your
self and it must be **ehem** UNIQUE :)

=head2 last inserted id

Well, there is also no way to get the last inserted id, for the obvious
reason mentioned above I guess, but you can query that if you want in a
new statement

=head1 INSTALLATION & TEST

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

OR

    cpan install DBD-Crate

If you want to run the complete test suite, you need to have
Crate DB installed and running, then set environment variable
CRATE_HOST to crate "ip:port"

on windows

    $ set CRATE_HOST=127.0.0.1:4200

on linux

    $ export CRATE_HOST=127.0.0.1:4200

=head1 See Also

=over 8

=item L<Crate.io|https://crate.io>

=item L<Crate Docs|https://crate.io/docs/stable/>

=back

=head1 AUTHOR

Mamod A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself
