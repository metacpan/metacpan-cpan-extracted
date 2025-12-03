!ru:en
# NAME

Aion::Run::RunsRun - список скриптов с аннотацией `#@run`

# SYNOPSIS

Файл etc/annotation/run.ann:
```
Aion::Run::RunRun#run=run:run „Executes Perl code in the context of the current project”
Aion::Run::RunsRun#list=run:runs „List of scripts”
```

```perl
use common::sense;
use Aion::Format qw/trappout coloring/;
use Aion::Run::RunsRun;

my $len = 4;
my $len2 = 6;

my $list = coloring "#yellow%s#r\n", "run";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "run", "code", "„Executes Perl code in the context of the current project”";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";

trappout { Aion::Run::RunsRun->new->list } # => $list
```

# DESCRIPTION

Печатает на стандартный вывод список сценариев из файла **etc/annotation/run.ann**.

Для этого загружает файлы, чтобы получить из них описание аргументов.

Поменять файл можно в конфиге `Aion::Run::Runner#INI`.

# FEATURES

## mask

Маска для фильтра по скриптам.

```perl
my $len = 4;
my $len2 = 6;

my $list = coloring "#yellow%s#r\n", "run";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";

trappout { Aion::Run::RunsRun->new(mask => 'runs')->list } # => $list
```

# SUBROUTINES

## list ()

Выводит список сценариев на `STDOUT`.

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Run::RunsRun module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
