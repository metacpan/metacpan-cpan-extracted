!ru:en
# NAME

Aion::Run::RunRun - выполняет Perl-код и распечатывает результат на STDOUT

# SYNOPSIS

```perl
use Aion::Format qw/trappout np/;
use Aion::Run::RunRun;

trappout { Aion::Run::RunRun->new(code => "1+2")->run } # -> np(3, caller_info => 0) . "\n"
```

# DESCRIPTION

Этот класс выполняет код perl `$ run [code](https://metacpan.org/pod/code)` и распечатывает результат на STDOUT.

# FEATURES

## code

Код для выполнения.

# SUBROUTINES

## run ()

Выполняет код perl в контексте текущего проекта.

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Run::RunRun module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
