package DBIx::QueryLog;

use strict;
use warnings;
use 5.008_001;

use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Term::ANSIColor qw(colored);
use Text::ASCIITable;
use Data::Dumper ();

$ENV{ANSI_COLORS_DISABLED} = 1 if $^O eq 'MSWin32';

our $VERSION = '0.41';

use constant _ORG_EXECUTE               => \&DBI::st::execute;
use constant _ORG_BIND_PARAM            => \&DBI::st::bind_param;
use constant _ORG_DB_DO                 => \&DBI::db::do;
use constant _ORG_DB_SELECTALL_ARRAYREF => \&DBI::db::selectall_arrayref;
use constant _ORG_DB_SELECTROW_ARRAYREF => \&DBI::db::selectrow_arrayref;
use constant _ORG_DB_SELECTROW_ARRAY    => \&DBI::db::selectrow_array;

use constant _HAS_MYSQL        => eval { require DBD::mysql; 1  } ? 1 : 0;
use constant _HAS_PG           => eval { require DBD::Pg; 1     } ? 1 : 0;
use constant _HAS_SQLITE       => eval { require DBD::SQLite; DBD::SQLite->VERSION(1.48); 1 } ? 1 : 0;
use constant _PP_MODE          => $INC{'DBI/PurePerl.pm'}         ? 1 : 0;

our %SKIP_PKG_MAP = (
    'DBIx::QueryLog' => 1,
);
our $LOG_LEVEL = 'debug';
our $OUTPUT    = *STDERR;

my $st_execute;
my $st_bind_param;
my $db_do;
my $selectall_arrayref;
my $selectrow_arrayref;
my $selectrow_array;

my $is_enabled = 0;

sub import {
    my ($class) = @_;

    $st_execute    ||= $class->_st_execute(_ORG_EXECUTE);
    $st_bind_param ||= $class->_st_bind_param(_ORG_BIND_PARAM);
    $db_do         ||= $class->_db_do(_ORG_DB_DO) if _HAS_MYSQL or _HAS_PG or _HAS_SQLITE;
    unless (_PP_MODE) {
        $selectall_arrayref ||= $class->_select_array(_ORG_DB_SELECTALL_ARRAYREF);
        $selectrow_arrayref ||= $class->_select_array(_ORG_DB_SELECTROW_ARRAYREF);
        $selectrow_array    ||= $class->_select_array(_ORG_DB_SELECTROW_ARRAY, 1);
    }

    no warnings qw(redefine prototype);
    *DBI::st::execute    = $st_execute;
    *DBI::st::bind_param = $st_bind_param;
    *DBI::db::do         = $db_do if _HAS_MYSQL or _HAS_PG or _HAS_SQLITE;
    unless (_PP_MODE) {
        *DBI::db::selectall_arrayref = $selectall_arrayref;
        *DBI::db::selectrow_arrayref = $selectrow_arrayref;
        *DBI::db::selectrow_array    = $selectrow_array;
    }

    $is_enabled = 1;
}

sub unimport {
    no warnings qw(redefine prototype);
    *DBI::st::execute    = _ORG_EXECUTE;
    *DBI::st::bind_param = _ORG_BIND_PARAM;
    *DBI::db::do         = _ORG_DB_DO if _HAS_MYSQL or _HAS_PG or _HAS_SQLITE;
    unless (_PP_MODE) {
        *DBI::db::selectall_arrayref = _ORG_DB_SELECTALL_ARRAYREF;
        *DBI::db::selectrow_arrayref = _ORG_DB_SELECTROW_ARRAYREF;
        *DBI::db::selectrow_array    = _ORG_DB_SELECTROW_ARRAY;
    }

    $is_enabled = 0;
}

*enable  = *begin = \&import;
*disable = *end   = \&unimport;

sub guard {
    my $org_is_enabled = DBIx::QueryLog->is_enabled;
    DBIx::QueryLog->enable();
    return DBIx::QueryLog::Guard->new($org_is_enabled);
}

sub ignore_trace {
    my $org_is_enabled = DBIx::QueryLog->is_enabled;
    DBIx::QueryLog->disable();
    return DBIx::QueryLog::Guard->new($org_is_enabled);
}

sub is_enabled { $is_enabled }

my $container = {};
for my $accessor (qw{
    logger threshold probability skip_bind
    color useqq compact explain show_data_source
}) {
    no strict 'refs';
    *{__PACKAGE__."::$accessor"} = sub {
        use strict 'refs';
        my ($class, $args) = @_;
        return $container->{$accessor} unless @_ > 1;
        $container->{$accessor} = $args;
    };
}

sub _st_execute {
    my ($class, $org) = @_;

    return sub {
        my $wantarray = wantarray ? 1 : 0;
        my $sth = shift;
        my @params = @_;
        my @types;

        my $probability = $container->{probability} || $ENV{DBIX_QUERYLOG_PROBABILITY};
        if ($probability && int(rand() * $probability) % $probability != 0) {
            return $org->($sth, @params);
        }

        my $dbh = $sth->{Database};
        my $ret = $sth->{Statement};
        if (my $attrs = $sth->{private_DBIx_QueryLog_attrs}) {
            my $bind_params = $sth->{private_DBIx_QueryLog_params};
            for my $i (1..@$attrs) {
                push @types, $attrs->[$i - 1]{TYPE};
                push @params, $bind_params->[$i - 1] if $bind_params;
            }
        }
        # DBD::Pg::st warns "undef in subroutine"
        $sth->{private_DBIx_QueryLog_params} = $dbh->{Driver}{Name} eq 'Pg' ? '' : undef;

        my $explain;
        if ($container->{explain} || $ENV{DBIX_QUERYLOG_EXPLAIN}) {
            $explain = _explain($dbh, $ret, \@params, \@types);
        }

        unless (($container->{skip_bind} || $ENV{DBIX_QUERYLOG_SKIP_BIND}) && @params) {
            $ret = _bind($dbh, $ret, \@params, \@types);
        }

        my $begin = [gettimeofday];
        my $res = $wantarray ? [$org->($sth, @_)] : scalar $org->($sth, @_);
        my $time = sprintf '%.6f', tv_interval $begin, [gettimeofday];

        $class->_logging($dbh, $ret, $time, \@params, $explain);

        return $wantarray ? @$res : $res;
    };
}

sub _st_bind_param {
    my ($class, $org) = @_;

    return sub {
        my ($sth, $p_num, $value, $attr) = @_;
        $sth->{private_DBIx_QueryLog_params} ||= [];
        $sth->{private_DBIx_QueryLog_attrs } ||= [];
        $attr = +{ TYPE => $attr || 0 } unless ref $attr eq 'HASH';
        $sth->{private_DBIx_QueryLog_params}[$p_num - 1] = $value;
        $sth->{private_DBIx_QueryLog_attrs }[$p_num - 1] = $attr;
        $org->(@_);
    };
}

sub _select_array {
    my ($class, $org, $is_selectrow_array) = @_;

    return sub {
        my $wantarray = wantarray;
        my ($dbh, $stmt, $attr, @bind) = @_;

        no warnings qw(redefine prototype);
        local *DBI::st::execute = _ORG_EXECUTE; # suppress duplicate logging

        my $probability = $container->{probability} || $ENV{DBIX_QUERYLOG_PROBABILITY};
        if ($probability && int(rand() * $probability) % $probability != 0) {
            return $org->($dbh, $stmt, $attr, @bind);
        }

        my $ret = ref $stmt ? $stmt->{Statement} : $stmt;

        my $explain;
        if ($container->{explain} || $ENV{DBIX_QUERYLOG_EXPLAIN}) {
            $explain = _explain($dbh, $ret, \@bind);
        }

        unless (($container->{skip_bind} || $ENV{DBIX_QUERYLOG_SKIP_BIND}) && @bind) {
            $ret = _bind($dbh, $ret, \@bind);
        }

        my $begin = [gettimeofday];
        my $res;
        if ($is_selectrow_array) {
            $res = $wantarray ? [$org->($dbh, $stmt, $attr, @bind)] : $org->($dbh, $stmt, $attr, @bind);
        }
        else {
            $res = $org->($dbh, $stmt, $attr, @bind);
        }
        my $time = sprintf '%.6f', tv_interval $begin, [gettimeofday];

        $class->_logging($dbh, $ret, $time, \@bind, $explain);

        if ($is_selectrow_array) {
            return $wantarray ? @$res : $res;
        }
        return $res;
    };
}

sub _db_do {
    my ($class, $org) = @_;

    return sub {
        my $wantarray = wantarray ? 1 : 0;
        my ($dbh, $stmt, $attr, @bind) = @_;

        if ($dbh->{Driver}{Name} ne 'mysql' && $dbh->{Driver}{Name} ne 'Pg' && !($dbh->{Driver}{Name} eq 'SQLite' && _HAS_SQLITE && !@bind)) {
            return $org->($dbh, $stmt, $attr, @bind);
        }

        my $probability = $container->{probability} || $ENV{DBIX_QUERYLOG_PROBABILITY};
        if ($probability && int(rand() * $probability) % $probability != 0) {
            return $org->($dbh, $stmt, $attr, @bind);
        }

        my $ret = $stmt;

        my $explain;
        if ($container->{explain} || $ENV{DBIX_QUERYLOG_EXPLAIN}) {
            $explain = _explain($dbh, $ret, \@bind);
        }

        unless (($container->{skip_bind} || $ENV{DBIX_QUERYLOG_SKIP_BIND}) && @bind) {
            $ret = _bind($dbh, $ret, \@bind);
        }

        my $begin = [gettimeofday];
        my $res = $wantarray ? [$org->($dbh, $stmt, $attr, @bind)] : scalar $org->($dbh, $stmt, $attr, @bind);
        my $time = sprintf '%.6f', tv_interval $begin, [gettimeofday];

        $class->_logging($dbh, $ret, $time, \@bind, $explain);

        return $wantarray ? @$res : $res;
    };
}

sub _explain {
    my ($dbh, $ret, $params, $types) = @_;
    $types ||= [];

    return unless $ret =~ m|
        \A                     # at start of string
        (?:
            \s*                # white space
            (?: /\* .*? \*/ )* # /* ... */
            \s*                # while space
        )*
        SELECT
        \s*                    # white space
        .+?                    # columns
        \s*                    # white space
        FROM
        \s*                    # white space
    |ixms;

    no warnings qw(redefine prototype);
    local *DBI::st::execute = _ORG_EXECUTE; # suppress duplicate logging

    my $sth;
    if ($dbh->{Driver}{Name} eq 'mysql' || $dbh->{Driver}{Name} eq 'Pg') {
        my $sql = 'EXPLAIN ' . _bind($dbh, $ret, $params, $types);
        $sth = $dbh->prepare($sql);
        $sth->execute;
    } elsif ($dbh->{Driver}{Name} eq 'SQLite') {
        my $sql = 'EXPLAIN QUERY PLAN ' . _bind($dbh, $ret, $params, $types);
        $sth = $dbh->prepare($sql);
        $sth->execute;
    } else {
        # not supported
        return;
    }

    return if $DBI::err; # skip if maybe statement error
    return sub {
        my %args = @_;

        return $sth->fetchall_arrayref(+{}) unless defined $args{print} and $args{print};

        my $t = Text::ASCIITable->new();
        $t->setCols(@{$sth->{NAME}});
        $t->addRow(map { defined($_) ? $_ : 'NULL' } @$_) for @{$sth->fetchall_arrayref};

        return $t;
    };
}

sub _bind {
    my ($dbh, $ret, $params, $types) = @_;
    $types ||= [];
    my $i = 0;
    if ($dbh->{Driver}{Name} eq 'mysql' or $dbh->{Driver}{Name} eq 'Pg') {
        my $limit_flag = 0;
        $ret =~ s{([?)])}{
            if ($1 eq '?') {
                $limit_flag ||= do {
                    my $pos = pos $ret;
                    ($pos >= 6 && substr($ret, $pos - 6, 6) =~ /\A[Ll](?:IMIT|imit) \z/) ? 1 : 0;
                };
                if ($limit_flag) {
                    $params->[$i++]
                }
                else {
                    my $type = $types->[$i];
                    if (defined $type and $dbh->{Driver}{Name} eq 'Pg' and $type == 0) {
                        $type = undef;
                    }
                    $dbh->quote($params->[$i++], defined $type ? $type : ());
                }
            }
            elsif ($1 eq ')') {
                $limit_flag = 0;
                ')';
            }
        }eg;
    }
    else {
        $ret =~ s/\?/$dbh->quote($params->[$i], $types->[$i++])/eg;
    }
    return $ret;
}

sub _logging {
    my ($class, $dbh, $ret, $time, $bind_params, $explain) = @_;

    my $threshold = $container->{threshold} || $ENV{DBIX_QUERYLOG_THRESHOLD};
    return unless !$threshold || $time > $threshold;

    $bind_params ||= [];

    my $i = 0;
    my $caller = { pkg => '???', line => '???', file => '???' };
    while (my @c = caller(++$i)) {
        if (!$SKIP_PKG_MAP{$c[0]} and $c[0] !~ /^DB[DI]::/) {
            $caller = { pkg => $c[0], file => $c[1], line => $c[2] };
            last;
        }
    }

    my $sql = $ret;
    if ($container->{skip_bind} || $ENV{DBIX_QUERYLOG_SKIP_BIND}) {
        local $" = ', ';
        $ret .= " : [@$bind_params]" if @$bind_params;
    }

    if ($container->{compact} || $ENV{DBIX_QUERYLOG_COMPACT}) {
        my ($buff, $i) = ('', 0);
        my $skip_space    = 0;
        my $before_escape = 0;
        my $quote_char    = '';
        for (my ($i, $l) = (0, length $ret); $i < $l; ++$i) {
            my $s = substr $ret, $i, 1;
            if (!$quote_char && ($s eq q{ }||$s eq "\n"||$s eq "\t"||$s eq "\r")) {
                next if $skip_space;
                $buff .= q{ };
                $skip_space = 1;
                next;
            }
            elsif ($s eq q{'} || $s eq q{"} || $s eq q{`}) {
                unless ($quote_char) {
                    $quote_char = $s;
                }
                elsif (!$before_escape && $s eq $quote_char) {
                    $quote_char = '';
                }
                else {
                    $before_escape = 0;
                }
            }
            elsif (!$before_escape && $quote_char && $s eq q{\\}) {
                $before_escape = 1;
            }
            elsif (!$quote_char) {
                if ($s eq q{(}) {
                    $buff .= $s;
                    $skip_space = 1;
                    next;
                }
                elsif (($s eq q{)}||$s eq q{,}) && substr($buff, -1, 1) eq q{ }) {
                    substr($buff, -1, 1) = '';
                }
            }
            $buff .= $s;
            $skip_space = 0;
        }
        ($ret = $buff) =~ s/^\s|\s$//g;
    }

    if ($container->{useqq} || $ENV{DBIX_QUERYLOG_USEQQ}) {
        local $Data::Dumper::Useqq  = 1;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $ret = Data::Dumper::Dumper($ret);
    }

    my $color = $container->{color} || $ENV{DBIX_QUERYLOG_COLOR};
    my $localtime = do {
        my ($sec, $min, $hour, $day, $mon, $year) = localtime;
        sprintf '%d-%02d-%02dT%02d:%02d:%02d', $year + 1900, $mon + 1, $day, $hour, $min, $sec;
    };
    my $data_source = "$dbh->{Driver}{Name}:$dbh->{Name}";
    my $message = sprintf "[%s] [%s] [%s] %s%s at %s line %s\n",
        $localtime, $caller->{pkg}, $time,
        $container->{show_data_source} || $ENV{DBIX_QUERYLOG_SHOW_DATASOURCE} ? "[$data_source] " : '',
        $color ? colored([$color], $ret) : $ret,
        $caller->{file}, $caller->{line};

    if (my $logger = $container->{logger}) {
        my %explain = $explain ? (explain => $explain->()) : ();
        $logger->log(
            level   => $LOG_LEVEL,
            message => $message,
            params  => {
                dbh         => $dbh,
                localtime   => $localtime,
                time        => $time,
                sql         => $sql,
                bind_params => $bind_params,
                data_source => $data_source,
                %explain,
                %$caller,
            },
        );
    }
    else {
        if (ref $OUTPUT eq 'CODE') {
            my %explain = $explain ? (explain => $explain->()) : ();
            $OUTPUT->(
                dbh         => $dbh,
                level       => $LOG_LEVEL,
                message     => $message,
                localtime   => $localtime,
                time        => $time,
                sql         => $sql,
                bind_params => $bind_params,
                data_source => $data_source,
                %explain,
                %$caller,
            );
        }
        else {
            print {$OUTPUT} $message, $explain ? $explain->(print => 1) : ();
        }
    }
}

{
    package # hide from pause
        DBIx::QueryLog::Guard;
    sub new {
        my ($class, $org_is_enabled) = @_;
        bless [$org_is_enabled], shift;
    }
    sub DESTROY {
        if (shift->[0]) {
            DBIx::QueryLog->enable();
        }
        else {
            DBIx::QueryLog->disable();
        }
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

DBIx::QueryLog - Logging queries for DBI

=head1 SYNOPSIS

  use DBIx::QueryLog;
  my $row = $dbh->selectrow_hashref('SELECT * FROM people WHERE user_id = ?', undef, qw/1986/);
  # => SELECT * FROM people WHERE user_id = '1986';

=head1 DESCRIPTION

DBIx::QueryLog logs each execution time and the actual query.

Currently, it works with DBD::mysql, DBD::Pg and DBD::SQLite.

=head1 CLASS METHODS

=over

=item threshold

If set, only queries that take more time than this threshold will be logged (default is undef)

  DBIx::QueryLog->threshold(0.1); # sec

You can also specify this with C<< DBIX_QUERYLOG_THRESHOLD >> environment variable.

=item probability

If set, the logger logs only once per a defined value. (default is undef)

  DBIx::QueryLog->probability(100); # about 1/100

You can also specify this with C<< DBIX_QUERYLOG_PROBABILITY >> environment variable.

=item logger

Sets a logger class (e.g. L<Log::Dispach>)

The logger class must have a `log` method, which should work like the one of L<Log::Dispatch> (but see also OUTPUT section below).

  DBIx::QueryLog->logger($logger);

=item skip_bind

If set, DBIx::QueryLog runs faster, but placeholders are not processed.

  DBIx::QueryLog->skip_bind(1);
  my $row = $dbh->do(...);
  # => 'SELECT * FROM people WHERE user_id = ?' : [1986]

You can also specify this with C<< DBIX_QUERYLOG_SKIP_BIND >> environment variable.

=item color

If set, log messages will be colored with L<Term::ANSIColor>.

  DBIx::QueryLog->color('green');

You can also specify this with C<< DBIX_QUERYLOG_COLOR >> environment variable.

=item useqq

If set, DBIx::QueryLog uses C<< $Data::Dumper::Useqq >>.

  DBIx::QueryLog->useqq(1);

You can also specify this with C<< DBIX_QUERYLOG_USEQQ >> environment variable.

=item compact

If set, log messages will be compact.

  DBIx::QueryLog->compact(1);
  #  FROM: SELECT          *  FROM      foo WHERE bar = 'baz'
  #  TO  : SELECT * FROM foo WHERE bar = 'baz'

You can also specify this with C<< DBIX_QUERYLOG_COMPACT >> environment variable.

=item explain

B<< EXPERIMENTAL >>

If set, DBIx::QueryLog logs the result of a C<< EXPLAIN >> statement.

  DBIx::QueryLog->explain(1);
  my $row = $dbh->do(...);
  # => SELECT * FROM peaple WHERE user_id = '1986'
  #  .----------------------------------------------------------------------------------------------.
  #  | id | select_type | table  | type  | possible_keys | key     | key_len | ref   | rows | Extra |
  #  +----+-------------+--------+-------+---------------+---------+---------+-------+------+-------+
  #  |  1 | SIMPLE      | peaple | const | PRIMARY       | PRIMARY |       4 | const |    1 |       |
  #  '----+-------------+--------+-------+---------------+---------+---------+-------+------+-------'

You can also specify this with C<< DBIX_QUERYLOG_EXPLAIN >> environment variable.

=item show_data_source

if set, DBI data_source will be added to the log messages.

  $dbh->do('SELECT * FROM sqlite_master');
  # [2012-03-09T00:58:23] [main] [0.000953] SELECT * FROM sqlite_master at foo.pl line 34

  DBIx::QueryLog->show_data_source(1);
  $dbh->do('SELECT * FROM sqlite_master');
  # [2012-03-09T00:58:23] [main] [0.000953] [SQLite:dbname=/tmp/TrSATdY3cc] SELECT * FROM sqlite_master at foo.pl line 56

You can also specify this with C<< DBIX_QUERYLOG_SHOW_DATASOURCE >> environment variable.

=item guard

Returns a guard object.

  use DBIx::QueryLog ();
  {
      my $guard = DBIx::QueryLog->guard;
      # ... do something
  }

The following code does the same:

  use DBIx::QueryLog ();

  DBIx::QueryLog->enable;
  # ... do something
  DBIx::QueryLog->disable;

=item ignore_trace

Returns a guard object and disables tracing while the object is alive.

  use DBIx::QueryLog;

  # enabled
  $dbh->do(...);

  {
      my $guard = DBIx::QueryLog->ignore_trace;
      # disable
      $dbh->do(...);
  }

  # enabled
  $dbh->do(...)

=item is_enabled

Returns if DBIx::QueryLog is enabled or not.

  use DBIx::QueryLog ();

  say DBIx::QueryLog->is_enabled;

  DBIx::QueryLog->disable;

See also L<< Localization >> section.

=back

=head1 TIPS

=head2 Localization

If you want to log only in a specific scope:

  use DBIx::QueryLog (); # or require DBIx::QueryLog;

  DBIx::QueryLog->begin; # or DBIx::QueryLog->enable
  my $row = $dbh->do(...);
  DBIx::QueryLog->end;   # or DBIx::QueryLog->disable

DBIx::QueryLog logs only between C<< begin >> and C<< end >>.

=head2 LOG_LEVEL

When you set a C<< logger >>, you might also want to change a log level.

  $DBIx::QueryLog::LOG_LEVEL = 'info'; # default 'debug'

=head2 OUTPUT

If you want to change where to output:

  open my $fh, '>', 'dbix_query.log';
  $DBIx::QueryLog::OUTPUT = $fh;

You can also specify a code reference:

  $DBIx::QueryLog::OUTPUT = sub {
      my %params = @_;

      my $format = << 'FORMAT';
  localtime  : %s       # ISO-8601 without timezone
  level      : %s       # log level ($DBIx::QueryLog::LOG_LEVEL)
  time       : %f       # elasped time
  data_source: $s       # data_source
  sql        : %s       # executed query
  bind_params: %s       # bind parameters
  pkg        : %s       # caller package
  file       : %s       # caller file
  line       : %d       # caller line
  FORMAT

      printf $format,
          @params{qw/localtime level pkg time data_source sql/},
          join(', ', @{$params{bind_params}}),
          @params{qw/file line/};

      printf "AutoCommit?: %d\n", $params->{dbh}->{AutoCommit} ? 1 : 0;
  };

You can also use this if you want to use a logger that doesn't have a C<< log >> method like the one of L<<Log::Dispatch>>.

  $DBIx::QueryLog::OUTPUT = sub {
      my %params = @_;
      my $logger = Log::Any->get_logger;
      $logger->debug("$params{message}");
  };

Note that this only works when C<<logger>> is not set.

Default C<< $OUTPUT >> is C<< STDERR >>.

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 THANKS TO

tokuhirom

yibe

kamipo

tomi-ru

riywo

makamaka

=head1 BUG REPORTING

Plese use github issues: L<< https://github.com/xaicron/p5-DBIx-QueryLog/issues >>.

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBI>

=cut
