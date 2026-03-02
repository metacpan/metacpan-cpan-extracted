# NAME

Aion::Emitter::ListenersRun - команда отображающая список слушателей

# SYNOPSIS

Файл etc/annotation/eon.ann:
```text
Aion::Emitter#new,1=Aion::Emitter
```

Файл etc/annotation/listen.ann:
```text
Listener::RadiusListener#listen,6=Event::BallEvent
Listener::WeightListener#listen,6=Event::BallEvent
Listener::WeightListener#minimize,6=Event::BallEvent#mini „Minimize version”
```

Код:
```perl
use Aion::Format qw/trappout/;
use Aion::Emitter::ListenersRun;

my $listenersRun = Aion::Emitter::ListenersRun->new;

my $output = trappout {
	$listenersRun->list;
};

$output # ~> „Minimize version”
```

# DESCRIPTION

Команда отображающая список слушателей.

# FEATURES

## mask

Маска для фильтра по командам.

## emitter

Эмиттер.

# SUBROUTINES

## list ()

Точка входа в команду.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Emitter::ListenersRun module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
