package App::MonM::Notifier::Store; # $Id: Store.pm 43 2017-12-01 16:30:32Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Store - monotifier store class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Store;

    my $store = new App::MonM::Notifier::Store;

=head1 DESCRIPTION

This module provides store methods.

For internal use only

=head2 METHODS

=over 8

=item B<new>

Constructor

=item B<status>

    my $status = $store->status;
    my $status = $store->status( 1 ); # Sets the status value and returns it

Get/set BOOL status of the operation

=item B<error>

    my $error = $store->error;

Returns error message

    my $status = $store->error( "Error message" );

Sets error message if argument is provided.
This method in "set" context returns status of the operation as status() method.

=item B<add>

    my $newid = $store->add(
        ip      => LOCALHOSTIP,
        host    => hostname,
        ident   => "quux",
        level   => getLevelByName("error"),
        to      => "test",
        from    => "test",
        subject => "Test message",
        message => "Content",
        pubdate => time() + 60*5,
        expires => 60*5 + 60*60*24,
        status  => "NEW",
    );

This method adds new record into store. Returns ID created record

=item B<get>

    my %data = $store->get( $id );

This method gets record from store. Returns hash of this record

=item B<getall>

    my @table = $store->getall( id => $id );
    my @table = $store->getall(
            id      => $id, # Integer value
            ip      => $ip, # IPv4 value
            host    => $host,
            ident   => $ident,
            level   => $level, # Integer value
            to      => $to,
            from    => $from,
            status  => $status, # String value
            errcode => $errcode, # Integer value
        );

This method returns all records from store by criteria. Returns array-ref

=item B<getJob>

    my %data = $store->getJob;

This method gets record as new job from store for processing. Returns hash of this record

=item B<setJob>

    $store->setJob(
            id      => $id,
            status  => $status,
            errcode => $errcode,
            errmsg  => $errmsg,
            comment => "... comment ...",
            # ... other fields ...
        );

This method sets the new data for the record by record id

=item B<ping>

    $store->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=item B<del>

    my $status = $store->del( $id );

This method removes record in store. Returns status

=item B<set>

    $store->set(
            id      => $id,
            status  => $status,
            errcode => $errcode,
            errmsg  => $errmsg,
            comment => "... comment ...",
            # ... other fields ...
        );

This method sets the new data for the record by record id

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<DBI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<App::MonM::AlertGrid>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK qw/ :BASE /;
use CTKx;
use CTK::DBI;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util;
use Try::Tiny;
use Compress::Raw::Zlib qw//;

use App::MonM::Notifier::Const;
use App::MonM::Notifier::Util;

use constant {
    LOCALHOSTIP => '127.0.0.1',
    DBTYPE      => 'sqlite',
    DBTABLE     => 'monotifier',
    DBFILE      => 'monotifier.db',
    EXPIRES     => "+1M", # 30 days max (Time waiting for hold requests)
    LIFETIME    => "+1y", # 365 days max (Storage time of the request)
    DBDDL       => [(<<DDL, 'CREATE INDEX I_ID ON [TABLE](id)')],
        CREATE TABLE
            IF NOT EXISTS [TABLE] (
                `id` INT(11) NOT NULL PRIMARY KEY,
                `ip` CHAR(15) NOT NULL, -- Client IP address
                `host` CHAR(128) NOT NULL, -- Client Host Name
                `ident` CHAR(64), -- Ident, name
                `level` INT(8) NOT NULL, -- Level
                `to` CHAR(255), -- Recipient address
                `from` CHAR(255), -- Sender's address
                `subject` TEXT, -- Subject of the message
                `message` TEXT, -- Message content
                `pubdate` BIGINT(20), -- Date (unixtime) of the publication
                `expires` BIGINT(20), -- Date (unixtime) of the expire
                `status` CHAR(32), -- Status of transaction
                `comment` CHAR(255), -- Comment
                `errcode` INT(11), -- Error code
                `errmsg` TEXT -- Error message
            )
DDL
    DBDML       => 'SELECT COUNT(`id`) AS `countid` FROM [TABLE]',
};

use vars qw/$VERSION/;
$VERSION = '1.00';

sub new {
    my $class = shift;
    my $c = CTKx->instance->c();
    my $config_store = node($c->config() => "store");
    my %props = (
            dbi     => undef,
            dsn     => undef,
            config  => $config_store,
            error   => '',
            file    => '',
            status  => 1,
            user    => '',
            password=> '',
        );

    # Структуру берем из конфигурации
    #<store>
    #    Type    SQLite
    #    File    test.db
    #</store>
    #<store>
    #    Type    DBI
    #
    #    DSN     DBI:mysql:database=DATABASE;host=HOSTNAME
    #
    #    User    USER
    #    Password PASSWORD
    #
    #    Connect_to    5     # Connect TimeOut
    #    Request_to    60    # Request TimeOut
    #
    #    Set mysql_enable_utf8 1
    #    Set PrintError 0
    #
    #    DDL CREATE TABLE IF NOT EXISTS `[TABLE]` ( \
    #          `id` int(11) NOT NULL COMMENT 'ID', \
    #          `ip` char(15) NOT NULL COMMENT 'Client IP address', \
    #          `host` char(128) DEFAULT NULL COMMENT 'Client Host Name', \
    #          `ident` char(64) DEFAULT NULL COMMENT 'Ident, name', \
    #          `level` int(8) NOT NULL DEFAULT '0' COMMENT 'Level', \
    #          `to` char(255) DEFAULT NULL COMMENT 'Recipient address', \
    #          `from` char(255) DEFAULT NULL COMMENT 'Sender''s address', \
    #          `subject` text COMMENT 'Subject of the message', \
    #          `message` text COMMENT 'Message content ', \
    #          `pubdate` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the publication', \
    #          `expires` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the expire', \
    #          `status` char(32) DEFAULT NULL COMMENT 'Status of transaction', \
    #          `comment` char(255) DEFAULT NULL COMMENT 'Comment', \
    #          `errcode` int(11) DEFAULT NULL COMMENT 'Error code', \
    #          `errmsg` text COMMENT 'Error message', \
    #          PRIMARY KEY (`id`), \
    #          KEY `I_ID` (`id`) \
    #        ) ENGINE=MyISAM DEFAULT CHARSET=utf8
    #</Store>

    my $db_type = lc(value($config_store => "type") || DBTYPE);
    $props{type} = $db_type;
    my %db_attr = _set_attr(array($config_store => "set"));
    my $ddl = array($config_store => "ddl"); $ddl = DBDDL unless @$ddl;
    my $dml = value($config_store => "dml") || DBDML;
    my $table = uv2null(value($config_store => "table")) || DBTABLE;
    $props{table} = $table;

    my ($dsn, $dbi);
    my %cnct = ();
    my $inited = 1;
    if ($db_type eq 'dbi') {
        $dsn = uv2null(value($config_store => "dsn"));
        croak("DSN missing") unless $dsn;

        # Defaults
        unless (%db_attr) {
            %db_attr = (
                sqlite_unicode => 1,
                PrintError => 0,
            );
        }

        my $user = uv2null(value($config_store => "user"));
        my $password = uv2null(value($config_store => "password"));
        my $cto = value($config_store => "connect_to");
        my $rto = value($config_store => "request_to");
        $props{user}  = $user;
        $props{password}  = $user;

        # Connect
        %cnct = (
            -dsn        => $dsn,
            -user       => $user,
            -pass       => $password,
            -connect_to => $cto,
            -request_to => $rto,
            -attr       => { %db_attr },
            -debug      => debugmode && verbosemode,
        );
    } else { # DBTYPE
        my $file = uv2null(value($config_store => "file")) || catfile($c->datadir(), DBFILE);
        croak("Store file missing. Check your configuration file") unless $file;
        $props{file} = $file;
        $dsn = sprintf("dbi:SQLite:dbname=%s", $file);

        # Defaults
        unless (%db_attr) {
            %db_attr = (
                sqlite_unicode  => 1,
                PrintError      => 0,
            );
        }

        $inited = 0 unless $file && (-e $file) && !(-z _);

        # Connect
        %cnct = (
            -dsn        => $dsn,
            -attr       => { %db_attr },
            -debug      => debugmode && verbosemode,
        );
    }
    $dbi = new CTK::DBI(%cnct);
    $props{cnct} = {%cnct};
    $props{dsn} = $dsn;
    $props{dbi} = $dbi;

    # Init
    if ($dbi && $dbi->{dbh}) {
        my $sql = dformat($dml, { TABLE => DBTABLE });
        unless ($inited && $dbi->field($sql)) {
            if ($DBI::errstr) {
                $props{error} = sprintf("Can't select \"%s\" on \"%s\": %s", $sql, $dsn, uv2null($DBI::errstr));
                $inited = 0;
            }
        }
        unless ($inited) {
            foreach my $dl (@$ddl) {
                $dbi->execute(dformat($dl, { TABLE => DBTABLE }));
            }
            if ($DBI::errstr) {
                $props{error} = sprintf("Can't init table \"%s\" on \"%s\": %s", DBTABLE, $dsn, uv2null($DBI::errstr));
            }
        }
    } else { # Connect error
        $props{error} = sprintf("Can't connect to \"%s\": %s", $dsn, uv2null($DBI::errstr));
    }

    $props{status} = 0 if $props{error};
    return bless { %props }, $class;
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $value;
}
sub ping {
    my $self = shift;
    return 0 unless $self->{dsn};
    my $dbi = $self->{dbi};
    return 0 unless $dbi;
    my $dbh = $dbi->{dbh};
    return 0 unless $dbh;
    return 1 unless $dbh->can('ping');
    return $dbh->ping();
}
sub _dbi {
    my $self = shift;
    my $cnct = $self->{cnct};
    if ($self->ping) {
        return $self->{dbi};
    } else {
        $self->{dbi} = new CTK::DBI(%$cnct);
    }
    if ($self->ping) {
        $self->error("");
    } else {
        $self->error(sprintf("Can't (re)connect to \"%s\": %s", $self->{dsn}, uv2null($DBI::errstr)));
        return undef;
    }
    return $self->{dbi};
}

sub add {
    my $self = shift;
    my %data = @_;
    my $dbi = $self->_dbi;
    return undef unless ($dbi && $dbi->{dbh}); #croak("No connect to store") unless ($dbi && $dbi->{dbh});
    my $c = CTKx->instance->c();
    my $config = $c->config();
    my $pubdate = $data{pubdate} || time();
    my $expires_def = value($config => "expires") || EXPIRES;
    my $expires = $pubdate + (getExpireOffset($data{expires} || $expires_def) || getExpireOffset($expires_def));
    my $lifetime_def = value($config => "lifetime") || LIFETIME;
    my $lifetime = time() - getExpireOffset($lifetime_def);
    my $newid = _get_id(
            $data{ip}       || LOCALHOSTIP,
            $data{level}    || 0,
            $data{pubdate}  || 0,
            $data{to}       || 'anonymous',
            $data{from}     || 'anonymous',
        );

    # Удаляем старые записи (LifeTime)
    $dbi->execute(sprintf('DELETE FROM %s WHERE `pubdate` <= ?', DBTABLE), $lifetime);
    if ($DBI::errstr) {
        $self->error(sprintf("Can't delete old records from table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return undef;
    }

    # Добавляем запись в БД
    $dbi->execute(sprintf('
        INSERT
            INTO %s (`id`,`ip`,`host`,`ident`,`level`, `to`, `from`, `subject`, `message`, `pubdate`, `expires`, `status`, `comment`, `errcode`, `errmsg`)
        VALUES
            ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
    ', DBTABLE),
        $newid,
        $data{ip} || LOCALHOSTIP,
        $data{host},
        $data{ident},
        $data{level} || 0,
        $data{to},
        $data{from},
        $data{subject},
        $data{message},
        $pubdate,
        $expires,
        $data{status} || JBS_NEW,
        $data{comment},
        0, "",
    );
    if ($DBI::errstr) {
        $self->error(sprintf("Can't insert new record into table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return undef;
    }

    return $newid;
}
sub del {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->_dbi;
    return 0 unless ($dbi && $dbi->{dbh});

    $dbi->execute(sprintf('DELETE FROM %s WHERE `id` = ?', DBTABLE), $id);
    if ($DBI::errstr) {
        $self->error(sprintf("Can't delete record from table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return 0;
    }

    return 1;
}
sub get {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->_dbi;
    return () unless ($dbi && $dbi->{dbh}); #croak("No connect to store") unless ($dbi && $dbi->{dbh});

    # Получаем данные
    my %rec = $dbi->recordh(sprintf('SELECT * FROM %s WHERE `id` = ?', DBTABLE), $id);

    if ($DBI::errstr) {
        $self->error(sprintf("Can't get record from table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return ();
    }

    return %rec;
}
sub set {
    my $self = shift;
    my %data = @_;

    if (exists($data{pubdate}) && defined($data{pubdate})) {
        if (exists($data{expires}) && defined($data{expires})) {
            $data{expires} = $data{pubdate} + uv2zero(getExpireOffset($data{expires}));
        }
    }

    return $self->setJob(%data);
}
sub getall {
    my $self = shift;
    my %opts = @_;
    my $dbi = $self->_dbi;
    return () unless ($dbi && $dbi->{dbh});

    # Gets all data
    my @wheres = ("1 = 1");
    while (my ($k,$v) = each %opts) {
        next unless defined $v;
        if (grep {$k eq $_} (qw/id level errcode pubdate expires/)) {
            my $ltg = "=";
            if ($v =~ /^([+\-])/) {
                $ltg = ">=" if $1 eq '+';
                $ltg = "<=" if $1 eq '-';
                $v =~ s/^[+\-]+//;
            }
            push @wheres, sprintf("`%s` %s %d", $k, $ltg, $v);
        } else {
            push @wheres, sprintf("`%s` = '%s'", $k, $v);
        }
    }
    my $sql = sprintf('SELECT * FROM %s WHERE %s', DBTABLE, join(" AND ", @wheres));
    my @tbl = $dbi->table($sql);

    if ($DBI::errstr) {
        $self->error(sprintf("Can't get fields from table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return ();
    }

    return @tbl;
}
sub getJob {
    my $self = shift;
    my $ident = shift || 0;
    my $dbi = $self->_dbi;
    return () unless ($dbi && $dbi->{dbh}); #croak("No connect to store") unless ($dbi && $dbi->{dbh});
    my %rec = ();

    my $tmpstatus = sprintf("%s%s",JBS_PROGRESS, $ident);
    my $comment = sprintf("Processing at worker server with ident %s",$ident);

    # Получаем только актуальные данные
    #my %rec = $dbi->recordh(sprintf('SELECT * FROM %s WHERE `id` = ?', DBTABLE), $id);
    my @tbl = $dbi->table(sprintf('SELECT `id` FROM %s WHERE (`status` = ? OR `status` = ?) AND `pubdate` <= ?', DBTABLE), JBS_NEW, JBS_POSTPONED, time());
    my @recs = sort {($a || 0) <=> ($b || 0)} map {shift @$_} @tbl if @tbl;

    my $prgid = 0;
    foreach my $id (@recs) {
        $dbi->execute(sprintf('UPDATE %s SET `status` = ? WHERE `id` = ? AND (`status` = ? OR `status` = ?)', DBTABLE), $tmpstatus, $id, JBS_NEW, JBS_POSTPONED);
        last if $DBI::errstr;
        %rec = $dbi->recordh(sprintf('SELECT * FROM %s WHERE `id` = ? AND `status` = ?', DBTABLE), $id, $tmpstatus);
        last if $DBI::errstr;
        if (%rec) {
            $prgid = $id;
            last;
        }
    }
    if ($DBI::errstr) {
        $self->error(sprintf("Can't update record in table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return ();
    }
    $dbi->execute(sprintf('UPDATE %s SET `status` = ?, `comment` = ?  WHERE `id` = ? AND `status` = ?', DBTABLE), JBS_PROGRESS, $comment, $prgid, $tmpstatus);
    if ($DBI::errstr) {
        $self->error(sprintf("Can't update record in table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return ();
    }

    return %rec;
}
sub setJob {
    my $self = shift;
    my %rec = @_;
    my $dbi = $self->_dbi;
    return 0 unless $dbi && $dbi->{dbh};
    my $id = $rec{id};
    unless ($id) {
        $self->error("Incorrect ID");
        return 0;
    }
    my @ks = grep {$_ && $_ ne "id"} keys %rec;
    return 1 unless @ks;
    my @vs = (); push @vs, $rec{$_} for @ks;
    my @inj = (); push @inj, sprintf('`%s` = ?', $_) for @ks;
    $dbi->execute(sprintf('UPDATE %s SET %s WHERE `id` = ?', DBTABLE, join(", ", @inj)), @vs, $id);
    if ($DBI::errstr) {
        $self->error(sprintf("Can't update record in table \"%s\" on \"%s\": %s", DBTABLE, $self->{dsn}, uv2null($DBI::errstr)));
        return 0;
    }
    return 1;
}

sub _set_attr {
    my $attr = shift;
    croak("Argument must be hash reference") unless is_array($attr);
    my %ra = ();
    foreach (@$attr) {
        $ra{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return %ra;
}
sub _get_id {
    my @arr = @_;
    unshift @arr, $$;
    my $text = join("|", @arr);
    my $short = time & 0x7FFFFF;
    my $crc8 = Compress::Raw::Zlib::crc32($text) & 0xFF;
    return hex(sprintf("%x%x",$short, $crc8));
}

1;
__END__
