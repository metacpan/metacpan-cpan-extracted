use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-aion-query/aion!query'    ;     File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
# # NAME
# 
# Aion::Query - функциональный интерфейс для доступа к базам данных SQL (MySQL, MariaDB, Postgres и SQLite)
# 
# # VERSION
# 
# 0.0.3
# 
# # SYNOPSIS
# 
# File .config.pm:
#@> .config.pm
#>> package config;
#>> 
#>> config_module Aion::Query => {
#>>     DRV  => "SQLite",
#>>     BASE => "test-base.sqlite",
#>>     BQ => 0,
#>> };
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Query;

query "CREATE TABLE author (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
)";

::is scalar do {insert "author", name => "Pushkin A.S."}, scalar do{1}, 'insert "author", name => "Pushkin A.S." # -> 1';

::is scalar do {touch "author", name => "Pushkin A."}, scalar do{2}, 'touch "author", name => "Pushkin A."    # -> 2';
::is scalar do {touch "author", name => "Pushkin A.S."}, scalar do{1}, 'touch "author", name => "Pushkin A.S."  # -> 1';
::is scalar do {touch "author", name => "Pushkin A."}, scalar do{2}, 'touch "author", name => "Pushkin A."    # -> 2';

::is scalar do {query_scalar "SELECT count(*) FROM author"}, scalar do{2}, 'query_scalar "SELECT count(*) FROM author"  # -> 2';

my @rows = query "SELECT *
FROM author
WHERE 1
    if_name>> AND name like :name
",
    if_name => Aion::Query::BQ == 0,
    name => "P%",
;

::is_deeply scalar do {\@rows}, scalar do {[{id => 1, name => "Pushkin A.S."}, {id => 2, name => "Pushkin A."}]}, '\@rows # --> [{id => 1, name => "Pushkin A.S."}, {id => 2, name => "Pushkin A."}]';

::is scalar do {$Aion::Query::DEBUG[1]}, "query: INSERT INTO author (name) VALUES ('Pushkin A.S.')", '$Aion::Query::DEBUG[1]  # => query: INSERT INTO author (name) VALUES (\'Pushkin A.S.\')';

# 
# # DESCRIPTION
# 
# `Aion::Query` позволяет строить SQL-запрос используя простой механизм шаблонов.
# 
# Обычно SQL-запросы строятся с помощью условий, что нагружает код.
# 
# Вторая проблема — размещение символов Юникода в однобайтовых кодировках, что уменьшает размер базы данных. Пока проблема решена только для кодировки **cp1251**. Это контролируется параметром `use config BQ => 1`.
# 
# # SUBROUTINES
# 
# ## query ($query, %params)
# 
# Предоставляет SQL-запросы (DCL, DDL, DQL и DML) к СУБД с квотированием параметров.
# 
done_testing; }; subtest 'query ($query, %params)' => sub { 
::is_deeply scalar do {query "SELECT * FROM author WHERE name=:name", name => 'Pushkin A.S.'}, scalar do {[{id=>1, name=>"Pushkin A.S."}]}, 'query "SELECT * FROM author WHERE name=:name", name => \'Pushkin A.S.\' # --> [{id=>1, name=>"Pushkin A.S."}]';

# 
# ## LAST_INSERT_ID ()
# 
# Возвращает идентификатор последней вставки.
# 
done_testing; }; subtest 'LAST_INSERT_ID ()' => sub { 
::is scalar do {query "INSERT INTO author (name) VALUES (:name)", name => "Alice"}, scalar do{1}, 'query "INSERT INTO author (name) VALUES (:name)", name => "Alice"  # -> 1';
::is scalar do {LAST_INSERT_ID}, scalar do{3}, 'LAST_INSERT_ID  # -> 3';

# 
# ## quote ($scalar)
# 
# Квотирует скаляр для SQL-запроса.
# 
done_testing; }; subtest 'quote ($scalar)' => sub { 
::is scalar do {quote undef}, "NULL", 'quote undef     # => NULL';
::is scalar do {quote "abc"}, "'abc'", 'quote "abc"     # => \'abc\'';
::is scalar do {quote 123}, "123", 'quote 123       # => 123';
::is scalar do {quote "123"}, "'123'", 'quote "123"     # => \'123\'';
::is scalar do {quote(0+"123")}, "123", 'quote(0+"123")  # => 123';
::is scalar do {quote(123 . "")}, "'123'", 'quote(123 . "") # => \'123\'';
::is scalar do {quote 123.0}, "123.0", 'quote 123.0       # => 123.0';
::is scalar do {quote(0.0+"126")}, "126", 'quote(0.0+"126")  # => 126';
::is scalar do {quote("127"+0.0)}, "127", 'quote("127"+0.0)  # => 127';
::is scalar do {quote("128"-0.0)}, "128", 'quote("128"-0.0)  # => 128';
::is scalar do {quote("129"+1.e-100)}, "129.0", 'quote("129"+1.e-100)  # => 129.0';

# use for insert formula: SELECT :x as summ ⇒ x => \"xyz + 123"
::is scalar do {quote \"without quote"}, "without quote", 'quote \"without quote"  # => without quote';

# use in: WHERE id in (:x)
::is scalar do {quote [1,2,"5"]}, "1, 2, '5'", 'quote [1,2,"5"] # => 1, 2, \'5\'';

# use in: INSERT INTO author VALUES :x
::is scalar do {quote [[1, 2], [3, "4"]]}, "(1, 2), (3, '4')", 'quote [[1, 2], [3, "4"]]  # => (1, 2), (3, \'4\')';

# use in multiupdate: UPDATE author SET name=CASE id :x ELSE null END
::is scalar do {quote \[2=>'Pushkin A.', 1=>'Pushkin A.S.']}, "WHEN 2 THEN 'Pushkin A.' WHEN 1 THEN 'Pushkin A.S.'", 'quote \[2=>\'Pushkin A.\', 1=>\'Pushkin A.S.\']  # => WHEN 2 THEN \'Pushkin A.\' WHEN 1 THEN \'Pushkin A.S.\'';

# use for UPDATE SET :x or INSERT SET :x
::is scalar do {quote {name => 'A.S.', id => 12}}, "id = 12, name = 'A.S.'", 'quote {name => \'A.S.\', id => 12}   # => id = 12, name = \'A.S.\'';

::is_deeply scalar do {[map quote, -6, "-6", 1.5, "1.5"]}, scalar do {[-6, "'-6'", 1.5, "'1.5'"]}, '[map quote, -6, "-6", 1.5, "1.5"] # --> [-6, "\'-6\'", 1.5, "\'1.5\'"]';


# 
# ## query_prepare ($query, %param)
# 
# Заменяет параметры (`%param`) в запросе (`$query`) и возвращает его. Параметры заключаются в кавычки через подпрограмму `quote`.
# 
# Параметры вида `:x` будут квотироваться с учётом флагов скаляра, которые укажут, что в нём находится: строка, целое или число с плавающей запятой.
# 
# Чтобы явно указать тип скаляра используйте префиксы: `:^x` – целое, `:.x` – строка, `:~x` – плавающее.
# 
done_testing; }; subtest 'query_prepare ($query, %param)' => sub { 
::is scalar do {query_prepare "INSERT author SET name IN (:name)", name => ["Alice", 1, 1.0]}, "INSERT author SET name IN ('Alice', 1, 1.0)", 'query_prepare "INSERT author SET name IN (:name)", name => ["Alice", 1, 1.0]  # => INSERT author SET name IN (\'Alice\', 1, 1.0)';

::is scalar do {query_prepare ":x :^x :.x :~x", x => "10"}, "'10' 10 10.0 '10'", 'query_prepare ":x :^x :.x :~x", x => "10"  # => \'10\' 10 10.0 \'10\'';

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

::is scalar do {$query}, scalar do{$res}, '$query # -> $res';

# 
# ## query_do ($query)
# 
# Выполняет запрос и возвращает его результат.
# 
done_testing; }; subtest 'query_do ($query)' => sub { 
::is_deeply scalar do {query_do "SELECT count(*) as n FROM author"}, scalar do {[{n=>3}]}, 'query_do "SELECT count(*) as n FROM author"  # --> [{n=>3}]';
::is_deeply scalar do {query_do "SELECT id FROM author WHERE id=2"}, scalar do {[{id=>2}]}, 'query_do "SELECT id FROM author WHERE id=2"  # --> [{id=>2}]';

# 
# ## query_ref ($query, %kw)
# 
# Как `query`, но всегда возвращает скаляр.
# 
done_testing; }; subtest 'query_ref ($query, %kw)' => sub { 
my @res = query_ref "SELECT id FROM author WHERE id=:id", id => 2;
::is_deeply scalar do {\@res}, scalar do {[[ {id=>2} ]]}, '\@res  # --> [[ {id=>2} ]]';

# 
# ## query_sth ($query, %kw)
# 
# Как `query`, но возвращает `$sth`.
# 
done_testing; }; subtest 'query_sth ($query, %kw)' => sub { 
my $sth = query_sth "SELECT * FROM author";
my @rows;
while(my $row = $sth->fetchrow_arrayref) {
    push @rows, $row;
}
$sth->finish;

::is scalar do {0+@rows}, scalar do{3}, '0+@rows  # -> 3';

# 
# ## query_slice ($key, $val, $query, %kw)
# 
# Как query, плюс преобразует результат в нужную структуру данных.
# 
# Если нужен хеш вида идентификатор – значение:
# 
done_testing; }; subtest 'query_slice ($key, $val, $query, %kw)' => sub { 
my %author = query_slice name => "id", "SELECT id, name FROM author";
::is_deeply scalar do {\%author}, scalar do {{"Pushkin A.S." => 1, "Pushkin A." => 2, "Alice" => 3}}, '\%author  # --> {"Pushkin A.S." => 1, "Pushkin A." => 2, "Alice" => 3}';

# 
# Если нужен хеш вида идентификатор – строка:
# 

my %author = query_slice id => {}, "SELECT id, name FROM author";

my $rows = {
    1 => {name => "Pushkin A.S.", id => 1},
    2 => {name => "Pushkin A.",   id => 2},
    3 => {name => "Alice",        id => 3},
};

::is_deeply scalar do {\%author}, scalar do {$rows}, '\%author  # --> $rows';

# 
# Если одному идентификатору соответствует несколько строк, то логично собрать их в массивы:
# 

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

::is_deeply scalar do {\%author}, scalar do {$rows}, '\%author  # --> $rows';

# 
# Ну и строки со всеми полями:
# 

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

::is_deeply scalar do {\%author}, scalar do {$rows}, '\%author  # --> $rows';

# 
# ## query_attach ($rows, $attach, $query, %kw)
# 
# Подсоединяет в результат запроса результат другого запроса.
# 
# `$attach` содержит три ключа через двоеточие: ключ для присоединяемых данных, столбец из `$rows` и столбец из `$query`. По столбцам происходит объединение строк.
# 
done_testing; }; subtest 'query_attach ($rows, $attach, $query, %kw)' => sub { 
my $authors = query "SELECT id, name FROM author";

my $res = [
    {name => "Pushkin A.S.", id => 1},
    {name => "Pushkin A.",   id => 2},
    {name => "Alice",        id => 3},
];

::is_deeply scalar do {$authors}, scalar do {$res}, '$authors # --> $res';

query_attach $authors => "books:id:author_id" => "SELECT author_id, title FROM book ORDER BY title";

my $attaches = [
    {name => "Pushkin A.S.", id => 1, books => [
        {title => "Kiss in night", author_id => 1},
        {title => "Mir",           author_id => 1},
    ]},
    {name => "Pushkin A.",   id => 2},
    {name => "Alice",        id => 3, books => [
        {title => "Mips as cpu", author_id => 3},
    ]},
];

::is_deeply scalar do {$authors}, scalar do {$attaches}, '$authors # --> $attaches';

# 
# Если нужно указать другие ключи, то это делается через двоеточия в `$attach`: `attach:id:attach_id`.
# 
# ## query_col ($query, %params)
# 
# Возвращает один столбец.
# 
done_testing; }; subtest 'query_col ($query, %params)' => sub { 
::is_deeply scalar do {query_col "SELECT name FROM author ORDER BY name"}, scalar do {["Alice", "Pushkin A.", "Pushkin A.S."]}, 'query_col "SELECT name FROM author ORDER BY name" # --> ["Alice", "Pushkin A.", "Pushkin A.S."]';

::like scalar do {eval {query_col "SELECT id, name FROM author"}; $@}, qr!Only one column is acceptable\!!, 'eval {query_col "SELECT id, name FROM author"}; $@  # ~> Only one column is acceptable!';

# 
# ## query_row ($query, %params)
# 
# Возвращает одну строку.
# 
done_testing; }; subtest 'query_row ($query, %params)' => sub { 
::is_deeply scalar do {query_row "SELECT name FROM author WHERE id=2"}, scalar do {{name => "Pushkin A."}}, 'query_row "SELECT name FROM author WHERE id=2" # --> {name => "Pushkin A."}';

my ($id, $name) = query_row "SELECT id, name FROM author WHERE id=2";
::is scalar do {$id}, scalar do{2}, '$id    # -> 2';
::is scalar do {$name}, "Pushkin A.", '$name  # => Pushkin A.';

::like scalar do {eval { query_row "SELECT id, name FROM author" }; $@}, qr!A few lines\!!, 'eval { query_row "SELECT id, name FROM author" }; $@ # ~> A few lines!';

# 
# ## query_row_ref ($query, %params)
# 
# Как `query_row`, но всегда возвращает скаляр.
# 
done_testing; }; subtest 'query_row_ref ($query, %params)' => sub { 
my @x = query_row_ref "SELECT name FROM author WHERE id=2";
::is_deeply scalar do {\@x}, scalar do {[{name => "Pushkin A."}]}, '\@x # --> [{name => "Pushkin A."}]';

::like scalar do {eval {query_row_ref "SELECT name FROM author"}; $@}, qr!A few lines\!!, 'eval {query_row_ref "SELECT name FROM author"}; $@  # ~> A few lines!';

# 
# ## query_scalar ($query, %params)
# 
# Возвращает первое значение. Запрос должен возвращать одну строку, иначе – выбрасывает исключение.
# 
done_testing; }; subtest 'query_scalar ($query, %params)' => sub { 
::is scalar do {query_scalar "SELECT name FROM author WHERE id=2"}, "Pushkin A.", 'query_scalar "SELECT name FROM author WHERE id=2" # => Pushkin A.';

# 
# ## make_query_for_order ($order, $next)
# 
# Создает условие запроса страницы не по смещению, а по **пагинации курсора**.
# 
# Для этого он получает `$order` SQL-запроса и `$next` — ссылку на следующую страницу.
# 
done_testing; }; subtest 'make_query_for_order ($order, $next)' => sub { 
my ($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", undef;

::is scalar do {$select}, "name || ',' || id", '$select     # => name || \',\' || id';
::is scalar do {$where}, scalar do{1}, '$where      # -> 1';
::is scalar do {$order_sel}, scalar do{undef}, '$order_sel  # -> undef';

my @rows = query "SELECT $select as next FROM author WHERE $where LIMIT 2";

my $last = pop @rows;

($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", $last->{next};
::is scalar do {$select}, "name || ',' || id", '$select     # => name || \',\' || id';
::is scalar do {$where}, "(name < 'Pushkin A.'\nOR name = 'Pushkin A.' AND id >= '2')", '$where      # => (name < \'Pushkin A.\'\nOR name = \'Pushkin A.\' AND id >= \'2\')';
::is_deeply scalar do {$order_sel}, scalar do {[qw/name id/]}, '$order_sel  # --> [qw/name id/]';

# 
# Смотрите также:
# 
# 1. Article [Paging pages on social networks
# ](https://habr.com/ru/articles/674714/).
# 2. [SQL::SimpleOps->SelectCursor](https://metacpan.org/dist/SQL-SimpleOps/view/lib/SQL/SimpleOps.pod#SelectCursor)
# 
# ## settings ($id, $value)
# 
# Устанавливает или возвращает ключ из таблицы `settings`.
# 
done_testing; }; subtest 'settings ($id, $value)' => sub { 
query "CREATE TABLE settings(
    id TEXT PRIMARY KEY,
	value TEXT NOT NULL
)";

::is scalar do {settings "x1"}, scalar do{undef}, 'settings "x1"       # -> undef';
::is scalar do {settings "x1", 10}, scalar do{1}, 'settings "x1", 10   # -> 1';
::is scalar do {settings "x1"}, scalar do{10}, 'settings "x1"       # -> 10';

# 
# ## load_by_id ($tab, $pk, $fields, @options)
# 
# Возвращает запись по ее идентификатору.
# 
done_testing; }; subtest 'load_by_id ($tab, $pk, $fields, @options)' => sub { 
::is_deeply scalar do {load_by_id author => 2}, scalar do {{id=>2, name=>"Pushkin A."}}, 'load_by_id author => 2  # --> {id=>2, name=>"Pushkin A."}';
::is_deeply scalar do {load_by_id author => 2, "name as n"}, scalar do {{n=>"Pushkin A."}}, 'load_by_id author => 2, "name as n"  # --> {n=>"Pushkin A."}';
::is_deeply scalar do {load_by_id author => 2, "id+:x as n", x => 10}, scalar do {{n=>12}}, 'load_by_id author => 2, "id+:x as n", x => 10  # --> {n=>12}';

# 
# ## insert ($tab, %x)
# 
# Добавляет запись и возвращает ее идентификатор.
# 
done_testing; }; subtest 'insert ($tab, %x)' => sub { 
::is scalar do {insert 'author', name => 'Masha'}, scalar do{4}, 'insert \'author\', name => \'Masha\'  # -> 4';

# 
# ## update ($tab, $id, %params)
# 
# Обновляет запись по её идентификатору и возвращает этот идентификатор.
# 
done_testing; }; subtest 'update ($tab, $id, %params)' => sub { 
::is scalar do {update author => 3, name => 'Sasha'}, scalar do{3}, 'update author => 3, name => \'Sasha\'  # -> 3';
::like scalar do {eval { update author => 5, name => 'Sasha' }; $@}, qr!Row author.id=5 is not\!!, 'eval { update author => 5, name => \'Sasha\' }; $@  # ~> Row author.id=5 is not!';

# 
# ## remove ($tab, $id)
# 
# Удалить строку из таблицы по её идентификатору и вернуть этот идентификатор.
# 
done_testing; }; subtest 'remove ($tab, $id)' => sub { 
::is scalar do {remove "author", 4}, scalar do{4}, 'remove "author", 4  # -> 4';
::like scalar do {eval { remove author => 4 }; $@}, qr!Row author.id=4 does not exist\!!, 'eval { remove author => 4 }; $@  # ~> Row author.id=4 does not exist!';

# 
# ## query_id ($tab, %params)
# 
# Возвращает идентификатор на основе других полей.
# 
done_testing; }; subtest 'query_id ($tab, %params)' => sub { 
::is scalar do {query_id 'author', name => 'Pushkin A.'}, scalar do{2}, 'query_id \'author\', name => \'Pushkin A.\' # -> 2';

# 
# ## stores ($tab, $rows, %opt)
# 
# Сохраняет данные (обновляет или вставляет). Возвращает подсчет успешных операций.
# 
done_testing; }; subtest 'stores ($tab, $rows, %opt)' => sub { 
my @authors = (
    {id => 1, name => 'Pushkin A.S.'},
    {id => 2, name => 'Pushkin A.'},
    {id => 3, name => 'Sasha'},
);

::is_deeply scalar do {query "SELECT * FROM author ORDER BY id"}, scalar do {\@authors}, 'query "SELECT * FROM author ORDER BY id" # --> \@authors';

my $rows = stores 'author', [
    {name => 'Locatelli'},
    {id => 3, name => 'Kianu R.'},
    {id => 2, name => 'Pushkin A.'},
];
::is scalar do {$rows}, scalar do{3}, '$rows  # -> 3';

my $sql = "query: INSERT INTO author (id, name) VALUES (NULL, 'Locatelli'),
(3, 'Kianu R.'),
(2, 'Pushkin A.') ON CONFLICT DO UPDATE SET id = excluded.id, name = excluded.name";

::is scalar do {$Aion::Query::DEBUG[$#Aion::Query::DEBUG]}, scalar do{$sql}, '$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # -> $sql';


@authors = (
    {id => 1, name => 'Pushkin A.S.'},
    {id => 2, name => 'Pushkin A.'},
    {id => 3, name => 'Kianu R.'},
    {id => 5, name => 'Locatelli'},
);

::is_deeply scalar do {query "SELECT * FROM author ORDER BY id"}, scalar do {\@authors}, 'query "SELECT * FROM author ORDER BY id" # --> \@authors';

# 
# ## store ($tab, %params)
# 
# Сохраняет данные (обновляет или вставляет) одну строку.
# 
done_testing; }; subtest 'store ($tab, %params)' => sub { 
::is scalar do {store 'author', name => 'Bishop M.'}, scalar do{1}, 'store \'author\', name => \'Bishop M.\' # -> 1';

# 
# ## touch ($tab, %params)
# 
# Супермощная функция: возвращает идентификатор строки, а если он не существует, создает или обновляет строку и всё равно возвращает.
# 
done_testing; }; subtest 'touch ($tab, %params)' => sub { 
::is scalar do {touch 'author', name => 'Pushkin A.'}, scalar do{2}, 'touch \'author\', name => \'Pushkin A.\' # -> 2';
::is scalar do {touch 'author', name => 'Pushkin X.'}, scalar do{7}, 'touch \'author\', name => \'Pushkin X.\' # -> 7';

# 
# ## START_TRANSACTION ()
# 
# Возвращает переменную на которой необходимо выполнить фиксацию, иначе происходит откат.
# 
done_testing; }; subtest 'START_TRANSACTION ()' => sub { 
my $transaction = START_TRANSACTION;

::is scalar do {query "UPDATE author SET name='Pushkin N.' where id=7"}, scalar do{1}, 'query "UPDATE author SET name=\'Pushkin N.\' where id=7"  # -> 1';

$transaction->commit;

::is scalar do {query_scalar "SELECT name FROM author where id=7"}, "Pushkin N.", 'query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.';


eval {
    my $transaction = START_TRANSACTION;

::is scalar do {query "UPDATE author SET name='Pushkin X.' where id=7"}, scalar do{1}, '    query "UPDATE author SET name=\'Pushkin X.\' where id=7" # -> 1';

    die "!";  # rollback
    $transaction->commit;
};

::is scalar do {query_scalar "SELECT name FROM author where id=7"}, "Pushkin N.", 'query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.';

# 
# ## default_dsn ()
# 
# DSN по умолчанию для `DBI->connect`.
# 
done_testing; }; subtest 'default_dsn ()' => sub { 
::is scalar do {default_dsn}, "DBI:SQLite:dbname=test-base.sqlite", 'default_dsn  # => DBI:SQLite:dbname=test-base.sqlite';

# 
# ## default_connect_options ()
# 
# DSN, пользователь, пароль и команды после подключения.
# 
done_testing; }; subtest 'default_connect_options ()' => sub { 
::is_deeply scalar do {[default_connect_options]}, scalar do {['DBI:SQLite:dbname=test-base.sqlite', 'root', 123, []]}, '[default_connect_options]  # --> [\'DBI:SQLite:dbname=test-base.sqlite\', \'root\', 123, []]';

# 
# ## base_connect ($dsn, $user, $password, $conn)
# 
# Подключаемся к базе и возвращаем соединение и идентифицируем.
# 
done_testing; }; subtest 'base_connect ($dsn, $user, $password, $conn)' => sub { 
my ($dbh, $connect_id) = base_connect("DBI:SQLite:dbname=base-2.sqlite", "toor", "toorpasswd", []);

::is scalar do {ref $dbh}, "DBI::db", 'ref $dbh     # => DBI::db';
::is scalar do {$connect_id}, scalar do{-1}, '$connect_id  # -> -1';

# 
# ## connect_respavn ($base)
# 
# Проверка подключения и повторное подключение.
# 
done_testing; }; subtest 'connect_respavn ($base)' => sub { 
my $old_base = $Aion::Query::base;

::is scalar do {$old_base->ping}, scalar do{1}, '$old_base->ping  # -> 1';
connect_respavn $Aion::Query::base, $Aion::Query::base_connection_id;

::is scalar do {$old_base}, scalar do{$Aion::Query::base}, '$old_base  # -> $Aion::Query::base';

# 
# ## connect_restart ($base)
# 
# Перезапуск соединения.
# 
done_testing; }; subtest 'connect_restart ($base)' => sub { 
my $connection_id = $Aion::Query::base_connection_id;
my $base = $Aion::Query::base;

connect_restart $Aion::Query::base, $Aion::Query::base_connection_id;

::is scalar do {$base->ping}, scalar do{0}, '$base->ping  # -> 0';
::is scalar do {$Aion::Query::base->ping}, scalar do{1}, '$Aion::Query::base->ping  # -> 1';

# 
# ## query_stop ()
# 
# Создает дополнительное соединение с базой и убивает основное.
# 
# Для этого используется `$Aion::Query::base_connection_id`.
# 
# SQLite работает в том же процессе, поэтому `$Aion::Query::base_connection_id` имеет `-1`. То есть для SQLite этот метод ничего не делает.
# 
done_testing; }; subtest 'query_stop ()' => sub { 
my @x = query_stop;
::is_deeply scalar do {\@x}, scalar do {[]}, '\@x  # --> []';

# 
# ## sql_debug ($fn, $query)
# 
# Сохраняет запросы к базе данных в `@Aion::Query::DEBUG`. Вызывается из `query_do`.
# 
done_testing; }; subtest 'sql_debug ($fn, $query)' => sub { 
sql_debug label => "SELECT 123";

::is scalar do {$Aion::Query::DEBUG[$#Aion::Query::DEBUG]}, "label: SELECT 123", '$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # => label: SELECT 123';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
