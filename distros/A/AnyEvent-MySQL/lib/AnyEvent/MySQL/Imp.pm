package AnyEvent::MySQL::Imp;

use strict;
use warnings;

use AE;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Digest::SHA1 qw(sha1);
use List::Util qw(reduce);
use Scalar::Util qw(dualvar);

use constant {
    DEV => 0,
};

use constant {
    CLIENT_LONG_PASSWORD      =>      1, # new more secure passwords +
    CLIENT_FOUND_ROWS         =>      2, # Found instead of affected rows *
    CLIENT_LONG_FLAG          =>      4, # Get all column flags * +
    CLIENT_CONNECT_WITH_DB    =>      8, # One can specify db on connect +
    CLIENT_NO_SCHEMA          =>     16, # Don't allow database.table.column
    CLIENT_COMPRESS           =>     32, # Can use compression protocol *
    CLIENT_ODBC               =>     64, # Odbc client
    CLIENT_LOCAL_FILES        =>    128, # Can use LOAD DATA LOCAL *
    CLIENT_IGNORE_SPACE       =>    256, # Ignore spaces before '(' *
    CLIENT_PROTOCOL_41        =>    512, # New 4.1 protocol +
    CLIENT_INTERACTIVE        =>   1024, # This is an interactive client * +
    CLIENT_SSL                =>   2048, # Switch to SSL after handshake *
    CLIENT_IGNORE_SIGPIPE     =>   4096, # IGNORE sigpipes
    CLIENT_TRANSACTIONS       =>   8192, # Client knows about transactions +
    CLIENT_RESERVED           =>  16384, # Old flag for 4.1 protocol 
    CLIENT_SECURE_CONNECTION  =>  32768, # New 4.1 authentication * +
    CLIENT_MULTI_STATEMENTS   =>  65536, # Enable/disable multi-stmt support * +
    CLIENT_MULTI_RESULTS      => 131072, # Enable/disable multi-results * +
};

use constant {
    COM_SLEEP               => "\x00", #   (none, this is an internal thread state)
    COM_QUIT                => "\x01", #   mysql_close
    COM_INIT_DB             => "\x02", #   mysql_select_db 
    COM_QUERY               => "\x03", #   mysql_real_query
    COM_FIELD_LIST          => "\x04", #   mysql_list_fields
    COM_CREATE_DB           => "\x05", #   mysql_create_db (deprecated)
    COM_DROP_DB             => "\x06", #   mysql_drop_db (deprecated)
    COM_REFRESH             => "\x07", #   mysql_refresh
    COM_SHUTDOWN            => "\x08", #   mysql_shutdown
    COM_STATISTICS          => "\x09", #   mysql_stat
    COM_PROCESS_INFO        => "\x0a", #   mysql_list_processes
    COM_CONNECT             => "\x0b", #   (none, this is an internal thread state)
    COM_PROCESS_KILL        => "\x0c", #   mysql_kill
    COM_DEBUG               => "\x0d", #   mysql_dump_debug_info
    COM_PING                => "\x0e", #   mysql_ping
    COM_TIME                => "\x0f", #   (none, this is an internal thread state)
    COM_DELAYED_INSERT      => "\x10", #   (none, this is an internal thread state)
    COM_CHANGE_USER         => "\x11", #   mysql_change_user
    COM_BINLOG_DUMP         => "\x12", #   sent by the slave IO thread to request a binlog
    COM_TABLE_DUMP          => "\x13", #   LOAD TABLE ... FROM MASTER (deprecated)
    COM_CONNECT_OUT         => "\x14", #   (none, this is an internal thread state)
    COM_REGISTER_SLAVE      => "\x15", #   sent by the slave to register with the master (optional)
    COM_STMT_PREPARE        => "\x16", #   mysql_stmt_prepare
    COM_STMT_EXECUTE        => "\x17", #   mysql_stmt_execute
    COM_STMT_SEND_LONG_DATA => "\x18", #   mysql_stmt_send_long_data
    COM_STMT_CLOSE          => "\x19", #   mysql_stmt_close
    COM_STMT_RESET          => "\x1a", #   mysql_stmt_reset
    COM_SET_OPTION          => "\x1b", #   mysql_set_server_option
    COM_STMT_FETCH          => "\x1c", #   mysql_stmt_fetch
};

use constant {
    MYSQL_TYPE_BIT                  => 16,
    MYSQL_TYPE_BLOB                 => 252,
    MYSQL_TYPE_DATE                 => 10,
    MYSQL_TYPE_DATETIME             => 12,
    MYSQL_TYPE_DECIMAL              => 0,
    MYSQL_TYPE_DOUBLE               => 5,
    MYSQL_TYPE_ENUM                 => 247,
    MYSQL_TYPE_FLOAT                => 4,
    MYSQL_TYPE_GEOMETRY             => 255,
    MYSQL_TYPE_INT24                => 9,
    MYSQL_TYPE_LONG                 => 3,
    MYSQL_TYPE_LONGLONG             => 8,
    MYSQL_TYPE_LONG_BLOB            => 251,
    MYSQL_TYPE_MEDIUM_BLOB          => 250,
    MYSQL_TYPE_NEWDATE              => 14,
    MYSQL_TYPE_NEWDECIMAL           => 246,
    MYSQL_TYPE_NULL                 => 6,
    MYSQL_TYPE_SET                  => 248,
    MYSQL_TYPE_SHORT                => 2,
    MYSQL_TYPE_STRING               => 254,
    MYSQL_TYPE_TIME                 => 11,
    MYSQL_TYPE_TIMESTAMP            => 7,
    MYSQL_TYPE_TINY                 => 1,
    MYSQL_TYPE_TINY_BLOB            => 249,
    MYSQL_TYPE_VARCHAR              => 15,
    MYSQL_TYPE_VAR_STRING           => 253,
    MYSQL_TYPE_YEAR                 => 13,
};

use constant {
    NOT_NULL_FLAG           => 1,                 # Field can't be NULL
    PRI_KEY_FLAG            => 2,                 # Field is part of a primary key
    UNIQUE_KEY_FLAG         => 4,                 # Field is part of a unique key
    MULTIPLE_KEY_FLAG       => 8,                 # Field is part of a key
    BLOB_FLAG               => 16,                # Field is a blob
    UNSIGNED_FLAG           => 32,                # Field is unsigned
    ZEROFILL_FLAG           => 64,                # Field is zerofill
    BINARY_FLAG             => 128,               # Field is binary
    ENUM_FLAG               => 256,               # Field is an enum
    AUTO_INCREMENT_FLAG     => 512,               # Field is a autoincrement field
    TIMESTAMP_FLAG          => 1024,              # Field is a timestamp
    SET_FLAG                => 2048,              # Field is a set
    NO_DEFAULT_VALUE_FLAG   => 4096,              # Field doesn't have default value
    ON_UPDATE_NOW_FLAG      => 8192,              # Field is set to NOW on UPDATE
    NUM_FLAG                => 32768,             # Field is num (for clients)
    PART_KEY_FLAG           => 16384,             # Intern; Part of some key
    GROUP_FLAG              => 32768,             # Intern: Group field
    UNIQUE_FLAG             => 65536,             # Intern: Used by sql_yacc
    BINCMP_FLAG             => 131072,            # Intern: Used by sql_yacc
    GET_FIXED_FIELDS_FLAG   => (1<<18),           # Used to get fields in item tree
    FIELD_IN_PART_FUNC_FLAG => (1<<19),           # Field part of partition func
    FIELD_IN_ADD_INDEX      => (1<<20),           # Intern: Field used in ADD INDEX
    FIELD_IS_RENAMED        => (1<<21),           # Intern: Field is being renamed
};

use constant {
    RES_OK => 0,
    RES_ERROR => 255,
    RES_RESULT => 1,
    RES_PREPARE => 2,
};

=head2 $str = take_zstring($data(modified))
null terminated string
=cut
sub take_zstr {
    $_[0] =~ s/(.*?)\x00//s;
    return $1;
}

=head2 $num = take_lcb($data(modifed))
length coded binary
=cut
sub take_lcb {
    my $fb = substr($_[0], 0, 1, '');
    if( $fb le "\xFA" ) { # 0-250
        return ord($fb);
    }
    if( $fb eq "\xFB" ) { # 251
        return undef;
    }
    if( $fb eq "\xFC" ) { # 252
        return unpack('v', substr($_[0], 0, 2, ''));
    }
    if( $fb eq "\xFD" ) { # 253
        return unpack('V', substr($_[0], 0, 3, '')."\x00");
    }
    if( $fb eq "\xFE" ) { # 254
        return unpack('Q<', substr($_[0], 0, 8, ''));
    }
    return undef; # error
}

=head2 $str = take_lcs($data(modified))
length coded string
=cut
sub take_lcs {
    my $len = &take_lcb;
    if( defined $len ) {
        return substr($_[0], 0, $len, '');
    }
    else {
        return undef;
    }
}

=head2 $num = take_num($data(modified), $len)
=cut
sub take_num {
    return unpack('V', substr($_[0], 0, $_[1], '')."\x00\x00\x00");
}

=head2 $str = take_str($data(modified), $len)
=cut
sub take_str {
    return substr($_[0], 0, $_[1], '');
}

=head2 () = take_filler($data(modified), $len)
=cut
sub take_filler {
    substr($_[0], 0, $_[1], '');
    return ();
}

=head2 $cell = take_type($data(modified), $type, $length, $flag)
WARN: some MySQL data types are not implemented
=cut
sub take_type {
    if( $_[1]==MYSQL_TYPE_TINY ) { # tinyint
        if( $_[3] & UNSIGNED_FLAG ) {
            return ord(substr($_[0], 0, 1, ''));
        }
        else {
            return unpack('c', substr($_[0], 0, 1, ''));
        }
    } elsif( $_[1]==MYSQL_TYPE_SHORT ) { # smallint
        if( $_[3] & UNSIGNED_FLAG ) {
            return unpack('v', substr($_[0], 0, 2, ''));
        }
        else {
            return unpack('s<', substr($_[0], 0, 2, ''));
        }
    } elsif( $_[1]==MYSQL_TYPE_INT24 ) { # mediumint
        if( $_[3] & UNSIGNED_FLAG ) {
            return unpack('V', substr($_[0], 0, 3, '')."\0");
        }
        else {
            return unpack('l<', substr($_[0], 0, 3, '')."\0");
        }
    } elsif( $_[1]==MYSQL_TYPE_LONG ) { # int
        if( $_[3] & UNSIGNED_FLAG ) {
            return unpack('V', substr($_[0], 0, 4, ''));
        }
        else {
            return unpack('l<', substr($_[0], 0, 4, ''));
        }
    } elsif( $_[1]==MYSQL_TYPE_LONGLONG ) { # bigint
        if( $_[3] & UNSIGNED_FLAG ) {
            return unpack('Q<', substr($_[0], 0, 8, ''));
        }
        else {
            return unpack('q<', substr($_[0], 0, 8, ''));
        }
    } elsif( $_[1]==MYSQL_TYPE_FLOAT ) { # float
        return unpack('f<', substr($_[0], 0, 4, ''));
    } elsif( $_[1]==MYSQL_TYPE_DOUBLE ) { # double
        return unpack('d<', substr($_[0], 0, 8, ''));
    } elsif( $_[1]==MYSQL_TYPE_NEWDECIMAL ) { # decimal, numeric
        warn "Not implement DECIMAL,NUMERIC yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_BIT ) { # bit(n)
        warn "Not implement BIT yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_DATE ) { # date
        warn "Not implement DATE yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_TIME ) { # time
        warn "Not implement TIME yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_DATETIME ) { # datetime
        warn "Not implement DATETIME yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_TIMESTAMP ) { # timestamp
        warn "Not implement TIMESTAMP yet";
        return;
    } elsif( $_[1]==MYSQL_TYPE_YEAR ) { # year
        return 1901+ord(substr($_[0], 0, 1, ''));
    } elsif( $_[1]==MYSQL_TYPE_STRING ) { # char(n), binary(n), enum(), set()
        if( $_[3] & ENUM_FLAG ) {
            warn "Not implement ENUM yet";
            return;
        }
        elsif( $_[3] & SET_FLAG ) {
            warn "Not implement SET yet";
            return;
        }
        else {
            my $data = substr($_[0], 0, $_[2], '');
            $data =~ s/ +$//;
            return $data;
        }
    } elsif( $_[1]==[ MYSQL_TYPE_VAR_STRING, MYSQL_TYPE_BLOB]) { # varchar(n), varbinary(n) | tinyblob, tinytext, blob, text, mediumblob, mediumtext, longblob, longtext
        my $len;
        if( $_[2]<=0xFF ) {
            $len = ord(substr($_[0], 0, 1, ''));
        }
        elsif( $_[2]<=0xFFFF ) {
            $len = unpack('v', substr($_[0], 0, 2, ''));
        }
        elsif( $_[2]<=0xFFFFFF ) {
            $len = unpack('V', substr($_[0], 0, 3, '')."\0");
        }
        else {
            $len = unpack('V', substr($_[0], 0, 4, ''));
        }
        return substr($_[0], 0, $len, '');
    } else {
        warn "Unsupported type: $_";
        use Devel::StackTrace;
        print Devel::StackTrace->new->as_string;
        return;
    }
}

=head2 put_type($data(modified), $cell, $type, $len, $flag)
=cut
sub put_type {
    if( $_[2]==MYSQL_TYPE_TINY ) { # tinyint
        if( $_[4] & UNSIGNED_FLAG ) {
            $_[0] .= chr($_[1]);
        }
        else {
            $_[0] .= pack('c', $_[1]);
        }
    } elsif( $_[2]==MYSQL_TYPE_SHORT ) { # smallint
        $_[0] .= pack( $_[4] & UNSIGNED_FLAG ? 'v' : 's<' , $_[1]);
    } elsif( $_[2]==MYSQL_TYPE_INT24 ) { # mediumint
        $_[0] .= substr(pack( $_[4] & UNSIGNED_FLAG ? 'V' : 'l<' , $_[1]), 0, 3);
    } elsif( $_[2]==MYSQL_TYPE_LONG ) { # int
        $_[0] .= pack( $_[4] & UNSIGNED_FLAG ? 'V' : 'l<' , $_[1] );
    } elsif( $_[2]==MYSQL_TYPE_LONGLONG ) { # bigint
        $_[0] .= pack( $_[4] & UNSIGNED_FLAG ? 'Q<' : 'q<' , $_[1] );
    } elsif( $_[2]==MYSQL_TYPE_FLOAT ) { # float
        $_[0] .= pack('f<', $_[1]);
    } elsif( $_[2]==MYSQL_TYPE_DOUBLE ) { # double
        $_[0] .= pack('d<', $_[1]);
    } elsif( $_[2]==MYSQL_TYPE_NEWDECIMAL ) { # decimal, numeric
        warn "Not implement DECIMAL,NUMERIC yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_BIT ) { # bit(n)
        warn "Not implement BIT yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_DATE ) { # date
        warn "Not implement DATE yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_TIME ) { # time
        warn "Not implement TIME yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_DATETIME ) { # datetime
        warn "Not implement DATETIME yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_TIMESTAMP ) { # timestamp
        warn "Not implement TIMESTAMP yet";
        return;
    } elsif( $_[2]==MYSQL_TYPE_YEAR ) { # year
        $_[0] .= chr($_[1]-1901);
    } elsif( $_[2]==MYSQL_TYPE_STRING ) { # char(n), binary(n), enum(), set()
        if( $_[4] & ENUM_FLAG ) {
            warn "Not implement ENUM yet";
            return;
        }
        elsif( $_[4] & SET_FLAG ) {
            warn "Not implement SET yet";
            return;
        }
        else {
            if( length($_[1]) >= $_[3] ) {
                $_[0] .= substr($_[1], 0, $_[3]);
            }
            else {
                $_[0] .= $_[1];
                $_[0] .= ' ' x ($_[3] - length $_[1]);
            }
        }
    } elsif( $_[2]==[ MYSQL_TYPE_VAR_STRING, MYSQL_TYPE_BLOB]) { # varchar(n), varbinary(n) | tinyblob, tinytext, blob, text, mediumblob, mediumtext, longblob, longtext
        my $len;
        $_[1] = substr($_[1], 0, $_[3]) if( length($_[1]) > $_[3] );
        if( $_[3]<=0xFF ) {
            $_[0] .= chr(length($_[1]));
        }
        elsif( $_[3]<=0xFFFF ) {
            $_[0] .= pack('v', length($_[1]));
        }
        elsif( $_[3]<=0xFFFFFF ) {
            $_[0] .= substr(pack('V', length($_[1])), 0, 3);
        }
        else {
            $_[0] .= pack('V', length($_[1]));
        }
        $_[0] .= $_[1];
    } else {
        warn "Unsupported type: $_[2]";
        return;
    }
}

=head2 put_num($data(modified), $num, $len)
=cut
sub put_num {
    $_[0] .= substr(pack('V', $_[1]), 0, $_[2]);
}

=head2 put_str($data(modified), $str, $len)
=cut
sub put_str {
    $_[0] .= substr($_[1].("\x00" x $_[2]), 0, $_[2]);
}

=head2 put_zstr($data(modified), $str)
=cut
sub put_zstr {
    no warnings 'uninitialized';
    $_[0] .= $_[1];
    $_[0] .= "\x00";
}

=head2 put_lcb($data(modified), $num)
=cut
sub put_lcb {
    if( $_[1] <= 250 ) {
        $_[0] .= chr($_[1]);
    }
    elsif( !defined($_[1]) ) {
        $_[0] .= "\xFB"; # 251
    }
    elsif( $_[1] <= 65535 ) {
        $_[0] .= "\xFC"; # 252
        $_[0] .= pack('v', $_[1]);
    }
    elsif( $_[1] <= 16777215 ) {
        $_[0] .= "\xFD"; # 253
        $_[0] .= substr(pack('V', $_[1]), 0, 3);
    }
    else {
        $_[0] .= "\xFE"; # 254
        $_[0] .= pack('Q<', $_[1]);
    }
}

=head2 put_lcs($data(modified), $str)
=cut
sub put_lcs {
    put_lcb($_[0], length($_[1]));
    $_[0] .= $_[1];
}

=head2 ($affected_rows, $insert_id, $server_status, $warning_count, $message) | $is = parse_ok($data(modified))
=cut
sub parse_ok {
    if( substr($_[0], 0, 1) eq "\x00" ) {
        if( wantarray ) {
            substr($_[0], 0, 1, '');
            return (
                take_lcb($_[0]),
                take_lcb($_[0]),
                take_num($_[0], 2),
                take_num($_[0], 2),
                $_[0],
            );
        }
        else {
            return 1;
        }
    }
    else {
        return;
    }
}

=head2 ($errno, $sqlstate, $message) = parse_error($data(modified))
=cut
sub parse_error {
    if( substr($_[0], 0, 1) eq "\xFF" ) {
        if( wantarray ) {
            substr($_[0], 0, 1, '');
            return (
                take_num($_[0], 2),
                ( substr($_[0], 0, 1) eq '#' ?
                  ( substr($_[0], 1, 5), substr($_[0], 6) ) :
                  ( '', $_[0] )
                )
            );
        }
        else {
            return 1;
        }
    }
    else {
        return;
    }
}

## ($field_count, $extra) = parse_result_set_header($data(modified))
#sub parse_result_set_header {
#    if( $substr($_[0], 0, 1) 
#}

=head2 recv_packet($hd, $cb->($packet))
=cut
sub recv_packet {
    my $cb = pop;
    my($hd) = @_;
    if( $hd ) {
        $hd->push_read( chunk => 4, sub {
            my $len = unpack("V", $_[1]);
            my $num = $len >> 24;
            $len &= 0xFFFFFF;
            print "pack_len=$len, pack_num=$num\n" if DEV;
            $_[0]->unshift_read( chunk => $len, sub {
                $cb->($_[1]);
            } );
        } );
    }
}

=head2 skip_until_eof($hd, $cb->())
=cut
sub skip_until_eof {
    my($hd, $cb) = @_;
    recv_packet($hd, sub {
        if( substr($_[0], 0, 1) eq "\xFE" ) {
            $cb->();
        }
        else {
            skip_until_eof($hd, $cb);
        }
    });
}

=head2 send_packet($hd, $packet_num, $packet_frag1, $pack_frag2, ...)
=cut
sub send_packet {
    return if !$_[0];
    local $_[0] = $_[0];
    my $len = reduce { $a + length($b) } 0, @_[2..$#_];
    $_[0]->push_write(substr(pack('V', $len), 0, 3) . chr($_[1]) . join('', @_[2..$#_]));
}

=head2 _recv_field($hd, \@field)
=cut
sub _recv_field {
    warn "get field." if DEV;
    my $field = $_[1];
    recv_packet($_[0], sub {
        warn "got field!" if DEV;
        push @$field, [
            take_lcs($_[0]), take_lcs($_[0]), take_lcs($_[0]),
            take_lcs($_[0]), take_lcs($_[0]), take_lcs($_[0]),
            take_filler($_[0], 1),
            take_num($_[0], 2),
            take_num($_[0], 4),
            take_num($_[0], 1),
            take_num($_[0], 2),
            take_num($_[0], 1),
            take_filler($_[0], 2),
            take_lcb($_[0]),
        ];
    });
}

=head2 recv_response($hd, %opt, $cb->(TYPE, data...))
  RES_OK, $affected_rows, $insert_id, $server_status, $warning_count, $message
  RES_ERROR, $errno, $sqlstate, $message
  RES_RESULT, \@field, \@row
   $field[$i] = [$catalog, $db, $table, $org_table, $name, $org_name, $charsetnr, $length, $type, $flags, $decimals, $default]
   $row[$i] = [$field, $field, $field, ...]
  RES_PREPARE, $stmt_id, \@param, \@column, $warning_count
   $param[$i] = [$catalog, $db, $table, $org_table, $name, $org_name, $charsetnr, $length, $type, $flags, $decimals, $default]
   $column[$i] = [$catalog, $db, $table, $org_table, $name, $org_name, $charsetnr, $length, $type, $flags, $decimals, $default]
 opt:
  prepare (set to truthy to recv prepare_ok)
=cut
sub recv_response {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : sub {};
    my($hd, %opt) = @_;

    if( DEV ) {
        my $cb0 = $cb;
        $cb = sub {
            use Data::Dumper;
            warn "recv_response: ".Dumper(\@_);
            &$cb0;
        };
    }

    recv_packet($hd, sub {
        my $head = substr($_[0], 0, 1);
        if( $head eq "\x00" ) { # OK
            substr($_[0], 0, 1, '');
            if( $opt{prepare} ) {
                my $stmt_id = take_num($_[0], 4);
                my $column_count = take_num($_[0], 2);
                my $param_count = take_num($_[0], 2);
                take_filler($_[0], 1);
                my $warning_count = take_num($_[0], 2);
                warn "stmt_id=$stmt_id, column_count=$column_count, param_count=$param_count, warning_count=$warning_count" if DEV;

                my(@param, @column);

                my $end_cv = AE::cv {
                    $cb->(RES_PREPARE, $stmt_id, \@param, \@column, $warning_count);
                };

                $end_cv->begin;

                if( $param_count ) {
                    $end_cv->begin;
                    for(my $i=0; $i<$param_count; ++$i) {
                        _recv_field($hd, \@param);
                    }
                    recv_packet($hd, sub { $end_cv->end }); # EOF
                }

                if( $column_count ) {
                    $end_cv->begin;
                    for(my $i=0; $i<$column_count; ++$i) {
                        _recv_field($hd, \@column);
                    }
                    recv_packet($hd, sub { $end_cv->end }); # EOF
                }

                $end_cv->end;
            }
            else {
                $cb->(
                    RES_OK,
                    take_lcb($_[0]),
                    take_lcb($_[0]),
                    take_num($_[0], 2),
                    take_num($_[0], 2),
                    $_[0],
                );
            }
        }
        elsif( $head eq "\xFF" ) { # Error
            substr($_[0], 0, 1, '');
            $cb->(
                RES_ERROR,
                take_num($_[0], 2),
                ( substr($_[0], 0, 1) eq '#' ?
                  ( substr($_[0], 1, 5), substr($_[0], 6) ) : # ver 4.1
                  ( undef, $_[0] )                            # ver 4.0
                )
            );
        }
        else { # Others (EOF shouldn't be here)
            my $field_count = take_lcb($_[0]);
            my $extra = $_[0] eq '' ? undef : take_lcb($_[0]);

            warn "field_count=$field_count" if DEV;

            my @field;
            for(my $i=0; $i<$field_count; ++$i) {
                _recv_field($hd, \@field);
            }
            recv_packet($hd, sub{ warn "got EOF" if DEV }); # EOF

            my @row;
            my $fetch_row; $fetch_row = sub { # text format
                warn "get row." if DEV;
                recv_packet($hd, sub {
                    if( substr($_[0], 0, 1) eq "\xFE" ) { # EOF
                        warn "got EOF!" if DEV;
                        undef $fetch_row;
                        $cb->(
                            RES_RESULT,
                            \@field,
                            \@row,
                        );
                    }
                    else {
                        warn "got row!" if DEV;
                        my @cell;
                        if( $opt{execute} ) {
                            take_filler($_[0], 1);
                            my $null_bit_map = substr($_[0], 0, $field_count + 9 >> 3, '');
                            for(my $i=0; $i<$field_count; ++$i) {
                                if( vec($null_bit_map, 2+$i, 1) ) {
                                    push @cell, undef;
                                }
                                else {
                                    push @cell, take_type($_[0], $field[$i][8], $field[$i][7], $field[$i][9]);
                                }
                            }
                        }
                        else {
                            for(my $i=0; $i<$field_count; ++$i) {
                                push @cell, take_lcs($_[0]);
                            }
                        }
                        push @row, \@cell;
                        $fetch_row->();
                    }
                });
            };
            $fetch_row->();
        }
    });
}

=head2 do_auth($hd, $username, [$password, [$database,]] $cb->($success, $err_num_and_msg, $thread_id))
=cut
sub do_auth {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : sub {};
    my($hd, $username, $password, $database) = @_;

    recv_packet($hd, sub {
        if( DEV ) {
            my $hex = $_[0];
            $hex =~ s/(.)/sprintf"%02X ",ord$1/ges;
            my $ascii = $_[0];
            $ascii =~ s/([^\x20-\x7E])/./g;
            warn $hex, $ascii;
        }
        my $proto_ver = take_num($_[0], 1); warn "proto_ver:$proto_ver" if DEV;
        my $server_ver = take_zstr($_[0]); warn "server_ver:$server_ver" if DEV;
        my $thread_id = take_num($_[0], 4); warn "thread_id:$thread_id" if DEV;
        my $scramble_buff = take_str($_[0], 8).substr($_[0], 19, 12); warn "scramble_buff:$scramble_buff" if DEV;
        my $filler = take_num($_[0], 1); warn "filler:$filler" if DEV;
        my $server_cap = take_num($_[0], 2);
        my $server_lang = take_num($_[0], 1); warn "server_lang:$server_lang" if DEV;
        my $server_status = take_num($_[0], 2); warn "server_status:$server_status" if DEV;
        $server_cap += take_num($_[0], 2) << 16;
        if( DEV ) {
            warn "server_cap:";
            warn "  CLIENT_LONG_PASSWORD" if( $server_cap & CLIENT_LONG_PASSWORD );
            warn "  CLIENT_FOUND_ROWS" if( $server_cap & CLIENT_FOUND_ROWS );
            warn "  CLIENT_LONG_FLAG" if( $server_cap & CLIENT_LONG_FLAG );
            warn "  CLIENT_CONNECT_WITH_DB" if( $server_cap & CLIENT_CONNECT_WITH_DB );
            warn "  CLIENT_NO_SCHEMA" if( $server_cap & CLIENT_NO_SCHEMA );
            warn "  CLIENT_COMPRESS" if( $server_cap & CLIENT_COMPRESS );
            warn "  CLIENT_ODBC" if( $server_cap & CLIENT_ODBC );
            warn "  CLIENT_LOCAL_FILES" if( $server_cap & CLIENT_LOCAL_FILES );
            warn "  CLIENT_IGNORE_SPACE" if( $server_cap & CLIENT_IGNORE_SPACE );
            warn "  CLIENT_PROTOCOL_41" if( $server_cap & CLIENT_PROTOCOL_41 );
            warn "  CLIENT_INTERACTIVE" if( $server_cap & CLIENT_INTERACTIVE );
            warn "  CLIENT_SSL" if( $server_cap & CLIENT_SSL );
            warn "  CLIENT_IGNORE_SIGPIPE" if( $server_cap & CLIENT_IGNORE_SIGPIPE );
            warn "  CLIENT_TRANSACTIONS" if( $server_cap & CLIENT_TRANSACTIONS );
            warn "  CLIENT_RESERVED" if( $server_cap & CLIENT_RESERVED );
            warn "  CLIENT_SECURE_CONNECTION" if( $server_cap & CLIENT_SECURE_CONNECTION );
            warn "  CLIENT_MULTI_STATEMENTS" if( $server_cap & CLIENT_MULTI_STATEMENTS );
            warn "  CLIENT_MULTI_RESULTS" if( $server_cap & CLIENT_MULTI_RESULTS );
        }
        my $scramble_len = take_num($_[0], 1); warn "scramble_len:$scramble_len" if DEV;

        my $packet = '';
        put_num($packet, $server_cap & (
            CLIENT_LONG_PASSWORD     | # new more secure passwords
            CLIENT_FOUND_ROWS        | # Found instead of affected rows
            CLIENT_LONG_FLAG         | # Get all column flags
            CLIENT_CONNECT_WITH_DB   | # One can specify db on connect
            # CLIENT_NO_SCHEMA         | # Don't allow database.table.column
            # CLIENT_COMPRESS          | # Can use compression protocol
            # CLIENT_ODBC              | # Odbc client
            # CLIENT_LOCAL_FILES       | # Can use LOAD DATA LOCAL
            # CLIENT_IGNORE_SPACE      | # Ignore spaces before '('
            CLIENT_PROTOCOL_41       | # New 4.1 protocol
            # CLIENT_INTERACTIVE       | # This is an interactive client
            # CLIENT_SSL               | # Switch to SSL after handshake
            # CLIENT_IGNORE_SIGPIPE    | # IGNORE sigpipes
            CLIENT_TRANSACTIONS      | # Client knows about transactions
            # CLIENT_RESERVED          | # Old flag for 4.1 protocol 
            CLIENT_SECURE_CONNECTION | # New 4.1 authentication
            CLIENT_MULTI_STATEMENTS  | # Enable/disable multi-stmt support
            CLIENT_MULTI_RESULTS     | # Enable/disable multi-results
            0
        ), 4); # client_flags
        put_num($packet, 0x1000000, 4); # max_packet_size
        put_num($packet, $server_lang, 1); # charset_number
        $packet .= "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"; # filler
        put_zstr($packet, $username); # username
        if( $password eq '' ) {
            put_lcs($packet, '');
        }
        else {
            my $stage1_hash = sha1($password);
            put_lcs($packet, sha1($scramble_buff.sha1($stage1_hash)) ^ $stage1_hash); # scramble buff
        }
        put_zstr($packet, $database); # database name

        send_packet($hd, 1, $packet);
        recv_packet($hd, sub {
            if( parse_ok($_[0]) ) {
                $cb->(1, undef, $thread_id);
            }
            else {
                my($errno, $sqlstate, $message) = parse_error($_[0]);
                warn "$errno [$sqlstate] $message" if DEV;
                $cb->(0, dualvar($errno, $message));
            }
        });
    });
}

=head2 do_reset_stmt($hd, $stmt_id)
=cut
sub do_reset_stmt {
    my $packet = '';
    put_num($packet, $_[1], 4);
    send_packet($_[0], 0, COM_STMT_RESET, $packet);
}

=head2 do_long_data_packet($hd, $stmt_id, $param_num, $type, $data, $len, $flag, $packet_num)
=cut
sub do_long_data_packet {
    my $packet = '';
    put_num($packet, $_[1], 4);
    put_num($packet, $_[2], 2);
    put_num($packet, $_[3], 2);
    put_type($packet, $_[4], $_[3], $_[5], $_[6]);
    send_packet($_[0], $_[7], COM_STMT_SEND_LONG_DATA, $packet);
}

=head2 do_execute($hd, $stmt_id, $null_bit_map, $packet_num)
=cut
sub do_execute {
    my $packet = '';
    put_num($packet, $_[1], 4);
    $packet .= "\0\1\0\0\0";
    $packet .= $_[2];
    $packet .= "\0";
    send_packet($_[0], $_[3], COM_STMT_EXECUTE, $packet);
}

=head2 do_execute_param($hd, $stmt_id, \@param, \@param_config)
=cut
sub do_execute_param {
    my $null_bit_map = pack('b*', join '', map { defined($_) ? '0' : '1' } @{$_[2]});
    my $packet = '';
    put_num($packet, $_[1], 4);
    $packet .= "\0\1\0\0\0";
    $packet .= $null_bit_map;
    $packet .= "\1";
    for(my $i=0; $i<@{$_[2]}; ++$i) {
        #put_num($packet, $_[3][$i][8], 2);
        put_num($packet, MYSQL_TYPE_BLOB, 2);
    }
    for(my $i=0; $i<@{$_[2]}; ++$i) {
        if( defined($_[2][$i]) ) {
            #put_type($packet, $_[2][$i], $_[3][$i][8], $_[3][$i][7], $_[3][$i][9]);
            put_type($packet, $_[2][$i], MYSQL_TYPE_BLOB, length($_[2][$i]), $_[3][$i][9]);
        }
    }
    send_packet($_[0], 0, COM_STMT_EXECUTE, $packet);
}

1;
