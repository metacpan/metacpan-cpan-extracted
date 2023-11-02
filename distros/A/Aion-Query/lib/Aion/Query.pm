package Aion::Query;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.2";

use Aion::Format qw//;
use Aion::Format::Json qw//;
use B qw//;
use DBI qw//;
use Scalar::Util qw//;
use List::Util qw//;
use Aion::Format qw//;
use Aion::Format::Json qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Query::{$_} eq "GLOB"
		&& *{$Aion::Query::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Query::;

use config {
	DSN  => undef,
    DRV  => 'mysql',
    BASE => 'BASE',
    HOST => undef,
    PORT => undef,
    SOCK => undef,
    USER => 'root',
    PASS => 123,
    CONN => undef,
    DEBUG => 0,
	MAX_QUERY_ERROR => 1000,
	BQ => 1,
};

# Формирует DSN на основе конфига
our $DEFAULT_DSN;
sub default_dsn() {
	$DEFAULT_DSN //= do {
		if(defined DSN) {DSN}
		elsif(DRV =~ /mysql|mariadb/i) {
			my $sock = SOCK;
			$sock //= "/var/run/mysqld/mysqld.sock" if !defined HOST;

			"DBI:${\ DRV}:database=${\ BASE};${\
				(defined(HOST)?
					'host=' . HOST
					. (defined(PORT)? ':' . PORT: ())
					. ';': ()
				)
			}${\ (defined($sock)? 'mysql_socket=' . $sock: ()) }"
		}
		elsif(DRV =~ /sqlite/i) { "DBI:${\ DRV}:dbname=${\ BASE}" }
		else { die "Using DSN! DRV: ${\ DRV} is'nt supported." }
	}
}

my $CONN;
sub default_connect_options() {
    return default_dsn, USER, PASS, $CONN //= CONN // do {
		if(DRV =~ /mysql|mariadb/i) {[
			"SET NAMES utf8",
			"SET sql_mode='NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'",
   		]}
		else {[]}
	};
}

# Коннект к базе и id коннекта
sub base_connect {
	my ($dsn, $user, $password, $conn) = @_;
	my $base = DBI->connect($dsn, $user, $password, {
		RaiseError => 1,
		PrintError => 0,
		$dsn =~ /^DBI:mysql/i ? (mysql_enable_utf8 => 1): (),
	}) or die "Connect to db failed";

	$base->do($_) for @$conn;
	return $base unless wantarray;
	my ($base_connection_id) = $dsn =~ /^DBI:(mysql|mariadb)/i
		? $base->selectrow_array("SELECT connection_id()")
		: -1;
	return $base, $base_connection_id;
}

# Проверка коннекта и переконнект
sub connect_respavn {
	my ($base) = @_;
	$base->disconnect, undef $base if $base and !$base->ping;
	($_[0], $_[1]) = base_connect(default_connect_options) if !$base;
	return;
}

# Рестарт коннекта
sub connect_restart {
	my ($base, $base_connection_id) = @_;
	$base->disconnect if $base;
	($_[0], $_[1]) = base_connect(default_connect_options());
	return;
}


# Инициализация БД
our $base; our $base_connection_id;

END {
	$base->disconnect if $base;
}

# возможно выполняется запрос - нужно его убить
sub query_stop {
	return if $base_connection_id == -1;
	# вспомогательное подключение
	my $signal = base_connect(default_connect_options());
	$signal->do("KILL HARD " . ($base_connection_id + 0));
	$signal->disconnect;
	return;
}

# Запросы к базе

our @DEBUG;
sub sql_debug(@) {
	my ($fn, $query) = @_;
	my $msg = "$fn: " . (ref $query? np($query): $query);
	push @DEBUG, $msg;
	print STDERR $msg, "\n" if DEBUG;
}

# sub debug_html {
# 	join "", map { ("<p class='debug'>", to_html($_), "</p>\n") } @DEBUG;
# }

# sub debug_text {
# 	return "" if !@DEBUG;
# 	join "", map { "$_\n\n" } @DEBUG, "";
# }

# sub debug_array {
# 	return if !@DEBUG;
# 	$_[0]->{SQL_DEBUG} = \@DEBUG;
# 	return;
# }


sub LAST_INSERT_ID() {
	$base->last_insert_id
}

# Преобразует в строку
sub _to_str($) {
	local($_) = @_;
	s/[\\']/\\$&/g;
	s/^(.*)\z/'$1'/s;
	$_
}

# Преобразует в бинарную строку принятую в MYSQL
sub _to_hex_str($) {
	my ($s) = @_;
	no utf8;
	use bytes;
	$s =~ s/./sprintf "%02X", ord $&/gaes;
	"X'$s'"
}

# Идея перекодирования символов:
# В базе используется cp1251, поэтому символы, которые в неё не входят, нужно перевести в последовательности.
# Вид последовательности: °ЧИСЛО_В_254-ричной системе; \x7F
# Знак ° выбран потому, что он выше 127, соответственно строка из базы данных, содержащая такую последовательность,
# будет с флагом utf8, что необходимо для обратного перекодирования.
sub _recode_cp1251 {
	my ($s) = @_;
	return $s unless BQ;
	$s =~ s/°|[^\Q$Aion::Format::CIF\E]/"°${\ to_radix(ord $&, 254) }\x7F"/ge;
	$s
}

sub quote(;$);
sub quote(;$) {
	my $k = @_ == 0? $_: $_[0];
	my $ref;

	!defined($k)? "NULL":
	ref $k eq "ARRAY" && ref $k->[0] eq "ARRAY"?
		join(", ", map { join "", "(", join(", ", map quote, @$_), ")" } @$k):
	ref $k eq "ARRAY"? join("", join(", ", map quote, @$k)):
	ref $k eq "HASH"?
		join(", ", map { join "", $_, " = ", quote $k->{$_} } sort keys %$k):
	ref $k eq "REF" && ref $$k eq "ARRAY"?
		join(" ", List::Util::pairmap { join " ", "WHEN", quote $a, "THEN", quote $b } @$$k):
	ref $k eq "SCALAR"? $$k:
	Scalar::Util::blessed $k ? $k:
	ref $k ne ""? die "Something strange: `$k`":
	$k =~ /^-?(?:0|[1-9]\d*)(\.\d+)?\z/a
		&& ($ref = ref B::svref_2object(@_ == 0? \$_: \$_[0])
		) ne "B::PV"? (
			!$1 && $ref eq "B::NV"? "$k.0": $k
		):
	!utf8::is_utf8($k)? (
		$k =~ /[^\t\n -~]/a ? _to_hex_str($k): #$base->quote($k, DBI::SQL_BINARY):
			_to_str($k)
	):
	_to_str(_recode_cp1251($k))
}

sub query_prepare (@) {
	my ($query, %param) = @_;

	$query =~ s!^[ \t]*(\w+)>>(.*\n?)!$param{$1}? $2: ""!mge;
	#$query =~ s!^[ \t]*(\w+)\*>(.*\n?)!$param{$1}? join("", map {  } @{$param{$1}}): ""!mge;
	$query =~ s!:([a-z_]\w*)! exists $param{$1}? quote($param{$1}): die "The :$1 parameter was not passed."!ige;

	$query
}

sub query_do($;$) {
	my ($query, $columns) = @_;
	sql_debug query => $query;
	connect_respavn($base, $base_connection_id);

	my $res = eval {
		if($query =~ /^\s*(select|show|desc(ribe)?)\b/in) {

			my $r = @_>1? do {
				my $sth = $base->prepare($query);
				$sth->execute;
				$_[1] = [@{$sth->{NAME}}];
				my $res = $sth->fetchall_arrayref({});
				$sth->finish;
				$res
			}: $base->selectall_arrayref($query, { Slice => {} });

			if(defined $r and BQ) {
				for my $row (@$r) {
					for my $k (keys %$row) {
						$row->{$k} =~ s/°([^\x7F]{1,7})\x7F/chr from_radix($1, 254)/ge if utf8::is_utf8($row->{$k});
					}
				}
			}
			$r
		} else {
			0 + $base->do($query)
		}
	};
	die +(length($query)>MAX_QUERY_ERROR? substr($query, 0, MAX_QUERY_ERROR) . " ...": $query) . "\n\n$@" if $@;

	$res
}

sub query_ref(@) {
	my ($query, %kw) = @_;
	my $map = delete $kw{MAP};
	$query = query_prepare($query, %kw) if @_>1;
	my $res = query_do($query);
	if($map && ref $res eq "ARRAY") {
		eval "require $map" or die unless UNIVERSAL::can($map, "new");
		[map { $map->new(%$_) } @$res]
	} else {
		$res
	}
}

sub query(@) {
	my $ref = query_ref(@_);
	wantarray && ref $ref? @$ref: $ref;
}

sub query_sth(@) {
	my ($query, %kw) = @_;
	$query = query_prepare($query, %kw) if @_>1;
	my $sth = $base->prepare($query);
	$sth->execute;
	$sth
}

# Для слайса
#
#	query_slice word => "id", "SELECT word, id FROM word WHERE word in (1,2,3)" 	-> 	{ 1 => 10, 2 => 20 }
#
# 	query_slice word => {}, "SELECT word, id FROM word WHERE word in (1,2,3)" 		-> 	{ 1 => {id => 10, word => 1} }
#
#	query_slice word => ["id"], "SELECT word, id FROM word WHERE word in (1,2,3)" 	-> 	{ 1 => [10, 20], 2 => [30] }
#
# 	query_slice word => [], "SELECT word, id FROM word WHERE word in (1,2,3)" 		-> 	{ 1 => [{id => 10, word => 1}, {id => 20, word => 2}] }
#
# 	query_slice word => [[]], "SELECT word, id FROM word WHERE word in (1,2,3)" 		-> [ [{id => 10, word => 1}, {id => 20, word => 2}], ... ]
#
# 	TODO: query_slice [] => word, "SELECT word, id FROM word WHERE word in (1,2,3)" 		-> 	[{id => 10, word => 1}, {id => 20, word => 2}]
#
#   TODO: [ "id", "name", "jinni" ] -> [{ id=>1, items => [{ name => "hi!", items => [{ jinni=>2, items => [{...}] }] }] }]
#
sub query_slice(@);
sub query_slice(@) {
	my ($key, $val, @args) = @_;

	my $is_array = ref $val eq "ARRAY" && @$val && ref $val->[0] eq "ARRAY";

	return $is_array? [ query_slice @_ ]: +{ query_slice @_ } if !wantarray;

	my $rows = query_ref(@args);

	if($is_array) {
		my %x; my @x;
		for(@$rows) {
			my $k = $_->{$key};
			push @x, $x{$k} = [] if !exists $x{$k};
			push @{$x{$k}}, $_;
		}
		@x
	}
	elsif(ref $val eq "HASH") {
		map { $_->{$key} => $_ } @$rows
	}
	elsif(ref $val eq "ARRAY") {
		if(@$val) {
			my $col = $val->[0];
			my %x;
			push @{$x{$_->{$key}}}, $_->{$col} for @$rows;
			%x
		} else {
			my %x;
			push @{$x{$_->{$key}}}, $_ for @$rows;
			%x
		}
	}
	else {
		map { $_->{$key} => $_->{$val} } @$rows
	}
}

# Выбрать один колумн
#
#   query_col "SELECT id FROM word WHERE word in (1,2,3)" 	-> 	[1,2,3]
#
sub query_col(@);
sub query_col(@) {
	return [query_col @_] if !wantarray;

	my $rows = query_ref(@_);
	die "Only one column is acceptable!" if @$rows and 1 != keys %{$rows->[0]};

	map { my ($k, $v) = %$_; $v } @$rows
}

# Выбрать строку
#
#   query_row_ref "SELECT id, word FROM word WHERE word = 1" 	-> 	{id=>1, word=>"серебро"}
#
sub query_row_ref(@) {
	my $rows = query_ref(@_);
	die "A few lines!" if @$rows>1;
	$rows->[0]
}

# Выбрать строку
#
#   ($id, $word) = query_row_ref "SELECT id, word FROM word WHERE word = 1"
#
sub query_row(@) {
	return query_row_ref(@_) unless wantarray;
	my $sql = query_prepare(@_);
	my $rows  = query_do($sql, my $columns);
	die "A few lines!" if @$rows > 1;
	my $row = $rows->[0];
	map $row->{$_}, @$columns
}

# Выбрать значение
#
#   query_scalar "SELECT word FROM word WHERE id = 1" 	-> 	"золото"
#
sub query_scalar(@) {
	my $rows = query_ref(@_);
	die "A few lines!" if @$rows>1;
	die "Only one column is acceptable! " . keys %{$rows->[0]} if @$rows and 1 != keys %{$rows->[0]};
	my ($k, $v) = %{$rows->[0]};
	$v
}

# Создаёт части sql-запроса для сортировки по условию, а не лимиту
#
# ("concat(size,',',likes)", "(size < 10 OR size = 10 AND likes >= 12)", ["size", "likes"]) = make_query_for_order "size desc, likes", "10,12"
#
# ("concat(size,',',likes)", 1) = make_query_for_order "size desc, likes", ""
#
sub make_query_for_order(@) {
	my ($order, $next) = @_;

	my @orders = split /\s*,\s*/, $order;
	my @order_direct;
	my @order_sel = map { my $x=$_; push @order_direct, $x=~s/\s+(asc|desc)\s*$//ie ? lc $1: "asc"; $x } @orders;

	my $select = @order_sel==1? $order_sel[0]: 
		_check_drv($base, "mysql|mariadb")? 
			join("", "concat(", join(",',',", @order_sel), ")"):
			join " || ',' || ", @order_sel
	;

	return $select, 1 if $next eq "";

	my @next = split /,/, $next;
	$next[$#orders] //= "";
	@next = map quote($_), @next;
	my @op = map { /^a/ ? ">": "<" } @order_direct;

	# id -> id >= next[0]
	# id, update -> id > next[0] OR id = next[0] and
	my @whr;
	for(my $i=0; $i<@orders; $i++) {
		my @opr;
		for(my $j=0; $j<=$i; $j++) {
			#my $eq = $j == $#orders? "=": "";
			if($j != $i) {
				push @opr, "$order_sel[$j] = $next[$j]";
			} elsif($j != $#orders) {
				push @opr, "$order_sel[$j] $op[$j] $next[$j]";
			} else {
				push @opr, "$order_sel[$j] $op[$j]= $next[$j]";
			}
		}
		push @whr, join " AND ", @opr;
	}
	my $where = join "\nOR ", map "$_", @whr;

	return $select, "($where)", \@order_sel;
}

# Устанавливает или возвращает ключ из таблицы settings
sub settings($;$) {
	my ($id, $value) = @_;
	if(@_ == 1) {
		my $v = query_scalar("SELECT value FROM settings WHERE id=:id", id => $id);
		return defined($v)? Aion::Format::Json::from_json($v): $v;
	}

	return remove("settings" => $id) if !defined $value;

	store('settings',
		id => $id,
		value => Aion::Format::Json::to_json($value),
	);
}

# возвращает запись по её pk
sub load_by_id(@) {
	my ($tab, $pk, $fields, @options) = @_;
	$fields //= "*";
	query_row("SELECT $fields FROM $tab WHERE id=:id LIMIT 2", @options, id=>$pk)
}

# Проверяет драйвер БД на имена
sub _check_drv {
	my ($dbh, $drv) = @_;
	$dbh->{Driver}{Name} =~ /^($drv)/ain
}

# Добавляет запись и возвращает её id
sub insert(@) {
	my ($tab, %x) = @_;
	if(_check_drv($base, "mysql|mariadb")) {
		query "INSERT INTO $tab SET :set", set => \%x;
	} else {
		stores($tab, [\%x], insert => 1);
	}
	LAST_INSERT_ID()
}

# Обновляет запись по её id
#
#	update "tab" => 123, word => 123 						-> 6
#
sub update(@) {
	my ($tab, $id, %x) = @_;
	die "Row $tab.id=$id is not!" if !query "UPDATE $tab SET :set WHERE id=:id", id=>$id, set => \%x;
	$id
}

# Удаляет запись по её id
#
#	remove "tab" => 123 		-> 123
#
sub remove(@) {
	my ($tab, $id) = @_;
	die "Row $tab.id=$id does not exist!" if !query "DELETE FROM $tab WHERE id=:id", id=>$id;
	$id
}

# Возвращает ключ по другим полям
#
#	query_id "tab", word => 123 						-> 6
#
sub query_id(@) {
	my $tab = shift; my %row = @_;

	my $pk = delete($row{'-pk'}) // "id";
	my $fields = ref $pk? join(", ", @$pk): $pk;

	my $where = join " AND ", map { my $v = $row{$_}; defined($v)? "$_ = ${\ quote($v) }": "$_ is NULL" } sort keys %row;
	my $query = "SELECT $fields FROM $tab WHERE $where LIMIT 2";

	my $v = query_row($query);

	ref $pk? $v: $v->{$pk}
}

# UPSERT: сохраняет данные (update или insert)
#
#	stores "tab", [{word=>1}, {word=>2}];
#
sub stores(@);
sub stores(@) {
	my ($tab, $rows, %opt) = @_;

	my ($ignore, $insert) = delete @opt{qw/ignore insert/};
	die "Keys ${\ join('', )}" if keys %opt;



	my @keys = sort keys %{+{map %$_, @$rows}};
	die "No fields in bean $tab!" if !@keys;

	my $fields = join ", ", @keys;

	my $values = join ",\n", map { my $row = $_; join "", "(", quote([map $row->{$_}, @keys]), ")" } @$rows;

	if($insert) {
		my $query = "INSERT INTO $tab ($fields) VALUES $values";
		query_do($query);
	}
	elsif(_check_drv($base, "mysql|mariadb")) {
		if($ignore) {
			my $query = "INSERT IGNORE INTO $tab ($fields) VALUES $values";
			query_do($query);
		}
		else {
			my $fupdate = join ", ", map "$_ = values($_)", @keys;
			my $query = "INSERT INTO $tab ($fields) VALUES $values ON DUPLICATE KEY UPDATE $fupdate";
			query_do($query);
		}
	}
	elsif(_check_drv($base, 'Pg|sqlite')) {
		if($ignore) {
			my $query = "INSERT INTO $tab ($fields) VALUES $values ON CONFLICT DO NOTHING";
			query_do($query);
		} else {
			my $fupdate = join ", ", map "$_ = excluded.$_", @keys;
			my $query = "INSERT INTO $tab ($fields) VALUES $values ON CONFLICT DO UPDATE SET $fupdate";
			query_do($query);
		}
	}
	else {
		my $count = 0;
		if($ignore) {
			$count += eval { stores $tab, [$_], insert => 1 } for @$rows;
		} else {
			$count += stores $tab, [$_] for @$rows;
		}
		$count
	}
}

# сохраняет данные (update или insert)
#
#	store "tab", word=>123;
#
sub store (@) {
	my $tab = shift;
	stores $tab, [+{@_}];
}

# Сверхмощная функция: возвращает pk, а если его нет - создаёт или обновляет запись и всё равно возвращает
sub touch(@) {
	my $sub;
	$sub = pop @_ if ref $_[$#_] eq "CODE";

	my $pk = query_id @_;
	return $pk if defined $pk;

	store @_, $sub? $sub->(): ();

	query_id @_
}

# возвращает переменную, на которой нужно установить commit, иначе происходит откат
sub START_TRANSACTION () {
	package Aion::Query::Transaction {
		sub commit {
			my ($self) = @_;
			$Aion::Query::base->commit;
			$self->{commit} = 1;
			return $self;
		}

		sub DESTROY {
			my ($self) = @_;
			$Aion::Query::base->rollback unless $self->{commit};
		}
	}

	$Aion::Query::base->begin_work;

	bless {}, 'Aion::Query::Transaction';
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Query - functional interface for accessing database mysql and mariadb

=head1 VERSION

0.0.2

=head1 SYNOPSIS

File .config.pm:

	package config;
	
	config_module Aion::Query => {
	    DRV  => "SQLite",
	    BASE => "test-base.sqlite",
	    BQ => 0,
	};
	
	1;



	use Aion::Query;
	
	query "CREATE TABLE author (
	    id INTEGER PRIMARY KEY AUTOINCREMENT,
	    name TEXT NOT NULL UNIQUE
	)";
	
	insert "author", name => "Pushkin A.S." # -> 1
	
	touch "author", name => "Pushkin A."    # -> 2
	touch "author", name => "Pushkin A.S."  # -> 1
	touch "author", name => "Pushkin A."    # -> 2
	
	query_scalar "SELECT count(*) FROM author"  # -> 2
	
	my @rows = query "SELECT *
	FROM author
	WHERE 1
	    if_name>> AND name like :name
	",
	    if_name => Aion::Query::BQ == 0,
	    name => "P%",
	;
	
	\@rows # --> [{id => 1, name => "Pushkin A.S."}, {id => 2, name => "Pushkin A."}]
	
	$Aion::Query::DEBUG[1]  # => query: INSERT INTO author (name) VALUES ('Pushkin A.S.')

=head1 DESCRIPTION

When constructing queries, many disparate conditions are used, usually separated by different methods.

C<Aion::Query> uses a different approach, which allows you to construct an SQL query in a query using a simple template engine.

The second problem is placing unicode characters into single-byte encodings, which reduces the size of the database. So far it has been solved only for the B<cp1251> encoding. It is controlled by the parameter C<BQ = 1>.

=head1 SUBROUTINES

=head2 query ($query, %params)

It provide SQL (DCL, DDL, DQL and DML) queries to DBMS with quoting params and .

	query "SELECT * FROM author WHERE name=:name", name => 'Pushkin A.S.' # --> [{id=>1, name=>"Pushkin A.S."}]

=head2 LAST_INSERT_ID ()

Returns last insert id.

	query "INSERT INTO author (name) VALUES (:name)", name => "Alice"  # -> 1
	#LAST_INSERT_ID  # -> 3

=head2 quote ($scalar)

Quoted scalar for SQL-query.

	quote undef     # => NULL
	quote "abc"     # => 'abc'
	quote 123       # => 123
	quote "123"     # => '123'
	quote(0+"123")  # => 123
	quote(123 . "") # => '123'
	quote 123.0       # => 123.0
	quote(0.0+"126")  # => 126
	quote("127"+0.0)  # => 127
	quote("128"-0.0)  # => 128
	quote("129"+1.e-100)  # => 129.0
	
	# use for insert formula: SELECT :x as summ ⇒ x => \"xyz + 123"
	quote \"without quote"  # => without quote
	
	# use in: WHERE id in (:x)
	quote [1,2,"5"] # => 1, 2, '5'
	
	# use in: INSERT INTO author VALUES :x
	quote [[1, 2], [3, "4"]]  # => (1, 2), (3, '4')
	
	# use in multiupdate: UPDATE author SET name=CASE id :x ELSE null END
	quote \[2=>'Pushkin A.', 1=>'Pushkin A.S.']  # => WHEN 2 THEN 'Pushkin A.' WHEN 1 THEN 'Pushkin A.S.'
	
	# use for UPDATE SET :x or INSERT SET :x
	quote {name => 'A.S.', id => 12}   # => id = 12, name = 'A.S.'
	
	[map quote, -6, "-6", 1.5, "1.5"] # --> [-6, "'-6'", 1.5, "'1.5'"]
	

=head2 query_prepare ($query, %param)

Replace the parameters in C<$query>. Parameters quotes by the C<quote>.

	query_prepare "INSERT author SET name = :name", name => "Alice"  # => INSERT author SET name = 'Alice'

=head2 query_do ($query)

Execution query and returns it result.

	query_do "SELECT count(*) as n FROM author"  # --> [{n=>3}]
	query_do "SELECT id FROM author WHERE id=2"  # --> [{id=>2}]

=head2 query_ref ($query, %kw)

As C<query>, but always returns a reference.

	my @res = query_ref "SELECT id FROM author WHERE id=:id", id => 2;
	\@res  # --> [[ {id=>2} ]]

=head2 query_sth ($query, %kw)

As C<query>, but returns C<$sth>.

	my $sth = query_sth "SELECT * FROM author";
	my @rows;
	while(my $row = $sth->fetchrow_arrayref) {
	    push @rows, $row;
	}
	$sth->finish;
	
	0+@rows  # -> 3

=head2 query_slice ($key, $val, @args)

As query, plus converts the result into the desired data structure.

	my %author = query_slice name => "id", "SELECT id, name FROM author";
	\%author  # --> {"Pushkin A.S." => 1, "Pushkin A." => 2, "Alice" => 3}

=head2 query_col ($query, %params)

Returns one column.

	query_col "SELECT name FROM author ORDER BY name" # --> ["Alice", "Pushkin A.", "Pushkin A.S."]
	
	eval {query_col "SELECT id, name FROM author"}; $@  # ~> Only one column is acceptable!

=head2 query_row ($query, %params)

Returns one row.

	query_row "SELECT name FROM author WHERE id=2" # --> {name => "Pushkin A."}
	
	my ($id, $name) = query_row "SELECT id, name FROM author WHERE id=2";
	$id    # -> 2
	$name  # => Pushkin A.

=head2 query_row_ref ($query, %params)

As C<query_row>, but retuns array reference always.

	my @x = query_row_ref "SELECT name FROM author WHERE id=2";
	\@x # --> [{name => "Pushkin A."}]
	
	eval {query_row_ref "SELECT name FROM author"}; $@  # ~> A few lines!

=head2 query_scalar ($query, %params)

Returns scalar.

	query_scalar "SELECT name FROM author WHERE id=2" # => Pushkin A.

=head2 make_query_for_order ($order, $next)

Creates a condition for requesting a page not by offset, but by B<cursor pagination>.

To do this, it receives C<$order> of the SQL query and C<$next> - a link to the next page.

	my ($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", undef;
	
	$select     # => name || ',' || id
	$where      # -> 1
	$order_sel  # -> undef
	
	my @rows = query "SELECT $select as next FROM author WHERE $where LIMIT 2";
	
	my $last = pop @rows;
	
	($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", $last->{next};
	$select     # => name || ',' || id
	$where      # => (name < 'Pushkin A.'\nOR name = 'Pushkin A.' AND id >= '2')
	$order_sel  # --> [qw/name id/]

See also:
1. Article LL<https://habr.com/ru/articles/674714/>.
2. LL<https://metacpan.org/dist/SQL-SimpleOps/view/lib/SQL/SimpleOps.pod#SelectCursor>

=head2 settings ($id, $value)

Sets or returns a key from a table C<settings>.

	query "CREATE TABLE settings(
	    id TEXT PRIMARY KEY,
		value TEXT NOT NULL
	)";
	
	settings "x1"       # -> undef
	settings "x1", 10   # -> 1
	settings "x1"       # -> 10

=head2 load_by_id ($tab, $pk, $fields, @options)

Returns the entry by its id.

	load_by_id author => 2  # --> {id=>2, name=>"Pushkin A."}
	load_by_id author => 2, "name as n"  # --> {n=>"Pushkin A."}
	load_by_id author => 2, "id+:x as n", x => 10  # --> {n=>12}

=head2 insert ($tab, %x)

Adds a record and returns its id.

	insert 'author', name => 'Masha'  # -> 4

=head2 update ($tab, $id, %params)

Updates a record by its id, and returns this id.

	update author => 3, name => 'Sasha'  # -> 3
	eval { update author => 5, name => 'Sasha' }; $@  # ~> Row author.id=5 is not!

=head2 remove ($tab, $id)

Remove row from table by it id, and returns this id.

	remove "author", 4  # -> 4
	eval { remove author => 4 }; $@  # ~> Row author.id=4 does not exist!

=head2 query_id ($tab, %params)

Returns the id based on other fields.

	query_id 'author', name => 'Pushkin A.' # -> 2

=head2 stores ($tab, $rows, %opt)

Saves data (update or insert). Returns count successful operations.

	my @authors = (
	    {id => 1, name => 'Pushkin A.S.'},
	    {id => 2, name => 'Pushkin A.'},
	    {id => 3, name => 'Sasha'},
	);
	
	query "SELECT * FROM author ORDER BY id" # --> \@authors
	
	my $rows = stores 'author', [
	    {name => 'Locatelli'},
	    {id => 3, name => 'Kianu R.'},
	    {id => 2, name => 'Pushkin A.'},
	];
	$rows  # -> 3
	
	my $sql = "query: INSERT INTO author (id, name) VALUES (NULL, 'Locatelli'),
	(3, 'Kianu R.'),
	(2, 'Pushkin A.') ON CONFLICT DO UPDATE SET id = excluded.id, name = excluded.name";
	
	$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # -> $sql
	
	
	@authors = (
	    {id => 1, name => 'Pushkin A.S.'},
	    {id => 2, name => 'Pushkin A.'},
	    {id => 3, name => 'Kianu R.'},
	    {id => 5, name => 'Locatelli'},
	);
	
	query "SELECT * FROM author ORDER BY id" # --> \@authors

=head2 store ($tab, %params)

Saves data (update or insert). But one row.

	store 'author', name => 'Bishop M.' # -> 1

=head2 touch ($tab, %params)

Super-powerful function: returns id of row, and if it doesn’t exist, creates or updates a row and still returns.

	touch 'author', name => 'Pushkin A.' # -> 2
	touch 'author', name => 'Pushkin X.' # -> 7

=head2 START_TRANSACTION ()

Returns the variable on which to set commit, otherwise the rollback occurs.

	my $transaction = START_TRANSACTION;
	
	query "UPDATE author SET name='Pushkin N.' where id=7"  # -> 1
	
	$transaction->commit;
	
	query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.
	
	
	eval {
	    my $transaction = START_TRANSACTION;
	
	    query "UPDATE author SET name='Pushkin X.' where id=7" # -> 1
	
	    die "!";  # rollback
	    $transaction->commit;
	};
	
	query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.

=head2 default_dsn ()

Default DSN for C<< DBI-E<gt>connect >>.

	default_dsn  # => DBI:SQLite:dbname=test-base.sqlite

=head2 default_connect_options ()

DSN, USER, PASSWORD and commands after connect.

	[default_connect_options]  # --> ['DBI:SQLite:dbname=test-base.sqlite', 'root', 123, []]

=head2 base_connect ($dsn, $user, $password, $conn)

Connect to base and returns connect and it identify.

	my ($dbh, $connect_id) = base_connect("DBI:SQLite:dbname=base-2.sqlite", "toor", "toorpasswd", []);
	
	ref $dbh     # => DBI::db
	$connect_id  # -> -1

=head2 connect_respavn ($base)

Connection check and reconnection.

	my $old_base = $Aion::Query::base;
	
	$old_base->ping  # -> 1
	connect_respavn $Aion::Query::base, $Aion::Query::base_connection_id;
	
	$old_base  # -> $Aion::Query::base

=head2 connect_restart ($base)

Connection restart.

	my $connection_id = $Aion::Query::base_connection_id;
	my $base = $Aion::Query::base;
	
	connect_restart $Aion::Query::base, $Aion::Query::base_connection_id;
	
	$base->ping  # -> 0
	$Aion::Query::base->ping  # -> 1

=head2 query_stop ()

A request may be running - you need to kill it.

Creates an additional connection to the base and kills the main one.

It using C<$Aion::Query::base_connection_id> for this.

SQLite runs in the same process, so C<$Aion::Query::base_connection_id> has C<-1>. In this case, this method does nothing.

	my @x = query_stop;
	\@x  # --> []

=head2 sql_debug ($fn, $query)

Stores queries to the database in C<@Aion::Query::DEBUG>. Called from C<query_do>.

	sql_debug label => "SELECT 123";
	
	$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # => label: SELECT 123

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
