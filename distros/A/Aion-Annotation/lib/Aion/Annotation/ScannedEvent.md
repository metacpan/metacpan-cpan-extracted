!ru:en
# NAME

Aion::Annotation::ScannedEvent - событие завершения сканирования аннотаций в проекте

# SYNOPSIS

Файл lib/ScannedListener.pm:
```perl
package ScannedListener;

use Aion;

has scanned_count => (is => 'ro', isa => Int, default => 0);

#@listen Aion::Annotation::ScannedEvent „End scan”
sub scan_ended_listen {
	my ($self, $event) = @_;
	$self->{scanned_count}++;
}

1;
```

```perl
use Aion::Annotation;

my $listener = Aion->pleroma->get('ScannedListener');

Aion::Annotation->new->scan;

$listener->scanned_count # -> 1
```

# DESCRIPTION

Когда `Aion::Annotation` завершает сканирование проекта и записывает новые аннотации, то оно инициирует это событие.
При этом события в эмиттере перечитываются сразу после сканирования и до излучения события.

Очевидное применение данного события: превращение файла аннотаций в `crontab`.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Annotation::ScannedEvent module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
