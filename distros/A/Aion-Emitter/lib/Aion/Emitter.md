!ru:en,badges
# NAME

Aion::Emitter - диспетчер событий

# SYNOPSIS

Файл lib/Event/BallEvent.pm:
```perl
package Event::BallEvent;

use Aion;

has radius => (is => 'rw', isa => Num);
has weight => (is => 'rw', isa => Num);

1;
```

Файл lib/Listener/RadiusListener.pm:
```perl
package Listener::RadiusListener;

use Aion;

#@listen Event::BallEvent
sub listen {
	my ($self, $event) = @_;
	
	$event->radius(10);
}

1;
```

Файл lib/Listener/WeightListener.pm:
```perl
package Listener::WeightListener;

use Aion;

#@listen Event::BallEvent
sub listen {
	my ($self, $event) = @_;
	
	$event->weight(12);
}

#@listen Event::BallEvent#mini „Minimize version”
sub minimize {
	my ($self, $event) = @_;
	
	$event->weight(3);
}

1;
```

Файл etc/annotation/listen.ann:
```text
Listener::RadiusListener#listen,6=Event::BallEvent
Listener::WeightListener#listen,6=Event::BallEvent
Listener::WeightListener#minimize,6=Event::BallEvent#mini „Minimize version”
```

```perl
use lib 'lib';

use Aion::Emitter;
use Event::BallEvent;

my $emitter = Aion::Emitter->new;
my $ballEvent = Event::BallEvent->new;

$emitter->emit($ballEvent);

$ballEvent->radius # -> 10
$ballEvent->weight # -> 12

$ballEvent->radius(0);

$emitter->emit($ballEvent, "mini");

$ballEvent->weight # -> 3
$ballEvent->radius # -> 0
```

# DESCRIPTION

Данный диспетчер событий реализует паттерн **Event Dispatcher** в котором событие определяется по классу объекта события (event).

Слушатель регистрируется как эон в плероме и будет всегда представлен одним объектом.

Метод обрабатывающий события отмечается аннотацией `#@listen`.

# SUBROUTINES

## emit ($event, [$key])

Излучает событие: вызывает все слушатели связанные с событием `$event`.

Дополнительный параметр `$key` позволяет указать уточняющее событие. Представьте, что у нас множество контроллеров и мы хотим излучить событие не для всех, а для каждого конкретного контроллера. Писать для каждого контроллера класс расширяющий класс запроса – расточительно.

`$key` может содержать буквы, цифры, подчёркивание, тире, двоеточие и точку.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Emitter module is copyright (c) 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
