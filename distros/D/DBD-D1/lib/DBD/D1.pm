package DBD::D1;

# DBD::D1 - DBI driver for Cloudflare D1 (SQLite-compatible serverless database)
# Communicates with Cloudflare D1 via the REST API using HTTP::Tiny and JSON::PP.

use strict;
use warnings;

our $VERSION  = '0.02';
our $err      = 0;
our $errstr   = '';
our $sqlstate = '';
our $drh      = undef;

use DBI ();
use DBI::DBD;

sub driver {
    return $drh if $drh;
    my ($class, $attr) = @_;
    $class .= '::dr';
    $drh = DBI::_new_drh($class, {
        Name        => 'D1',
        Version     => $VERSION,
        Err         => \$DBD::D1::err,
        Errstr      => \$DBD::D1::errstr,
        State       => \$DBD::D1::sqlstate,
        Attribution => 'DBD::D1',
    }) or return undef;
    return $drh;
}

sub CLONE { undef $drh }

# ---------------------------------------------------------------
# Internal HTTP helper
# ---------------------------------------------------------------
package DBD::D1::_http;

use strict;
use warnings;
use HTTP::Tiny ();
use JSON::PP   ();

my $json = JSON::PP->new->utf8->allow_nonref;

sub _ssl_available { HTTP::Tiny->can_ssl ? 1 : 0 }

# Returns ($result_arrayref, undef) on success or (undef, $error_string) on failure.
sub query {
    my ($account_id, $database_id, $api_token, $sql, $params) = @_;

    unless (_ssl_available()) {
        return (undef,
            'DBD::D1 requires HTTPS. Install IO::Socket::SSL and Net::SSLeay: '
          . 'cpanm IO::Socket::SSL Net::SSLeay');
    }

    my $url = sprintf(
        'https://api.cloudflare.com/client/v4/accounts/%s/d1/database/%s/query',
        $account_id, $database_id,
    );

    my $body = $json->encode({
        sql    => $sql,
        params => ($params && @$params) ? $params : [],
    });

    my $http = HTTP::Tiny->new(
        default_headers => {
            'Authorization' => "Bearer $api_token",
            'Content-Type'  => 'application/json',
        },
        timeout => 30,
    );

    my $res = $http->post($url, { content => $body });

    # Try to parse JSON response to get detailed error info
    my $data;
    if ($res->{content}) {
        $data = eval { $json->decode($res->{content}) };
    }

    unless ($res->{success}) {
        my $detail = $res->{content} // '';
        if ($res->{status} == 599 && $detail =~ /ssl|IO::Socket/i) {
            return (undef,
                'HTTPS failed (status 599). '
              . 'Install IO::Socket::SSL and Net::SSLeay: '
              . 'cpanm IO::Socket::SSL Net::SSLeay');
        }
        
        # If we have JSON error details, use those
        if ($data && ref $data eq 'HASH') {
            if (!$data->{success}) {
                my $errs = $data->{errors} // [];
                if (@$errs) {
                    my $msg = $errs->[0]{message} // 'Unknown D1 API error';
                    return (undef, $msg);
                }
            }
        }
        
        return (undef, sprintf('HTTP %s: %s', $res->{status}, $res->{reason} // 'Unknown'));
    }

    if (!$data) {
        $data = eval { $json->decode($res->{content}) };
        if ($@) { return (undef, "JSON decode error: $@") }
    }

    unless ($data->{success}) {
        my $errs = $data->{errors} // [];
        my $msg  = @$errs ? $errs->[0]{message} : 'Unknown D1 API error';
        return (undef, $msg);
    }

    return ($data->{result}, undef);
}

# ---------------------------------------------------------------
# DBD::D1::dr  – driver handle
# ---------------------------------------------------------------
package DBD::D1::dr;

use strict;
use warnings;

$DBD::D1::dr::imp_data_size = 0;

# DSN:  dbi:D1:account_id=<id>;database_id=<id>
# Pass Cloudflare API token as $password.
sub connect {
    my ($drh, $dsn, $user, $auth, $attr) = @_;

    my %dsnargs;
    for my $pair (split /;/, $dsn) {
        my ($k, $v) = split /=/, $pair, 2;
        $dsnargs{$k} = $v if defined $k && defined $v;
    }

    # Use DBI->set_err on the drh with the caller's err/errstr so that
    # PrintError/RaiseError on the caller handle control output, not the drh.
    my $account_id = $dsnargs{account_id}
        or return $drh->set_err(1,
            "DBD::D1 connect: 'account_id' missing from DSN", undef, 'connect');

    my $database_id = $dsnargs{database_id}
        or return $drh->set_err(1,
            "DBD::D1 connect: 'database_id' missing from DSN", undef, 'connect');

    my $api_token = $auth || $dsnargs{api_token}
        or return $drh->set_err(1,
            "DBD::D1 connect: Cloudflare API token required (pass as password)", undef, 'connect');

    my ($outer, $dbh) = DBI::_new_dbh($drh, { Name => $dsn });

    $dbh->{Active}          = 1;
    $dbh->{d1_account_id}   = $account_id;
    $dbh->{d1_database_id}  = $database_id;
    $dbh->{d1_api_token}    = $api_token;

    return $outer;
}

sub data_sources { () }
sub disconnect_all { }

# ---------------------------------------------------------------
# DBD::D1::db  – database handle
# ---------------------------------------------------------------
package DBD::D1::db;

use strict;
use warnings;

$DBD::D1::db::imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, @attribs) = @_;

    my ($outer, $sth) = DBI::_new_sth($dbh, { Statement => $statement });

    # Count ? placeholders outside quoted strings
    (my $copy = $statement) =~ s/'[^']*'|"[^"]*"//g;
    my $num_params = () = $copy =~ /\?/g;

    $sth->{NUM_OF_PARAMS}    = $num_params;
    $sth->{d1_params}        = [];
    $sth->{d1_rows_affected} = undef;
    $sth->{d1_result_data}   = undef;
    $sth->{d1_cursor}        = 0;

    return $outer;
}

sub commit {
    my ($dbh) = @_;
    warn "DBD::D1: commit() has no effect – D1 is AutoCommit only\n"
        if $dbh->{Warn};
    return 1;
}

sub rollback {
    my ($dbh) = @_;
    warn "DBD::D1: rollback() has no effect – D1 is AutoCommit only\n"
        if $dbh->{Warn};
    return 0;
}

sub disconnect {
    my ($dbh) = @_;
    $dbh->{Active} = 0;
    return 1;
}

sub ping {
    my ($dbh) = @_;
    my $prev_raise = $dbh->{RaiseError};
    my $prev_print = $dbh->{PrintError};
    $dbh->{RaiseError} = 0;
    $dbh->{PrintError} = 0;

    my $ok = 0;
    eval {
        my $sth = $dbh->prepare('SELECT 1');
        $ok = 1 if $sth && $sth->execute();
    };

    $dbh->{RaiseError} = $prev_raise;
    $dbh->{PrintError} = $prev_print;
    return $ok;
}

sub FETCH {
    my ($dbh, $attr) = @_;
    return 1          if $attr eq 'AutoCommit';
    return $dbh->{$attr} if $attr =~ /^d1_/;
    return $dbh->SUPER::FETCH($attr);
}

sub STORE {
    my ($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
        die "DBD::D1: AutoCommit cannot be disabled\n" unless $val;
        return 1;
    }
    if ($attr =~ /^d1_/) { $dbh->{$attr} = $val; return 1 }
    return $dbh->SUPER::STORE($attr, $val);
}

sub table_info {
    my ($dbh) = @_;
    return $dbh->prepare(q{
        SELECT NULL AS TABLE_CAT, NULL AS TABLE_SCHEM,
               name AS TABLE_NAME, type AS TABLE_TYPE, NULL AS REMARKS
        FROM   sqlite_master
        WHERE  type IN ('table','view')
        ORDER  BY name
    });
}

sub column_info {
    my ($dbh, $catalog, $schema, $table, $column) = @_;
    $table =~ s/[^\w]//g;
    my $sth_raw = $dbh->prepare(qq{PRAGMA table_info("$table")})
        or return undef;
    $sth_raw->execute() or return undef;

    my @cols;
    while (my $row = $sth_raw->fetchrow_hashref) {
        push @cols, {
            TABLE_CAT        => undef,
            TABLE_SCHEM      => undef,
            TABLE_NAME       => $table,
            COLUMN_NAME      => $row->{name},
            DATA_TYPE        => DBD::D1::db::_sqlite_type_to_sql_type($row->{type}),
            TYPE_NAME        => $row->{type},
            COLUMN_DEF       => $row->{dflt_value},
            NULLABLE         => $row->{notnull} ? 0 : 1,
            ORDINAL_POSITION => $row->{cid} + 1,
        };
    }

    my $sponge = DBI->connect("dbi:Sponge:", '', '', { RaiseError => 1 });
    my @field_names = qw(
        TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
        DATA_TYPE TYPE_NAME COLUMN_DEF NULLABLE ORDINAL_POSITION
    );
    my @rows;
    for my $h (@cols) {
        push @rows, [ @{$h}{@field_names} ];
    }
    return $sponge->prepare("column_info $table", {
        rows          => \@rows,
        NAME          => \@field_names,
        NUM_OF_FIELDS => scalar @field_names,
    });
}

sub _sqlite_type_to_sql_type {
    my ($type) = @_;
    $type = uc($type // '');
    return 4  if $type =~ /INT/;
    return 12 if $type =~ /CHAR|TEXT|CLOB/;
    return 8  if $type =~ /REAL|FLOA|DOUB/;
    return -2 if $type =~ /BLOB/;
    return 0;
}

# ---------------------------------------------------------------
# DBD::D1::st  – statement handle
# ---------------------------------------------------------------
package DBD::D1::st;

use strict;
use warnings;

$DBD::D1::st::imp_data_size = 0;

sub bind_param {
    my ($sth, $pNum, $val, $attr) = @_;
    $sth->{d1_params}[$pNum - 1] = $val;
    return 1;
}

sub execute {
    my ($sth, @bind_values) = @_;

    my @params = @bind_values ? @bind_values : @{ $sth->{d1_params} // [] };

    my $dbh         = $sth->{Database};
    my $account_id  = $dbh->{d1_account_id};
    my $database_id = $dbh->{d1_database_id};
    my $api_token   = $dbh->{d1_api_token};
    my $sql         = $sth->{Statement};

    my ($result, $err) = DBD::D1::_http::query(
        $account_id, $database_id, $api_token, $sql, \@params,
    );

    if (defined $err) {
        return $sth->set_err(1, $err);
    }

    # D1 REST returns an array of result objects (one per statement).
    my $res  = ref($result) eq 'ARRAY' ? $result->[0] : $result;
    my $rows = $res->{results} // [];   # array of hashrefs
    my $meta = $res->{meta}    // {};

    if (@$rows) {
        my @col_names = sort keys %{ $rows->[0] };

        # Must use direct hash assignment – STORE() rejects DBI read-only attrs
        $sth->{NAME}          = \@col_names;
        $sth->{NAME_lc}       = [ map { lc $_ } @col_names ];
        $sth->{NAME_uc}       = [ map { uc $_ } @col_names ];
        $sth->{NUM_OF_FIELDS} = scalar @col_names;

        $sth->{d1_result_data} = [
            map { my $r = $_; [ @{$r}{@col_names} ] } @$rows
        ];
    } else {
        $sth->{NAME}           = [];
        $sth->{NAME_lc}        = [];
        $sth->{NAME_uc}        = [];
        $sth->{NUM_OF_FIELDS}  = 0;
        $sth->{d1_result_data} = [];
    }

    $sth->{d1_cursor}        = 0;
    $sth->{d1_rows_affected} = $meta->{changes} // $meta->{rows_affected} // 0;
    $sth->{Active}           = 1;

    return $sth->{d1_rows_affected} || '0E0';
}

sub fetchrow_arrayref {
    my ($sth) = @_;
    my $data   = $sth->{d1_result_data} or return undef;
    my $cursor = $sth->{d1_cursor};

    if ($cursor >= scalar @$data) {
        $sth->{Active} = 0;
        return undef;
    }

    $sth->{d1_cursor}++;
    return $data->[$cursor];
}

*fetch = \&fetchrow_arrayref;

sub fetchall_arrayref {
    my ($sth, $slice, $max_rows) = @_;
    my $data = $sth->{d1_result_data} // [];
    my @result;

    for my $row (@$data) {
        last if defined $max_rows && @result >= $max_rows;
        if (!defined $slice) {
            push @result, [@$row];
        } elsif (ref $slice eq 'HASH') {
            my $names = $sth->{NAME} // [];
            my %h; @h{@$names} = @$row;
            my @keys = keys %$slice ? keys %$slice : keys %h;
            push @result, { map { $_ => $h{$_} } @keys };
        } elsif (ref $slice eq 'ARRAY') {
            push @result, [ @{$row}[@$slice] ];
        }
    }

    $sth->{Active} = 0;
    return \@result;
}

sub rows   { $_[0]->{d1_rows_affected} // -1 }

sub finish {
    my ($sth) = @_;
    $sth->{Active}          = 0;
    $sth->{d1_result_data}  = undef;
    $sth->{d1_cursor}       = 0;
    return 1;
}

sub FETCH {
    my ($sth, $attr) = @_;
    return $sth->{$attr} if $attr =~ /^d1_/;
    return $sth->SUPER::FETCH($attr);
}

sub STORE {
    my ($sth, $attr, $val) = @_;
    if ($attr =~ /^d1_/) { $sth->{$attr} = $val; return 1 }
    return $sth->SUPER::STORE($attr, $val);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::D1 - DBI driver for Cloudflare D1 (serverless SQLite)

=head1 VERSION

0.02

=head1 SYNOPSIS

    use DBI;

    my $dbh = DBI->connect(
        'dbi:D1:account_id=<ACCOUNT_ID>;database_id=<DATABASE_ID>',
        undef,
        $ENV{CF_API_TOKEN},
        { RaiseError => 1, PrintError => 0 },
    ) or die $DBI::errstr;

    my $sth = $dbh->prepare('SELECT * FROM users WHERE active = ?');
    $sth->execute(1);

    while (my $row = $sth->fetchrow_hashref) {
        printf "%s <%s>\n", $row->{name}, $row->{email};
    }

    $dbh->disconnect;

=head1 DESCRIPTION

B<DBD::D1> is a L<DBI> driver for L<Cloudflare D1|https://developers.cloudflare.com/d1/>,
Cloudflare's serverless SQLite-compatible relational database.

It communicates via the D1 REST API using L<HTTP::Tiny> and L<JSON::PP>
(both ship with Perl 5.14+), so no compiled extensions are required.

=head1 DSN FORMAT

    dbi:D1:account_id=<ACCOUNT_ID>;database_id=<DATABASE_ID>

=head1 AUTHENTICATION

Pass your Cloudflare API token (B<D1 Edit> permission) as the C<$password>
argument to C<DBI-E<gt>connect()>.

=head1 LIMITATIONS

=over 4

=item * B<AutoCommit only> – D1 REST has no multi-statement transaction support.

=item * B<Column ordering> – rows arrive as JSON objects; column order follows
C<sort> on key names. Use C<fetchrow_hashref> for reliable named access.

=back

=head1 DEPENDENCIES

L<DBI>, L<HTTP::Tiny>, L<JSON::PP>, L<IO::Socket::SSL>, L<Net::SSLeay>

=head1 AUTHOR

Aldo Montes Zapata, C<< <amontes@cpan.org> >>

=head1 COPYRIGHT (c)

Copyright 2026 by Aldo Montes Zapata C<< <amontes@cpan.org> >>.

=head1 LICENSE

Same terms as Perl itself.

=cut
