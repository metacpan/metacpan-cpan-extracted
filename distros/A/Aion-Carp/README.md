[![Actions Status](https://github.com/darviarush/perl-aion-carp/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-carp/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion-Carp.svg)](https://metacpan.org/release/Aion-Carp) [![Coverage](https://raw.githubusercontent.com/darviarush/perl-aion-carp/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=Aion-Carp+1.6)
# NAME

Aion::Carp - добавляет трассировку стека в исключения

# VERSION

1.6

# SYNOPSIS

```perl
use Aion::Carp;

sub A { die "hi!" }
sub B { A() }
sub C { eval { B() }; die if $@ }
sub D { C() }

eval { D() };

my $expected = "hi!
    die(...) called at t/aion/carp.t line 15
    main::A() called at t/aion/carp.t line 16
    main::B() called at t/aion/carp.t line 17
    eval {...} called at t/aion/carp.t line 17
    main::C() called at t/aion/carp.t line 18
    main::D() called at t/aion/carp.t line 20
    eval {...} called at t/aion/carp.t line 20
";
$expected =~ s/^ {4}/\t/gm;

substr($@, 0, length $expected) # => $expected


my $exception = {message => "hi!"};
eval { die $exception };
$@  # -> $exception
$@->{message}  # => hi!
$@->{STACKTRACE}  # ~> ^die\(\.\.\.\) called at

$exception = {message => "hi!", STACKTRACE => 123};
eval { die $exception };
$exception->{STACKTRACE} # -> 123

$exception = [];
eval { die $exception };
$@ # --> []
```

# DESCRIPTION

Этот модуль заменяет `$SIG{__DIE__}` на функцию, добавляющую в исключения трассировку стека.

Если исключением является строка, к сообщению добавляется трассировка стека. А если исключением является хэш (`{}`) или объект на базе хеша (`bless {}, "..."`), то к нему добавляется ключ `STACKTRACE` со stacktrace.

При повторном выбрасывании исключения трассировка стека не добавляется, а остаётся прежней.

# SUBROUTINES

## handler ($message)

Добавляет трассировку стека в `$message`.

```perl
eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie
```

## import

Заменяет `$SIG{__DIE__}` на `handler`.

```perl
$SIG{__DIE__} = undef;
$SIG{__DIE__} # --> undef

Aion::Carp->import;

$SIG{__DIE__} # -> \&Aion::Carp::handler
```

# SEE ALSO

* `Carp::Always`

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
