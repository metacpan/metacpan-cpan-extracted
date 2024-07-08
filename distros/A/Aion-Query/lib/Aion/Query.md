!ru:en
# NAME

Aion::Query - функциональный интерфейс для доступа к базам данных SQL (MySQL, MariaDB, Postgres и SQLite)

# VERSION

0.0.6

# SYNOPSIS

File .config.pm:
```perl
package config;

config_module Aion::Query => {
    DRV  => "SQLite",
    BASE => "test-base.sqlite",
    BQ => 0,
};

1;
```

```perl
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
```

# DESCRIPTION

`Aion::Query` позволяет строить SQL-запрос используя простой механизм шаблонов.

Обычно SQL-запросы строятся с помощью условий, что нагружает код.

Вторая проблема — размещение символов Юникода в однобайтовых кодировках, что уменьшает размер базы данных. Пока проблема решена только для кодировки **cp1251**. Это контролируется параметром `use config BQ => 1`.

# SUBROUTINES

## query ($query, %params)

Предоставляет SQL-запросы (DCL, DDL, DQL и DML) к СУБД с квотированием параметров.

```perl
query "SELECT * FROM author WHERE name=:name", name => 'Pushkin A.S.' # --> [{id=>1, name=>"Pushkin A.S."}]
```

## LAST_INSERT_ID ()

Возвращает идентификатор последней вставки.

```perl
query "INSERT INTO author (name) VALUES (:name)", name => "Alice"  # -> 1
LAST_INSERT_ID  # -> 3
```

## quote ($scalar)

Квотирует скаляр для SQL-запроса.

```perl
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

```

## query_prepare ($query, %param)

Заменяет параметры (`%param`) в запросе (`$query`) и возвращает его. Параметры заключаются в кавычки через подпрограмму `quote`.

Параметры вида `:x` будут квотироваться с учётом флагов скаляра, которые укажут, что в нём находится: строка, целое или число с плавающей запятой.

Чтобы явно указать тип скаляра используйте префиксы: `:^x` – целое, `:.x` – строка, `:~x` – плавающее.

```perl
query_prepare "INSERT author SET name IN (:name)", name => ["Alice", 1, 1.0]  # => INSERT author SET name IN ('Alice', 1, 1.0)

query_prepare ":x :^x :.x :~x", x => "10"  # => '10' 10 10.0 '10'

my $query = query_prepare "SELECT *
FROM author
    words*>> JOIN word:_
WHERE 1
    name>> AND name like :name
",
    name => "%Alice%",
    words => [1, 2, 3],
;

my $res = << 'END';
SELECT *
FROM author
    JOIN word1
    JOIN word2
    JOIN word3
WHERE 1
    AND name like '%Alice%'
END

$query # -> $res
```

## query_do ($query)

Выполняет запрос и возвращает его результат.

```perl
query_do "SELECT count(*) as n FROM author"  # --> [{n=>3}]
query_do "SELECT id FROM author WHERE id=2"  # --> [{id=>2}]
```

## query_ref ($query, %kw)

Как `query`, но всегда возвращает скаляр.

```perl
my @res = query_ref "SELECT id FROM author WHERE id=:id", id => 2;
\@res  # --> [[ {id=>2} ]]
```

## query_sth ($query, %kw)

Как `query`, но возвращает `$sth`.

```perl
my $sth = query_sth "SELECT * FROM author";
my @rows;
while(my $row = $sth->fetchrow_arrayref) {
    push @rows, $row;
}
$sth->finish;

0+@rows  # -> 3
```

## query_slice ($key, $val, $query, %kw)

Как query, плюс преобразует результат в нужную структуру данных.

Если нужен хеш вида идентификатор – значение:

```perl
my %author = query_slice name => "id", "SELECT id, name FROM author";
\%author  # --> {"Pushkin A.S." => 1, "Pushkin A." => 2, "Alice" => 3}
```

Если нужен хеш вида идентификатор – строка:

```perl
my %author = query_slice id => {}, "SELECT id, name FROM author";

my $rows = {
    1 => {name => "Pushkin A.S.", id => 1},
    2 => {name => "Pushkin A.",   id => 2},
    3 => {name => "Alice",        id => 3},
};

\%author  # --> $rows
```

Если одному идентификатору соответствует несколько строк, то логично собрать их в массивы:

```perl
query "CREATE TABLE book (
	id SERIAL PRIMARY KEY,
    author_id INT NOT NULL REFERENCES author(id),
    title TEXT NOT NULL
)";

stores book => [
    {author_id => 1, title => "Mir"},
    {author_id => 1, title => "Kiss in night"},
    {author_id => 3, title => "Mips as cpu"},
];

my %author = query_slice author_id => ["title"], "SELECT author_id, title FROM book ORDER BY title";

my $rows = {
    1 => ["Kiss in night", "Mir"],
    3 => ["Mips as cpu"],
};

\%author  # --> $rows
```

Ну и строки со всеми полями:

```perl
my %author = query_slice author_id => [], "SELECT author_id, title FROM book ORDER BY title";

my $rows = {
    1 => [
        {title => "Kiss in night", author_id => 1},
        {title => "Mir",           author_id => 1},
    ],
    3 => [
        {title => "Mips as cpu",   author_id => 3}
    ],
};

\%author  # --> $rows
```

## query_attach ($rows, $attach, $query, %kw)

Подсоединяет в результат запроса результат другого запроса.

`$attach` содержит три ключа через двоеточие: ключ для присоединяемых данных, столбец из `$rows` и столбец из `$query`. По столбцам происходит объединение строк.

Возвращает функция массив с результатом запроса (`$query`), в который можно приаттачить ещё что-то.

```perl
my $authors = query "SELECT id, name FROM author";

my $res = [
    {name => "Pushkin A.S.", id => 1},
    {name => "Pushkin A.",   id => 2},
    {name => "Alice",        id => 3},
];

$authors # --> $res

my @books = query_attach $authors => "books:id:author_id" => "SELECT author_id, title FROM book ORDER BY title";

my $attaches = [
    {name => "Pushkin A.S.", id => 1, books => [
        {title => "Kiss in night", author_id => 1},
        {title => "Mir",           author_id => 1},
    ]},
    {name => "Pushkin A.",   id => 2, books => []},
    {name => "Alice",        id => 3, books => [
        {title => "Mips as cpu", author_id => 3},
    ]},
];

$authors # --> $attaches

my $books = [
    {title => "Kiss in night", author_id => 1},
    {title => "Mips as cpu",   author_id => 3},
    {title => "Mir",           author_id => 1},
];

\@books  # --> $books
```

## query_col ($query, %params)

Возвращает один столбец.

```perl
query_col "SELECT name FROM author ORDER BY name" # --> ["Alice", "Pushkin A.", "Pushkin A.S."]

eval {query_col "SELECT id, name FROM author"}; $@  # ~> Only one column is acceptable!
```

## query_row ($query, %params)

Возвращает одну строку.

```perl
query_row "SELECT name FROM author WHERE id=2" # --> {name => "Pushkin A."}

my ($id, $name) = query_row "SELECT id, name FROM author WHERE id=2";
$id    # -> 2
$name  # => Pushkin A.

eval { query_row "SELECT id, name FROM author" }; $@ # ~> A few lines! 
```

## query_row_ref ($query, %params)

Как `query_row`, но всегда возвращает скаляр.

```perl
my @x = query_row_ref "SELECT name FROM author WHERE id=2";
\@x # --> [{name => "Pushkin A."}]

eval {query_row_ref "SELECT name FROM author"}; $@  # ~> A few lines!
```

## query_scalar ($query, %params)

Возвращает первое значение. Запрос должен возвращать одну строку, иначе – выбрасывает исключение.

```perl
query_scalar "SELECT name FROM author WHERE id=2" # => Pushkin A.
```

## make_query_for_order ($order, $next)

Создает условие запроса страницы не по смещению, а по **пагинации курсора**.

Для этого он получает `$order` SQL-запроса и `$next` — ссылку на следующую страницу.

```perl
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
```

Смотрите также:

1. Article [Paging pages on social networks
](https://habr.com/ru/articles/674714/).
2. [SQL::SimpleOps->SelectCursor](https://metacpan.org/dist/SQL-SimpleOps/view/lib/SQL/SimpleOps.pod#SelectCursor)

## settings ($id, $value)

Устанавливает или возвращает ключ из таблицы `settings`.

```perl
query "CREATE TABLE settings(
    id TEXT PRIMARY KEY,
	value TEXT NOT NULL
)";

settings "x1"       # -> undef
settings "x1", 10   # -> 1
settings "x1"       # -> 10
```

## load_by_id ($tab, $pk, $fields, @options)

Возвращает запись по ее идентификатору.

```perl
load_by_id author => 2  # --> {id=>2, name=>"Pushkin A."}
load_by_id author => 2, "name as n"  # --> {n=>"Pushkin A."}
load_by_id author => 2, "id+:x as n", x => 10  # --> {n=>12}
```

## insert ($tab, %x)

Добавляет запись и возвращает ее идентификатор.

```perl
insert 'author', name => 'Masha'  # -> 4
```

## update ($tab, $id, %params)

Обновляет запись по её идентификатору и возвращает этот идентификатор.

```perl
update author => 3, name => 'Sasha'  # -> 3
eval { update author => 5, name => 'Sasha' }; $@  # ~> Row author.id=5 is not!
```

## remove ($tab, $id)

Удалить строку из таблицы по её идентификатору и вернуть этот идентификатор.

```perl
remove "author", 4  # -> 4
eval { remove author => 4 }; $@  # ~> Row author.id=4 does not exist!
```

## query_id ($tab, %params)

Возвращает идентификатор на основе других полей.

```perl
query_id 'author', name => 'Pushkin A.' # -> 2
```

## stores ($tab, $rows, %opt)

Сохраняет данные (обновляет или вставляет). Возвращает подсчет успешных операций.

```perl
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
```

## store ($tab, %params)

Сохраняет данные (обновляет или вставляет) одну строку.

```perl
store 'author', name => 'Bishop M.' # -> 1
```

## touch ($tab, %params)

Супермощная функция: возвращает идентификатор строки, а если он не существует, создает или обновляет строку и всё равно возвращает.

```perl
touch 'author', name => 'Pushkin A.' # -> 2
touch 'author', name => 'Pushkin X.' # -> 7
```

## START_TRANSACTION ()

Возвращает переменную на которой необходимо выполнить фиксацию, иначе происходит откат.

```perl
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
```

## default_dsn ()

DSN по умолчанию для `DBI->connect`.

```perl
default_dsn  # => DBI:SQLite:dbname=test-base.sqlite
```

## default_connect_options ()

DSN, пользователь, пароль и команды после подключения.

```perl
[default_connect_options]  # --> ['DBI:SQLite:dbname=test-base.sqlite', 'root', 123, []]
```

## base_connect ($dsn, $user, $password, $conn)

Подключаемся к базе и возвращаем соединение и идентифицируем.

```perl
my ($dbh, $connect_id) = base_connect("DBI:SQLite:dbname=base-2.sqlite", "toor", "toorpasswd", []);

ref $dbh     # => DBI::db
$connect_id  # -> -1
```

## connect_respavn ($base)

Проверка подключения и повторное подключение.

```perl
my $old_base = $Aion::Query::base;

$old_base->ping  # -> 1
connect_respavn $Aion::Query::base, $Aion::Query::base_connection_id;

$old_base  # -> $Aion::Query::base
```

## connect_restart ($base)

Перезапуск соединения.

```perl
my $connection_id = $Aion::Query::base_connection_id;
my $base = $Aion::Query::base;

connect_restart $Aion::Query::base, $Aion::Query::base_connection_id;

$base->ping  # -> 0
$Aion::Query::base->ping  # -> 1
```

## query_stop ()

Создает дополнительное соединение с базой и убивает основное.

Для этого используется `$Aion::Query::base_connection_id`.

SQLite работает в том же процессе, поэтому `$Aion::Query::base_connection_id` имеет `-1`. То есть для SQLite этот метод ничего не делает.

```perl
my @x = query_stop;
\@x  # --> []
```

## sql_debug ($fn, $query)

Сохраняет запросы к базе данных в `@Aion::Query::DEBUG`. Вызывается из `query_do`.

```perl
sql_debug label => "SELECT 123";

$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # => label: SELECT 123
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
