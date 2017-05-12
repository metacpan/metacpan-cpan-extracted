package DBD::mysqlPPrawSjis;
use strict;

use DBI;
use Carp;
use vars qw($VERSION $err $errstr $state $drh);

$VERSION = '0.09';
$err = 0;
$errstr = '';
$state = undef;
$drh = undef;


sub driver
{
    return $drh if $drh;

    my $class = shift;
    my $attr  = shift;
    $class .= '::dr';

    $drh = DBI::_new_drh($class, {
        Name        => 'mysqlPPrawSjis',
        Version     => $VERSION,
        Err         => \$DBD::mysqlPPrawSjis::err,
        Errstr      => \$DBD::mysqlPPrawSjis::errstr,
        State       => \$DBD::mysqlPPrawSjis::state,
        Attribution => 'DBD::mysqlPPrawSjis by Hiroyuki OYAMA and ShiftJIS support by INABA Hitoshi',
    }, {});
}


sub _parse_dsn
{
    my $class = shift;
    my ($dsn, $args) = @_;
    my($hash, $var, $val);
    return if ! defined $dsn;

    while (length $dsn) {
        if ($dsn =~ /([^:;]*)[:;](.*)/) {
            $val = $1;
            $dsn = $2;
        }
        else {
            $val = $dsn;
            $dsn = '';
        }
        if ($val =~ /([^=]*)=(.*)/) {
            $var = $1;
            $val = $2;
            if ($var eq 'hostname' || $var eq 'host') {
                $hash->{'host'} = $val;
            }
            elsif ($var eq 'db' || $var eq 'dbname') {
                $hash->{'database'} = $val;
            }
            else {
                $hash->{$var} = $val;
            }
        }
        else {
            for $var (@$args) {
                if (!defined($hash->{$var})) {
                    $hash->{$var} = $val;
                    last;
                }
            }
        }
    }

# DBD::mysqlPPrawSjis (1 of 5)
    $hash->{'host'} = '127.0.0.1' unless defined $hash->{'host'};

    return $hash;
}


sub _parse_dsn_host
{
    my($class, $dsn) = @_;
    my $hash = $class->_parse_dsn($dsn, ['host', 'port']);
    ($hash->{'host'}, $hash->{'port'});
}



package DBD::mysqlPPrawSjis::dr;

use vars qw($imp_data_size);
$DBD::mysqlPPrawSjis::dr::imp_data_size = 0;

use Net::MySQL;
use strict;


sub connect
{
    my $drh = shift;
    my ($dsn, $user, $password, $attrhash) = @_;

    my $data_source_info = DBD::mysqlPPrawSjis->_parse_dsn(
        $dsn, ['database', 'host', 'port'],
    );
    $user     ||= '';
    $password ||= '';

    my $dbh = DBI::_new_dbh($drh, {
        Name         => $dsn,
        USER         => $user,
        CURRENT_USRE => $user,
    }, {});
    eval {
        my $mysql = Net::MySQL->new(
            hostname => $data_source_info->{host},
            port     => $data_source_info->{port},
            database => $data_source_info->{database},
            user     => $user,
            password => $password,
            debug    => $attrhash->{protocol_dump},
        );
        $dbh->STORE(mysqlpprawsjis_connection => $mysql);
        $dbh->STORE(thread_id => $mysql->{server_thread_id});
    };
    if ($@) {
        return $dbh->DBI::set_err(1, $@);
    }

# DBD::mysqlPPrawSjis (2 of 5)
    return $dbh;

    my $sth = $dbh->prepare(q{SHOW VARIABLES LIKE 'character\\_set\\_%'});
    $sth->execute();
    my %character_set = ();
    while(my($variable_name,$value) = $sth->fetchrow_array()){
        $character_set{$variable_name} = $value;
    }
    if (($character_set{'character_set_server'}   eq 'cp932') and
        ($character_set{'character_set_database'} eq 'cp932') and
        ($character_set{'character_set_client'}   eq 'cp932')
    ) {
    }
    elsif (($character_set{'character_set_server'}   eq 'sjis') and
           ($character_set{'character_set_database'} eq 'sjis') and
           ($character_set{'character_set_client'}   eq 'sjis')
    ) {
    }
    elsif ($character_set{'character_set_server'} ne 'cp932') {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Variable 'character_set_server' is not 'cp932').\n");
    }
    elsif ($character_set{'character_set_database'} ne 'cp932') {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Variable 'character_set_database' is not 'cp932').\n");
    }
    elsif ($character_set{'character_set_client'} ne 'cp932') {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Variable 'character_set_client' is not 'cp932').\n");
    }

    eval {
        $dbh->do(q{DROP TABLE test_character_set});
    };
    $dbh->do(q{CREATE TABLE test_character_set (id INT, c_cp932 TEXT)});
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 1, 'ab');					# <LATIN SMALL LETTER A> <LATIN SMALL LETTER B>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 2, '\\');					# 0x5C
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 3, "\xB6\xC5");			# <HALFWIDTH KATAKANA LETTER KA> <HALFWIDTH KATAKANA LETTER NA>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 4, "\x83\x4A\x83\x69");	# <KATAKANA LETTER KA> <KATAKANA LETTER NA>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 5, "\x81\x60\x81\x61");	# <FULLWIDTH TILDE> <PARALLEL TO>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 6, "\x87\x40\x87\x62");	# <CIRCLED DIGIT ONE> <SQUARE MEETORU>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 7, "\xFA\x42\xFB\xFC");	# <SMALL ROMAN NUMERAL THREE> <CJK UNIFIED IDEOGRAPH>
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 8, "\xF8\x9F");			# 0xF89F

    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {},  9, "\x00");				# NUL
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 10, "\x0A");				# LF
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 11, "\x0D");				# CR
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 12, "\x1A");				# Ctrl+Z
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 13, "\x5C");				# \
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 14, "\x27");				# '
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 15, "\x22");				# "
    $dbh->do(q{INSERT INTO test_character_set (id,c_cp932) VALUES (?,?)}, {}, 16, "\x83\x5C");			# <KATAKANA LETTER SO>

    my $sth2 = $dbh->prepare(q{SELECT id, c_cp932 FROM test_character_set});
    $sth2->execute();
    my %c_cp932 = ();
    while(my($id,$c_cp932) = $sth2->fetchrow_array()){
        $c_cp932{$id} = $c_cp932;
    }

    if ($c_cp932{1} ne "\x61\x62") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('61','62') can't select such as).\n");
    }
    if ($c_cp932{2} ne "\x5C") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('5C') can't select such as).\n");
    }
    if ($c_cp932{3} ne "\xB6\xC5") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('B6','C5') can't select such as).\n");
    }
    if ($c_cp932{4} ne "\x83\x4A\x83\x69") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('834A','8369') can't select such as).\n");
    }
    if ($c_cp932{5} ne "\x81\x60\x81\x61") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('8160','8161') can't select such as).\n");
    }
    if ($c_cp932{6} ne "\x87\x40\x87\x62") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('8740','8762') can't select such as).\n");
    }
    if ($c_cp932{7} ne "\xFA\x42\xFB\xFC") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('FA42','FBFC') can't select such as).\n");
    }
    if ($c_cp932{8} ne "\xF8\x9F") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('F89F') can't select such as).\n");
    }

    if ($c_cp932{9} ne "\x00") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('00') can't select such as).\n");
    }
    if ($c_cp932{10} ne "\x0A") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('0A') can't select such as).\n");
    }
    if ($c_cp932{11} ne "\x0D") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('0D') can't select such as).\n");
    }
    if ($c_cp932{12} ne "\x1A") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('1A') can't select such as).\n");
    }
    if ($c_cp932{13} ne "\x5C") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('5C') can't select such as).\n");
    }
    if ($c_cp932{14} ne "\x27") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('27') can't select such as).\n");
    }
    if ($c_cp932{15} ne "\x22") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('22') can't select such as).\n");
    }
    if ($c_cp932{16} ne "\x83\x5C") {
        return $dbh->DBI::set_err(1, "Can't handle cp932(Inserted HEX('835C') can't select such as).\n");
    }

    return $dbh;
}


sub data_sources
{
    return ("dbi:mysqlPPrawSjis:");
}


sub disconnect_all {}



package DBD::mysqlPPrawSjis::db;

use vars qw($imp_data_size);
$DBD::mysqlPPrawSjis::db::imp_data_size = 0;
use strict;


# Patterns referred to 'mysql_sub_escape_string()' of libmysql.c
sub quote
{
    my $dbh = shift;
    my ($statement, $type) = @_;
    return 'NULL' unless defined $statement;

# DBD::mysqlPPrawSjis (3 of 5)
    if (1) {
        my @statement = ();
        while ($statement =~ /\G ( [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF] )/gsx) {
            push @statement,
                {
                    # ref. mysql_real_escape_string()
                    qq(\\)   => q(\\\\),
                    qq(\0)   => q(\\0),
                    qq(\n)   => q(\\n),
                    qq(\r)   => q(\\r),
                    qq(')    => q(\\'),
                    qq(")    => q(\\"),
                    qq(\x1A) => q(\\Z),
                }->{$1} || $1;
        }
        $statement = join '', @statement;
    }
    else {
        for ($statement) {
            s/\\/\\\\/g;
            s/\0/\\0/g;
            s/\n/\\n/g;
            s/\r/\\r/g;
            s/'/\\'/g;
            s/"/\\"/g;
            s/\x1a/\\Z/g;
        }
    }
    return "'$statement'";
}


sub _count_param
{
# DBD::mysqlPPrawSjis (4 of 5)
    if (1) {
        my $statement = shift;
        my $num = 0;

        while ($statement =~ /\G (
            ' (?: '' | \\' | [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC'] )*? ' |
            " (?: "" | \\" | [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC"] )*? " |
              (?:            [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF] )
        )/gsx) {
            $num++ if $1 eq '?';
        }
        return $num;
    }
    else {
        my @statement = split //, shift;
        my $num = 0;

        while (defined(my $c = shift @statement)) {
            if ($c eq '"' || $c eq "'") {
                my $end = $c;
                while (defined(my $c = shift @statement)) {
                    last if $c eq $end;
                    @statement = splice @statement, 2 if $c eq '\\';
                }
            }
            elsif ($c eq '?') {
                $num++;
            }
        }
        return $num;
    }
}


sub prepare
{
    my $dbh = shift;
    my ($statement, @attribs) = @_;

    my $sth = DBI::_new_sth($dbh, {
        Statement => $statement,
    });
    $sth->STORE(mysqlpprawsjis_handle => $dbh->FETCH('mysqlpprawsjis_connection'));
    $sth->STORE(mysqlpprawsjis_params => []);
    $sth->STORE(NUM_OF_PARAMS => _count_param($statement));
    $sth;
}


sub commit
{
    my $dbh = shift;
    if ($dbh->FETCH('Warn')) {
        warn 'Commit ineffective while AutoCommit is on';
    }
    1;
}


sub rollback
{
    my $dbh = shift;
    if ($dbh->FETCH('Warn')) {
        warn 'Rollback ineffective while AutoCommit is on';
    }
    1;
}


sub tables
{
    my $dbh = shift;
    my @args = @_;
    my $mysql = $dbh->FETCH('mysqlpprawsjis_connection');

    my @database_list;
    eval {
        $mysql->query('show tables');
        die $mysql->get_error_message if $mysql->is_error;
        if ($mysql->has_selected_record) {
            my $record = $mysql->create_record_iterator;
            while (my $db_name = $record->each) {
                push @database_list, $db_name->[0];
            }
        }
    };
    if ($@) {
        warn $mysql->get_error_message;
    }
    return $mysql->is_error
        ? undef
        : @database_list;
}


sub _ListDBs
{
    my $dbh = shift;
    my @args = @_;
    my $mysql = $dbh->FETCH('mysqlpprawsjis_connection');

    my @database_list;
    eval {
        $mysql->query('show databases');
        die $mysql->get_error_message if $mysql->is_error;
        if ($mysql->has_selected_record) {
            my $record = $mysql->create_record_iterator;
            while (my $db_name = $record->each) {
                push @database_list, $db_name->[0];
            }
        }
    };
    if ($@) {
        warn $mysql->get_error_message;
    }
    return $mysql->is_error
        ? undef
        : @database_list;
}


sub _ListTables
{
    my $dbh = shift;
    return $dbh->tables;
}


sub disconnect
{
    return 1;
}


sub FETCH
{
    my $dbh = shift;
    my $key = shift;

    return 1 if $key eq 'AutoCommit';
    return $dbh->{$key} if $key =~ /^(?:mysqlpprawsjis_.*|thread_id|mysql_insertid)$/;
    return $dbh->SUPER::FETCH($key);
}


sub STORE
{
    my $dbh = shift;
    my ($key, $value) = @_;

    if ($key eq 'AutoCommit') {
        die "Can't disable AutoCommit" unless $value;
        return 1;
    }
    elsif ($key =~ /^(?:mysqlpprawsjis_.*|thread_id|mysql_insertid)$/) {
        $dbh->{$key} = $value;
        return 1;
    }
    return $dbh->SUPER::STORE($key, $value);
}


sub DESTROY
{
    my $dbh = shift;
    my $mysql = $dbh->FETCH('mysqlpprawsjis_connection');
    $mysql->close;
}


package DBD::mysqlPPrawSjis::st;

use vars qw($imp_data_size);
$DBD::mysqlPPrawSjis::st::imp_data_size = 0;
use strict;


sub bind_param
{
    my $sth = shift;
    my ($index, $value, $attr) = @_;
    my $type = (ref $attr) ? $attr->{TYPE} : $attr;
    if ($type) {
        my $dbh = $sth->{Database};
        $value = $dbh->quote($sth, $type);
    }
    my $params = $sth->FETCH('mysqlpprawsjis_param');
    $params->[$index - 1] = $value;
}


sub execute
{
    my $sth = shift;
    my @bind_values = @_;
    my $params = (@bind_values) ?
        \@bind_values : $sth->FETCH('mysqlpprawsjis_params');
    my $num_param = $sth->FETCH('NUM_OF_PARAMS');
    if (@$params != $num_param) {
        # ...
    }
    my $statement = $sth->{Statement};

# DBD::mysqlPPrawSjis (5 of 5)
    if (1) {
        my $dbh = $sth->{Database};
        my @statement = ();
        my $i = 0;

        # LIMIT m,n [Li][Ii][Mm][Ii][Tt] for ignorecase on ShiftJIS (Can't use /LIMIT/i)
        # LIMIT n
        # OFFSET m

        while ($statement =~ /\G (
            ' (?: '' | \\' | [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC'] )*? ' |
            " (?: "" | \\" | [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC"] )*? " |
              (?: \s+ [Ll][Ii][Mm][Ii][Tt] \s+ [?]    \s* , \s* [?]    )                    |
              (?: \s+ [Ll][Ii][Mm][Ii][Tt] \s+ [0-9]+ \s* , \s* [?]    )                    |
              (?: \s+ [Ll][Ii][Mm][Ii][Tt] \s+ [?]    \s* , \s* [0-9]+ )                    |
              (?: \s+ [Ll][Ii][Mm][Ii][Tt] \s+ [?] )                                        |
              (?: \s+ [Oo][Ff][Ff][Ss][Ee][Tt] \s+ [?] )                                    |
              (?:            [\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF] )
        )/gsx) {
            my $element = $1;
            if (($element =~ /\A \s+ [Ll][Ii][Mm][Ii][Tt] \s+ [?] \s* , \s* [?] \z/x) and
                defined($params->[$i+1]) and
                ($params->[$i+0] =~ /^[0-9]+$/) and
                ($params->[$i+1] =~ /^[0-9]+$/)
            ) {
                $element =~ s{[?]}{$params->[$i++]}e;
                $element =~ s{[?]}{$params->[$i++]}e;
                push @statement, $element;
            }
            elsif (
                ($element =~ /\A \s+ [Ll][Ii][Mm][Ii][Tt] \s+ /x) and
                defined($params->[$i]) and
                ($params->[$i] =~ /^[0-9]+$/)
            ) {
                $element =~ s{[?]}{$params->[$i++]}e;
                push @statement, $element;
            }
            elsif (
                ($element =~ /\A \s+ [Oo][Ff][Ff][Ss][Ee][Tt] \s+ /x) and
                defined($params->[$i]) and
                ($params->[$i] =~ /^[0-9]+$/)
            ) {
                $element =~ s{[?]}{$params->[$i++]}e;
                push @statement, $element;
            }
            elsif (($element eq '?') and defined($params->[$i])) {
                push @statement, $dbh->quote($params->[$i++]);
            }
            else {
                push @statement, $element;
            }
        }
        $statement = join '', @statement;
    }
    else {
        for (my $i = 0; $i < $num_param; $i++) {
            my $dbh = $sth->{Database};
            my $quoted_param = $dbh->quote($params->[$i]);
            $statement =~ s/\?/$quoted_param/e;
        }
    }

# for debug DBD::mysqlPPrawSjis
    if (0) {
        open(QUERY,'>>query.log');
        my($year,$month,$day,$hour,$min,$sec) = (localtime)[5,4,3,2,1,0];
        printf QUERY ("-- %04d-%02d-%02d %02d:%02d:%02d\n", 1900+$year,$month+1,$day,$hour,$min,$sec);
        print QUERY $statement, "\n";
        close(QUERY);
    }

    my $mysql = $sth->FETCH('mysqlpprawsjis_handle');
    my $result = eval {
        $sth->{mysqlpprawsjis_record_iterator} = undef;
        $mysql->query($statement);
        die if $mysql->is_error;

        my $dbh = $sth->{Database};
        $dbh->STORE(mysqlpprawsjis_insertid => $mysql->get_insert_id);
        $dbh->STORE(mysql_insertid => $mysql->get_insert_id);

        $sth->{mysqlpprawsjis_rows} = $mysql->get_affected_rows_length;
        if ($mysql->has_selected_record) {
            my $record = $mysql->create_record_iterator;
            $sth->{mysqlpprawsjis_record_iterator} = $record;
            $sth->STORE(NUM_OF_FIELDS => $record->get_field_length);
            $sth->STORE(NAME => [ $record->get_field_names ]);
        }
        $mysql->get_affected_rows_length;
    };
    if ($@) {
        $sth->DBI::set_err(
            $mysql->get_error_code, $mysql->get_error_message
        );
        return undef;
    }

    return $mysql->is_error
        ? undef : $result
            ? $result : '0E0';
}


sub fetch
{
    my $sth = shift;

    my $iterator = $sth->FETCH('mysqlpprawsjis_record_iterator');
    my $row = $iterator->each;
    return undef unless $row;

    if ($sth->FETCH('ChopBlanks')) {
        map {s/\s+$//} @$row;
    }
    return $sth->_set_fbav($row);
}
use vars qw(*fetchrow_arrayref);
*fetchrow_arrayref = \&fetch;


sub rows
{
    my $sth = shift;
    $sth->FETCH('mysqlpprawsjis_rows');
}


sub FETCH
{
    my $dbh = shift;
    my $key = shift;

    return 1 if $key eq 'AutoCommit';
    return $dbh->{NAME} if $key eq 'NAME';
    return $dbh->{$key} if $key =~ /^mysqlpprawsjis_/;
    return $dbh->SUPER::FETCH($key);
}


sub STORE
{
    my $dbh = shift;
    my ($key, $value) = @_;

    if ($key eq 'AutoCommit') {
        die "Can't disable AutoCommit" unless $value;
        return 1;
    }
    elsif ($key eq 'NAME') {
        $dbh->{NAME} = $value;
        return 1;
    }
    elsif ($key =~ /^mysqlpprawsjis_/) {
        $dbh->{$key} = $value;
        return 1;
    }
    return $dbh->SUPER::STORE($key, $value);
}


sub DESTROY
{
    my $dbh = shift;
}


1;
__END__

=head1 NAME

DBD::mysqlPPrawSjis - Pure Perl MySQL driver for raw ShiftJIS

=head1 SYNOPSIS

    use DBI;

    $dsn = "dbi:mysqlPPrawSjis:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, $user, $password);

    $drh = DBI->install_driver("mysqlPPrawSjis");

    $sth = $dbh->prepare("SELECT * FROM foo WHERE bla");
    $sth->execute;
    $numRows = $sth->rows;
    $numFields = $sth->{'NUM_OF_FIELDS'};
    $sth->finish;

=head1 EXAMPLE

  #!/usr/bin/perl

  use strict;
  use DBI;

  # Connect to the database.
  my $dbh = DBI->connect("dbi:mysqlPPrawSjis:database=test;host=localhost",
                         "joe", "joe's password",
                         {'RaiseError' => 1});

  # Drop table 'foo'. This may fail, if 'foo' doesn't exist.
  # Thus we put an eval around it.
  eval { $dbh->do("DROP TABLE foo") };
  print "Dropping foo failed: $@\n" if $@;

  # Create a new table 'foo'. This must not fail, thus we don't
  # catch errors.
  $dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");

  # INSERT some data into 'foo'. We are using $dbh->quote() for
  # quoting the name.
  $dbh->do("INSERT INTO foo VALUES (1, " . $dbh->quote("Tim") . ")");

  # Same thing, but using placeholders
  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 2, "Jochen");

  # Now retrieve data from the table.
  my $sth = $dbh->prepare("SELECT id, name FROM foo");
  $sth->execute();
  while (my $ref = $sth->fetchrow_arrayref()) {
    print "Found a row: id = $ref->[0], name = $ref->[1]\n";
  }
  $sth->finish();

  # Disconnect from the database.
  $dbh->disconnect();


=head1 DESCRIPTION

DBD::mysqlPPrawSjis is a Pure Perl client interface for the MySQL database.
This module implements network protool between server and client of MySQL,
thus you don't need external MySQL client library like libmysqlclient for
this module to work. It means this module enables you to connect to MySQL
server from some operation systems which MySQL is not ported.
Using this software and Sjis software, you can store ShiftJIS literal into
MySQL database without code conversion at all. How nifty!

From perl you activate the interface with the statement

    use DBI;

After that you can connect to multiple MySQL database servers
and send multiple queries to any of them via a simple object oriented
interface. Two types of objects are available: database handles and
statement handles. Perl returns a database handle to the connect
method like so:

  $dbh = DBI->connect("dbi:mysqlPPrawSjis:database=$db;host=$host",
              $user, $password, {RaiseError => 1});

Once you have connected to a database, you can can execute SQL
statements with:

  my $query = sprintf("INSERT INTO foo VALUES (%d, %s)",
              $number, $dbh->quote("name"));
  $dbh->do($query);

See L<DBI(3)> for details on the quote and do methods. An alternative
approach is

  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef,
       $number, $name);

in which case the quote method is executed automatically. See also
the bind_param method in L<DBI(3)>. See L<DATABASE HANDLES> below
for more details on database handles.

If you want to retrieve results, you need to create a so-called
statement handle with:

  $sth = $dbh->prepare("SELECT id, name FROM $table");
  $sth->execute();

This statement handle can be used for multiple things. First of all
you can retreive a row of data:

  my $row = $sth->fetchow_arrayref();

If your table has columns ID and NAME, then $row will be array ref with
index 0 and 1. See L<STATEMENT HANDLES> below for more details on
statement handles.

I's more formal approach:


=head2 Class Methods

=over

=item B<connect>

    use DBI;

    $dsn = "dbi:mysqlPPrawSjis:$database";
    $dsn = "dbi:mysqlPPrawSjis:database=$database;host=$hostname";
    $dsn = "dbi:mysqlPPrawSjis:database=$database;host=$hostname;port=$port";

    $dbh = DBI->connect($dsn, $user, $password);

A C<database> must always be specified.

=over

=item host

The hostname, if not specified or specified as '', will default to an
MySQL daemon running on the local machine on the default port
for the INET socket.

=item port

Port where MySQL daemon listens to. default is 3306.

=back

=back

=head2 MetaData Method

=over 4

=item B<tables>

    @names = $dbh->tables;

Returns a list of table and view names, possibly including a schema prefix.
This list should include all tables that can be used in a "SELECT" statement
without further qualification.

=back

=head2 Private MetaData Methods

=over 4

=item ListDBs

    @dbs = $dbh->func('_ListDBs');

Returns a list of all databases managed by the MySQL daemon.

=item ListTables

B<WARNING>: This method is obsolete due to DBI's $dbh->tables().

    @tables = $dbh->func('_ListTables');

Once connected to the desired database on the desired mysql daemon with the
"DBI-"connect()> method, we may extract a list of the tables that have been
created within that database.

"ListTables" returns an array containing the names of all the tables present
within the selected database. If no tables have been created, an empty list is
returned.

    @tables = $dbh->func('_ListTables');
    foreach $table (@tables) {
        print "Table: $table\n";
    }

=back


=head1 DATABASE HANDLES

The DBD::mysqlPPrawSjis driver supports the following attributes of database
handles (read only):

  $insertid = $dbh->{'mysqlpprawsjis_insertid'};
  $insertid = $dbh->{'mysql_insertid'};

=head1 STATEMENT HANDLES

The statement handles of DBD::mysqlPPrawSjis support a number
of attributes. You access these by using, for example,

  my $numFields = $sth->{'NUM_OF_FIELDS'};

=over

=item mysqlpprawsjis_insertid/mysql_insertid

MySQL has the ability to choose unique key values automatically. If this
happened, the new ID will be stored in this attribute. An alternative
way for accessing this attribute is via $dbh->{'mysqlpprawsjis_insertid'}.
(Note we are using the $dbh in this case!)

=item NUM_OF_FIELDS

Number of fields returned by a I<SELECT> statement. You may use this for
checking whether a statement returned a result.
A zero value indicates a non-SELECT statement like I<INSERT>, I<DELETE> or
I<UPDATE>.

=back

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make.bat install
   make.bat test
   perl mysql_sjistest.pl

=head1 SUPPORT OPERATING SYSTEM

This module has been tested on these OSes.

=over 4

=item * Windows Vista Service Pack 1

with ActivePerl version 5.005_03 built for MSWin32-x86-object Binary build 522 Built 09:52:28 Nov  2 1999
with ActivePerl v5.6.1 built for MSWin32-x86-multi-thread Binary build 638 Built Apr 13 2004 19:24:21
with ActivePerl v5.8.9 built for MSWin32-x86-multi-thread Binary build 825 [288577] Built Dec 14 2008 21:07:41
with ActivePerl v5.10.0 built for MSWin32-x86-multi-thread Binary build 1004 [287188] Built Sep  3 2008 13:16:37

=item * Windows XP Service Pack 2, Service Pack 3

with ActivePerl version 5.005_03 built for MSWin32-x86-object Binary build 522 Built 09:52:28 Nov  2 1999
with ActivePerl v5.6.1 built for MSWin32-x86-multi-thread Binary build 638 Built Apr 13 2004 19:24:21
with ActivePerl v5.8.9 built for MSWin32-x86-multi-thread Binary build 825 [288577] Built Dec 14 2008 21:07:41
with ActivePerl v5.10.0 built for MSWin32-x86-multi-thread Binary build 1004 [287188] Built Sep  3 2008 13:16:37

=item * Windows 2000 Service Pack 4

with ActivePerl version 5.005_03 built for MSWin32-x86-object Binary build 522 Built 09:52:28 Nov  2 1999
with ActivePerl v5.6.1 built for MSWin32-x86-multi-thread Binary build 638 Built Apr 13 2004 19:24:21
with ActivePerl v5.8.9 built for MSWin32-x86-multi-thread Binary build 825 [288577] Built Dec 14 2008 21:07:41
with ActivePerl v5.10.0 built for MSWin32-x86-multi-thread Binary build 1004 [287188] Built Sep  3 2008 13:16:37

=back

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  DBI
  Net::MySQL

B<Net::MySQL> is a Pure Perl client interface for the MySQL database.

B<Net::MySQL> implements network protool between server and client of
MySQL, thus you don't need external MySQL client library like
libmysqlclient for this module to work. It means this module enables
you to connect to MySQL server from some operation systems which MySQL
is not ported. How nifty!.

=head1 DIFFERENCE FROM "DBD::mysql"

The function of B<DBD::mysql> which cannot be used by B<DBD::mysqlPPrawSjis> is described.

=head2 Parameter of Cnstructor

Cannot be used.

=over 4

=item * msql_configfile

=item * mysql_compression

=item * mysql_read_default_file/mysql_read_default_group

=item * mysql_socket

=back

=head2 Private MetaData Methods

These methods cannot be used for $drh.

=over 4

=item * ListDBs

=item * ListTables


=back

=head2 Server Administration

All func() method cannot be used.

=over 4

=item * func('createdb')

=item * func('dropdb')
 
=item * func('shutdown')

=item * func('reload')

=back

=head2 Database Handles

Cannot be used

=over 4

=item * $dbh->{info}

=back

=head2 Statement Handles

A different part.

=over 4

=item * The return value of I<execute('SELECT * from table')>

Although B<DBD::mysql> makes a return value the number of searched records SQL
of I<SELECT> is performed, B<DBD::mysqlPPrawSjis> surely returns I<0E0>.

=back

Cannot be used.

=over 4

=item * 'mysql_use_result' attribute

=item * 'ChopBlanks' attribute

=item * 'is_blob' attribute

=item * 'is_key' attribute

=item * 'is_num' attribute

=item * 'is_pri_key' attribute

=item * 'is_not_null' attribute

=item * 'length'/'max_length' attribute

=item * 'NULLABLE' attribute

=item * 'table' attribute

=item * 'TYPE' attribute

=item * 'mysql_type' attribute

=item * 'mysql_type_name' attributei

=back

=head2 SQL Extensions

Cannot be used.

=over 4

=item * LISTFIELDS

=item * LISTINDEX

=back

=head1 Raw ShiftJIS

The "ShiftJIS" in this software means widely codeset than general ShiftJIS.
When the character is taken out of the octet string, it is necessary to
distinguish a single octet character and the double octet character.
The distinction is done only by first octet.

    Single octet code is:
      0x00-0x7F, 0x81-0x9F and 0xA1-0xFC

    Double octet code is:
      First octet   0x81-0x9F, 0xE0-0xEF and 0xF0-0xFC
      Second octet  0x40-0x7E and 0x80-0xFC

    *MALFORMED* single octet code is:
      0x80, 0xA0 and 0xFD-0xFF
      Single octet code that cannot be used

See also code table:

         Single octet code

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x00-0x7F
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xA1-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


                                 Double octet code
            First octet                                     Second octet

   0 1 2 3 4 5 6 7 8 9 A B C D E F                 0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |              0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |              1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |              2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |              3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |              4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x40-0x7E
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |              5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |              6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |              7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F    8|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x80-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|              9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| | | | | | | | | | | | | | | | |              A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |              B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |              C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |              D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xE0-0xFC    E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |              F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


    *MALFORMED* Single octet code
    Single octet code that cannot be used

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8|M| | | | | | | | | | | | | | | | 0x80
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A|M| | | | | | | | | | | | | | | | 0xA0
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F| | | | | | | | | | | | | |M|M|M| 0xFD-0xFF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


=head1 OPTIONS OF mysqld

shell$ mysqld --default-character-set=cp932 --skip-character-set-client-handshake --old-passwords &

=head1 TODO

Enables access to much metadata.

=head1 SEE ALSO

L<Net::MySQL>, L<DBD::mysql>, L<Sjis>

=head1 AUTHORS

Hiroyuki OYAMA E<lt>oyama@module.jpE<gt>
INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2011 Hiroyuki OYAMA. Japan. All rights reserved.
Copyright (C) 2011 Takuya Tsuchida
ShiftJIS support 2005,2008,2009,2011 INABA Hitoshi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
