[![Actions Status](https://github.com/darviarush/perl-aion-run/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-run/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion-Run.svg)](https://metacpan.org/release/Aion-Run) [![Coverage](https://raw.githubusercontent.com/darviarush/perl-aion-run/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=Aion-Run+0.0.1-prealpha)
# NAME

Aion::Run - роль для консольных команд

# VERSION

0.0.1-prealpha

# SYNOPSIS

Файл lib/Scripts/MyScript.pm:
```perl
package Scripts::MyScript;

use common::sense;

use List::Util qw/reduce/;
use Aion::Format qw/trappout/;

use Aion;

with qw/Aion::Run/;

# Operands for calculations
has operands => (is => "ro+", isa => ArrayRef[Int], arg => "-a", init_arg => "operand");

# Operator for calculations
has operator => (is => "ro+", isa => Enum[qw!+ - * /!], arg => 1);

#@run math/calc „Calculate”
sub calculate_sum {
    my ($self) = @_;
    printf "Result: %g\n", reduce {
        given($self->operator) {
            $a+$b when /\+/;
            $a-$b when /\-/;
            $a*$b when /\*/;
            $a/$b when /\//;
        }
    } @{$self->operands};
}

1;
```

```perl
use Aion::Format qw/trappout/;

use lib "lib";
use Scripts::MyScript;

trappout { Scripts::MyScript->new_from_args([qw/-a 1 -a 2 -a 3 +/])->calculate_sum } # => Result: 6\n
trappout { Scripts::MyScript->new_from_args([qw/--operand=4 * --operand=2/])->calculate_sum } # => Result: 8\n
```

# DESCRIPTION

Роль `Aion::Run` реализует аспект `arg` для установки фич из параметров командной строки.

* `arg => "-X"` — именованный параметр. Можно использовать как шорткут **\-X**, так и название фичи с **\--**.
* `arg => natural` — порядковый параметр. `1+`.
* `arg => 0` — все неименованные параметры. Используется с `isa => ArrayRef`.

# METHODS

## new_from_args ($pkg, $args)

Конструктор. Он создает объект сценария с параметрами командной строки.

```perl
package ArgExample {
	use Aion;
	
	with qw/Aion::Run/;
	
	has args => (is => "ro+", isa => ArrayRef[Str], arg => 0);
	has arg => (is => "ro+", isa => ArrayRef[Str], arg => '-a');
	has arg1 => (is => "ro+", isa => Str, arg => 1);
	has arg2 => (is => "ro+", isa => Str, init_arg => '_arg2', arg => 2);
	has arg_1 => (is => "ro+", isa => Str, init_arg => '_arg_1', arg => -1);
	has arg_2 => (is => "ro+", isa => Str, arg => -2);
}

my $ex = ArgExample->new_from_args([qw/1  -a 5  2  --arg=6 -2 5 --_arg_1=4/]);

$ex->arg1 # => 1
$ex->arg2 # => 2
$ex->arg_1 # => 4
$ex->arg_2 # => 5
$ex->args # --> [1, 2]
$ex->arg # --> [5, 6]
```

# SEE ALSO

* [Aion](https://metacpan.org/pod/Aion)

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Run module is copyright (с) 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
