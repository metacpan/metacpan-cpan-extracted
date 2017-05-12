# $Id: Default.pm,v 1.1 2001/08/02 16:32:22 matt Exp $

package Example::DB::Default;

use strict;

use Time::Object;
use Time::Seconds;

use Digest::MD5 qw(md5_hex);

sub ping {
    my $self = shift;
    my $dbh = $self->get_dbh;
    return $dbh->ping;
}

sub commit {
    my $self = shift;

    # More commits than begin_tran.  Not correct.
    unless ( defined $self->{tran_count} ) {
        my $callee = (caller(1))[3];
        warn "$callee called commit without corresponding begin_tran call\n";
    }

    $self->{tran_count}--;

    # Don't actually commit to we reach 'uber-commit'
    return if $self->{tran_count};

    my $dbh = $self->get_dbh;
    if (!$dbh->{AutoCommit}) {
        $dbh->commit;
    }
    $dbh->{AutoCommit} = 1;

    $self->{tran_count} = undef;
}

sub rollback {
    my $self = shift;
    
    my $dbh = $self->get_dbh;
    if (!$dbh->{AutoCommit}) {
        $dbh->rollback;
    }
    $dbh->{AutoCommit} = 1;

    $self->{tran_count} = undef;
}

sub begin_tran {
    my $self = shift;

    $self->{tran_count} = 0 unless defined $self->{tran_count};
    $self->{tran_count}++;

    $self->get_dbh->{AutoCommit} = 0;
}

sub DESTROY
{
    my $self = shift;

    if ( $self->{tran_count} ) {
        warn "DB object is going out of scope with unbalanced begin_tran/commit call count of $self->{tran_count}\n";
    }
}

###############################
# Utility SQL executing methods
###############################

sub get_rows
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => ['sql'],
#                   optional => [ qw( begin limit bind ) ],
#                 );

    my %p = @_;
    my $sth = $self->_prepare_and_execute(%p);

    my @data;
    eval {
        my @row;
        $sth->bind_columns( \ (@row[ 0..$#{ $sth->{NAME_lc} } ] ) );

        while ( $sth->fetch ) {
            push @data, [@row];
        }

        $sth->finish;
    };
    if ($@) {
        my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
        Example::Exception::SQL->throw( -text => $@,
                           -sql => $p{sql},
                           -bind => \@bind );
    }

    if ( $p{limit} && @data > $p{limit} ) {
        my $end = $p{limit} + $p{begin} - 1;
        $end = $#data if $end > $#data;
        @data = @data[$p{begin}..$end];
    }

    return @data;
}

sub get_rows_hashref
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => ['sql'],
#                   optional => [ qw( begin limit bind ) ],
#                 );
    my %p = @_;
    my $sth = $self->_prepare_and_execute(%p);

    my @data;

    eval {
        my %hash;
        $sth->bind_columns( \ ( @hash{ @{ $sth->{NAME_lc} } } ) );

        while ( $sth->fetch ) {
            push @data, {%hash};
        }

        $sth->finish;
    };
    if ($@) {
        my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
        Example::Exception::SQL->throw( -text => $@,
                           -sql => $p{sql},
                           -bind => \@bind );
    }

    if ( $p{limit} && @data > $p{limit} ) {
        my $end = $p{limit} + $p{begin} - 1;
        $end = $#data if $end > $#data;
        @data = @data[$p{begin}..$end];
    }

    return @data;
}

sub get_one_row
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => ['sql'],
#                   optional => [ qw( bind ) ],
#                 );
    my %p = @_;

    my $sth = $self->_prepare_and_execute(%p);

    my @row;
    eval {
        @row = $sth->fetchrow_array;
        $sth->finish;
    };
    if ($@) {
        my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
        Example::Exception::SQL->throw( -text => $@,
                           -sql => $p{sql},
                           -bind => \@bind );
    }

    return wantarray ? @row : $row[0];
}

sub get_one_row_hash
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => ['sql'],
#                   optional => [ qw( bind ) ],
#                 );
    my %p = @_;

    my $sth = $self->_prepare_and_execute(%p);

    my %hash;
    eval {
        my @row = $sth->fetchrow_array;
        @hash{ @{ $sth->{NAME_lc} } } = @row if @row;
        $sth->finish;
    };
    if ($@) {
        my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
        Example::Exception::SQL->throw( -text => $@,
                           -sql => $p{sql},
                           -bind => \@bind );
    }

    return %hash;
}

sub get_column
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => ['sql'],
#                   optional => [ qw( begin limit bind ) ],
#                 );
    my %p = @_;
    my $sth = $self->_prepare_and_execute(%p);

    my @data;
    eval {
        my @row;
        $sth->bind_columns( \ (@row[ 0..$#{ $sth->{NAME_lc} } ] ) );

        while ( $sth->fetch ) {
            push @data, $row[0];
        }
        $sth->finish;
    };
    if ($@) {
        my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
        Example::Exception::SQL->throw( -text => $@,
                           -sql => $p{sql},
                           -bind => \@bind );
    }

    if ( $p{limit} && @data > $p{limit} ) {
        my $end = $p{limit} + $p{begin} - 1;
        $end = $#data if $end > $#data;
        @data = @data[$p{begin}..$end];
    }

    return wantarray ? @data : $data[0];
}

sub do_sql
{
    my $self = shift;
#    ::Utils::check_params( @_,
#				   mandatory => ['sql'],
#				   optional => [ qw( bind ) ],
#				 );
    my %p = @_;

    my $sth = $self->_prepare_and_execute(%p);

    my $rows;
    eval {
	$rows = $sth->rows;
	$sth->finish;
    };
    if ($@) {
	my @bind = exists $p{bind} ? ( ref $p{bind} ? $p{bind} : [$p{bind}] ) : ();
	Example::Exception::SQL->throw( -text => $@,
					       -sql => $p{sql},
					       -bind => \@bind );
    }

    return $rows;
}

sub _prepare_and_execute
{
    die "Virtual function _prepare_and_execute";
}

sub _outer_join
{
    my $self = shift;
#    ::Utils::check_params( @_,
#                   mandatory => [ qw( select from join ) ],
#                   optional => [ qw( where ) ],
#                 );
    my %p = @_;

    my $outer_join = $self->_outer_join_operator;
    my $sql = 'SELECT ';
    $sql .= join ', ', @{ $p{select} };
    $sql .= ' FROM ';
    $sql .= join ', ', @{ $p{from} };
    $sql .= " WHERE $p{join}->[0] $outer_join $p{join}->[1]";
    $sql .= " AND $p{where}" if $p{where};

    return $sql;
}

sub get_next_pk
{
    die "get_next_pk is a virtual method and must be subclassed";
}

sub last_id
{
    die "last_id is a virtual method and must be subclassed";
}

sub sql_date {
    my $time = $_[1] || time;
    return localtime($time)->strftime('%Y/%m/%d %H:%M:%S');
}

sub sql_date_struct {
    my $self = shift;
    my $struct = shift;
    
    my $date = sprintf("%04d/%02d/%02d",
            $struct->{year},
            $struct->{month},
            $struct->{day_of_month},
            );

    $struct->{hours} ||= 0;
    $struct->{minutes} ||= 0;
    $struct->{seconds} ||= 0;

    $date .= sprintf(" %02d:%02d:%02d",
             $struct->{hours},
             $struct->{minutes},
             $struct->{seconds},
            );

    return $date;
}

###############################################################
# Main SQL methods here
###############################################################

sub match_user {
    my $self = shift;
    
    my ($username, $password) = @_;
    
    my ($user_id) = $self->get_one_row(
            sql => "SELECT id FROM CMSUser WHERE username = ? AND password_md5 = ?",
            bind => [ $username, md5_hex($password) ],
            );
    
    return $user_id;
}

sub get_asset {
    my $self = shift;
    my %p = @_;
    
    my @bind;
    push @bind, $p{asset_id} if $p{asset_id};
    push @bind, $p{status} if $p{status};
    push @bind, $p{type} if $p{type};

    return $self->get_rows_hashref(
            sql => "SELECT WebItem.id,
                           ItemType.short_desc    AS item_type,
                           WebItem.item_type_id,
                           ItemStatus.description AS item_status,
                           WebItem.item_status_id,
                           ItemGroup.description  AS item_group,
                           WebItem.item_group_id,
                           to_char(WebItem.date_created, 'Month DD, YYYY') AS date_created,
                           to_char(WebItem.date_live, 'Month DD, YYYY') AS date_live,
                           to_char(WebItem.date_live, 'YYYY') AS live_year,
                           to_char(WebItem.date_live, 'MM') AS live_mon,
                           to_char(WebItem.date_live, 'DD') AS live_day,
                           to_char(WebItem.date_live, 'HH') as live_hour,
                           to_char(WebItem.date_expires, 'Month DD, YYYY') AS date_expires,
                           to_char(WebItem.date_expires, 'YYYY') AS expires_year,
                           to_char(WebItem.date_expires, 'MM') AS expires_mon,
                           to_char(WebItem.date_expires, 'DD') AS expires_day,
                           WebItem.title,
                           WebItem.link,
                           WebItem.subtitle,
                           WebItem.location,
                           WebItem.booth,
                           WebItem.body
                    FROM WebItem 
                    JOIN ItemType 
                      ON WebItem.item_type_id = ItemType.id
                    JOIN ItemStatus
                      ON WebItem.item_status_id = ItemStatus.id
                    JOIN ItemGroup
                      ON WebItem.item_group_id = ItemGroup.id
                    WHERE 1 = 1
                    " .
                  ($p{asset_id} ? " AND WebItem.id = ? " : "") .
                  ($p{status} ? " AND ItemStatus.description = ? " : "") .
                  ($p{type} ? " AND ItemType.short_desc = ? " : "") .
                  ($p{include_expired} ? "" : "AND WebItem.date_expires > now()"),
            (@bind ? (bind => \@bind) : ()),
            );
}

sub update_announce {
    my $self = shift;
    my %p = @_;
    
    $p{expires} = $self->sql_date_struct($p{expires});
    $p{live} = $self->sql_date_struct($p{live});
    
    $self->do_sql(
            sql => "UPDATE WebItem
                    SET title = ?,
                        link = ?,
                        date_expires = ?,
                        date_live = ?
                    WHERE id = ?",
            bind => [ @p{qw(title link expires live id)} ],
            );
}

sub update_news {
    my $self = shift;
    my %p = @_;
    
    $p{expires} = $self->sql_date_struct($p{expires});
    $p{live} = $self->sql_date_struct($p{live});
    
    $self->do_sql(
            sql => "UPDATE WebItem
                    SET title = ?,
                        link = ?,
                        date_expires = ?,
                        date_live = ?
                    WHERE id = ?",
            bind => [ @p{qw(title link expires live id)} ],
            );
}

sub update_event {
    my $self = shift;
    my %p = @_;
    
    $p{expires} = $self->sql_date_struct($p{expires});
    $p{live} = $self->sql_date_struct($p{live});
    
    $self->do_sql(
            sql => "UPDATE WebItem
                    SET title = ?,
                        link = ?,
                        date_expires = ?,
                        date_live = ?,
                        location = ?,
                        booth = ?
                    WHERE id = ?",
            bind => [ @p{qw(title link expires live location booth id)} ],
            );
}

sub update_pr {
    my $self = shift;
    my %p = @_;
    
    $p{expires} = $self->sql_date_struct($p{expires});
    $p{live} = $self->sql_date_struct($p{live});
    
    $self->do_sql(
            sql => "UPDATE WebItem
                    SET title = ?,
                        date_expires = ?,
                        date_live = ?,
                        subtitle = ?,
                        location = ?,
                        body = ?
                    WHERE id = ?",
            bind => [ @p{qw(title expires live subtitle location body id)} ],
            );
}

sub update_asset_column {
    my $self = shift;
    my ($id, $column, $value) = @_;
    
    $self->do_sql(
                sql => "UPDATE WebItem
                        SET $column = ?
                        WHERE id = ?",
                bind => [ $value, $id ],
                );
}

sub create_asset {
    my $self = shift;
    my %p = @_;
    
    $p{expires} = $self->sql_date_struct($p{expires} || {year => 2030, month => 1, day_of_month => 1 });
    $p{live} = $self->sql_date_struct($p{live} || { year => 1970, month => 1, day_of_month => 1 });
    
    # get defaults
    my ($item_group_id, $item_status_id, $item_type_id) = 
        $self->get_one_row(
            sql => "SELECT ItemGroup.id AS itemgroup_id, 
                            ItemStatus.id AS itemstatus_id,
                            ItemType.id AS itemtype_id
                    FROM ItemGroup, ItemStatus, ItemType
                    WHERE ItemStatus.description = 'Initial Edit'
                    AND   ItemGroup.description = 'None'
                    AND   ItemType.short_desc = ?",
            bind => [ $p{asset_type} ],
        );
    
    my $next_id = $self->get_next_pk(table => "WebItem");
    
    $self->do_sql(
            sql => "INSERT INTO WebItem (id, item_type_id,
                    item_status_id, item_group_id,
                    date_created, date_live, date_expires,
                    title, link, subtitle, location,
                    booth, body )
                    VALUES ( ?, ?,
                    ?, ?, 
                    now(), ?, ?,
                    ?, ?, ?, ?,
                    ?, ? )",
            bind => [ $next_id, $item_type_id, $item_status_id, $p{item_group_id} || $item_group_id,
                      @p{qw(live expires title link subtitle location booth body)} ],
            );
    
    return $next_id;
}

sub get_create_pages {
    my $self = shift;
    
    my @rows = $self->get_rows(
            sql => "SELECT short_desc, create_page FROM ItemType ORDER BY id"
            );
    
    my @results;
    
    foreach my $row (@rows) {
        push @results, @$row;
    }
    
    return @results;
}

sub get_edit_page {
    my $self = shift;
    my %p = @_;
    
    my $page;
    if ($p{create_page}) {
        $page = $self->get_one_row(
            sql => "SELECT edit_page FROM ItemType WHERE create_page = ?",
            bind => $p{create_page},
                );
    }
    elsif ($p{asset_id}) {
        $page = $self->get_one_row(
                sql => "SELECT ItemType.edit_page
                        FROM ItemType
                        JOIN WebItem
                          ON WebItem.item_type_id = ItemType.id
                        WHERE WebItem.id = ?",
                bind => $p{asset_id},
                );
    }
    return $page;
}

sub get_view_page {
    my $self = shift;
    my %p = @_;
    
    my $page;
    if ($p{create_page}) {
        $page = $self->get_one_row(
            sql => "SELECT view_page FROM ItemType WHERE create_page = ?",
            bind => $p{create_page},
                );
    }
    elsif ($p{asset_id}) {
        $page = $self->get_one_row(
                sql => "SELECT ItemType.view_page
                        FROM ItemType
                        JOIN WebItem
                          ON WebItem.item_type_id = ItemType.id
                        WHERE WebItem.id = ?",
                bind => $p{asset_id},
                );
    }
    return $page;
}

sub list_users {
    my $self = shift;
    
    return $self->get_rows_hashref(
            sql => "SELECT * FROM CMSUser ORDER BY super_user, last_name, first_name",
            );
}

sub is_super_user {
    my $self = shift;
    my $user_id = shift;
    
    return $self->get_one_row(
            sql => "SELECT super_user FROM CMSUser WHERE id = ?",
            bind => $user_id,
            );
}

use Digest::MD5 qw(md5_hex);

sub add_user {
    my $self = shift;
    my %p = @_;
    
    $p{password_md5} = md5_hex($p{password});
    $p{super_user} = $p{super_user} ? 't' : 'f';
    
    $self->do_sql(
            sql => "INSERT INTO CMSUser 
                    (id, username, password_md5, 
                    first_name, last_name, email, super_user)
                    VALUES
                    (nextval('CMSUser_seq'), ?, ?, ?, ?, ?, ?)",
            bind => [ @p{qw(username password_md5 first_name last_name email super_user)} ],
            );
}

sub get_user {
    my $self = shift;
    my $id = shift;
    
    return {
        $self->get_one_row_hash(
                sql => "SELECT * FROM CMSUser WHERE id = ?",
                bind => $id,
                )
            };
}

sub update_user {
    my $self = shift;
    my %p = @_;
    
    if ($p{password}) {
        $p{password_md5} = md5_hex($p{password});
    }
    
    $p{super_user} = $p{super_user} ? 't' : 'f';
    
    $self->do_sql(
                sql => "UPDATE CMSUser
                        SET first_name = ?,
                            last_name = ?,
                            email = ?,
                            super_user = ?
                            " .
                        ($p{password_md5} ? ", password_md5 = ?" : "") .
                        " WHERE id = ?",
                bind => [ @p{qw(first_name last_name email super_user)}, ($p{password_md5} ? ($p{password_md5}) : ()), $p{id} ],
                );
}

sub get_user_id {
    my $self = shift;
    my $username = shift;
    
    return $self->get_one_row(
            sql => "SELECT id FROM CMSUser WHERE username = ?",
            bind => $username,
            );
}

sub log {
    my $self = shift;
    my $log_text = join('', @_);

    my $next_id = $self->get_next_pk(table => "CMSLog");
    
    my $user_id = $self->get_user_id(Example::User::get_user());
    
    $self->do_sql(
            sql => "INSERT INTO CMSLog (id, user_id, log_detail)
                    VALUES ( ?, ?, ? )",
            bind => [ $next_id, $user_id, $log_text ],
            );
}

sub set_status {
    my $self = shift;
    
    my ($status, $asset_id) = @_;
    
    if ($status =~ /\D/) {
        # status is a description
        $self->do_sql(
                sql => "UPDATE WebItem SET item_status_id = 
                        (SELECT ItemStatus.id FROM ItemStatus 
                         WHERE ItemStatus.description = ?)
                        WHERE WebItem.id = ?",
                bind => [ $status, $asset_id ],
                );
    }
    else {
        # status is a number
        $self->do_sql(
                sql => "UPDATE WebItem SET item_status_id = ?
                        WHERE WebItem.id = ?",
                bind => [ $status, $asset_id ],
                );
    }
}

sub get_statuses {
    my $self = shift;
    
    my @rows = $self->get_rows(
                sql => "SELECT id, description
                        FROM ItemStatus
                        ORDER BY ordering"
                        );
    return @rows;
}

sub get_asset_types {
    my $self = shift;
    
    my @rows = $self->get_rows(
                sql => "SELECT id, short_desc
                        FROM ItemType
                        ORDER BY id"
                        );
    return @rows;
}

sub get_long_desc {
    my $self = shift;
    my %p = @_;
    
    $self->get_one_row(
                sql => "SELECT long_desc FROM ItemType WHERE short_desc = ?",
                bind => $p{type},
                );
}

sub validate_date {
    my $self = shift;
    my (%date_struct) = @_;
    
    # Note: We're using WebItem here to do selects against simply because
    # selecting from no table is different depending on what DB you're using.
    # This allows us to do it db independantly, saving us one method to port
    # to Oracle should it be needed.
    
    my $date_str = $self->sql_date_struct(\%date_struct);
    eval {
        $self->do_sql(sql => "SELECT id FROM WebItem WHERE date_created > ?", bind => $date_str);
    };
    if ($@) {
        die "Invalid date";
    }
    
    eval {
        my $row = $self->get_one_row(sql => "SELECT id FROM WebItem WHERE now() > ?", bind => $date_str);
        if ($row) {
            die "1";
        }
    };
    if ($@) {
        die "Date is in the past";
    }
    return 1;
}

sub compare_dates {
    my $self = shift;
    my ($date1, $date2) = @_;
    
    my $date1_str = $self->sql_date_struct($date1);
    my $date2_str = $self->sql_date_struct($date2);
    
    # NB: PostgreSQL specific code.
    
    return $self->get_one_row(
                sql => "SELECT CAST(? AS DATE) - CAST(? AS DATE)",
                bind => [ $date1_str, $date2_str ],
                );
}

1;
