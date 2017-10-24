package DBIx::Struct::JSON::Array;
use strict;
use warnings;

sub TIEARRAY {
    bless [$_[1], $_[2], $_[3]], $_[0];
}

sub FETCHSIZE {
    scalar @{$_[0][0]};
}

sub STORESIZE {
    $_[0][1]{$_[0][2]} = undef;
    $#{$_[0][0]} = $_[1] - 1;
}

sub STORE {
    $_[0][1]{$_[0][2]} = undef;
    $_[0][0][$_[1]] = $_[2];
}
sub FETCH {$_[0][0][$_[1]]}

sub CLEAR {
    $_[0][1]{$_[0][2]} = undef;
    @{$_[0][0]} = ();
}

sub POP {
    $_[0][1]{$_[0][2]} = undef;
    pop(@{$_[0][0]});
}

sub PUSH {
    my $o = shift;
    $o->[1]{$o->[2]} = undef;
    push(@{$o->[0]}, @_);
}

sub SHIFT {
    $_[0][1]{$_[0][2]} = undef;
    shift(@{$_[0][0]});
}

sub UNSHIFT {
    my $o = shift;
    $o->[1]{$o->[2]} = undef;
    unshift(@$o, @_);
}
sub EXISTS {exists $_[0][0]->[$_[1]]}
sub DELETE {delete $_[0][0]->[$_[1]]}

sub SPLICE {
    my $ob  = shift;
    my $sz  = $ob->FETCHSIZE;
    my $off = @_ ? shift : 0;
    $off += $sz if $off < 0;
    my $len = @_ ? shift : $sz - $off;
    $ob->[1]{$ob->[2]} = undef;
    return splice(@{$ob->[0]}, $off, $len, @_);
}

package DBIx::Struct::JSON::Hash;
use strict;
use warnings;

sub TIEHASH {
    bless [$_[1], $_[2], $_[3]], $_[0];
}

sub STORE {
    $_[0][1]{$_[0][2]} = undef;
    $_[0][0]->{$_[1]} = $_[2];
}

sub FETCH {
    $_[0][0]->{$_[1]};
}

sub FIRSTKEY {
    my $a = scalar keys %{$_[0][0]};
    each %{$_[0][0]};
}

sub NEXTKEY {
    each %{$_[0][0]};
}

sub EXISTS {
    exists $_[0][0]->{$_[1]};
}

sub DELETE {
    $_[0][1]{$_[0][2]} = undef;
    delete $_[0][0]->{$_[1]};
}

sub CLEAR {
    $_[0][1]{$_[0][2]} = undef;
    %{$_[0][0]} = ();
}

sub SCALAR {
    scalar %{$_[0][0]};
}

package DBIx::Struct::JSON;

use strict;
use warnings;
use JSON;

sub factory {
    my ($class, $value_ref, $update_hash, $hash_key) = @_;
    my $self;
    if (not ref $$value_ref) {
        my $jv = from_json($$value_ref) if $$value_ref;
        $$value_ref = $jv if $jv;
    }
    if (not defined $$value_ref) {
        $self = [undef, undef];
    } elsif ('HASH' eq ref $$value_ref) {
        my %h;
        tie %h, 'DBIx::Struct::JSON::Hash', $$value_ref, $update_hash, $hash_key;
        $self = [\%h, $$value_ref];
    } elsif ('ARRAY' eq ref $$value_ref) {
        my @a;
        tie @a, 'DBIx::Struct::JSON::Array', $$value_ref, $update_hash, $hash_key;
        $self = [\@a, $$value_ref];
    }
    $$value_ref = bless $self, $class;
}

sub revert {
    $_[0] = defined($_[0][1]) ? to_json $_[0][1] : undef;
}

sub data {
    $_[0][1];
}

sub accessor {
    $_[0][0];
}

package DBIx::Struct::Connector;
use strict;
use warnings;
use base 'DBIx::Connector';

our $db_reconnect_timeout = 30;

sub _connect {
    my ($self, @args) = @_;
    for my $try (1 .. $db_reconnect_timeout) {
        my $dbh = eval {$self->SUPER::_connect(@args)};
        return $dbh if $dbh;
        sleep 1 if $try != $db_reconnect_timeout;
    }
    die $@ if $@;
    die "DB connect error";
}

package DBIx::Struct::Error::String;
use strict;
use warnings;
use Carp;

sub error_message (+%) {
    my $msg = $_[0];
    delete $msg->{result};
    my $message = delete $msg->{message};
    croak join "; ", $message, map {"$_: $msg->{$_}"} keys %$msg;
}

package DBIx::Struct::Error::Hash;
use strict;
use warnings;

sub error_message (+%) {
    die $_[0];
}

package DBIx::Struct;
use strict;
use warnings;
use SQL::Abstract;
use Digest::MD5;
use Data::Dumper;
use Scalar::Util 'refaddr';
use base 'Exporter';
use v5.14;

our $VERSION = '0.37';

our @EXPORT = qw{
    one_row
    all_rows
    for_rows
    new_row
};

our @EXPORT_OK = qw{
    connector
    hash_ref_slice
};

sub ccmap ($) {
    my $name = $_[0];
    $name =~ s/([[:upper:]])/_\l$1/g;
    $name =~ s/^_//;
    return $name;
}

our $camel_case_map = \&ccmap;
our $conn;
our $update_on_destroy     = 1;
our $connector_module      = 'DBIx::Struct::Connector';
our $connector_constructor = 'new';
our $connector_pool;
our $connector_pool_method = 'get_connector';
our $connector_args        = [];
our $connector_driver;
our $table_classes_namespace = 'DBC';
our $query_classes_namespace = 'DBQ';
our $error_message_class     = 'DBIx::Struct::Error::String';
our %driver_pk_insert;

sub error_message (+%) {
    goto &DBIx::Struct::Error::String::error_message;
}

%driver_pk_insert = (
    _returning => sub {
        my ($table, $pk_row_data, $pk_returninig) = @_;
        my $ret;
        if ($pk_row_data) {
            $ret = <<INS;
						($pk_row_data) =
							\$_->selectrow_array(\$insert . " $pk_returninig", undef, \@bind)
INS
        } else {
            $ret = <<INS;
						\$_->do(\$insert, undef, \@bind)
INS
        }
        $ret .= <<INS
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' inserting into table $table'
						};
INS
    },
    _last_id_undef => sub {
        my ($table, $pk_row_data) = @_;
        my $ret;
        $ret = <<INS;
						\$_->do(\$insert, undef, \@bind)
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' inserting into table $table'
						};
INS
        if ($pk_row_data) {
            $ret .= <<INS;
						$pk_row_data = \$_->last_insert_id(undef, undef, undef, undef);
INS
        }
    },
    _last_id_empty => sub {
        my ($table, $pk_row_data) = @_;
        my $ret;
        $ret = <<INS;
						\$_->do(\$insert, undef, \@bind)
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' inserting into table $table'
						};
INS
        if ($pk_row_data) {
            $ret .= <<INS;
						$pk_row_data = \$_->last_insert_id("", "", "", "");
INS
        }
    }
);

$driver_pk_insert{Pg}     = $driver_pk_insert{_returning};
$driver_pk_insert{mysql}  = $driver_pk_insert{_last_id_undef};
$driver_pk_insert{SQLite} = $driver_pk_insert{_last_id_empty};

sub hash_ref_slice($@) {
    my ($hashref, @slice) = @_;
    error_message {
        message => "first parameter is not hash reference",
        result  => 'INTERR',
        }
        if 'HASH' ne ref $hashref;
    map {$_ => $hashref->{$_}} @slice;
}

my @already_exported_to;

sub connector {
    $conn;
}

sub connector_from_pool {
    $connector_pool->$connector_pool_method();
}

sub set_connector_pool {
    $connector_pool = $_[0];
    if (\&connector != \&connector_from_pool) {
        no warnings 'redefine';
        no strict 'refs';
        *connector = \&connector_from_pool;
        for my $aep (@already_exported_to) {
            *{"$aep\::connector"} = \&connector;
        }
    }
}

sub set_connector_pool_method {
    $connector_pool_method = $_[0];
}

sub set_connector_object {
    *conn = \$_[0];
}

sub set_camel_case_map {
    error_message {
        message => "CamelCaseMap must be code reference",
        result  => 'SQLERR',
    } if 'CODE' ne ref $_[0];
    $camel_case_map = $_[0];
}

sub check_package_scalar {
    my ($package, $scalar) = @_;
    no strict 'refs';
    my $pr = \%{$package . '::'};
    my $er = $$pr{$scalar};
    return unless $er;
    defined *{$er}{'SCALAR'};
}

sub import {
    my ($class, @args) = @_;
    my $defconn = 0;
    my $_emc    = 0;
    my $_cp     = 0;
    my $_c      = 0;
    for (my $i = 0; $i < @args; ++$i) {
        if ($args[$i] eq 'connector_module') {
            (undef, $connector_module) = splice @args, $i, 2;
            --$i;
            if (not $defconn and check_package_scalar($connector_module, 'conn')) {
                no strict 'refs';
                set_connector_object(${$connector_module . '::conn'});
            }
        } elsif ($args[$i] eq 'connector_constructor') {
            (undef, $connector_constructor) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'camel_case_map' && 'CODE' eq ref $args[$i]) {
            (undef, $camel_case_map) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'table_classes_namespace') {
            (undef, $table_classes_namespace) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'query_classes_namespace') {
            (undef, $query_classes_namespace) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'connect_timeout') {
            (undef, $db_reconnect_timeout) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'error_class') {
            my (undef, $emc) = splice @args, $i, 2;
            $error_message_class = $emc;
            $_emc                = 1;
            --$i;
        } elsif ($args[$i] eq 'connector_pool') {
            (undef, $connector_pool) = splice @args, $i, 2;
            $_cp = 1;
            --$i;
        } elsif ($args[$i] eq 'connector_pool_method') {
            (undef, $connector_pool_method) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'connector_args') {
            (undef, $connector_args) = splice @args, $i, 2;
            --$i;
        } elsif ($args[$i] eq 'connector') {
            $_c = 1;
        } elsif ($args[$i] eq 'connector_object') {
            $defconn = 1;
            set_connector_object($args[$i + 1]);
            splice @args, $i, 2;
            --$i;
        }
    }
    if ($_emc) {
        no warnings 'redefine';
        no strict 'refs';
        *error_message = \&{$error_message_class . "::error_message"};
    }
    if ($_cp) {
        no warnings 'redefine';
        no strict 'refs';
        *connector = \&connector_from_pool;
        for my $aep (@already_exported_to) {
            *{"$aep\::connector"} = \&connector;
        }
    }
    my $callpkg = caller;
    push @already_exported_to, $callpkg if $_c;
    my %imps = map {$_ => undef} @args, @EXPORT;
    $class->export_to_level(1, $class, keys %imps);
}

sub _not_yet_connected {
    if (!$connector_pool && !$conn) {
        my ($dsn, $user, $password) = @_;
        if ($dsn && $dsn !~ /^dbi:/i) {
            $dsn = "dbi:Pg:dbname=$dsn";
        }
        my $connect_attrs = {
            AutoCommit          => 1,
            PrintError          => 0,
            AutoInactiveDestroy => 1,
            RaiseError          => 0,
        };
        if ($dsn) {
            my ($driver) = $dsn =~ /^dbi:(\w*?)(?:\((.*?)\))?:/i;
            if ($driver) {
                if ($driver eq 'Pg') {
                    $connect_attrs->{pg_enable_utf8} = 1;
                } elsif ($driver eq 'mysql') {
                    $connect_attrs->{mysql_enable_utf8} = 1;
                } elsif ($driver eq 'SQLite') {
                    $connect_attrs->{sqlite_unicode} = 1;
                }
            }
        }
        if (!@$connector_args) {
            @$connector_args = ($dsn, $user, $password, $connect_attrs);
        }
        $conn = $connector_module->$connector_constructor(@$connector_args)
            or error_message {
            message => "DB connect error",
            result  => 'SQLERR',
            };
        $conn->mode('fixup');
    }
    '' =~ /()/;
    $connector_driver = connector->driver->{driver};
    no warnings 'redefine';
    *connect = \&connector;
    populate();
    connector;
}

sub connect {
    goto &_not_yet_connected;
}

{
    my $md5 = Digest::MD5->new;

    sub make_name {
        my ($table) = @_;
        my $simple_table = (index($table, " ") == -1);
        my $ncn;
        if ($simple_table) {
            $ncn = $table_classes_namespace . "::" . join('', map {ucfirst($_)} split(/[^a-zA-Z0-9]/, $table));
        } else {
            $md5->add($table);
            $ncn = $query_classes_namespace . "::" . "G" . $md5->hexdigest;
            $md5->reset;
        }
        $ncn;
    }
}

sub populate {
    my @tables;
    DBIx::Struct::connect->run(
        sub {
            my $sth = $_->table_info('', '', '%', "TABLE");
            return if not $sth;
            my $tables = $sth->fetchall_arrayref;
            @tables = map {$_->[2]} grep {$_->[3] eq 'TABLE' and $_->[2] !~ /^sql_/} @$tables;
        }
    );
    setup_row($_) for @tables;
}

#<<<
my @uneq = (
	qr/LessThanEqual$/,    '<=',
	qr/LessThan$/,         '<',
	qr/GreaterThanEqual$/, '>=',
	qr/GreaterThan$/,      '>',
	qr/IsNull$/,           sub {"'$_[0]' => {'=', undef}"},
	qr/IsNotNull$/,        sub {"'$_[0]' => {'!=', undef}"},
	qr/IsNot$/,            '!=',
	qr/NotNull$/,          sub {"'$_[0]' => {'!=', undef}"},
	qr/NotEquals$/,        '!=',
	qr/NotIn$/,            '-not_in',
	qr/NotLike$/,          '-not_like',
	qr/IsEqualTo$/,        '=',
	qr/IsTrue$/,           sub {"-bool => '$_[0]'"},
	qr/IsFalse$/,          sub {"-not_bool => '$_[0]'"},
	qr/Equals$/,           '=',
	qr/True$/,             sub {"-bool => '$_[0]'"},
	qr/False$/,            sub {"-not_bool => '$_[0]'"},
	qr/Like$/,             '-like',
	qr/Is$/,               '=',
	qr/Not$/,              '!=',
	qr/In$/,               '-in',
);
#>>>

sub _parse_find_by {
    my ($table, $find) = @_;
    $find =~ s/^find(?<what>.*?)By(?![[:lower:]])// || $find =~ s/^find(?<what>.*)// or die "bad pattern: $find";
    my $what = $+{what} || 'All';
    $what =~ s/(?<distinct>Distinct)(?![[:lower:]])//;
    my $distinct = $+{distinct} // 0;
    $what =~ s/((?<type>(All|One|First))(?<limit>\d+)?)(?![[:lower:]])//;
    my $type = $+{type} // 'All';
    my $limit = $+{limit};
    $what =~ s/(?<column>\w+)//;
    my $column = $camel_case_map->($+{column} // '');
    $find =~ s/OrderBy(?<order>.*?)(?<asc>Asc|Desc)(?=[[:upper:]]|$)// || $find =~ s/OrderBy(?<order>.*?)$//;
    my $order = $+{order};
    my $asc   = $+{asc} || 'Asc';
    my $where = $find;

    if ($type eq 'First' && !$limit) {
        $limit = 1;
    }
    if ($limit && $limit == 1) {
        $type = 'One';
    }
    my $pi = 1;
    my $pp = sub {
        my ($param) = @_;
        my $found;
        for (my $i = 0; $i < @uneq; $i += 2) {
            if ($param =~ s/$uneq[$i]//) {
                $found = $i + 1;
                last;
            }
        }
        $param = $camel_case_map->($param);
        my $ret;
        if ($found) {
            if ('CODE' eq ref $uneq[$found]) {
                $ret = $uneq[$found]->($param);
            } else {
                $ret = "'$param' => { '$uneq[$found]' => \$_[$pi]}";
                ++$pi;
            }
        } else {
            $ret = "'$param' => \$_[$pi]";
            ++$pi;
        }
        $ret;
    };
#<<<
	my $conds = join(
		", ",
		map {
			/And(?![[:lower:]])/
				? '-and => [' . join(", ", map {$pp->($_)} split /And(?![[:lower:]])/x, $_) . ']'
				: $pp->($_);
		} split /Or(?![[:lower:]])/, $where
	);
#>>>
    my $obj   = $type eq 'One' ? 'DBIx::Struct::one_row'  : 'DBIx::Struct::all_rows';
    my $flags = $column        ? ", -column => '$column'" : '';
    $flags = $distinct ? $flags ? ", -distinct => '$column'" : ", '-distinct'" : $flags;
    $order
        = $order
        ? $asc eq 'Asc'
            ? ", -order_by => '" . $camel_case_map->($order) . "'"
            : ", -order_by => {-desc => '" . $camel_case_map->($order) . "'}"
        : '';
    $where = $conds ? ", -where => [$conds]" : '';
    $limit = $limit && $limit > 1 && $type ne 'One' ? ", -limit => $limit" : '';
    my $tspec = "'$table'" . $flags;
    $tspec = "[$tspec]" if $column;
    $tspec .= $where . $order . $limit;
    return "sub { $obj($tspec) }";
}

sub _row_data ()    {0}
sub _row_updates () {1}

sub make_object_new {
    my ($table, $required, $pk_row_data, $pk_returninig) = @_;
    my $new = <<NEW;
		sub new {
			my \$class = \$_[0];
			my \$self = [ [] ];
			bless \$self, \$class;
			if(CORE::defined(\$_[1]) && CORE::ref(\$_[1]) eq 'ARRAY') {
				\$self->[@{[_row_data]}] = \$_[1];
			}
NEW
    if (not ref $table) {
        $new .= <<NEW;
			 else {
				my \%insert;
				for(my \$i = 1; \$i < \@_; \$i += 2) {
					if (CORE::exists \$fields{\$_[\$i]}) {
						my \$f = \$_[\$i];
						\$self->[@{[_row_data]}]->[\$fields{\$_[\$i]}] = \$_[\$i + 1];
						\$insert{\$f} = \$_[\$i + 1];
					} else {
						DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => "unknown column \$_[\$i] inserting into table $table"
						}
					}
				}
				my (\@insert, \@values, \@bind);
				\@insert =
					CORE::map { 
						if(CORE::ref(\$insert{\$_}) eq 'ARRAY' and CORE::ref(\$insert{\$_}[0]) eq 'SCALAR') {
							CORE::push \@bind, \@{\$insert{\$_}}[1..\$#{\$insert{\$_}}];
							CORE::push \@values, \${\$insert{\$_}[0]};
							DBIx::Struct::connect->dbh->quote_identifier(\$_);
						} elsif(CORE::ref(\$insert{\$_}) eq 'REF' and CORE::ref(\${\$insert{\$_}}) eq 'ARRAY') {
							if(CORE::defined \${\$insert{\$_}}->[0]) {
								CORE::push \@bind, \@{\${\$insert{\$_}}}[1..\$#{\${\$insert{\$_}}}];
								CORE::push \@values, \${\$insert{\$_}}->[0];
								DBIx::Struct::connect->dbh->quote_identifier(\$_);
							} else {
								CORE::push \@values, "null";
								DBIx::Struct::connect->dbh->quote_identifier(\$_)
							}
						} elsif(CORE::ref(\$insert{\$_}) eq 'SCALAR') {
							CORE::push \@values, \${\$insert{\$_}};
							DBIx::Struct::connect->dbh->quote_identifier(\$_);
						} elsif(CORE::exists (\$json_fields{\$_})
							&& (CORE::ref(\$insert{\$_}) eq 'ARRAY' || CORE::ref(\$insert{\$_}) eq 'HASH')) {
							CORE::push \@bind, JSON::to_json(\$insert{\$_});
							CORE::push \@values, "?";
							DBIx::Struct::connect->dbh->quote_identifier(\$_);
						} else {
							CORE::push \@bind, \$insert{\$_};
							CORE::push \@values, "?";
							DBIx::Struct::connect->dbh->quote_identifier(\$_);
						}						
					} CORE::keys \%insert;
				my \$insert;
				if(\%insert){
					\$insert = "insert into $table (" . CORE::join( ", ", \@insert) . ") values ("
					.  CORE::join( ", ", \@values) . ")";
				} else {
					\$insert = "insert into $table values (default)";
				}
NEW
        if ($required) {
            $new .= <<NEW;
				for my \$r ($required) {
					DBIx::Struct::error_message {
						result  => 'SQLERR',
						message => "required field \$r is absent for table $table"
					} if not CORE::exists \$insert{\$r};
				}
NEW
        }
        $new .= <<NEW;
				DBIx::Struct::connect->run(
					sub {
NEW
        $new .= $driver_pk_insert{$connector_driver}->($table, $pk_row_data, $pk_returninig);
        $new .= <<NEW;
	  			});
			}
NEW
    }
    $new .= <<NEW;
	  		\$self;
		}
NEW
    $new;
}

sub make_object_filter_timestamp {
    my ($timestamps) = @_;
    my $filter_timestamp = <<FTS;
		sub filter_timestamp {
			my \$self = \$_[0];
			if(\@_ == 1) {
				for my \$f ($timestamps) {
					if(\$self->[@{[_row_data]}][\$fields{\$f}]) {
						\$self->[@{[_row_data]}][\$fields{\$f}] =~ s/\\.\\d+(\$|\\+|\\-)/$1/;
						\$self->[@{[_row_data]}][\$fields{\$f}] =~ s/(\\+|\\-)(\\d{2})\$/\$1\${2}00/;
					}
				}
			} else {
				for my \$f (\@_[1..\$#_]) {
					if(\$self->[@{[_row_data]}][\$fields{\$f}]) {
						\$self->[@{[_row_data]}][\$fields{\$f}] =~ s/\\.\\d+(\$|\\+|\\-)/$1/;
						\$self->[@{[_row_data]}][\$fields{\$f}] =~ s/(\\+|\\-)(\\d{2})\$/\$1\${2}00/;
					}
				}
			}
			'' =~ /()/;
			\$self;
		}
FTS
    $filter_timestamp;
}

sub make_object_set {
    my $table = $_[0];
    my $set   = <<SET;
		sub set {
			my \$self = \$_[0];
			my \@unknown_columns;
			if(CORE::defined(\$_[1])) {
				if(CORE::ref(\$_[1]) eq 'ARRAY') {
					\$self->[@{[_row_data]}] = \$_[1];
					\$self->[@{[_row_updates]}] = {};
				} elsif(CORE::ref(\$_[1]) eq 'HASH') {
					for my \$f (CORE::keys \%{\$_[1]}) {
						if (CORE::exists \$fields{\$f}) {
							\$self->\$f(\$_[1]->{\$f});
						} else {
							CORE::push \@unknown_columns, \$f;
						}
					}
				} elsif(not CORE::ref(\$_[1])) {
					for(my \$i = 1; \$i < \@_; \$i += 2) {
						if (CORE::exists \$fields{\$_[\$i]}) {
							my \$f = \$_[\$i];
							\$self->\$f(\$_[\$i + 1]);
						} else {
							CORE::push \@unknown_columns, \$_[\$i];
						}
					}
				}
			}
			DBIx::Struct::error_message {
					result  => 'SQLERR',
					message => 'unknown columns '.CORE::join(", ", \@unknown_columns).' for $table->data'
			} if \@unknown_columns;
			\$self;
		}
SET
    $set;
}

sub make_object_data {
    my $table = $_[0];
    my $data  = <<DATA;
		sub data {
			my \$self = \$_[0];
			my \@ret_keys;
			my \$ret;
			if(CORE::defined(\$_[1])) {
				if(CORE::ref(\$_[1]) eq 'ARRAY') {
					if(!\@{\$_[1]}) {
						\$ret = \$self->[@{[_row_data]}];
					} else {
						\$ret = [CORE::map {\$self->[@{[_row_data]}]->[\$fields{\$_}] } \@{\$_[1]}];
					}
				} else {
					for my \$k (\@_[1..\$#_]) {
						CORE::push \@ret_keys, \$k if CORE::exists \$fields{\$k};
					}
				}
			} else {
				\@ret_keys = keys \%fields;
			}
			my \@unknown_columns = CORE::grep {not CORE::exists \$fields{\$_}} \@ret_keys;
			DBIx::Struct::error_message {
					result  => 'SQLERR',
					message => 'unknown columns '.CORE::join(", ", \@unknown_columns).' for $table->data'
			} if \@unknown_columns;
			\$ret = { 
				CORE::map {\$_ => \$self->\$_} \@ret_keys
			} if not CORE::defined \$ret;
			\$ret;
		}
DATA
    $data;
}

sub make_object_update {
    my ($table, $pk_where, $pk_row_data) = @_;
    my $update;
    if (not ref $table) {

        # means this is just one simple table
        $update = <<UPD;
		sub update {
			my \$self = \$_[0];
			if(\@_ > 1 && CORE::ref(\$_[1]) eq 'HASH') {
				my (\$set, \$where, \@bind, \@bind_where);
				{
					no strict 'vars';
					local *set_hash = \$_[1];
					my \@unknown_columns = CORE::grep {not CORE::exists \$fields{\$_}} CORE::keys %set_hash;
					DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'unknown columns '.CORE::join(", ", \@unknown_columns).' updating table $table'
					} if \@unknown_columns;
					\$set = 
						CORE::join ", ", 
						CORE::map { 
							if(CORE::ref(\$set_hash{\$_}) eq 'ARRAY' and CORE::ref(\$set_hash{\$_}[0]) eq 'SCALAR') {
								CORE::push \@bind, \@{\$set_hash{\$_}}[1..\$#{\$set_hash{\$_}}];
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \${\$set_hash{\$_}[0]};
							} elsif(CORE::ref(\$set_hash{\$_}) eq 'REF' and CORE::ref(\${\$set_hash{\$_}}) eq 'ARRAY') {
								if(CORE::defined \${\$set_hash{\$_}}->[0]) {
									CORE::push \@bind, \@{\${\$set_hash{\$_}}}[1..\$#{\${\$set_hash{\$_}}}];
									DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \${\$set_hash{\$_}}->[0];
								} else {
									DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = null"
								}
							} elsif(CORE::ref(\$set_hash{\$_}) eq 'SCALAR') {
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \${\$set_hash{\$_}};
							} elsif(CORE::exists(\$json_fields{\$_})
								&& (CORE::ref(\$set_hash{\$_}) eq 'ARRAY' || CORE::ref(\$set_hash{\$_}) eq 'HASH')) {
								CORE::push \@bind, JSON::to_json(\$set_hash{\$_});
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = ?" 
							} else {
								CORE::push \@bind, \$set_hash{\$_};
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = ?" 
							}						
						} CORE::keys \%set_hash;
				}
				if(\@_ > 2) {
					my \$cond = \$_[2];
					if(not CORE::ref(\$cond)) {
						\$cond = {(selectKeys)[0] => \$_[2]};
					}
					(\$where, \@bind_where) = SQL::Abstract->new->where(\$cond);
				}
				return DBIx::Struct::connect->run(sub {
					\$_->do(qq{update $table set \$set \$where}, undef, \@bind, \@bind_where)
					or DBIx::Struct::error_message {
						result  => 'SQLERR',
						message => 'error '.\$_->errstr.' updating table $table'
					}
				});
			} elsif (CORE::ref(\$self) && \@\$self > 1 && \%{\$self->[@{[_row_updates]}]}) {
				my (\$set, \@bind);
				{
					no strict 'vars';
					\$set = 
						CORE::join ", ", 
						CORE::map { 
							local *column_value = \\\$self->[@{[_row_data]}][\$fields{\$_}];
							if(CORE::ref(\$column_value) eq 'ARRAY' and CORE::ref(\$column_value->[0]) eq 'SCALAR') {
								CORE::push \@bind, \@{\$column_value}[1..\$#\$column_value];
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \${\$column_value->[0]};
							} elsif(CORE::ref(\$column_value) eq 'REF' and CORE::ref(\${\$column_value}) eq 'ARRAY') {
								if(CORE::defined \${\$column_value}->[0]) {
									CORE::push \@bind, \@{\${\$column_value}}[1..\$#{\${\$column_value}}];
									DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \${\$column_value}->[0];
								} else {
									DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = null"
								}
							} elsif(CORE::ref(\$column_value) && CORE::ref(\$column_value) =~ /^DBIx::Struct::JSON/) {
								\$column_value->revert;
								CORE::push \@bind, \$column_value;
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = ?" 
							} elsif(CORE::ref(\$column_value) eq 'SCALAR') {
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = " . \$\$column_value;
							} else {
								CORE::push \@bind, \$column_value;
								DBIx::Struct::connect->dbh->quote_identifier(\$_) . " = ?" 
							}						
						} CORE::keys \%{\$self->[@{[_row_updates]}]};
				}
				my \$update_query = qq{update $table set \$set where $pk_where};
				DBIx::Struct::connect->run(
					sub {
						\$_->do(\$update_query, undef, \@bind, $pk_row_data)
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' updating table $table',
							query   => \$update_query,
							bind    => \\\@bind,
						}
					}
				);
				\$#\$self = @{[_row_data]};
			}
			\$self;
		}
UPD
    } else {
        $update = <<UPD;
		sub update {}
UPD
    }
    $update;
}

sub make_object_delete {
    my ($table, $pk_where, $pk_row_data) = @_;
    my $delete;
    if (not ref $table) {
        $delete = <<DEL;
		sub delete {
			my \$self = \$_[0];
			if(Scalar::Util::blessed \$self) {
				DBIx::Struct::connect->run(
					sub {
						\$_->do(qq{delete from $table where $pk_where}, undef, $pk_row_data)
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' updating table $table'
						}
					});
				return \$self;
			}
			my \$where = '';
			my \@bind;
			my \$cond = \$_[1] if \@_ > 1;
			if(not CORE::ref(\$cond)) {
				\$cond = {};
				my \@keys = selectKeys();
				for(my \$i = 1; \$i < \@_; ++\$i) {
					DBIx::Struct::error_message {
						result  => 'SQLERR',
						message => "Too many keys to delete for $table"
					} if not CORE::defined \$keys[\$i-1];
					\$cond->{\$keys[\$i-1]} = \$_[\$i];
				}
			}
			my \@rpar = ();
			if(\$cond) {
				(\$where, \@bind) = SQL::Abstract->new->where(\$cond);
				\@rpar = (undef, \@bind);
			}
			return DBIx::Struct::connect->run(sub {
				\$_->do(qq{delete from $table \$where}, \@rpar)
				or DBIx::Struct::error_message {
					result  => 'SQLERR',
					message => 'error '.\$_->errstr.' updating table $table'
				}
			});
		}
DEL
    } else {
        $delete = <<DEL
		sub delete {}
DEL
    }
    $delete;
}

sub make_object_autoload_find {
    my ($table, $pk_where, $pk_row_data) = @_;
    my $find = '';
    if (not ref $table) {
        $find = <<AUTOLOAD;
		sub AUTOLOAD {
			my \$self = \$_[0];
			( my \$method = \$AUTOLOAD ) =~ s{.*::}{};
			 
			if(Scalar::Util::blessed \$self) {
				\$self = CORE::ref \$self;
			}
			DBIx::Struct::error_message {
				result  => 'SQLERR',
				message => "Unknown method \$method for $table"
			} if !\$self || !"\$self"->can("tableName") || \$method !~ /^find/;
			my \$func = DBIx::Struct::_parse_find_by('$table', \$method);
			my \$ncn = DBIx::Struct::make_name('$table');
			{
				no strict 'refs';
				*{\$ncn."::".\$method} = eval \$func;
				DBIx::Struct::error_message {
					result  => 'SQLERR',
					message => "Error creating method \$method for $table: \$!"
				} if \$!;
			}
			goto &{\$ncn."::".\$method};
		}
AUTOLOAD
    }
    $find;
}

sub make_object_fetch {
    my ($table, $pk_where, $pk_row_data) = @_;
    my $fetch;
    if (not ref $table) {
        $fetch = <<FETCH;
		sub fetch {
			my \$self = \$_[0];
			if(\@_ > 1) {
				my (\$where, \@bind);
				my \$cond = \$_[1];
				if(not CORE::ref(\$cond)) {
					\$cond = {(selectKeys)[0] => \$_[1]};
				}
				(\$where, \@bind) = SQL::Abstract->new->where(\$cond);
				DBIx::Struct::connect->run(sub {
					my \$rowref = \$_->selectrow_arrayref(qq{select * from $table \$where}, undef, \@bind)
					or DBIx::Struct::error_message {
						result  => 'SQLERR',
						message => 'error '.\$_->errstr.' fetching table $table'
					};
					\$self->[@{[_row_data]}] = [\@\$rowref]; 
				});
			} else {
				DBIx::Struct::connect->run(
					sub {
						my \$rowref = \$_->selectrow_arrayref(qq{select *  from $table where $pk_where}, undef, $pk_row_data)
						or DBIx::Struct::error_message {
							result  => 'SQLERR',
							message => 'error '.\$_->errstr.' fetching table $table'
						};
						\$self->[@{[_row_data]}] = [\@\$rowref];
					});
			}
			\$self;
		}
FETCH
    } else {
        $fetch = <<FETCH;
		sub fetch { \$_[0] }
FETCH
    }
    $fetch;
}

sub _exists_row ($) {
    my $ncn = $_[0];
    no strict "refs";
    if (grep {!/::$/} keys %{"${ncn}::"}) {
        return 1;
    }
    return;
}

sub _parse_interface ($) {
    my $interface = $_[0];
    my %ret;
    $interface = [$interface] if not ref $interface;
    if ('ARRAY' eq ref $interface) {
        for my $i (@$interface) {
            my $dbc_name = make_name($i);
            error_message {
                result  => 'SQLERR',
                message => "Unknown base interface table $i",
                }
                unless _exists_row $dbc_name;
            no strict 'refs';
            my $href = \%{"${dbc_name}::fkfuncs"};
            if ($href && %$href) {
                my @i = keys %$href;
                @ret{@i} = @{$href}{@i};
            }
        }
    } elsif ('HASH' eq ref $interface) {
        for my $i (keys %$interface) {
            my $dbc_name = make_name($i);
            error_message {
                result  => 'SQLERR',
                message => "Unknown base interface table $i",
                }
                unless _exists_row $dbc_name;
            no strict 'refs';
            my $href = \%{"${dbc_name}::fkfuncs"};
            next if not $href or not %$href;
            my $fl = $interface->{$i};
            $fl = [$fl] if not ref $fl;
            if ('ARRAY' eq ref $fl) {

                for my $m (@$fl) {
                    $ret{$m} = $href->{$m} if exists $href->{$m};
                }
            } else {
                error_message {
                    result  => 'SQLERR',
                    message => "Usupported interface structure",
                };
            }
        }
    } else {
        error_message {
            result  => 'SQLERR',
            message => "Unknown interface structure: " . ref($interface),
        };
    }
    \%ret;
}

sub make_object_to_json {
    my ($table, $field_types, $fields) = @_;
    my $field_to_types = join ",\n\t\t\t\t ", map {
        qq|"$_" => !defined(\$self->[@{[_row_data]}][$fields->{$_}])? undef: |
            . (
              $field_types->{$_} eq 'number'  ? "0+\$self->[@{[_row_data]}][$fields->{$_}]"
            : $field_types->{$_} eq 'boolean' ? "\$self->[@{[_row_data]}][$fields->{$_}]? \\1: \\0"
            : $field_types->{$_} eq 'json'
            ? "CORE::ref(\$self->[@{[_row_data]}]->[$fields->{$_}])? \$self->[@{[_row_data]}][$fields->{$_}]->data"
                . ": JSON::from_json(\$self->[@{[_row_data]}][$fields->{$_}])"
            : "\"\$self->[@{[_row_data]}][$fields->{$_}]\""
            )
    } keys %$field_types;
    my $set = <<TOJSON;
		sub TO_JSON {
			my \$self = \$_[0];
			return +{
				$field_to_types
			};
		}
TOJSON
}

sub _field_type_from_name {
    my $type_name = $_[0];
    return 'string' if not defined $type_name;
    if (   $type_name =~ /int(\d+)?$/i
        || $type_name =~ /integer/i
        || $type_name =~ /bit$/
        || $type_name =~ /float|double|real|decimal|numeric/i)
    {
        return 'number';
    } elsif ($type_name =~ /json/i) {
        return 'json';
    } elsif ($type_name =~ /bool/i) {
        return 'boolean';
    } else {
        return 'string';
    }
}

sub setup_row {
    my ($table, $ncn, $interface) = @_;
    error_message {
        result  => 'SQLERR',
        message => "Unsupported driver $connector_driver",
        }
        unless exists $driver_pk_insert{$connector_driver};
    $ncn ||= make_name($table);
    return $ncn if _exists_row $ncn ;
    my %fields;
    my @fields;
    my @timestamp_fields;
    my @required;
    my @pkeys;
    my @fkeys;
    my @refkeys;
    my %json_fields;
    my $connector = DBIx::Struct::connect;
    my %field_types;

    if (not ref $table) {
        # means this is just one simple table
        $connector->run(
            sub {
                my $cih = $_->column_info(undef, undef, $table, undef);
                error_message {
                    result  => 'SQLERR',
                    message => "Unknown table $table",
                    }
                    if not $cih;
                my $i = 0;
                while (my $chr = $cih->fetchrow_hashref) {
                    $chr->{COLUMN_NAME} =~ s/"//g;
                    $chr->{COLUMN_NAME} = lc $chr->{COLUMN_NAME};
                    push @fields, $chr->{COLUMN_NAME};
                    if ($chr->{TYPE_NAME} =~ /^time/i) {
                        push @timestamp_fields, $chr->{COLUMN_NAME};
                    }
                    if ($chr->{TYPE_NAME} =~ /^json/i) {
                        $json_fields{$chr->{COLUMN_NAME}} = undef;
                    }
                    $chr->{COLUMN_DEF} ||= $chr->{mysql_is_auto_increment};
                    if ($chr->{NULLABLE} == 0 && !defined($chr->{COLUMN_DEF})) {
                        push @required, $chr->{COLUMN_NAME};
                    }
                    $fields{$chr->{COLUMN_NAME}}      = $i++;
                    $field_types{$chr->{COLUMN_NAME}} = _field_type_from_name($chr->{TYPE_NAME});
                }
                @pkeys = map {lc} $_->primary_key(undef, undef, $table);
                if (!@pkeys && @required) {
                    my $ukh = $_->statistics_info(undef, undef, $table, 1, 1);
                    my %req = map {$_ => undef} @required;
                    my %pkeys;
                    while (my $ukr = $ukh->fetchrow_hashref) {
                        if (not exists $req{$ukr->{COLUMN_NAME}} or defined $ukr->{FILTER_CONDITION}) {
                            $pkeys{lc $ukr->{INDEX_NAME}}{drop} = 1;
                        } else {
                            $pkeys{lc $ukr->{INDEX_NAME}}{fields}{lc $ukr->{COLUMN_NAME}} = undef;
                        }
                    }
                    my @d = grep {exists $pkeys{$_}{drop}} keys %pkeys;
                    delete $pkeys{$_} for @d;
                    if (%pkeys) {
                        my @spk = sort {scalar(keys %{$pkeys{$a}{fields}}) <=> scalar(keys %{$pkeys{$b}{fields}})}
                            keys %pkeys;
                        @pkeys = keys %{$pkeys{$spk[0]}{fields}};
                    }
                }
                my $sth = $_->foreign_key_info(undef, undef, undef, undef, undef, $table);
                if ($sth) {
                    @fkeys = grep {($_->{PKTABLE_NAME} || $_->{UK_TABLE_NAME}) && $_->{FK_COLUMN_NAME} !~ /[^a-z_0-9]/}
                        map {
                        $_->{FK_COLUMN_NAME} = $_->{FKCOLUMN_NAME}
                            if $_->{FKCOLUMN_NAME};
                        $_->{FK_TABLE_NAME}  = $_->{FKTABLE_NAME} if $_->{FKTABLE_NAME};
                        $_->{FK_TABLE_NAME}  = lc $_->{FK_TABLE_NAME};
                        $_->{FK_COLUMN_NAME} = lc $_->{FK_COLUMN_NAME};
                        $_->{PKTABLE_NAME}  ||= $_->{UK_TABLE_NAME};
                        $_->{PKCOLUMN_NAME} ||= $_->{UK_COLUMN_NAME};
                        $_->{PKTABLE_NAME}  = lc $_->{PKTABLE_NAME}  if $_->{PKTABLE_NAME};
                        $_->{PKCOLUMN_NAME} = lc $_->{PKCOLUMN_NAME} if $_->{PKCOLUMN_NAME};
                        $_
                        } @{$sth->fetchall_arrayref({})};
                }
                $sth = $_->foreign_key_info(undef, undef, $table, undef, undef, undef);
                if ($sth) {
                    @refkeys = grep {($_->{PKTABLE_NAME} || $_->{UK_TABLE_NAME}) && $_->{FK_COLUMN_NAME} !~ /[^a-z_0-9]/}
                        map {
                        $_->{FK_COLUMN_NAME} = $_->{FKCOLUMN_NAME}
                            if $_->{FKCOLUMN_NAME};
                        $_->{FK_TABLE_NAME}  = $_->{FKTABLE_NAME} if $_->{FKTABLE_NAME};
                        $_->{FK_TABLE_NAME}  = lc $_->{FK_TABLE_NAME};
                        $_->{FK_COLUMN_NAME} = lc $_->{FK_COLUMN_NAME};
                        $_->{PKTABLE_NAME}   = lc($_->{PKTABLE_NAME} || $_->{UK_TABLE_NAME});
                        $_->{PKCOLUMN_NAME}  = lc($_->{PKCOLUMN_NAME} || $_->{UK_COLUMN_NAME});
                        $_
                        } @{$sth->fetchall_arrayref({})};
                }
            }
        );
    } else {

        # means this is a query
        my %tnh = %{$table->{NAME_lc_hash}};
        for my $k (keys %tnh) {
            my $fk = $k;
            $fk =~ s/[^\w ].*$//;
            $fields{$fk} = $tnh{$k};
        }
        $connector->run(
            sub {
                for (my $cn = 0; $cn < @{$table->{NAME}}; ++$cn) {
                    my $ti    = $_->type_info($table->{TYPE}->[$cn]);
                    my $field = lc $table->{NAME}->[$cn];
                    $field =~ s/[^\w ].*$//;
                    $field_types{$field} = _field_type_from_name($ti->{TYPE_NAME});
                    push @timestamp_fields, $field
                        if $ti->{TYPE_NAME} && $ti->{TYPE_NAME} =~ /^time/;
                    $json_fields{$field} = undef
                        if $ti->{TYPE_NAME} && $ti->{TYPE_NAME} =~ /^json/;
                }
            }
        );
    }
    my $field_types = join ", ", map {qq|"$_" => '$field_types{$_}'|} keys %field_types;
    my $fields      = join ", ", map {qq|"$_" => $fields{$_}|} keys %fields;
    my $json_fields = join ", ", map {qq|"$_" => undef|} keys %json_fields;
    my $required    = '';
    if (@required) {
        $required = join(", ", map {qq|"$_"|} @required);
    }
    my $timestamps = '';
    if (@timestamp_fields) {
        $timestamps = join(", ", map {qq|"$_"|} @timestamp_fields);
    } else {
        $timestamps = "()";
    }
    my %keywords = (
        new              => undef,
        set              => undef,
        data             => undef,
        delete           => undef,
        fetch            => undef,
        update           => undef,
        DESTROY          => undef,
        filter_timestamp => undef,
    );
    my $pk_row_data   = '';
    my $pk_returninig = '';
    my $pk_where      = '';
    my $select_keys   = '';
    my %pk_fields;
    if (@pkeys) {
        @pk_fields{@pkeys} = undef;
        $pk_row_data = join(", ", map {qq|\$self->[@{[_row_data]}]->[$fields{"$_"}]|} @pkeys);
        $pk_returninig = 'returning ' . join(", ", @pkeys);
        $pk_where = join(" and ", map {"$_ = ?"} @pkeys);
        my $sk_list = join(", ", map {qq|"$_"|} @pkeys);
        $select_keys = <<SK;
		sub selectKeys () { 
		 	($sk_list) 
		}
SK
    } else {
        if (@fields) {
            my $sk_list = join(", ", map {qq|"$_"|} @fields);
            $select_keys = <<SK;
		sub selectKeys () { 
			($sk_list)
		}
SK
        } else {
            $select_keys = <<SK;
		sub selectKeys () { () } 
SK
        }
    }
    my $foreign_tables = '';
    my %foreign_tables;
    my %fkfuncs;
    for my $fk (@fkeys) {
        $fk->{FK_COLUMN_NAME} =~ s/"//g;
        my $fn = $fk->{FK_COLUMN_NAME};
        $fn =~ tr/_/-/;
        $fn =~ s/\b(\w)/\u$1/g;
        $fn =~ tr/-//d;
        (my $pt = $fk->{PKTABLE_NAME}  || $fk->{UK_TABLE_NAME}) =~ s/"//g;
        (my $pk = $fk->{PKCOLUMN_NAME} || $fk->{UK_COLUMN_NAME}) =~ s/"//g;
        $fn =~ s/^${pk}_*//i or $fn =~ s/_$pk(?=[^a-z]|$)//i or $fn =~ s/$pk(?=[^a-z]|$)//i;
        $fkfuncs{$fn} = undef;
        $foreign_tables .= <<FKT;
		sub $fn { 
			if(CORE::defined(\$_[0]->$fk->{FK_COLUMN_NAME})) {
				return DBIx::Struct::one_row("$pt", {$pk => \$_[0]->$fk->{FK_COLUMN_NAME}});
			} else { 
				return 
			} 
		}
FKT
        $foreign_tables{$pt} = [$fk->{FK_COLUMN_NAME} => $pk];
    }
    for my $ft (keys %foreign_tables) {
        my $ucft = ucfirst $ft;
        $fkfuncs{"foreignKey$ucft"} = undef;
        $foreign_tables .= <<FKT;
		sub foreignKey$ucft () {("$foreign_tables{$ft}[0]" => "$foreign_tables{$ft}[1]")}
FKT
    }
    my $references_tables = '';
    for my $rk (@refkeys) {
        $rk->{FK_TABLE_NAME} =~ s/"//g;
        my $ft = $rk->{FK_TABLE_NAME};
        (my $fk = $rk->{FK_COLUMN_NAME}) =~ s/"//g;
        (my $pt = $rk->{PKTABLE_NAME} || $rk->{UK_TABLE_NAME}) =~ s/"//g;
        (my $pk = $rk->{PKCOLUMN_NAME} || $rk->{UK_COLUMN_NAME}) =~ s/"//g;
        if ($pk ne $fk) {
            my $fn = $fk;
            $fn =~ s/^${pk}_*//i or $fn =~ s/_$pk(?=[^a-z]|$)//i or $fn =~ s/$pk(?=[^a-z]|$)//i;
            $fn =~ s/$pt//i;
            $ft .= "_$fn" if $fn;
        }
        $ft =~ tr/_/-/;
        $ft =~ s/\b(\w)/\u$1/g;
        $ft =~ tr/-//d;
        $fkfuncs{"ref${ft}s"} = undef;
        $fkfuncs{"ref${ft}"}  = undef;
        $references_tables .= <<RT;
		sub ref${ft}s {
			my (\$self, \@cond) = \@_;
			my \%cond;
			if(\@cond) {
				if(not CORE::ref \$cond[0]) {
					\%cond = \@cond;
				} else {
					\%cond = \%{\$cond[0]};
				}
			}
			\$cond{$fk} = \$self->$pk;
			return DBIx::Struct::all_rows("$rk->{FK_TABLE_NAME}", \\\%cond);
		}
		sub ref${ft} {
			my (\$self, \@cond) = \@_;
			my \%cond;
			if(\@cond) {
				if(not CORE::ref \$cond[0]) {
					\%cond = \@cond;
				} else {
					\%cond = \%{\$cond[0]};
				}
			}
			\$cond{$fk} = \$self->$pk;
			return DBIx::Struct::one_row("$rk->{FK_TABLE_NAME}", \\\%cond);
		}
RT
    }
    my $accessors = <<ACC;
		sub markUpdated {
			\$_[0]->[@{[_row_updates]}]{\$_[1]} = undef if CORE::exists \$fields{\$_[1]};
			\$_[0];
		}
ACC
    for my $k (keys %fields) {
        next if exists $keywords{$k};
        next if $k =~ /^\d/;
        $k =~ s/[^\w\d]/_/g;
        if (!exists $json_fields{$k}) {
            if (!exists($pk_fields{$k}) && (not ref $table)) {
                $accessors .= <<ACC;
		sub $k {
			if(\@_ > 1) {
				\$_[0]->[@{[_row_data]}]->[$fields{$k}] = \$_[1];
				\$_[0]->[@{[_row_updates]}]{"$k"} = undef;
			}
			\$_[0]->[@{[_row_data]}]->[$fields{$k}];
		}
ACC
            } else {
                $accessors .= <<ACC;
		sub $k {
			\$_[0]->[@{[_row_data]}]->[$fields{$k}];
		}
ACC
            }
        } else {
            if (!exists($pk_fields{$k}) && (not ref $table)) {
                $accessors .= <<ACC;
		sub $k {
			if(\@_ > 1) {
				if(not CORE::ref \$_[1]) {
					\$_[0]->[@{[_row_data]}]->[$fields{$k}] = \$_[1];
				} else {
					\$_[0]->[@{[_row_data]}]->[$fields{$k}] = JSON::to_json(\$_[1]);
				}
				\$_[0]->[@{[_row_updates]}]{"$k"} = undef;
			}
			if(not CORE::ref \$_[0]->[@{[_row_data]}]->[$fields{$k}]) {
				\$_[0]->[@{[_row_updates]}] = {} if not \$_[0]->[@{[_row_updates]}];
				\$_[0]->[@{[_row_data]}]->[$fields{$k}] = 
					DBIx::Struct::JSON->factory(\\\$_[0]->[@{[_row_data]}]->[$fields{$k}], \$_[0]->[@{[_row_updates]}], "$k");
			}
			\$_[0]->[@{[_row_data]}]->[$fields{$k}]->accessor;
		}
ACC
            } else {
                $accessors .= <<ACC;
		sub $k {
			if(\$_[0]->[@{[_row_data]}]->[$fields{$k}] and not CORE::ref \$_[0]->[@{[_row_data]}]->[$fields{$k}]) {
				\$_[0]->[@{[_row_data]}]->[$fields{$k}] = JSON::from_json(\$_[0]->[@{[_row_data]}]->[$fields{$k}]);
			}
			\$_[0]->[@{[_row_data]}]->[$fields{$k}];
		}
ACC
            }
        }
    }
    my $package_header = <<PHD;
		package ${ncn};
		use strict;
		use warnings;
		use Carp;
		use SQL::Abstract;
		use JSON;
		use Scalar::Util 'blessed';
		use vars qw(\$AUTOLOAD);
		our \%field_types = ($field_types);
		our \%fields = ($fields);
		our \%json_fields = ($json_fields);
PHD
    if (not ref $table) {
        if (%fkfuncs) {
            my $fkfuncs = join ",", map {qq{"$_" => \\&${ncn}::$_}} keys %fkfuncs;
            $package_header .= <<PHD;
		our \%fkfuncs = ($fkfuncs);
PHD
        } else {
            $package_header .= <<PHD;
		our \%fkfuncs = ();
PHD
        }
        $package_header .= <<PHD;
		sub tableName () {"$table"}
PHD
    } else {
        $package_header .= <<PHD;
		sub tableName () {"\\\$query\\\$$ncn"}
PHD
    }
    my $new              = make_object_new($table, $required, $pk_row_data, $pk_returninig);
    my $filter_timestamp = make_object_filter_timestamp($timestamps);
    my $set              = make_object_set($table);
    my $data             = make_object_data($table);
    my $update           = make_object_update($table, $pk_where, $pk_row_data);
    my $delete           = make_object_delete($table, $pk_where, $pk_row_data);
    my $fetch            = make_object_fetch($table, $pk_where, $pk_row_data);
    my $autoload         = make_object_autoload_find($table, $pk_where, $pk_row_data);
    my $to_json          = make_object_to_json($table, \%field_types, \%fields);
    my $destroy;

    if (not ref $table) {
        $destroy = <<DESTROY;
		sub DESTROY {
			no warnings 'once';
			\$_[0]->update if \$DBIx::Struct::update_on_destroy;
		}
DESTROY
    } else {
        $destroy = '';
    }
    my $eval_code = join "", $package_header, $select_keys, $new,
        $set,    $data,   $fetch,   $autoload,  $to_json,        $filter_timestamp,
        $update, $delete, $destroy, $accessors, $foreign_tables, $references_tables;

    # print $eval_code;
    eval $eval_code;
    error_message {
        result  => 'SQLERR',
        message => "Unknown error: $@",
    } if $@;
    if ($interface) {
        my $ifuncs = _parse_interface $interface;
        no strict 'refs';
        for my $f (keys %$ifuncs) {
            *{"${ncn}::$f"} = $ifuncs->{$f};
        }
    }
    '' =~ /()/;
    return $ncn;
}

my %cache_complex_query;
my $json_canonical = JSON->new->canonical->convert_blessed;

sub _cached_complex_query {
    my $key = $json_canonical->encode(\@_);
    my ($ret, $is_one_column);
    if (exists $cache_complex_query{$key}) {
        ($ret, $is_one_column) = @{$cache_complex_query{$key}};
    } else {
        ($ret, $is_one_column) = _build_complex_query(@_);
        $cache_complex_query{$key} = [($ret, $is_one_column)];
    }
    if (wantarray) {
        return ($ret, $is_one_column);
    } else {
        return $ret;
    }
}

sub _table_name()    {0}
sub _table_alias()   {1}
sub _table_join()    {2}
sub _table_join_on() {3}

my $sql_abstract = SQL::Abstract->new;
my $tblnum;

sub _build_complex_query {
    my ($table, $query_bind, $where) = @_;
    return $table if not ref $table;
    my @from;
    my @columns;
    my @linked_list = (
        ref($table) eq 'ARRAY'
        ? @$table
        : error_message {
            result  => 'SQLERR',
            message => "Unsupported type of query: " . ref($table)
        }
    );
    my ($conditions, $groupby, $having, $limit, $offset, $orderby);
    my $one_column = 0;
    my $distinct   = 0;
    my $count      = 0;
    my $all        = 0;

    for (my $i = 0; $i < @linked_list; ++$i) {
        my $le = $linked_list[$i];
        if ('ARRAY' eq ref $le) {
            my $subfrom = _build_complex_query($le, $query_bind);
            my $ta = "t$tblnum";
            ++$tblnum;
            push @from, ["($subfrom)", $ta];
            next;
        }
        if (substr($le, 0, 1) ne '-') {
            my ($tn, $ta) = split ' ', $le;
            $ta = $tn if not $ta;
            error_message {
                result  => 'SQLERR',
                message => "Unknown table $tn"
                }
                unless _exists_row(make_name($tn));
            push @from, [$tn, $ta];
        } else {
            my $cmd = substr($le, 1);
            if ($cmd eq 'left') {
                $from[-1][_table_join] = 'left join';
            } elsif ($cmd eq 'right') {
                $from[-1][_table_join] = 'right join';
            } elsif ($cmd eq 'join') {
                $from[-1][_table_join] = 'join';
            } elsif ($cmd eq 'on') {
                $from[-1][_table_join_on] = ["on", $linked_list[++$i]];
            } elsif ($cmd eq 'using') {
                $from[-1][_table_join_on] = ["using", $linked_list[++$i]];
            } elsif ($cmd eq 'as') {
                $from[-1][_table_alias] = $linked_list[++$i];
            } elsif ($cmd eq 'where') {
                $conditions = $linked_list[++$i];
            } elsif ($cmd eq 'group_by') {
                $groupby = $linked_list[++$i];
            } elsif ($cmd eq 'order_by') {
                $orderby = $linked_list[++$i];
            } elsif ($cmd eq 'having') {
                $having = $linked_list[++$i];
            } elsif ($cmd eq 'limit') {
                $limit = 0 + $linked_list[++$i];
            } elsif ($cmd eq 'offset') {
                $offset = 0 + $linked_list[++$i];
            } elsif ($cmd eq 'columns' || $cmd eq 'column' || $cmd eq 'distinct' || $cmd eq 'count' || $cmd eq 'all') {
                if ($cmd eq 'all') {
                    $all = 1;
                }
                if ($cmd eq 'distinct') {
                    $distinct = 1;
                }
                if ($cmd eq 'count') {
                    $count = 1;
                }
                if ($i + 1 < @linked_list && substr($linked_list[$i + 1], 0, 1) ne '-') {
                    my $cols = $linked_list[++$i];
                    if ($cols && $cols !~ /^\d|^true$/) {
                        if ('ARRAY' eq ref($cols)) {
                            push @columns, @$cols;
                        } else {
                            push @columns, $cols;
                        }
                    } elsif (($cols =~ /^\d+$/ && $cols == 0) || $cols eq '') {
                        $distinct = 0 if $cmd eq 'distinct';
                    }
                }
                if ($cmd eq 'column') {
                    ++$one_column;
                } else {
                    $one_column += 2;
                }

            } else {
                error_message {
                    result  => 'SQLERR',
                    message => "Unknown directive $le"
                };
            }
        }
    }
    error_message {
        result  => 'SQLERR',
        message => "No table to build query on"
    } if !@from;
    for (my $idx = 1; $idx < @from; ++$idx) {
        next if $from[$idx][_table_join_on] or not $from[$idx - 1][_table_join];
        next if substr($from[$idx][_table_name], 0, 1) eq "(";
        my $cta  = $from[$idx][_table_alias];
        my $cto  = make_name($from[$idx][_table_name]);
        my $ucct = ucfirst $from[$idx][_table_name];
        my @join;
        for (my $i = $idx - 1; $i >= 0; --$i) {
            next if not $from[$i][_table_join];
            my $ptn = $from[$i][_table_name];
            next if substr($ptn, 0, 1) eq "(";
            my $ucfptn = ucfirst $ptn;
            if ($cto->can("foreignKey$ucfptn")) {
                my $fkfn = "foreignKey$ucfptn";
                my ($ctf, $ptk) = $cto->$fkfn;
                push @join, "$cta.$ctf = " . $from[$i][_table_alias] . ".$ptk";
            } else {
                my $ptno = make_name($ptn);
                if ($ptno->can("foreignKey$ucct")) {
                    my $fkfn = "foreignKey$ucct";
                    my ($ptf, $ctk) = $ptno->$fkfn;
                    push @join, "$cta.$ctk = " . $from[$i][_table_alias] . ".$ptf";
                }
            }
        }
        $from[$idx][_table_join_on] = ["on", join(" and ", @join)];
    }
    my $from = '';
    @columns = ('*') if not @columns;
    @columns = map {('SCALAR' eq ref) ? DBIx::Struct::connect->dbh->quote_identifier($$_) : $_} @columns;
    my $joined = 0;
    for (my $idx = 0; $idx < @from; ++$idx) {
        if (not $joined) {
            $from .= " " . $from[$idx][_table_name];
            $from .= " " . $from[$idx][_table_alias] if $from[$idx][_table_alias] ne $from[$idx][_table_name];
        }
        if ($from[$idx][_table_join]) {
            my $nt = $from[$idx + 1];
            $from .= " " . $from[$idx][_table_join];
            $from .= " " . $nt->[_table_name];
            $from .= " " . $nt->[_table_alias] if $nt->[_table_alias] ne $nt->[_table_name];
            my $using_on = $nt->[_table_join_on][0];
            if ($using_on eq 'on' and ref $nt->[_table_join_on][1]) {
                my ($on_where, @on_bind) = $sql_abstract->where($nt->[_table_join_on][1]);
                $on_where =~ s/WHERE //;
                push @$query_bind, @on_bind;
                $from .= " $using_on(" . $on_where . ")";
            } else {
                $from .= " $using_on(" . $nt->[_table_join_on][1] . ")";
            }
            $joined = 1;
        } else {
            $from .= "," if $idx != $#from;
            $joined = 0;
        }
    }
    my $what = join(", ", @columns);
    if ($count) {
        $one_column = 1;
        if ($distinct) {
            $what = $from[0][_table_alias] . ".*" if $what eq '*';
            $what = "count(distinct $what)";
        } elsif ($all) {
            $what = $from[0][_table_alias] . ".*" if $what eq '*';
            $what = "count(all $what)";
        } else {
            $what = "count(*)";
        }
    } else {
        if ($distinct) {
            $what = "distinct $what";
        }
    }
    my $ret = "select $what from" . $from;
    if (not defined $where) {
        my $sql_grp     = _parse_groupby($groupby);
        my $having_bind = [];
        if ($sql_grp && defined $having) {
            my $sql_having;
            ($sql_having, $having_bind) = _parse_having($having);
            $sql_grp .= " $sql_having";
        }
        if ($conditions) {
            my @where_bind;
            ($where, @where_bind) = $sql_abstract->where($conditions);
            push @$query_bind, @where_bind;
        } else {
            $where = '';
        }
        if (defined $sql_grp) {
            $where .= " $sql_grp";
            push @$query_bind, @$having_bind;
        }
        $where .= " limit $limit"   if defined $limit;
        $where .= " offset $offset" if $offset;
    }
    $ret .= " $where" if $where;
    if (wantarray) {
        return ($ret, $one_column == 1);
    } else {
        return $ret;
    }
}

sub _parse_groupby {
    my $groupby = $_[0];
    my $sql_grp;
    if (defined $groupby) {
        $sql_grp = "GROUP BY ";
        my @groupby = map {/^\d+$/ ? $_ : /^[a-z][\w ]*$/i ? "\"$_\"" : "$_"} (ref($groupby) ? @$groupby : ($groupby));
        $sql_grp .= join(", ", @groupby);
    }
    $sql_grp;
}

sub _parse_having {
    my $having = $_[0];
    my $sql_having;
    my @having_bind;
    if (defined $having) {
        ($sql_having, @having_bind) = $sql_abstract->where($having);
        $sql_having =~ s/\bWHERE\b/HAVING/;
    }
    ($sql_having, \@having_bind);
}

sub execute {
    my ($groupby, $having, $up_conditions, $up_order, $up_limit, $up_offset, $up_interface, $sql, $dry_run);
    my $distinct = '';
    for (my $i = 2; $i < @_; ++$i) {
        next unless defined $_[$i] and not ref $_[$i];
        if ($_[$i] eq '-group_by') {
            (undef, $groupby) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-distinct') {
            $distinct = ' distinct';
            splice @_, $i, 1;
            --$i;
        } elsif ($_[$i] eq '-having') {
            (undef, $having) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-order_by') {
            (undef, $up_order) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-where') {
            (undef, $up_conditions) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-limit') {
            (undef, $up_limit) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-interface') {
            (undef, $up_interface) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-offset') {
            (undef, $up_offset) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-sql') {
            (undef, $sql) = splice @_, $i, 2;
            --$i;
        } elsif ($_[$i] eq '-dry_run') {
            (undef, $dry_run) = splice @_, $i, 2;
            --$i;
        } elsif (substr($_[$i], 0, 1) eq '-') {
            error_message {
                result  => 'SQLERR',
                message => "Unknown directive $_[$i]"
            };
        }
    }
    $tblnum = 1;
    my $sql_grp     = _parse_groupby($groupby);
    my $having_bind = [];
    if ($sql_grp && defined $having) {
        my $sql_having;
        ($sql_having, $having_bind) = _parse_having($having);
        $sql_grp .= " $sql_having";
    }
    my ($code, $table, $conditions, $order, $limit, $offset) = @_;
    my $have_conditions = @_ > 2;
    $conditions //= $up_conditions;
    $order      //= $up_order;
    $limit      //= $up_limit;
    $offset     //= $up_offset;
    my $where;
    my $need_where = 0;
    my @where_bind;
    my $simple_table = (not ref $table and index($table, " ") == -1);
    my $ncn;

    if ($simple_table) {
        $ncn = make_name($table);
        setup_row($table);
        if ($have_conditions and not ref $conditions) {
            my $id = ($ncn->selectKeys())[0]
                or error_message {
                result  => 'SQLERR',
                message => "unknown primary key",
                query   => "select * from $table",
                };
            if (defined $conditions) {
                $where      = "where $id = ?";
                @where_bind = ($conditions);
            } else {
                $where = "where $id is null";
            }
        } else {
            $need_where = 1;
        }
    } else {
        $need_where = 1;
    }
    if ($need_where) {
        ($where, @where_bind) = $sql_abstract->where($conditions);
    }
    if (defined $sql_grp) {
        $where .= " $sql_grp";
        push @where_bind, @$having_bind;
    }
    if ($order) {
        my ($order_sql, @order_bind) = $sql_abstract->where(undef, $order);
        $where .= " $order_sql";
        push @where_bind, @order_bind;
    }
    if (defined($limit)) {
        $limit += 0;
        $where .= " limit $limit";
    }
    if (defined($offset)) {
        $offset += 0;
        $where .= " offset $offset" if $offset;
    }
    my $query;
    my @query_bind;
    my $one_column = 0;
    if ($simple_table) {
        $query = qq{select$distinct * from $table $where};
    } else {
        if (not ref $table) {
            $query = "$table $where";
        } else {
            ($query, $one_column) = _cached_complex_query($table, \@query_bind, $where);
        }
        $ncn = make_name($query);
    }
    if ($sql) {
        if ('CODE' eq ref $sql) {
            $sql->($query, \@where_bind);
        } elsif ('SCALAR' eq ref $sql) {
            $$sql = $query;
        }
    }
    return if $dry_run;
    '' =~ /()/;
    my $sth;
    return DBIx::Struct::connect->run(
        sub {
            $sth = $_->prepare($query)
                or error_message {
                result  => 'SQLERR',
                message => $_->errstr,
                query   => $query,
                };
            $sth->execute(@query_bind, @where_bind)
                or error_message {
                result     => 'SQLERR',
                message    => $_->errstr,
                query      => $query,
                where_bind => Dumper(\@where_bind),
                query_bind => Dumper(\@query_bind),
                conditions => Dumper($conditions),
                };
            setup_row($sth, $ncn, $up_interface);
            return $code->($sth, $ncn, $one_column);
        }
    );
}

sub one_row {
    return execute(
        sub {
            my ($sth, $ncn, $one_column) = @_;
            my $data = $sth->fetchrow_arrayref;
            $sth->finish;
            return if not $data;
            if ($one_column) {
#<<<
# json type is not working yet here					
#				no strict 'refs';
#				my @f = %{$ncn . "::field_types"};
#				if ($f[1] eq 'json') {
#					return (defined($data->[0]) ? from_json($data->[0]) : undef);
#				} else {
					return $data->[0];
#>>>				}
            }
            return $ncn->new([@$data]);
        },
        @_
    );
}

sub all_rows {
    my $mapfunc;
    for (my $i = 0; $i < @_; ++$i) {
        if (ref($_[$i]) eq 'CODE') {
            $mapfunc = splice @_, $i, 1;
            last;
        }
    }
    return execute(
        sub {
            my ($sth, $ncn, $one_column) = @_;
            my @rows;
            my $row;
            if ($mapfunc) {
                while ($row = $sth->fetch) {
                    local $_ = $ncn->new([@$row]);
                    push @rows, $mapfunc->();
                }
            } else {
                if ($one_column) {
#<<<
# json type is not working yet here					
#					no strict 'refs';
#					my @f = %{$ncn . "::field_types"};
#					if ($f[1] eq 'json') {
#						push @rows, (defined($row->[0]) ? from_json($row->[0]) : undef) while ($row = $sth->fetch);
#					} else {
						push @rows, $row->[0] while ($row = $sth->fetch);
#					}
#>>>
                } else {
                    push @rows, $ncn->new([@$row]) while ($row = $sth->fetch);
                }
            }
            return \@rows;
        },
        @_
    );
}

sub for_rows {
    my $itemfunc;
    for (my $i = 0; $i < @_; ++$i) {
        if (ref($_[$i]) eq 'CODE') {
            $itemfunc = splice @_, $i, 1;
            last;
        }
    }
    error_message {
        result     => 'SQLERR',
        message    => "Item function is required",
        query      => "(not parsed)",
        where_bind => "(not parsed)",
        query_bind => "(not parsed)",
        conditions => "(not parsed)",
        }
        if not $itemfunc;
    return execute(
        sub {
            my ($sth, $ncn) = @_;
            my $rows = 0;
            my $row;
            my $dbh = $_;
            local $dbh->{mysql_use_result} = 1 if $connector_driver eq 'mysql';
            local $_;
            while ($row = $sth->fetch) {
                ++$rows;
                $_ = $ncn->new([@$row]);
                last if not $itemfunc->();
            }
            return $rows;
        },
        @_
    );
}

sub new_row {
    my ($table, @data) = @_;
    my $simple_table = (index($table, " ") == -1);
    error_message {
        result  => 'SQLERR',
        message => "insert row can't work for queries"
        }
        unless $simple_table;
    my $ncn = setup_row($table);
    return $ncn->new(@data);
}

1;
