[//]: # ( README.md Fri 19 Apr 2024 13:16:21 MSK )

# Acrux::DBI

**Acrux::DBI** - Database independent interface for Acrux applications

Acrux::DBI это модуль-оболочка для [DBI](https://metacpan.org/pod/DBI) призванный концептуально заменить устаревающий [CTK::DBI](https://metacpan.org/pod/CTK::DBI). Пакет Acrux::DBI входит в семейство пакетов [Acrux](https://metacpan.org/pod/Acrux), которое определяет основную область применения нашего нового модуля - написание моделей для проектов [Acrux](https://metacpan.org/pod/Acrux) и связанных с ним проектов [WWW::Suffit](https://metacpan.org/pod/WWW::Suffit). Наш новый модуль базируется на успешной практике применения модулей [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg), [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) и [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite). Acrux::DBI, также как и перечисленные выше модули, базируется на фреймворке [Mojolicious](https://metacpan.org/pod/Mojolicious), но имеет ряд своих особенностей:

- количество зависимостей сведено к минимуму (на текущий момент их всего 3);
- область применения модуля шире, чем у его предшественника [CTK::DBI](https://metacpan.org/pod/CTK::DBI);
- в модуле сознательно отсутствует набор методов для задач асинхронности (для этих задач потребуются дополнительные расширения);
- в модуле имеется механизм организации хранения и размещения SQL блоков и SQL дампов;
- модуль подходит для SQL СУБД *MySQL*, *MariaDB*, *PostgreSQL*, *SQLite* и *Oracle*
- расширяя модуль в своих приложениях можно добиться максимальной "красоты" ваших моделей
- нет ничего лишнего

Знакомство с модулем лучше всего начать с практики. Для примера я буду в описании использовать  тестовый WEB проект под именем *altair*, написанный на [WWW::Suffit](https://metacpan.org/pod/WWW::Suffit) и [Acrux](https://metacpan.org/pod/Acrux). Сам модуль *Acrux::DBI* в проекте будет расширяться наследованием в модуле модели - `WWW::Altair::Model`

## Constructor

В проекте *altair* модель будет создаваться с помощью атрибута `model`:

```perl
package WWW::Altair::Server;

use Mojo::Base 'WWW::Suffit::Server';
use WWW::Altair::Model;

has 'model' => sub {
  WWW::Altair::Model->new(
    $_[0]->conf->latest("/modelurl")
  );
};
```

В этом примере модуль модели подключается в основном классе сервера [WWW::Suffit::Server](https://metacpan.org/pod/WWW::Suffit::Server), а экземпляр модели создаётся на этапе первого вызова атрибута `model`. Конструктор имеет первый аргумент - **ModelURL**, который в свою очередь получается из одноименной директивы конфигурационного файла проекта. **ModelURL** -- это строка вида классического URL, пример нескольких таких строк:

```text
mysql://username:password@hostname/altair?mysql_auto_reconnect=1

mariadb://username:password@hostname/altair?mariadb_auto_reconnect=1

sqlite:///var/lib/altair/altair.db?sqlite_unicode=1
```

Далее указанная URL строка будет преобразована автоматически в DSN будущего соединения

## Connect

При запуске WEB сервера и переходе на главную страницу тестового сайта будет осуществлен "вход" в обработчик этого маршрута `WWW::Altair::Server::Alpha::root`, именно в нём и будет производиться инициализация соединения с базой данных:

```perl
my $model = $self->app->model->init;
return $self->reply->error(500 => "E0500" => $model->error)
  if $model->error;
```

Сам код инициализации находится в классе `WWW::Altair::Model`:

```perl
package WWW::Altair::Model;

use parent 'Acrux::DBI';

use Acrux::Util qw/ touch dformat /;
use Acrux::RefUtil qw/ is_hash_ref is_void /;

sub init {
    my $self = shift->connect_cached;

    my $is_new = 0;
    my $dbh = $self->dbh;
    if (defined($dbh)) {
        if ($self->is_sqlite) {
            my $file = $dbh->sqlite_db_filename();
            unless ($file && (-e $file) && !(-z $file)) {
                touch($file);
                chmod(0666, $file);
                $is_new = 1;
            }
        } elsif ($self->is_mysql) {
            if (my $res = $self->query("SHOW TABLES FROM
            `" . $self->database() . "` LIKE 'altair'")) {
                $is_new = 1 if is_void($res->array);
            }
        }
    }

    # Check DB handler
    return $self->error(sprintf("Can't connect to database \"%s\": %s",
        $self->dsn, $self->errstr || "unknown error")) unless $dbh;

    # Import schema
    if ($is_new) {
        $self->dump->from_data->poke("ddl_" . $self->driver());
        return $self if $self->error;
    }

    # Check connect
    return $self->error(sprintf("Can't init database \"%s\". Ping failed: %s",
        $self->dsn, $self->errstr() || "unknown error")) unless $self->ping;

    return $self;
}
sub is_mysql {
    my $self = shift;
    my $dr = $self->driver;
    return ($dr eq 'mysql' or $dr eq 'mariadb' or $dr eq 'maria') ? 1 : 0;
}
sub is_sqlite {
    my $self = shift;
    return $self->driver eq 'sqlite' ? 1 : 0;
}
```

Инициализация начинается с создания кешированного соединения с базой данных. Далее идёт проверка инициализации схемы, если схема не инициализирована, то выставляется признак необходимости выполнить предварительную инициализацию схемы, которая заключается в импорте SQL дампа с помощью строки `$self->dump->from_data->poke("ddl_" . $self->driver())`. Эта строка использует данные сеции `__DATA__` текущего класса и "выбирает" SQL блок помеченный тегом `ddl_sqlite` или `ddl_mysql` в зависимости от типа СУБД:

```sql
__DATA__
@@ schema

-- # ddl_sqlite
CREATE TABLE IF NOT EXISTS "altair" (
    "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "status"      INTEGER DEFAULT NULL,
    "comment"     TEXT DEFAULT NULL
)

-- # ddl_mysql
CREATE TABLE IF NOT EXISTS `altair` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `status` INT(11) DEFAULT NULL,
    `comment` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
```

После успешной инициализации происходит контрольный вызов проверки активности соединения, и возврат ошибки если что-то пошло не так

## Using

В обработчиках маршрутов класса `WWW::Altair::Server::Alpha` инициализация уже не потребуется, а этих обработчиках происходит использование ранее инициализированного кэшированного соединения, например:

```perl
sub tail { # GET /tail
    my $self = shift;

    # Get model
    my $model = $self->app->model->connect_cached;
    return $self->reply->json_error(500 => "E9003", $model->error)
      if $model->error;

    # Get log tail
    my @tail = $model->get_log_tail;
    return $self->reply->json_error(500 => "E9004", $model->error)
      if $model->error;

    # Render
    return $self->reply->json_ok({tail => \@tail});
}
```

В классе модели метод `get_log_tail` выглядит так:

```perl
use constant DML_LOG_TAIL => <<'DML';
SELECT * FROM altair ORDER BY `id` DESC LIMIT 100
DML

sub get_log_tail {
    my $self = shift;
    return () unless $self->ping;

    # Log tail
    my $tbl = {};
    if (my $res = $self->query(DML_LOG_TAIL)) {
        $tbl = $res->hashed_by( 'id' );
    } else {
        return ();
    }

    # Last 100 records (tail)
    my @tail = ();
    foreach my $id (sort {$b <=> $a} keys %$tbl) {
        my $v = $tbl->{$id};
        foreach my $k (keys %$v) {
            $v->{$k} //= "";
        }
        push @tail, $v;
    }

    return @tail;
}
```
