# $Id: JDBC.pm,v 1.49 2008/12/17 00:05:23 gemerson Exp $
#
#  Copyright 1999-2001,2005,2008 Vizdom Software, Inc. All Rights Reserved.
#  
#  This program is free software; you can redistribute it and/or 
#  modify it under the same terms as the Perl Kit, namely, under 
#  the terms of either:
#  
#      a) the GNU General Public License as published by the Free
#      Software Foundation; either version 1 of the License, or 
#      (at your option) any later version, or
#  
#      b) the "Artistic License" that comes with the Perl Kit.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
# either the GNU General Public License or the Artistic License
# for more details.

# There's a warning in (some) later versions of Perl about the 
# string used here in require, so try to ignore that.

{ no warnings qw(portable); require 5.8.0; }

{
    package DBD::JDBC;
    use DBI 1.48;
    require Exporter; 
    @ISA = qw(Exporter); 

    # DBI 1.54 added SQL_BIGINT back.
    if ($DBI::VERSION > 1.54) {
        %EXPORT_TAGS = ( sql_types => [ ], ); 
        @EXPORT_OK = ();
    }
    else {
        %EXPORT_TAGS = ( sql_types => [ qw( SQL_BIGINT ) ], ); 
        @EXPORT_OK = qw(SQL_BIGINT);
    }


    use vars qw($methods_installed); 

    $DBD::JDBC::VERSION = '0.71';
    
    $DBD::JDBC::drh = undef;

    # Driver handle constructor. This is pretty much straight
    # from the DBD doc.
    sub driver {
        return $drh if $drh;
        my($class, $attr) = @_;
        DBI->setup_driver('DBD::JDBC');
        $class .= "::dr";
        ($drh) = DBI::_new_drh($class, {
            'Name' => 'JDBC',
            'Version' => $VERSION,
            'Attribution' => "DBD::JDBC $VERSION by Gennis Emerson",
        });
        if (!$methods_installed++) {
            DBD::JDBC::db->install_method('jdbc_func', {});
            DBD::JDBC::st->install_method('jdbc_func', {});
            DBD::JDBC::db->install_method('jdbc_disconnect', {});
        }
        $drh;
    }


    # This will dump the BER buffer to STDERR in a rather verbose way. 
    #
    # args: the BER buffer, as a string
    # returns: nothing
    sub _dump {
        my ($str) = shift;
        my ($b, $result);
        my ($pos) = 0; 
        my ($upper) = shift || length($str);
        do {
            $b = CORE::unpack("C",substr($str,$pos++,1));
            $result .= join('', unpack("B*", chr($b))) . 
                " (" . chr($b) .  ") | ";
        } while($pos < $upper);
        print STDERR "$result\n";
    }


    # This is a utility which handles the tedious part of
    # sending a message to the server and decoding the
    # response. If an error occurs, this function will use
    # DBI::set_err and return undef. 
    #
    # args: 
    #   $h: a DBI object handle; used for debugging and error reporting
    #   $socket: the server socket
    #   $ber: a BER object for encoding and decoding messages
    #   $encode_list: an array reference containing the arguments 
    #                 for the BER encode
    #   $decode_list: an array reference containing the arguments for
    #                 the BER decode method
    #
    # returns: true on success, false (and calls $h->set_err) on failure
    sub _send_request { 
        my ($h, $socket, $ber, $encode_list, $decode_list, $method, 
            $avoid_set_err) = @_;
        my $debug = $h->trace();


        $ber->buffer("");
        $h->trace_msg("Encoding [" . join(" | ", @$encode_list) . "]\n", 3) 
            if $debug;
        $ber->encode(@$encode_list);

        local($SIG{PIPE}) = "IGNORE";
        $h->trace_msg("Sending request to server\n", 3) if $debug;
        $ber->write($socket); 
        if ($@) {
            die $@ if $avoid_set_err;
            return $h->set_err(DBD::JDBC::ErrorMessages::send_error($@));
        }

        $h->trace_msg("Listening for response\n", 3) if $debug;
        $ber->read($socket);
        if ($@) {
            die $@ if $avoid_set_err;
            return $h->set_err(DBD::JDBC::ErrorMessages::recv_error($@));
        }
        $h->trace_msg("Received response from server\n", 3) if $debug;

        my $err;
        my $tag = $ber->tag();
        if ($tag == $ber->ERROR_RESP()) {
            my (@errors);
            $ber->decode(ERROR_RESP => \@errors);
            $ber->buffer("");
            if ($err = $ber->error()) {
                $h->trace_msg("Error decoding response from server: $err", 3)
                    if $debug;
                $ber->[ Convert::BER::_ERROR() ] = "";
                die $err if $avoid_set_err;
                return
                   $h->set_err(DBD::JDBC::ErrorMessages::ber_error($err));
            }
            $h->{jdbc_error} = []; # Reset the error list.
            push @{$h->{jdbc_error}}, @errors;
            $h->trace_msg("Error: ".$errors[0]->{errstr}."\n", 3) if $debug;
            die $errors[0]->{errstr} if $avoid_set_err;
            return $h->set_err($errors[0]->{err}, $errors[0]->{errstr}, 
                                    substr($errors[0]->{state}, 0, 5), $method);
        }
        else {
            $h->trace_msg("Decoding [" . join(" | ", @$decode_list) . "]\n", 3)
                if $debug;
            $ber->decode(@$decode_list);
            $ber->buffer("");
            if ($err = $ber->error()) {
                $h->trace_msg("Error decoding response from server: $err", 3)
                    if $debug;
                $ber->[ Convert::BER::_ERROR() ] = "";
                die $err if $avoid_set_err;
                return 
                   $h->set_err(DBD::JDBC::ErrorMessages::ber_error($err));
            }
            return 1;
        }
    }


    # JDBC constants. Since these seem to be based on values
    # from the SQL standard, I don't feel too bad about
    # hard-coding them here.
    %DBD::JDBC::Types = (NULL => 0,
                         CHAR => 1,
                         NUMERIC => 2,
                         DECIMAL => 3,
                         INTEGER => 4,
                         SMALLINT => 5,
                         FLOAT => 6,
                         REAL => 7,
                         DOUBLE => 8,
                         VARCHAR => 12,
                         LONGVARCHAR => -1,
                         BINARY => -2,
                         VARBINARY => -3,
                         LONGVARBINARY => -4,
                         BIGINT => -5,
                         TINYINT => -6,
                         DATE => 91,
                         TIME => 92,
                         TIMESTAMP => 93,
                         BIT => -7,
                         OTHER => 1111,
                         JAVA_OBJECT => 2000,
                         DISTINCT => 2001,
                         STRUCT => 2002,
                         ARRAY => 2003,
                         BLOB => 2004, 
                         CLOB => 2005, 
                         REF => 2006,
              );

    # DBI no longer defines this value due to a lack of desire to
    # choose between SQL and ODBC. Since JDBC uses it, we need to
    # define it separately.
    sub SQL_BIGINT() { -5 };
}


{
    package DBD::JDBC::dr;

    # imp_data_size, according to the DBD doc, is used by DBI and
    # should be set here. 0 is a default which means something
    # like 'no size limit imposed'.
    $imp_data_size = 0;
    $imp_data_size = 0; # Avoid -w warnings.
    use strict;
    use IO::Socket;

    *_send_request = \&DBD::JDBC::_send_request;

    # Opens a socket connection to the host/port specified in the
    # dsn, sends a connection request to the server-side JDBC
    # driver, and returns a new database handle. Parameters which
    # can be specified in the DSN: 
    #  hostname: the DBD::JDBC server host; may be in the form name:port
    #  port: the DBD::JDBC server port
    #  url: the JDBC URL to pass to the JDBC driver
    #  jdbc_character_set: a Java character encoding name; should
    #    be the client's (the Perl application's) character encoding
    #
    # Arbitrary JDBC connection properties can be specified by
    # passing a hash reference as the value of the
    # "jdbc_properties" key in the attributes hash in the
    # DBI->connect method.
    #
    # If the user and password values passed to this method in
    # the DBI->connect call are undefined, the server will use
    # the DriverManager.getConnection(String, Properties)
    # method. Otherwise, the server will use the
    # DriverManager.getConnection(String, String, String) method.
    #
    # args
    #  $drh: driver handle
    #  $dsn: dsn
    #  $user: username; may be undef
    #  $auth: password; may be undef
    #  $attr: hash reference of connection properties
    #
    # JDBC: DriverManager.getConnection, Connection.setXXX
    sub connect {
        my ($drh, $dsn, $user, $auth, $attr) = @_;

        my $debug = DBI->trace(); 

        # Any ; or = characters in the url must be escaped using
        # http url escape syntax (e.g., an url of foo=bar becomes
        # foo%3Dbar). The driver will unescape the url portion of
        # the dsn. dsn format: 
        #   hostname=<host>[:port];[port=<port>;]url=<url>[;jdbc_character_set=<encoding>]

        my %dsn = split /[;=]/, $dsn;
        my $hostname = $dsn{'hostname'};
        my $port     = $dsn{'port'};
        my $url      = $dsn{'url'};
        my $encoding = $dsn{'jdbc_character_set'} || "ISO8859_1";
        if ($hostname && !$port) {
            ($hostname, $port) = split /:/, $hostname;
        }
        $url =~ s/%(3[bBdD])/pack("c", hex($1))/ge;   # (; is 0x3b, = is 0x3d)
        my %properties;
        if ($attr && $attr->{'jdbc_properties'}) {
            %properties = %{ $attr->{'jdbc_properties'} };
        }
        else {
            %properties = ();
        }
        return $drh->set_err(
                  DBD::JDBC::ErrorMessages::missing_dsn_component('hostname'))
            unless $hostname;
        return $drh->set_err(
                  DBD::JDBC::ErrorMessages::missing_dsn_component('port'))
            unless $port;
        return $drh->set_err(
                  DBD::JDBC::ErrorMessages::missing_dsn_component('url'))
            unless $url;

        # Connect to the server.
        my $socket = IO::Socket::INET->new(PeerAddr => $hostname, 
                                           PeerPort => $port,
                                           Proto => 'tcp');

        return $drh->set_err(DBD::JDBC::ErrorMessages::socket_error($@)) 
            if !$socket;

        my ($ber) = new DBD::JDBC::BER;

        my $response;
        return undef unless
            _send_request($drh,
                          $socket, $ber, 
                          [CONNECT_REQ => [STRING => $url, 
                                           ($user?'STRING':'NULL') => $user, 
                                           ($auth?'STRING':'NULL') => $auth,
                                           STRING => $encoding,
                                           HASH => [STRING => [%properties]]]],
                          [CONNECT_RESP => \$response]);


        # Create $dbh after we know connect succeeded. If this
        # method fails while using $h->set_err after $dbh has been
        # created, and the calling script checks for errors using
        # $DBI::{err,errstr,state} in a separate statement from
        # the call to connect, the undefined $dbh will somehow be
        # the last-used handle and cause an error. That's my best
        # theory, anyway.

        my ($dbh) = DBI::_new_dbh($drh, {
            'Name' => $dsn,
        });

        $dbh->STORE('Active' => 1);
        $dbh->STORE('jdbc_socket' => $socket);
        $dbh->STORE('jdbc_ber' => $ber);
        $dbh->STORE('jdbc_character_set' => $encoding);
        $dbh->STORE('jdbc_url' => $url); 
        # The connection list is used by disconnect_all.
        my ($conns) = $drh->FETCH('jdbc_connections') || [];
        push @$conns, $dbh;
        $drh->STORE('jdbc_connections' => $conns);
        my $lra = $drh->FETCH('jdbc_longreadall');
        $dbh->STORE('jdbc_longreadall' => ((defined $lra) ? $lra : 1));

        $dbh;
    }


    # This method is required to return usable dsn's, and JDBC
    # doesn't provide any sort of 'getURL' method. Available
    # drivers is about the best we could do. We also currently
    # have no way of knowing the server's host and port.
    sub data_sources {
        ();
    }


    # Added in DBI 1.42. Not currently implemented here.
    sub parse_trace_flag {
        my ($flag) = shift;
        return DBI->parse_trace_flag($flag);
    } 


    # All cached database handles will be disconnected. The
    # handles will be removed from the cache even if the
    # disconnect call fails so they can be garbage
    # collected. This may be called by the user, but is more
    # likely to be called by DBI's END block on shutdown.
    #
    # Args: none
    # Return value: none
    sub disconnect_all {
        my ($drh) = shift;
        my ($conns) = $drh->FETCH('jdbc_connections');
        return unless $conns;

        $drh->trace_msg("Found ".scalar(@$conns)." connections to close\n", 3);

        my ($conn, $name);
        while ($conn = shift @$conns) {
            $name = $conn->{'Name'};
            $drh->trace_msg("Disconnecting $name\n", 3);
            $conn->disconnect() ||
                $drh->trace_msg("Failed to disconnect $name: " . 
                                ($drh->errstr ? $drh->errstr : "") . "\n", 3);
        }
    }

    sub STORE {
        my ($drh, $attr, $value) = @_;

        if ($attr =~ /^jdbc_/) {
            $drh->{$attr} = $value;
            return 1;
        }

        $drh->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($drh, $attr) = @_;
        if ($attr =~ /^jdbc_/) {
            return $drh->{$attr};
        }

        $drh->SUPER::FETCH($attr);
    }
}



{
    package DBD::JDBC::db;


    $imp_data_size = 0;
    $imp_data_size = 0; # Avoid -w warnings.
    use strict;

    *_send_request = \&DBD::JDBC::_send_request;

    # Prepares a statement for execution.
    # 
    # JDBC: Connection.prepareStatement
    sub prepare {
        my ($dbh, $statement, $params) = @_;
        my ($debug) = $dbh->trace();
        
        my ($keyType, $keyTypeCode, $keyList) = (undef, 'STRING', []); 
        if ($params && $params->{'jdbc_columnnames'}) {
            $keyType = "name"; 
            $keyList = $params->{'jdbc_columnnames'}; 
        }
        elsif ($params && $params->{'jdbc_columnindexes'}) {
            $keyType = "index"; 
            $keyTypeCode = 'INTEGER';
            $keyList = $params->{'jdbc_columnindexes'}; 
        }

        my ($statement_handle);
        return undef unless
            _send_request($dbh,
                          $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                          [PREPARE_REQ => [STRING => $statement, 
                                           ($keyType?'STRING':'NULL') => $keyType, 
                                           $keyTypeCode => [@$keyList] ] ],
                          [PREPARE_RESP => \$statement_handle]);
        
        my $param_count = _count_params($statement); 
        my $sth = DBI::_new_sth($dbh, {
            'Statement' => $statement,
            'NUM_OF_PARAMS' => $param_count,
            'NUM_OF_FIELDS' => undef,
        });

        $sth->STORE('jdbc_handle' => $statement_handle);
        $sth->STORE('jdbc_socket' => $dbh->FETCH('jdbc_socket'));
        $sth->STORE('jdbc_ber' => $dbh->FETCH('jdbc_ber'));
        $sth->STORE('jdbc_rowcount' => -1);

        ## Set up ParamValues (DBI 1.28). Initialize the keys to the
        ## parameter numbers (if any).
        $sth->STORE('jdbc_params', {}); 
        $sth->STORE('jdbc_params_types', {}); 
        for my $i (1..$param_count) { 
            $sth->{'jdbc_params'}->{$i} = undef; 
            $sth->{'jdbc_params_types'}->{$i} = undef; 
        }

        # Copy the current value of inherited properties to the server.
        $sth->STORE('LongReadLen' => $dbh->FETCH('LongReadLen'));
        $sth->STORE('LongTruncOk' => $dbh->FETCH('LongTruncOk') ? 1 : 0);
        $sth->STORE('ChopBlanks' => $dbh->FETCH('ChopBlanks') ? 1 : 0);
        $sth->STORE('jdbc_longreadall' => 
            $dbh->FETCH('jdbc_longreadall') ? 1 : 0);
        $sth;
    }

    # JDBC: Connection.commit
    sub commit {
        my ($dbh) = shift;
        my ($resp);
        return _send_request($dbh,
                             $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                             [COMMIT_REQ => 0],
                             [COMMIT_RESP => \$resp]);
    }

    # JDBC: Connection.rollback
    sub rollback {
        my ($dbh) = shift;
        my ($resp);
        return _send_request($dbh,
                             $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                             [ROLLBACK_REQ => 0],
                             [ROLLBACK_RESP => \$resp]);
    }

    # Confirms that the server is alive and that this particular
    # (JDBC) connection has not been closed.
    #
    # JDBC: Connection.isClosed
    sub ping {
        my ($dbh) = shift;
        
        # If the connection isn't active, no point in pinging it.
        return 0 unless $dbh->FETCH('Active');
        my ($resp);
        return undef unless
            _send_request($dbh,
                          $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                          [PING_REQ => 0],
                          [PING_RESP => \$resp]);
        return $resp;
    }


    # Sends a disconnect message to the server. The server will
    # attempt to close any open ResultSets and Statements, then
    # close the JDBC Connection. This driver's end of the socket
    # will be closed.
    #
    # JDBC: ResultSet.close, Statement.close, Connection.close
    sub disconnect {
        my ($dbh) = shift;
        my ($debug) = $dbh->trace();
        
        # Don't disconnect inactive connections.
        return 1 unless $dbh->FETCH('Active');
        
        $dbh->STORE('Active' => 0);
        my $resp;
        my ($result) = _send_request($dbh,
                                     $dbh->FETCH('jdbc_socket'), 
                                     $dbh->FETCH('jdbc_ber'),
                                     [DISCONNECT_REQ => 0],
                                     [DISCONNECT_RESP => \$resp]);

        $dbh->FETCH('jdbc_socket')->close();
        return $result;
    }

    # A private disconnect method which can be called from user
    # code even in environments such as Apache::DBI which disable
    # the standard disconnect. It's possible for a JDBC exception
    # to be returned which indicates that the underlying database
    # connection is non-functional. The DBD::JDBC server doesn't
    # know anything about specific database error codes, so it
    # can't handle the exception, but user code may be able to
    # tell that the connection should be closed.
    sub jdbc_disconnect {
        my ($dbh) = shift;
        disconnect($dbh);
    }

    # This is the func implementation. It expects the method name
    # to be a valid java.sql.Connection method name. The
    # parameter list may be empty if the method takes no
    # arguments. Otherwise, parameters may be specified as
    # scalars, if they should be mapped to java.lang.String
    # objects, or as [value,type] pairs (array references) if the
    # parameter type is something other than String. For example,
    # $dbh->func([1 => SQL_BIT], "setAutoCommit") If the method
    # returned void or null, this method will return
    # undef. Otherwise, the return value of the Java method will
    # be returned as a string.

    sub jdbc_func {
        my ($dbh) = shift;
        my ($method) = pop @_; 
        $method =~ s/.*://;  # method name starts out fully-qualified
        $method =~ s/^jdbc_//;
        my (@parameters) = @_;

        # When we're done, parameters_with_types will be a list
        # of alternating parameter value/JDBC type codes.
        my @parameters_with_types = ();
        my $param;
        foreach $param (@parameters) {
            if (ref $param) {
                push @parameters_with_types, $param->[0], DBD::JDBC::st::_jdbc_type($param->[1]);
            }
            else {
                push @parameters_with_types, $param, $DBD::JDBC::Types{VARCHAR};
            }
        }

        my (@value);
        return undef unless
            _send_request($dbh,
                          $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                          [CONNECTION_FUNC_REQ => [$method,
                                                   \@parameters_with_types]],

                          [CONNECTION_FUNC_RESP => \@value]); 
                            
        return $value[0];
    }


    # This method is partially implemented. It needs to get its
    # data from DatabaseMetaData on the server.
    sub get_info {
        my ($dbh, $type) = @_;
        
        return undef unless defined $type and length $type;
        
        ## For now, use the JDBC URL to retrieve a string to
        ## serve as the DBMS name. Whenever access to
        ## DatabaseMetaData is implemented, use
        ## getDatabaseProductName.
        my $name; 
        my $url = $dbh->{jdbc_url}; 
        if ($url =~ m`jdbc:(.+)://`) { # jdbc:xxx[:yyy]://conn_info
            $name = $1;
        } elsif ($url =~ m`jdbc:([^:]+):`) { # jdbc:xxx:conn_info
            $name = $1;
        } elsif ($url =~ m`jdbc:(.+)`) { # jdbc:xxx
            $name = $1;
        } else {
            $name = $url;
        }

        my %type = (
            ## Basic information:
            6  => ["SQL_DRIVER_NAME", 'DBD/JDBC.pm'],
            17  => ["SQL_DBMS_NAME", $name ]);

        ## Put both numbers and names into a hash
        my %t;
        for (keys %type) {
            $t{$_} = $type{$_}->[1];
            $t{$type{$_}->[0]} = $type{$_}->[1];
        }
        return undef unless exists $t{$type};
        my $ans = $t{$type};
        return $ans;
    }


    # This method is not implemented. 
    # Implementation notes: call
    # DatabaseMetaData.getTables(). Use JDBC's default values
    # (null, "", etc) for the catalog, schema, tablenamepattern,
    # and types arguments. Note that this returns a statement
    # handle, so the server will have to be able to deal with
    # that.

    sub table_info {
        undef;
    }

    # This method is not implemented.  
    # These names match the column names in DatabaseMetaData.getTypeInfo
    # exactly, except for AUTO_UNIQUE_VALUE, which is
    # AUTO_INCREMENT in JDBC, and COLUMN_SIZE, which is PRECISION in JDBC.
    #                     JDBC                  DBI
    # TYPE_NAME           String               String
    # DATA_TYPE           SQL type             DBI type
    # COLUMN_SIZE         int                  int
    # LITERAL_PREFIX      String (nullable)    String (nullable)
    # LITERAL_SUFFIX      String (nullable)    String (nullable)
    # CREATE_PARAMS       String (nullable)    String (nullable)
    # NULLABLE            short (0,1,2)        int (0,1,2)
    # CASE_SENSITIVE      boolean              boolean
    # SEARCHABLE          short (...)          int (need to match up constants)
    # UNSIGNED_ATTRIBUTE  boolean              boolean (nullable)
    # FIXED_PREC_SCALE    boolean              boolean (nullable)
    # AUTO_UNIQUE_VALUE   boolean              boolean (nullable)
    # LOCAL_TYPE_NAME     String (nullable)    string (localized TYPE_NAME)
    # MINIMUM_SCALE       short                int (nullable)
    # MAXIMUM_SCALE       short                int (nullable)
    # NUM_PREC_RADIX      int                  int (assume JDBC values are ok)

    sub type_info_all {
        undef;
    }


    # Added in DBI 1.42. Not currently implemented here.
    sub parse_trace_flag {
        my ($flag) = shift;
        return DBI->parse_trace_flag($flag);
    } 


    # Implementation of last_insert_id.
    sub last_insert_id {
        my ($dbh, $catalog, $schema, $table, $field) = @_; 
        my $key; 
        return undef unless
            _send_request($dbh, 
                          $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                          [GET_GENERATED_KEYS_REQ => [($catalog?'STRING':'NULL') => $catalog, 
                                                      ($schema?'STRING':'NULL') => $schema,
                                                      ($table?'STRING':'NULL') => $table, 
                                                      ($field?'STRING':'NULL') => $field]],
                          [GET_GENERATED_KEYS_RESP => \$key]); 
        return $key; 
    }

    sub STORE {
        my ($dbh, $attr, $value) = @_;

        if ($attr =~ /^jdbc_/) {
            $dbh->{$attr} = $value;
            return 1;
        }
        if ($attr eq 'AutoCommit') {
            die DBD::JDBC::ErrorMessages::bad_autocommit_value($value)
                unless ($value == 0 or $value == 1);
            return _set_attr($dbh, $attr, $value);
        }
        if ($attr eq 'RowCacheSize') { # unimplemented
            return;
        }

        $dbh->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($dbh, $attr) = @_;

        if ($attr =~ /^jdbc_/) {
            return $dbh->{$attr};
        }
        if ($attr eq 'AutoCommit') {
            return _get_attr($dbh, $attr)->[0];
        }
        if ($attr eq 'RowCacheSize') { # unimplemented
            return undef;
        }
        $dbh->SUPER::FETCH($attr);
    }

    # According to the DBI spec, we need to call rollback and
    # disconnect here.
    sub DESTROY {
        my ($dbh) = shift;
        return unless $dbh->FETCH('Active');
        return if $dbh->FETCH('InactiveDestroy');
        my $name = $dbh->FETCH('Name');

        # Log any existing error on the current handle. 
        my ($err, $errstr, $state) = ($dbh->err, $dbh->errstr, $dbh->state);
        $dbh->trace_msg("Error on db handle being destroyed: " . 
                        "($err) $errstr [$state]\n", 3)
            if ($dbh->trace() and $err);

        # Override of DIE and $@ copied from DBD::Proxy.
        local $SIG{__DIE__} = 'DEFAULT';
        local $@;
        eval {
            $dbh->rollback() or
                $dbh->trace_msg("Rollback '$name' failed: " . $dbh->errstr . "\n", 3);
            $dbh->disconnect() or
                $dbh->trace_msg("Disconnect '$name' failed: " . $dbh->errstr . "\n", 3);
        }; 
        $dbh->trace_msg("Error in DBD::JDBC::db::DESTROY: $@\n", 3) 
            if ($dbh->trace() and $@);
        1;
    }


    # This private method retrieves an attribute value from the server.
    #
    # args: handle, attribute name
    # returns: an array reference to a list of attribute values
    sub _get_attr {
        my ($dbh, $attr) = @_;
        my (@data);
        return undef unless
            _send_request($dbh,
                          $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'),
                          [GET_CONNECTION_PROPERTY_REQ => $attr],
                          [GET_CONNECTION_PROPERTY_RESP => \@data]);
        return \@data;
    }


    # This private method sets an attribute value on the
    # server. Attribute values are always passed as strings; the
    # server is responsible for decoding them
    #
    # args: handle, attribute name, attribute value
    sub _set_attr {
        my ($dbh, $attr, $value) = @_;
        my ($data); 
        _send_request($dbh,
                      $dbh->FETCH('jdbc_socket'), $dbh->FETCH('jdbc_ber'), 
                      [SET_CONNECTION_PROPERTY_REQ => 
                       [STRING => $attr,
                        STRING => $value]],
                      [SET_CONNECTION_PROPERTY_RESP => \$data]);
    }

    # Simple SQL parameter counting implementation. This handles
    # single- and double-quoted strings within SQL
    # statements. This is made available because DBI says it should
    # be. I'm reluctant to rely on it, since we don't necessarily
    # know anything about the database language being used.
    #
    # args: a SQL statement
    # returns: the number of substitutable parameters in the statement
    sub _count_params {
        my (@chars) = split //, shift;
        my ($params, $state, $i, $last);
        
        # states
        my ($outside_quote, $in_single_quote, $in_double_quote) = (0, 1, 2);
        
        $last = 0;  # Avoid lookahead at end of string.
        $params = 0;
        $state = $outside_quote;
        for ($i=0; $i < @chars; $i++) {
            next unless $chars[$i] =~ /[?'"]/;                      #']
            $last = 1 if $i == $#chars;

            if ($state == $outside_quote) {
                if ($chars[$i] eq '?') { $params++; }
                if ($chars[$i] eq "'") { $state = $in_single_quote; }
                if ($chars[$i] eq '"') { $state = $in_double_quote; }
            }
            elsif ($state == $in_single_quote) {
                if ($chars[$i] eq "'") {
                    (!$last && $chars[$i+1] eq "'") ? $i++  : ($state = $outside_quote);
                }
            }
            elsif ($state == $in_double_quote) {
                if ($chars[$i] eq '"') {
                    (!$last && $chars[$i+1] eq '"') ? $i++  : ($state = $outside_quote);
                }
            }
        }
        $params;
    }
}

{
    package DBD::JDBC::st;
    $imp_data_size = 0;
    $imp_data_size = 0; # Avoid -w warnings.
    ##use vars qw($AUTOLOAD);
    use strict;
    use DBI qw(:sql_types);

    *_send_request = \&DBD::JDBC::_send_request;

    # TODO: Don't allow a parameter type to be changed after it's been
    # set (DBI spec requirement).

    # If a type hint is provided, it should be a DBI type
    # constant. This method will convert the DBI types to JDBC
    # types for transmission to the server.
    sub bind_param {
        my ($sth, $param, $value, $attr) = @_;
        my ($type) = (ref $attr) ? $attr->{'TYPE'} : $attr;
        # Don't pass $type to _jdbc_type if it's undef to avoid warnings.
        $type = ($type ? _jdbc_type($type) : undef);

        # Store the parameter.
        $sth->{'jdbc_params'}->{$param} = $value;

        # Store the type hint, unless it's previously been set or is
        # currently undef.
        $sth->{'jdbc_params_types'}->{$param} = $type
            unless ($sth->{'jdbc_params_types'}->{$param} or not $type);
        1;
    }


    # This method sends the parameters, if any, to the server and
    # causes the server to execute the previously prepared
    # statement.
    #
    # JDBC: PreparedStatement.setXXX, PreparedStatement.execute
    sub execute {
        my ($sth, @values) = @_;
        my $debug = $sth->trace();

        # Set parameter values, if provided. For now, I'm
        # assuming that it's ok for bind_param to have been
        # called for parameter indexes larger than the highest
        # index in @values.

        if (@values) { 
            my $i;
            for ($i = 1; $i <= @values; $i++) {
                $sth->{'jdbc_params'}->{$i} = $values[$i - 1]; 
            }
        }

        my ($i, @encodelist);
        my $paramcount = $sth->{'jdbc_params'} 
            ? scalar( keys %{ $sth->{'jdbc_params'} }) : 0;
        $sth->trace_msg("Warning: number of parameters set ($paramcount) " 
                        . "does not match NUM_OF_PARAMS (" 
                        . $sth->FETCH('NUM_OF_PARAMS') . ")", 3) 
            if $debug && ($paramcount != $sth->FETCH('NUM_OF_PARAMS'));

        # encodelist is a list of alternating parameter values/types
        for ($i = 1; $i <= $paramcount; $i++) {
            push @encodelist, $sth->{'jdbc_params'}->{$i};
            push @encodelist, 
               $sth->{'jdbc_params_types'}->{$i} || $DBD::JDBC::Types{VARCHAR};
        }

        my ($rowcount, $columncount);
        return undef unless
            _send_request($sth,
                          $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'),
                          [EXECUTE_REQ => [$sth->FETCH('jdbc_handle'),
                                           $paramcount,
                                           \@encodelist]],
                          [EXECUTE_RESP => 
                           [OPTIONAL => [EXECUTE_ROWS_RESP => \$rowcount],
                            OPTIONAL => 
                            [EXECUTE_RESULTSET_RESP => \$columncount]]]);
        
        return $sth->set_err(DBD::JDBC::ErrorMessages::bad_execute())
            unless ((defined $rowcount) xor (defined $columncount));
        if (defined $rowcount) {
            $sth->STORE('Active' => 0);
            $sth->STORE('NUM_OF_FIELDS', 0); 
            $sth->{'jdbc_rowcount'} = $rowcount;
            return $rowcount == 0 ? "0E0" : $rowcount;
        }
        else {   # must be columncount
            $sth->STORE('NUM_OF_FIELDS', $columncount) unless
                $sth->FETCH('NUM_OF_FIELDS');
            $sth->{'jdbc_rowcount'} = 0;
            $sth->STORE('Active' => 1);
            return 1;
        }
    }


    sub fetch {
        my ($sth) = @_;
        my $debug = $sth->trace();
        my @row;

        return undef 
            unless _send_request($sth,
                                 $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'), 
                                 [FETCH_REQ => $sth->FETCH('jdbc_handle')],
                                 [FETCH_RESP => \@row]);
        if (shift @row) {  # row contains data
            $sth->{'jdbc_rowcount'}++;
            return $sth->_set_fbav(\@row); 
        }
        $sth->trace_msg("At end of result set\n", 3) if $debug;
        $sth->finish(); # no more data
        return undef;
    }

    # DBI requires this alias.
    *fetchrow_arrayref = \1;       # avoid -w warnings
    *fetchrow_arrayref = \&fetch;


    # This will return the number of rows affected by a DML
    # statement, or the number of rows returned so far by a
    # select statement.
    sub rows { 
        return shift->{'jdbc_rowcount'}; 
    }


    # I want finish to clean up server resources, but doing so
    # would most likely mean closing a ResultSet, and that would
    # force a commit in AutoCommit mode.  The DBI spec says that
    # finish should have no effect on the connection's
    # transaction state.
    sub finish { 
        my ($sth) = @_;
        $sth->STORE('Active' => 0);
        1;
    }



    # This is the func implementation. It expects the method name
    # to be prefixed with one of "ResultSet.", "Statement.", or
    # "ResultSetMetaData." to indicate on which object the method
    # should be called. The parameter list may be empty if the
    # method takes no arguments. Otherwise, parameters may be
    # specified as scalars, if they should be mapped to
    # java.lang.String objects, or as [value,type] pairs (array
    # references) if the parameter type is something other than
    # String. For example, 
    #  $sth->func("eno", [5003 => SQL_INTEGER], "ResultSet.updateInt");
    # If the method returned void or null, this
    # method will return undef. Otherwise, the return value of
    # the Java method will be returned as a string.

    sub jdbc_func {
        my ($sth) = shift;
        my ($method) = pop @_;
        $method =~ s/.*://;  # method name starts out fully-qualified
        $method =~ s/^jdbc_//;
        my (@parameters) = @_;

        # When we're done, parameters_with_types will be a list
        # of alternating parameter value/JDBC type codes.
        my @parameters_with_types = ();
        my $param;
        foreach $param (@parameters) {
            if (ref $param) {
                push @parameters_with_types, $param->[0], DBD::JDBC::st::_jdbc_type($param->[1]);
            }
            else {
                push @parameters_with_types, $param, $DBD::JDBC::Types{VARCHAR};
            }
        }

        my (@return_value);
        return undef unless
            _send_request($sth,
                          $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'),
                          [STATEMENT_FUNC_REQ => [$sth->FETCH('jdbc_handle'),
                                                  $method,
                                                   \@parameters_with_types]],
                          [STATEMENT_FUNC_RESP => \@return_value]);
        return $return_value[0];
    }


    # Added in DBI 1.42. Not currently implemented here.
    sub parse_trace_flag {
        my ($flag) = shift;
        return DBI->parse_trace_flag($flag);
    } 


    sub STORE {
        my ($sth, $attr, $value) = @_;

        if ($attr =~ /^jdbc_/) {
            $sth->{$attr} = $value;
            my $ok = 1; 
            if ($attr eq 'jdbc_longreadall') {
                $value = ($value ? 1 : 0);  # Canonicalize for server.
                $sth->{$attr} = $value;
                $ok = _set_attr($sth, $attr, $value);
            }
            ## TODO: how should we report an error in storing on the server?
            return; 
        }
        
        if ($attr eq 'LongReadLen') {
            return _set_attr($sth, $attr, $value) && 
                $sth->SUPER::STORE($attr, $value);             
        }
        if ($attr eq 'LongTruncOk') {
            return _set_attr($sth, $attr, $value ? 1 : 0) && 
                $sth->SUPER::STORE($attr, $value);             
        }
        if ($attr eq 'ChopBlanks') {
            return _set_attr($sth, $attr, $value ? 1 : 0) && 
                $sth->SUPER::STORE($attr, $value);             
        }

        $sth->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($sth, $attr) = @_;

        if ($attr =~ /^jdbc_/) {
            return $sth->{$attr};
        }

        if ($attr eq 'ParamValues') {
            return $sth->{'jdbc_params'};
        }

        # These attributes shouldn't change value for a given
        # statement, so cache them after retrieval.

        if ($attr eq 'NAME') {
            return ($sth->{'jdbc_NAME'} or 
                    $sth->{'jdbc_NAME'} = _get_attr($sth, $attr, 'STRING'));
        }
        if ($attr eq 'TYPE') {
            return ($sth->{'jdbc_TYPE'} or eval {
                my $row;
                if ($row = _get_attr($sth, $attr, 'INTEGER')) {
                    my $new_row = [ map { _dbi_type($_) } @$row ];
                    return $sth->{'jdbc_TYPE'} = $new_row;
                }
                else {
                    return undef;
                }
            });
        }
        if ($attr eq 'PRECISION') {
            return ($sth->{'jdbc_PRECISION'} or 
                $sth->{'jdbc_PRECISION'} = _get_attr($sth, $attr, 'INTEGER'));
        }
        if ($attr eq 'SCALE') {
            return ($sth->{'jdbc_SCALE'} or 
                    $sth->{'jdbc_SCALE'} = _get_attr($sth, $attr, 'INTEGER'));
        }
        if ($attr eq 'NULLABLE') {
            return ($sth->{'jdbc_NULLABLE'} or 
                $sth->{'jdbc_NULLABLE'} = _get_attr($sth, $attr, 'INTEGER'));
        }
        if ($attr eq 'CursorName') {
            return ($sth->{'jdbc_CursorName'} or eval {
                my $row = _get_attr($sth, $attr, 'STRING');
                if ($row && scalar(@$row)) {  # non-empty list
                    return $sth->{'jdbc_CursorName'} = $row->[0];
                }
                else {
                    return undef;
                }
            });
        }
        if ($attr eq 'RowsInCache') {
            return undef; # Not supported.
        }

        $sth->SUPER::FETCH($attr);
    }

    # Destroys the object on garbage collection. Give the server
    # a chance to remove any references to the Statement object.
    # IMPORTANT: Check Active to see if the connection has been
    # disconnected; it's no use talking to the server if the
    # connection's closed. This is intended to let the server get
    # rid of the Statement if this particular statement handle is
    # being destroyed while the connection is still open. 
    sub DESTROY {
        my ($sth) = shift;
        return if $sth->FETCH('InactiveDestroy');
        return unless $sth->FETCH('Database')->FETCH('Active');

        my $handle = $sth->FETCH('jdbc_handle');
        my $resp;

        # Log any existing error on the current handle. 
        my ($err, $errstr, $state) = ($sth->err, $sth->errstr, $sth->state);
        $sth->trace_msg("Error on statement handle being destroyed: " . 
                        "($err) $errstr [$state]\n", 3)
            if ($sth->trace() and $err);

        # Don't let calling _send_request affect the current
        # value of $@. (Override of $SIG{__DIE__} and $@ copied from
        # DBD::Proxy.)
        local $SIG{__DIE__} = 'DEFAULT';
        local $@;
        eval {
            _send_request($sth,
                          $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'),
                          [STATEMENT_DESTROY_REQ => $handle],
                          [STATEMENT_DESTROY_RESP => \$resp], 
                          "sth::destroy", 1);
        };
        $sth->trace_msg("Error in DBD::JDBC::st::DESTROY: $@\n", 3) 
            if ($sth->trace() and $@);

        ## Calling finish as $sth->finish interferes with
        ## $DBI::errstr after this DESTROY completes. Calling
        ## finish($sth) doesn't. All we're currently after is
        ## setting Active to false, so it's possible that we
        ## should just do that explicitly here, but if finish
        ## ever does something else, we might want that something
        ## also.
        finish($sth);

        1;
    }


    # This private method retrieves an attribute value from the server.
    #
    # args: handle, attribute name
    # returns: an array reference to a list of attribute values
    sub _get_attr {
        my ($sth, $attr) = @_;
        my ($debug) = DBI->trace();

        my @data;
        return undef unless
            _send_request($sth,
                          $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'),
                          [GET_STATEMENT_PROPERTY_REQ =>
                           [INTEGER => $sth->FETCH('jdbc_handle'),
                            STRING => $attr]],
                          [GET_STATEMENT_PROPERTY_RESP => \@data]);
        return \@data;
    }


    # This private method sets an attribute value on the
    # server. Attribute values are always passed as strings; the
    # server is responsible for decoding them
    #
    # args: handle, attribute name, attribute value
    sub _set_attr {
        my ($sth, $attr, $value) = @_;

        my $data;
        return 
            _send_request($sth,
                          $sth->FETCH('jdbc_socket'), $sth->FETCH('jdbc_ber'),
                          [SET_STATEMENT_PROPERTY_REQ => 
                           [INTEGER => $sth->FETCH('jdbc_handle'),
                            STRING => $attr,
                            STRING => $value]],
                          [SET_STATEMENT_PROPERTY_RESP => \$data]);
    }


    # Returns the JDBC type code corresponding to a given DBI type code.
    sub _jdbc_type {
        my ($dbi_type) = @_;

        return $DBD::JDBC::Types{VARCHAR}       if $dbi_type == SQL_VARCHAR;
        return $DBD::JDBC::Types{LONGVARCHAR}   if $dbi_type == SQL_LONGVARCHAR;
        return $DBD::JDBC::Types{VARBINARY}     if $dbi_type == SQL_VARBINARY;
        return $DBD::JDBC::Types{LONGVARBINARY} if $dbi_type == SQL_LONGVARBINARY;

        return $DBD::JDBC::Types{BIT}           if $dbi_type == SQL_BIT;
        return $DBD::JDBC::Types{INTEGER}       if $dbi_type == SQL_INTEGER;
        return $DBD::JDBC::Types{NUMERIC}       if $dbi_type == SQL_NUMERIC;
        return $DBD::JDBC::Types{DECIMAL}       if $dbi_type == SQL_DECIMAL;
        return $DBD::JDBC::Types{FLOAT}         if $dbi_type == SQL_FLOAT;
        return $DBD::JDBC::Types{REAL}          if $dbi_type == SQL_REAL;
        return $DBD::JDBC::Types{DOUBLE}        if $dbi_type == SQL_DOUBLE;
        return $DBD::JDBC::Types{TINYINT}       if $dbi_type == SQL_TINYINT;
        return $DBD::JDBC::Types{SMALLINT}      if $dbi_type == SQL_SMALLINT;
        return $DBD::JDBC::Types{BIGINT}        if $dbi_type == DBD::JDBC::SQL_BIGINT;
        return $DBD::JDBC::Types{BINARY}        if $dbi_type == SQL_BINARY;
        return $DBD::JDBC::Types{CHAR}          if $dbi_type == SQL_CHAR;

        return $DBD::JDBC::Types{DATE}          if $dbi_type == SQL_DATE;
        return $DBD::JDBC::Types{TIME}          if $dbi_type == SQL_TIME;
        return $DBD::JDBC::Types{TIMESTAMP}     if $dbi_type == SQL_TIMESTAMP;

        return $DBD::JDBC::Types{ARRAY}         if $dbi_type == SQL_ARRAY;
        return $DBD::JDBC::Types{BLOB}          if $dbi_type == SQL_BLOB;
        return $DBD::JDBC::Types{CLOB}          if $dbi_type == SQL_CLOB;
        return $DBD::JDBC::Types{REF}           if $dbi_type == SQL_REF;

        # SQL_ALL_TYPES has no meaningful mapping.
        # There's no SQL_XXX type to map to null.
        undef;
    }

    # Returns the DBI type code correponding to the given JDBC
    # type. If there's no known mapping, the JDBC type is
    # returned.
    sub _dbi_type {
        my ($jdbc_type) = @_;

        return SQL_VARCHAR     if $jdbc_type == $DBD::JDBC::Types{VARCHAR};  
        return SQL_LONGVARCHAR if $jdbc_type == $DBD::JDBC::Types{LONGVARCHAR};
        return SQL_VARBINARY   if $jdbc_type == $DBD::JDBC::Types{VARBINARY};
        return SQL_LONGVARBINARY if $jdbc_type == $DBD::JDBC::Types{LONGVARBINARY}; 
        return SQL_BIT         if $jdbc_type == $DBD::JDBC::Types{BIT}; 
        return SQL_INTEGER     if $jdbc_type == $DBD::JDBC::Types{INTEGER}; 
        return SQL_NUMERIC     if $jdbc_type == $DBD::JDBC::Types{NUMERIC}; 
        return SQL_DECIMAL     if $jdbc_type == $DBD::JDBC::Types{DECIMAL}; 
        return SQL_FLOAT       if $jdbc_type == $DBD::JDBC::Types{FLOAT};
        return SQL_REAL        if $jdbc_type == $DBD::JDBC::Types{REAL}; 
        return SQL_DOUBLE      if $jdbc_type == $DBD::JDBC::Types{DOUBLE}; 
        return SQL_TINYINT     if $jdbc_type == $DBD::JDBC::Types{TINYINT}; 
        return SQL_SMALLINT    if $jdbc_type == $DBD::JDBC::Types{SMALLINT};  
        return DBD::JDBC::SQL_BIGINT      if $jdbc_type == $DBD::JDBC::Types{BIGINT}; 
        return SQL_BINARY      if $jdbc_type == $DBD::JDBC::Types{BINARY}; 
        return SQL_CHAR        if $jdbc_type == $DBD::JDBC::Types{CHAR}; 
        return SQL_DATE        if $jdbc_type == $DBD::JDBC::Types{DATE}; 
        return SQL_TIME        if $jdbc_type == $DBD::JDBC::Types{TIME}; 
        return SQL_TIMESTAMP   if $jdbc_type == $DBD::JDBC::Types{TIMESTAMP}; 

        return SQL_ARRAY       if $jdbc_type == $DBD::JDBC::Types{ARRAY};
        return SQL_BLOB        if $jdbc_type == $DBD::JDBC::Types{BLOB};
        return SQL_CLOB        if $jdbc_type == $DBD::JDBC::Types{CLOB};
        return SQL_REF         if $jdbc_type == $DBD::JDBC::Types{REF};

        return $jdbc_type; # May define exported jdbc_ constants for this.
    }
}

{
    # This package contains the Convert::BER subclass which
    # implements the application-specific BER packet types used
    # by this driver. I've overridden the pack/unpack behavior of
    # a few object types in a way consistent with Convert::BER
    # but not documented.
    #
    # To add a new message type
    #    - add the request and response tag numbers
    #    - add the type definitions to the call to define()
    # In the Java source,
    #    - create classes for the objects
    #    - add the tag numbers to BerDbdModule and register the
    #      request's factory method
    #    - add code to handle the request in Connection


    package DBD::JDBC::BER;
    use Convert::BER 1.31 qw(/^(\$|BER_|ber)/);
    use strict;
    use vars qw($VERSION @ISA);
    @ISA = qw(Convert::BER);
    $VERSION = $DBD::JDBC::VERSION;

    # Tag numbers. 
    sub JDBC_MYSEQUENCE ()                     { 0 }
    sub JDBC_ERROR_RESP ()                     { 0xA + 1000 }
    sub JDBC_CONNECT_REQ ()                    { 0xB }
    sub JDBC_CONNECT_RESP ()                   { 0xB + 1000 }
    sub JDBC_DISCONNECT_REQ ()                 { 0xC }
    sub JDBC_DISCONNECT_RESP ()                { 0xC + 1000 }
    sub JDBC_COMMIT_REQ ()                     { 0xD }
    sub JDBC_COMMIT_RESP ()                    { 0xD + 1000 }
    sub JDBC_ROLLBACK_REQ ()                   { 0xE }
    sub JDBC_ROLLBACK_RESP ()                  { 0xE + 1000 }
    sub JDBC_PREPARE_REQ ()                    { 0xF }
    sub JDBC_PREPARE_RESP ()                   { 0xF + 1000 }
    sub JDBC_EXECUTE_REQ ()                    { 0x10 }
    sub JDBC_EXECUTE_RESP ()                   { 0x10 + 1000 }
    sub JDBC_FETCH_REQ ()                      { 0x11 }
    sub JDBC_FETCH_RESP ()                     { 0x11 + 1000 }
    sub JDBC_EXECUTE_ROWS_RESP ()              { 0x12 + 1000 }
    sub JDBC_EXECUTE_RESULTSET_RESP ()         { 0x13 + 1000 }
    sub JDBC_GET_CONNECTION_PROPERTY_REQ ()    { 0x14 }
    sub JDBC_GET_CONNECTION_PROPERTY_RESP ()   { 0x14 + 1000 }
    sub JDBC_GET_STATEMENT_PROPERTY_REQ ()     { 0x15 }
    sub JDBC_GET_STATEMENT_PROPERTY_RESP ()    { 0x15 + 1000 }
    sub JDBC_SET_CONNECTION_PROPERTY_REQ ()    { 0x16 }
    sub JDBC_SET_CONNECTION_PROPERTY_RESP ()   { 0x16 + 1000 }
    sub JDBC_SET_STATEMENT_PROPERTY_REQ ()     { 0x17 }
    sub JDBC_SET_STATEMENT_PROPERTY_RESP ()    { 0x17 + 1000 }
    sub JDBC_STATEMENT_FINISH_REQ ()           { 0x18 }
    sub JDBC_STATEMENT_FINISH_RESP ()          { 0x18 + 1000 }
    sub JDBC_STATEMENT_DESTROY_REQ ()          { 0x19 }
    sub JDBC_STATEMENT_DESTROY_RESP ()         { 0x19 + 1000 }
    sub JDBC_PING_REQ ()                       { 0x1A }
    sub JDBC_PING_RESP ()                      { 0x1A + 1000 }
    sub JDBC_HASH()                            { 0x1B }

    sub JDBC_ERROR()                           { 0x1C }

    sub JDBC_CONNECTION_FUNC_REQ()             { 0x1D }
    sub JDBC_CONNECTION_FUNC_RESP()            { 0x1D + 1000 }

    # Either Convert::BER or the Java BER classes are failing
    # around 1E and 1F. Just skip those cases.

    sub JDBC_STATEMENT_FUNC_REQ()              { 0x20 }
    sub JDBC_STATEMENT_FUNC_RESP()             { 0x20 + 1000 }

    sub JDBC_GET_GENERATED_KEYS_REQ()          { 0x21 }
    sub JDBC_GET_GENERATED_KEYS_RESP()         { 0x21 + 1000 }

    # Define name/type/tag triplets.

    DBD::JDBC::BER->define(
 [MYSEQUENCE => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_MYSEQUENCE())],
 [ERROR_RESP => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_ERROR_RESP())],

 [CONNECT_REQ => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_CONNECT_REQ())],
 [CONNECT_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_CONNECT_RESP())],

 [DISCONNECT_REQ => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_DISCONNECT_REQ())],
 [DISCONNECT_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_DISCONNECT_RESP())],

 [COMMIT_REQ=> $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_COMMIT_REQ())],
 [COMMIT_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_COMMIT_RESP())],

 [ROLLBACK_REQ => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_ROLLBACK_REQ())],
 [ROLLBACK_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_ROLLBACK_RESP())],

 #[PREPARE_REQ  => $STRING,  
 # ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_PREPARE_REQ())],
 [PREPARE_REQ  => $SEQUENCE,  
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_PREPARE_REQ())],
 [PREPARE_RESP => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_PREPARE_RESP())],

 [EXECUTE_REQ  => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_EXECUTE_REQ())],
 [EXECUTE_RESP => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_EXECUTE_RESP())],

 [FETCH_REQ => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_FETCH_REQ())],
 [FETCH_RESP => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_FETCH_RESP())],

 [EXECUTE_ROWS_RESP => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_EXECUTE_ROWS_RESP())],

 [EXECUTE_RESULTSET_RESP => $INTEGER, 
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_EXECUTE_RESULTSET_RESP())], 

 [GET_CONNECTION_PROPERTY_REQ => $STRING,
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_GET_CONNECTION_PROPERTY_REQ())], 
 [GET_CONNECTION_PROPERTY_RESP  => 'MYSEQUENCE',
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 
          JDBC_GET_CONNECTION_PROPERTY_RESP())],

 [SET_CONNECTION_PROPERTY_REQ => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 
          JDBC_SET_CONNECTION_PROPERTY_REQ())], 
 [SET_CONNECTION_PROPERTY_RESP  => $NULL,
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, 
          JDBC_SET_CONNECTION_PROPERTY_RESP())],

 [GET_STATEMENT_PROPERTY_REQ => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 
          JDBC_GET_STATEMENT_PROPERTY_REQ())], 
 [GET_STATEMENT_PROPERTY_RESP  => 'MYSEQUENCE',
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 
          JDBC_GET_STATEMENT_PROPERTY_RESP())],

 [SET_STATEMENT_PROPERTY_REQ => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 
          JDBC_SET_STATEMENT_PROPERTY_REQ())], 
 [SET_STATEMENT_PROPERTY_RESP  => $NULL,
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, 
          JDBC_SET_STATEMENT_PROPERTY_RESP())],

 [STATEMENT_FINISH_REQ => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_STATEMENT_FINISH_REQ())],
 [STATEMENT_FINISH_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_STATEMENT_FINISH_RESP())],

 [STATEMENT_DESTROY_REQ => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_STATEMENT_DESTROY_REQ())],
 [STATEMENT_DESTROY_RESP => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_STATEMENT_DESTROY_RESP())],

 [PING_REQ => $NULL,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_PING_REQ())],
 [PING_RESP => $INTEGER,  
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_PING_RESP())],

 [GET_GENERATED_KEYS_REQ => $SEQUENCE,  
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_GET_GENERATED_KEYS_REQ())],
 [GET_GENERATED_KEYS_RESP => $STRING,
  ber_tag(BER_APPLICATION | BER_PRIMITIVE, JDBC_GET_GENERATED_KEYS_RESP())],

 [HASH => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_HASH())],  

 [ERROR => $SEQUENCE,
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_ERROR())],  

 # I was going to have the func response objects just be
 # SEQUENCEs. However, when I tried to read the response data
 # with [XXX_FUNC_RESP => [ OPTIONAL => STRING, OPTIONAL => NULL]
 # (syntax approximate), I kept getting "buffer not empty"
 # errors, so I gave up and went to MYSEQUENCE. The dumps of the
 # buffers looked fine.

 [CONNECTION_FUNC_REQ  => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_CONNECTION_FUNC_REQ())],
 [CONNECTION_FUNC_RESP => 'MYSEQUENCE', 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_CONNECTION_FUNC_RESP())],

 [STATEMENT_FUNC_REQ  => $SEQUENCE, 
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_STATEMENT_FUNC_REQ())],
 [STATEMENT_FUNC_RESP => 'MYSEQUENCE',
  ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, JDBC_STATEMENT_FUNC_RESP())],

 );

}


{
    package DBD::JDBC::BER::MYSEQUENCE;

    # I want to know the length of the contents, not the length of
    # the packet, so $ber->length doesn't suffice.
    sub _content_length {
        my ($self, $ber) = @_;
        my $pos = $ber->[ Convert::BER::_POS() ];
        my $len = $ber->unpack_length();
        $ber->[ Convert::BER::_POS() ] = $pos;
        $len;
    }

    sub unpack_array {
        my ($self, $ber, $arg) = @_;
        
        if ($self->_content_length($ber) == 0) {
            @$arg = ();
            return 1;
        }
        
        my ($ber2, $tag, $i, $field);
        # Unpack the buffer into a new BER object. 
        $self->unpack($ber, \$ber2);
        
        # TODO: There should be a better way to do this. CHOICE, ANY, ... ?
        # tag() will return undef when the end of the buffer is reached
        for ($i = 0; $tag = $ber2->tag(); $i++) {
            if ($tag == $ber2->NULL()) {
                $ber2->decode(NULL => \$field);
                push @$arg, undef;
            }
            elsif ($tag == $ber2->STRING()) {
                $ber2->decode(STRING => \$field);
                push @$arg, $field;
            }
            elsif ($tag == $ber2->INTEGER()) {
                $ber2->decode(INTEGER => \$field);
                push @$arg, $field;
            }
        }
        1;
    }
}


{
    package DBD::JDBC::BER::EXECUTE_REQ;

    # Modified from Convert::BER::SEQUENCE;
    sub pack_array {
        my ($self, $ber, $arg) = @_;  # $arg is an array ref
        my ($handle, $param_count, $param_list) = @$arg;
        
        # Convert::BER::_encode should have packed the tag value already.
        # Build up the message body using a new BER object.
        my $ber2 = $ber->new;
        $ber2->_encode([INTEGER => $handle]);  # handle
        
        $ber2->_encode([INTEGER => $param_count]);  # parameter count
        
        my $i = 0;
        while ($i < scalar(@$param_list)) {
            my ($value, $type) = ($param_list->[$i], $param_list->[$i+1]);
            $i += 2;
            
            # Parameters may be null, but a type will always be specified.
            defined $value 
                ? $ber2->_encode([STRING => $value]) 
                    : $ber2->_encode([NULL => 0]);
            $ber2->_encode([INTEGER => $type]);
        }
        
        $ber->pack_length(CORE::length($ber2->[ Convert::BER::_BUFFER() ]));
        $ber->[ Convert::BER::_BUFFER() ] .= $ber2->[ Convert::BER::_BUFFER() ];
        1;
    }
}

{
    package DBD::JDBC::BER::FETCH_RESP;
    # TODO: Can this be another MYSEQUENCE?
    sub unpack_array {
        my ($self, $ber, $arg) = @_;
        
        my ($ber2, $tag, $i, $field);
        $self->unpack($ber, \$ber2);
        
        # This value indicates whether or not there's a row to be decoded.
        $ber2->decode(INTEGER => \$i);
        push @$arg, $i;    
        
        if ($i) {
            # tag() will return undef when the end of the buffer is reached
            while ($tag = $ber2->tag()) {
                if ($tag == $ber2->NULL()) {
                    $ber2->decode(NULL => \$field);
                    push @$arg, undef;
                }
                elsif ($tag == $ber2->STRING()) {
                    $ber2->decode(STRING => \$field);
                    push @$arg, $field;
                }
                $i++;    # Used periodically in debugging.
            }
        }
        1;
    }
}


{
    package DBD::JDBC::BER::ERROR_RESP;

    # This will push hash references containing the components of
    # ERROR packets onto the array argument.
    sub unpack_array {
        my ($self, $ber, $arg) = @_;
        
        my ($ber2);
        $self->unpack($ber, \$ber2);
        
        # tag() will return undef when the end of the buffer is reached;
        while ($ber2->tag()) {
            my %error;
            $ber2->decode(ERROR => [STRING => \$error{'errstr'},
                                    STRING => \$error{'err'},
                                    STRING => \$error{'state'}]);
            push @$arg, \%error;
        }
        1;
    }
}



# A func request consists of a sequence in which the first
# element is a method name and the remaining elements are
# (alternating) values and typecodes.

{
    package DBD::JDBC::BER::CONNECTION_FUNC_REQ;

    # Modified from Convert::BER::SEQUENCE;
    sub pack_array {
        my ($self, $ber, $arg) = @_;  # $arg is an array ref
        my ($method, $param_list) = @$arg;
        
        # Convert::BER::_encode should have packed the tag value already.
        # Build up the message body using a new BER object.
        my $ber2 = $ber->new;
        $ber2->_encode([STRING => $method]);  # method name
        
        my $i = 0;
        while ($i < scalar(@$param_list)) {
            my ($value, $type) = ($param_list->[$i], $param_list->[$i+1]);
            $i += 2;
            
            # Parameters may be null, but a type will always be specified.
            defined $value 
                ? $ber2->_encode([STRING => $value]) 
                    : $ber2->_encode([NULL => 0]);
            $ber2->_encode([INTEGER => $type]);
        }
        
        $ber->pack_length(CORE::length($ber2->[ Convert::BER::_BUFFER() ]));
        $ber->[ Convert::BER::_BUFFER() ] .= $ber2->[ Convert::BER::_BUFFER() ];
        1;
    }
}


# A func request consists of a sequence in which the first
# element is a method name, the second element is a statement
# handle, and the remaining elements are (alternating) values and
# typecodes.
{
    package DBD::JDBC::BER::STATEMENT_FUNC_REQ;

    # Modified from Convert::BER::SEQUENCE;
    sub pack_array {
        my ($self, $ber, $arg) = @_;  # $arg is an array ref
        my ($handle, $method, $param_list) = @$arg;
        
        # Convert::BER::_encode should have packed the tag value already.
        # Build up the message body using a new BER object.
        my $ber2 = $ber->new;
        $ber2->_encode([INTEGER => $handle]);  # handle
        $ber2->_encode([STRING => $method]);  # method name
        
        my $i = 0;
        while ($i < scalar(@$param_list)) {
            my ($value, $type) = ($param_list->[$i], $param_list->[$i+1]);
            $i += 2;
            
            # Parameters may be null, but a type will always be specified.
            defined $value 
                ? $ber2->_encode([STRING => $value]) 
                    : $ber2->_encode([NULL => 0]);
            $ber2->_encode([INTEGER => $type]);
        }
        
        $ber->pack_length(CORE::length($ber2->[ Convert::BER::_BUFFER() ]));
        $ber->[ Convert::BER::_BUFFER() ] .= $ber2->[ Convert::BER::_BUFFER() ];
        1;
    }
}




## ====================

package DBD::JDBC::ErrorMessages;

# All error messages generated by DBD::JDBC, including the Java
# server component, but not including messages generated by the
# JDBC driver in use, are assigned a SQL state of 'IJDBC'. The
# server uses error numbers in the range 0-99, and DBD::JDBC
# proper uses error numbers in the range 100-199. Other error
# number ranges may be assigned as needed. (Note that we can't
# guarantee that the JDBC driver doesn't use the SQL state IJDBC;
# if it does, the application will have to distinguish between
# errors itself.)


$DBD::JDBC::ErrorMessages::sql_state = "IJDBC";

# This one is used in die, not set_err.
sub bad_autocommit_value($) {
    return "Unsupported AutoCommit value $_[0]";
}

sub send_error($) { 
    return (100, $_[0], $sql_state);
}

sub recv_error($) {
    return (101, $_[0], $sql_state);
}

sub ber_error($) {
    return (102, $_[0], $sql_state);
}

sub missing_dsn_component($) {
    return (103, "Missing $_[0] in dsn", $sql_state);
}

sub socket_error($) { 
    return (104, "Failed to open socket to server: $_[0]", $sql_state);
}

sub bad_execute() {
    return (105, "Invalid execute response", $sql_state);
}

sub bad_func_method($) {
    return (106, "Invalid func method name: $_[0]", $sql_state);
}

1;

