use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

my $handler = test_handler();

my %triggered;
$handler->on('ns:all',  sub { $triggered{ns}++   });
$handler->on('ns:type', sub { $triggered{type}++ });

$handler->trigger('ns:type');
is $triggered{ns}, 1, 'triggered namespace for event with namespace and event';
is $triggered{type}, 1, 'triggered type for event with matching namespace and type';

%triggered = ();
$handler->trigger('ns:different-type');
ok !$triggered{type}, 'did not trigger type for event with matching namespace but different type';

%triggered = ();
$handler->trigger('ns');
ok !$triggered{ns}, 'did not trigger all types for event with no namespace';
ok !$triggered{type}, 'did not trigger type for event with matching type but no namespace';

%triggered = ();
$handler->trigger('different-ns:type');
ok !$triggered{ns}, 'did not trigger namespace for event with different namespace';
ok !$triggered{type}, 'did not trigger type for event with different namespace but matching type';

done_testing;
