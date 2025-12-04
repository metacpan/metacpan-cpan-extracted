!ru:en
# NAME

Aion::Run::Runner - запускает команду описанную аннотацией `#@run`

# SYNOPSIS

Файл etc/annotation/run.ann:
```
Aion::Run::RunRun#run,3=run:run „Executes Perl code in the context of the current project”
Aion::Run::RunsRun#list,5=run:runs „List of scripts”
```

```perl
use Aion::Format qw/trappout np/;
use Aion::Run::Runner;
use Aion::Run::RunRun;

trappout { Aion::Run::Runner->run("run", "1+2") } # -> np(3, caller_info => 0) . "\n"
```

# DESCRIPTION

`Aion::Run::Runner` считывает файл **etc/annotation/run.ann** со списком скриптов, а выполнить любой скрипт из списка можно через его метод `run`.

Путь к файлу cо скриптами можно поменять с помощью конфига `INI`.

Используется в команде `act`.

# FEATURES

## runs

Хеш с командами. Подгружается по дефолту из файла `INI`.

# SUBROUTINES

## run ($name, @args)

Запускает команду с именем `$name` и аргументами `@args` из списка **etc/annotation/run.ann**.

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Run::Runner module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
